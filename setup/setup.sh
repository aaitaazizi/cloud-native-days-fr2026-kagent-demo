#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
set -o pipefail

# Set default GitHub ID if not provided
GITHUB_ID=${GITHUB_ID:-aaitaazizi}
echo "Using GitHub ID: $GITHUB_ID"

# Replace aaitaazizi with the provided GitHub ID in all YAML and shell files
echo "Updating repository references with GitHub ID: $GITHUB_ID..."
find .. -type f \( -name "*.yaml" -o -name "*.sh" \) -exec sed -i '' "s/aaitaazizi/${GITHUB_ID}/g" {} +

echo "Setting up ArgoCD..."

if ! kubectl get namespace argocd &> /dev/null; then
    echo "Creating argocd namespace..."
    kubectl create namespace argocd
else
    echo "Namespace 'argocd' already exists, skipping creation."
fi

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

if ! helm status argocd -n argocd &> /dev/null; then
    echo "Installing ArgoCD via Helm..."
    helm upgrade --install argocd argo/argo-cd --version 8.0.0 -n argocd --values argo-values.yaml --wait
    kubectl rollout status -n argocd deploy/argocd-server

    # TODO: debug password reset
    echo "Setting default ArgoCD admin password to 'admin123'..." 
    kubectl patch secret -n argocd argocd-secret \
  -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" admin123 | tr -d ':\n')'"}}'

    echo "ArgoCD installed on kind cluster with username/password admin/admin123"
else
    echo "ArgoCD already installed, skipping installation."
fi

if ! kubectl get application sample-apps -n argocd &> /dev/null; then
    echo "Installing ArgoCD application..."
    kubectl apply -f argo-application.yaml
else
    echo "ArgoCD application 'sample-apps' already exists, skipping creation."
fi

# --- Check for OpenAI API Key ---
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set."
    echo "Please set it before running this script: export OPENAI_API_KEY='your-api-key'"
    exit 1
else
    echo "OPENAI_API_KEY is set."
fi

# --- Install kagent (CRDs and controller) ---
if ! kubectl get crd agents.kagent.dev &> /dev/null; then
    echo "kagent CRDs not found. Installing kagent CRDs via Helm (OCI)..."
    helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
        --namespace kagent \
        --create-namespace \
        --wait
else
    echo "kagent CRDs already present. Ensuring they are up to date..."
    helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
        --namespace kagent \
        --create-namespace \
        --wait
fi

echo "Installing/Upgrading kagent via Helm (OCI)..."
helm upgrade --install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace kagent \
    --set providers.default=openAI \
    --set providers.openAI.apiKey="$OPENAI_API_KEY" \
    --wait

# --- Check for GitHub token and create Secret ---
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "Error: GITHUB_PERSONAL_ACCESS_TOKEN environment variable is not set."
    echo "Please set it before running this script: export GITHUB_PERSONAL_ACCESS_TOKEN='your-github-pat'"
    exit 1
else
    echo "GITHUB_PERSONAL_ACCESS_TOKEN is set."
    if ! kubectl get secret github-pat-secret -n kagent &> /dev/null; then
        echo "Creating github-pat-secret with GITHUB_PERSONAL_ACCESS_TOKEN..."
        kubectl create secret generic github-pat-secret \
          --from-literal=GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
          -n kagent
    else
        echo "Secret 'github-pat-secret' already exists, ensuring required key is present..."
        if ! kubectl get secret github-pat-secret -n kagent -o jsonpath='{.data.GITHUB_PERSONAL_ACCESS_TOKEN}' | grep -q .; then
            echo "Patching secret to add GITHUB_PERSONAL_ACCESS_TOKEN..."
            kubectl patch secret github-pat-secret -n kagent \
              --type=merge \
              -p '{"stringData": {"GITHUB_PERSONAL_ACCESS_TOKEN": "'$GITHUB_PERSONAL_ACCESS_TOKEN'"}}'
        else
            echo "Key GITHUB_PERSONAL_ACCESS_TOKEN already present."
        fi
    fi
fi

echo "Setup complete!"

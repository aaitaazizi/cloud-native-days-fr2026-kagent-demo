### Demo Steps

1. Port-forward argocd server and visit http://localhost:8080
```bash
kubectl -n default port-forward service/argocd-server -n argocd 9000:443
```

2. Port forward the frontend service and view healthy application.
```bash
kubectl -n default port-forward svc/frontend 9090:9090
```
Open http://localhost:9090/ui/

3. Break the environment.
```bash
./break.sh
```

4. The sample-app repo should now show the broken commit: https://github.com/aaitaazizi

5. Go to Argo UI, sync the application. The frontend will show the application as unhealthy.

6. Apply the Github MCP Server yaml.
```bash
kubectl -n kagent apply -f gh-server.yaml
```

7. Apply the gitops agent yaml.
```bash
kubectl -n kagent apply -f gitops-agent.yaml
```

8. Start kagent dashboard, navigate to gitops agent.
```
kubectl -n kagent port-forward service/kagent-ui 8082:8080
```
Open http://localhost:8082

9. Ask the agent to fix the environment.

Prompts:
```
Calling the frontend service at http://frontend:9090 I see HTTP 500 errors reaching the backend. The apps are running in the default namespace.
```


9. Kagent should open a PR in the repo to fix the incorrect config.


10. Merge the PR, sync the application in Argo UI, then show the application as healthy in the UI.

# kagent Demo

### Prerequisites
* [Kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally.
* [Helm](https://helm.sh/docs/intro/install/) installed locally.
* [Kagent CLI](https://kagent.dev/docs/kagent/getting-started/quickstart#installing-kagent) installed locally.
* An [OpenAI API key](https://platform.openai.com/api-keys), set as an environment variable `OPENAI_API_KEY`.
* A [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token), set as an environment variable `GITHUB_PERSONAL_ACCESS_TOKEN`.

### Using Your Own GitHub Repository

To fork this project and use your own GitHub repository instead of the default one, export your GitHub ID as an environment variable:

```bash
export GITHUB_ID=your-github-username
```

### Setup

```bash
cd setup
./setup.sh
```

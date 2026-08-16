## 28-07-2026 - Planning a project

### What I learned

- How to write a project vision.

### What i tested

- Installing git on windows.
- Merging a branch.

 ## 29-07-2026 - FastAPI, Gemini

 ### What I worked on

- Select an AI provider.
- Create and work on phase 1 Jira Epic.
- Connected a basic FastAPI endpoint to Gemini.
- Explored Gemini’s free tier, API keys, quotas, and rate limits.
  
 ### What I learned

- Gemini’s free tier is a practical option for learning and small projects.
- Codex/ChatGPT tokens are separate from OpenAI API usage.
- AI output should be validated by the application instead of being trusted automatically.
- How a Python API receives and handles requests.

### What I tested

- Creating an API endpoint.
- Sending an API request to my app.
- Sending an API request to Gemini.

## 30-07-2026 - API requests, Vibe coding and health checks 

 ### What I worked on

- Improved and tested MealOps FastAPI application.
- Sent JSON requests using Postman, PowerShell and curl.
- Added a simple browser UI for MealOps.
- Planned the path from the local MVP to Docker, Azure/AKS, Terraform, Helm, and production.
- Created and started working on the KAN-25 — Containerize MealOps Epic.
- Added and ran automated tests with pytest and FastAPI TestClient.
  
 ### What I learned

- Configuration such as GEMINI_MODEL, LOG_LEVEL, and PROVIDER_TIMEOUT_MS should come from environment variables.
  Also how to write it in a Python script.
- How to configure health checks.
- pytest discovers and runs automated tests.
- FastAPI’s TestClient uses httpx internally and tests the application without starting a separate Uvicorn server.
- How to work with VS Code and Git repository.

### What I tested

- Vibe coding with Codex and Claude.
- Describing system instructions to an AI agent.
- Sending API requests with Postman.
- MealOps application.
- pytest.

## 31-07-2026 - Error handling, Docker

 ### What I worked on

- Containerize MealOps.
- Improved error handling.
- Add automated tests.
- Validated container security.
  
 ### What I learned

- "Exception" is a Python built-in class that catches most common application error.
- SIGTERM is a signal sent from the OS to the application, telling it to stop, Uvicron tells FastAPI to stop.
- Application tests shouldn't generally call a live AI. Their purpose is to check code validation.
- It is important to mention the version number on the requirements file.
- Docker scout is a Docker tool that looks for security problems.

### What I tested

- Writing application tests.
- Gemini errors: timeout, no given answers and invalid answers.
- User inputs invalid answer.
- Building and running MealOps on Docker.
- Docker scout for security problems.

## 01-08-2026 - Azure and terraform basics

 ### What I worked on

- Creating Azure account.
- Installed terraform and azure cli.
- Learning the basics of Terraform and Azure.
- Creating Resource Group, Storage Account, Blob Container.
- Configured Terraform remote state.
  
 ### What I learned

- A Service Principal is an Azure identity used by applications and automation to authenticate without a user.
- A Provider allows terraform to communicate with external platforms such as Azure.
- Resources are infrastructure objects managed by Terraform. Inside Terraform, each resource is identified by <resource_type>.<local_name>.
- The basic terraform worklow is: init, plan, apply, destroy.
- terraform.tfstate is a sate file that stores informtation anout the resources Terraform manage and maps your configuration to real infrastructure.
- variables.tf defines the variables, while terraform.tfvars provides values for those variables.
  This allows the same Terraform code to be reused for different environments (development, test, production).
- Some Azure resource properties require replacement instead of an update.
  For example, changing a Resource Group name causes Terraform to destroy and recreate it.
- A Blob is Azure name for file.
- A Blob Container is similar to a folder that stores blobs.
- How to read terraform plan.
- Azure Storage Account names must be globally unique.
- Terraform automatically detects dependencies between resources when one resource references another (implicit dependencies).
- Remote state allows multiple computers or team members to manage the same infrastructure.
  
### What I tested

- Created and deleted a Resource Group.
- Created a Storage Account.
- Created a Blob Container.
- Configured and verified Terraform remote state.
- Used Terraform commands: init, plan, apply, destroy, state.

## 03-08-2026 - Bootstrap & Infra, ACR

 ### What I worked on

- Dividing my Terraform project into 2 modules: 'bootstrap' and 'infra'.
- Created an Azure Container Registry (ACR).
  
 ### What I learned

- Terraform identifies resources by their resource address (e.g. `azurerm_resource_group.main`),
  not only by their Azure name. If the address changes, Terraform may plan to destroy and recreate the resource.
- The Terraform state file is stored remotely in Azure Blob Storage.
- The `backend` block tells Terraform where to store and retrieve its state.
- The `key` in the backend configuration is the name (or path) of the state file inside the Blob Container.
- How to define a Terraform resource and reference it from other resources.
- The difference between an input variable (`var`), a managed resource (`resource`), and a data source (`data`).
- The `bootstrap` module owns the backend infrastructure (Resource Group, Storage Account, and Blob Container).
- The `infra` module owns the application infrastructure (currently ACR).
- The difference between an Azure resource name and Terraform's local resource name.
- The difference between a Terraform resource and a data source.
- Terraform root modules are independent projects. Each module has its own provider configuration, backend configuration, and state file.

 ## 04-08-2026 - Azure Kubernetes Service (AKS)

 ### What I worked on

- Tagged and pushed the MealOps image to Azure Container Registry (ACR).
- Created an Azure Kubernetes Service (AKS) cluster with Terraform.
- Configured Azure RBAC to allow AKS to pull images from ACR.
- Created Kubernetes Deployment and Service manifests for MealOps.
- Deployed and ran MealOps on AKS.
  
 ### What I learned

- Tagging an existing Docker image does not create another image;
  it adds another tag that tell Docker where the image should be stored.
- `terraform fmt` automatically formtas Terraform configuration files
- `terraform validate` checks whether the terraform configuration is syntactically and logically valid
- Azure automatically creates a separate Managed Cluster Resource Group (MC_...)
  that contains the underlying infrastructure used by AKS (VM Scale Set, Load Balancer, Public IP, disks, etc.).
- A Cluster Identity is used by Azure to manage the Kubernetes cluster itself.
- Kubelet Identity is used by the worker nodes to get access to Azure resources, such as pulling images.
- `kubelet_identity` is exposed by the Terraform Azure provider as a list, even though it typically contains only one identity.
- The main Kubernetes Service types are ClusterIP, NodePort, LoadBalancer, and ExternalName
- A Kubernetes manifest is a YAML file that declares the desired state of a Kubernetes resource.
  
 ### Challenges & Solutions
  
- AKS creation initially failed because the Standard_B2s VM size was not
  available in my Azure subscription/region. I changed the node VM size to Standard_B2s_v2.
- Interrupted terraform apply, which left the remote state locked.
  Learned how Terraform state locking works and resolved it using terraform force-unlock.

## 07-08-2026 - Kubernetes Manifests Refactor, Health Checks, Secrets & ConfigMaps

### What I worked on

- Refactored Kubernetes Deployment and Service manifests.
- Added standard labels to the Deployment and Service.
- Added resource requests and limits.
- Created a Kustomization file to apply multiple Kubernetes resources together.
- Added readiness and liveness probes.
- Created a Kubernetes Secret for the Gemini API key.
- Created a ConfigMap for non-sensitive environment variables.

### What I learned

- `imagePullPolicy: IfNotPresent` pulls an image only if it does not already exist on the node. If an image with the same tag is cached, Kubernetes may use the cached version.
- When choosing resource requests and limits for the first time, start with reasonable values, run the application, monitor its actual usage, and adjust them based on real data.
- Kubernetes commonly uses binary memory units such as `Ki`, `Mi`, and `Gi`.
- `1000m` CPU equals 1 CPU core.
- `1 MiB` is about `1.05 MB`.
- Reaching a CPU limit can cause CPU throttling, while exceeding a memory limit can cause the container to be terminated with `OOMKilled`.
- The Kubernetes Scheduler decides which node a Pod should run on.
- Kustomize is built into `kubectl` and allows multiple Kubernetes manifests to be managed and applied together.
- `apiVersion` defines which Kubernetes API group and version should be used to interpret a resource.
- `kubectl` uses the kubeconfig file to know which Kubernetes cluster to connect to and how to authenticate.
- Docker CLI commands communicate with the Docker Engine.
- Kubernetes creates a default `kubernetes` Service for access to the Kubernetes API server.
- A Service endpoint represents the Pod IP and port that the Service can send traffic to.
- A readiness probe checks whether a Pod is ready to receive traffic.
- A liveness probe checks whether a container is healthy enough to keep running or should be restarted.
- If a readiness probe fails, Kubernetes removes the Pod from the Service endpoints, so traffic is no longer sent to it.
- When a Deployment is updated, Kubernetes usually performs a rolling update by creating new Pods before removing the old healthy ones.
- Editing a Kubernetes manifest locally does not change the resource in the cluster until it is applied with `kubectl apply`.
- `kubectl rollout restart` only restarts the Pods using the configuration that currently exists in the cluster; it does not apply changes from local YAML files.


### Challenges & Solutions

- After recreating the infrastructure with Terraform, the ACR was empty, so I had to push the Docker image again.
- I received an `ImagePullBackOff` error after deployment. Kubernetes retried pulling the image and the Pod eventually started successfully.
- My liveness probe used the wrong path (`/live` instead of `/health/live`), which caused the new Pod to enter `CrashLoopBackOff`. I found the issue using `kubectl describe pod`, corrected the path, and redeployed.
- The application was not reachable at first because I tried to access it with HTTPS instead of HTTP. Using the LoadBalancer external IP with HTTP worked.
- To test the ConfigMap behavior, I changed `PROVIDER_TIMEOUT_MS` to `300`. The Pod failed to start, so I changed it back to `30000` and ran `kubectl rollout restart deployment mealops`, but the application still did not recover. I entered the Pod using `kubectl exec` and checked the environment variable. I discovered that the Pod was still using the old timeout value. I realized that changing the local `configmap.yaml` file does not update the ConfigMap inside Kubernetes automatically. I first needed to run `kubectl apply -k .` to update the ConfigMap in the cluster, and only then restart the Deployment. After running `kubectl apply -k .` followed by `kubectl rollout restart deployment mealops`, the new Pod received the updated environment variable and started successfully.


## 09-08-2026 - GitOps with Argo CD and Multiple Kubernetes Environments

### What I worked on
- Created a PowerShell `start.ps1` script to automate the daily startup of the MealOps environment.
- Created a PowerShell `stop.ps1` script to automate Terraform destroy at the end of the day.
- Automated the startup flow:
  - `terraform init`
  - `terraform apply`
  - Read AKS, ACR, and Resource Group names from Terraform outputs.
  - Connect `kubectl` to AKS.
  - Login to ACR.
  - Tag and push the existing MealOps Docker image.
  - Create the Gemini API key Kubernetes Secret.
  - Wait for the Deployment and LoadBalancer.
- Added validation and status messages to the startup script.
- Installed Argo CD on AKS.
- Created an Argo CD Application for MealOps.
- Connected Argo CD to the MealOps Git repository.
- Configured Argo CD to automatically sync Kubernetes resources from Git.
- Enabled automatic sync, self-healing, and pruning.
- Tested GitOps synchronization by changing Kubernetes configuration in Git.
- Tested drift detection by manually changing the number of Deployment replicas.
- Updated the startup automation so Argo CD is responsible for deploying MealOps instead of `kubectl apply`.
- Created separate `mealops-prod` and `mealops-dev` namespaces.
- Restructured the Kubernetes manifests using Kustomize base and overlays.
- Created separate Kustomize overlays for dev and prod.
- Started configuring environment-specific Docker image versions.

### What I learned
- `$PSScriptRoot` is an automatic PowerShell variable that contains the directory path of the script that is currently running.
- `Split-Path -Parent $PSScriptRoot` can be used to get the project root when the script is stored inside a `scripts` directory.
- Terraform outputs are useful for connecting infrastructure automation with deployment automation instead of hard-coding Azure resource names.
- `kubectl create ... --dry-run=client -o yaml | kubectl apply -f -` allows a resource such as a Secret to be created or updated idempotently.
- If a Kubernetes Deployment starts a rollout but the Pods do not become Ready, the Deployment can eventually fail with `exceeded its progress deadline`.
- After fixing a configuration problem that affected already-created Pods, a Deployment may need to be restarted with:
  `kubectl rollout restart deployment mealops`
  so Kubernetes creates new Pods with the corrected configuration.
- `OutOfSync` means the live state in Kubernetes differs from the desired state stored in Git.
- Automatic sync applies Git changes automatically.
- `selfHeal` automatically restores resources when someone manually changes the Kubernetes cluster and causes it to differ from Git.
- `prune` allows Argo CD to delete Kubernetes resources that were removed from Git.
- Server-side apply can be used for large resources such as Argo CD CRDs to avoid the annotation size limit of client-side apply.
- The `images` section in a Kustomize overlay can replace the image name and tag without changing the base `deployment.yaml`.
- A dev Kubernetes environment is useful even when application code is tested locally because Kubernetes configuration changes still need a safe environment for testing.
- Local Docker builds and CI builds have different purposes: local builds are for development/testing, while CI creates the official deployable artifact from committed code.
- A good image strategy is to use the Git commit SHA as an immutable image tag, allowing me to know exactly which version of the application is running.

### Challenges & Solutions

- **Challenge:** The startup script calculated the wrong project path because `$PSScriptRoot` was initially handled incorrectly.
  - **Solution:** Used `$PSScriptRoot` directly as the `scripts` directory and `Split-Path -Parent $PSScriptRoot` to reliably get the MealOps project root.

- **Challenge:** The startup script could not read the AKS, ACR, and Resource Group names correctly.
  - **Solution:** Read the resource names directly from `terraform output -raw` while the script was inside the correct `terraform/infra` directory instead of hard-coding them.

- **Challenge:** The Deployment failed with `ProgressDeadlineExceeded` and the Pods did not become Ready.
  - **Solution:** Investigated the Pod/Deployment state and found that the Secret name created by `start.ps1` did not match the Secret name referenced by the Deployment. Fixed the Secret name and restarted the Deployment so new Pods were created with the correct configuration.

- **Challenge:** After fixing the configuration, the existing Pods were still part of the failed rollout.
  - **Solution:** Used `kubectl rollout restart deployment mealops` to force Kubernetes to recreate the Pods and start a new rollout.

- **Challenge:** Installing Argo CD failed with:

  `metadata.annotations: Too long: may not be more than 262144 bytes`

  for the `applicationsets.argoproj.io` CRD.
  - **Solution:** Installed Argo CD using `kubectl apply --server-side`. Server-side apply lets the Kubernetes API server manage the apply operation and field ownership instead of storing the entire previous configuration in the large client-side `last-applied-configuration` annotation.

- **Challenge:** Using the same mutable `latest` image for dev and prod would make it unclear which application version each environment is running.
  - **Solution:** Decided that CI-built images will eventually use the Git commit SHA as the image tag, while Kustomize overlays will specify which exact image version each environment should run.

 ## 10-08-2026 - GitHub Actions CI, Azure OIDC & ACR

 ### What I worked on
- Refactored start.ps1 so it no longer builds or pushes Docker images.
- Changed the startup flow so ACR is treated as persistent infrastructure and AKS/runtime infrastructure is recreated daily.
- Created my first GitHub Actions CI workflow for MealOps.
- Configured the workflow to run only when a push is made to `main` or a `kan-*` branch and something under `app/**` was changed.
- Configured GitHub Actions to build the MealOps Docker image from `app/Dockerfile`.
- Changed the Docker image tagging strategy to use the Git commit SHA.
- Created an App Registration and Service Principal for GitHub Actions.
- Gave the Service Principal `AcrPush` permission on the MealOps ACR.
- Configured OIDC authentication between GitHub Actions and Azure.
- Created a GitHub `development` Environment for temporary `kan-*` branches.
- Created separate Azure federated credentials for `development` and `main`.
- Added Azure IDs as GitHub repository secrets.
- Added Azure and ACR login to the CI workflow.
- Configured CI to push commit-tagged Docker images to ACR.
- Split the workflow into separate `build-dev` and `build-prod` jobs.
- Verified that the image created by CI exists in ACR.

 ### What I learned

- GitHub Actions workflows are stored under `.github/workflows/`.
- `runs-on: ubuntu-latest` means GitHub creates a temporary Ubuntu runner on which the job executes.
- `actions/checkout` downloads the repository content to the runner.
- `${{ github.sha }}` contains the Git commit SHA that triggered the workflow and can be used as an immutable Docker image tag.
- An App Registration defines an application's identity in Microsoft Entra ID.
- A Service Principal is the representation of that application inside a tenant and can receive Azure permissions.
- One App Registration can have Service Principals in different tenants, while a Service Principal represents one application.
- OIDC allows GitHub Actions to authenticate to Azure without storing a long-lived Azure client secret.
- `contents: read` explicitly allows the workflow to read repository content.
- `id-token: write` allows the workflow to request an OIDC token from GitHub.
- Before explicitly defining `permissions`, GitHub can provide default `GITHUB_TOKEN` permissions, which is why `actions/checkout` worked before adding `contents: read`.
- A GitHub Environment is a named context used by a job.
- A branch does not automatically belong to an Environment; the workflow assigns the job to it with `environment: development`.
- GitHub Environments can have their own security rules, secrets and OIDC identity.

 ### Challenges and solutions

- Challenge: start.ps1 stopped while waiting for Argo because kubectl get deployment returned NotFound.
- Solution: Redirected the command output so the expected NotFound result does not terminate the PowerShell script, allowing the retry loop to continue.
- Challenge: The first Argo-managed Pods could not start because the image was missing from ACR.
- Solution: Pushed the required image to the persistent ACR and reran the startup script.
- Challenge: The registry and infra Terraform folders originally used the same backend key, which mixed their Terraform state.
- Solution: Gave the registry stack its own backend key so persistent ACR state is separate from disposable runtime infrastructure.
- Challenge: Azure login initially failed with `AADSTS700016: Application with identifier was not found`.
- Solution: Verified the App Registration and corrected the `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` GitHub secrets.
- Challenge: After fixing the IDs, Azure returned `AADSTS700213: No matching federated identity record found`.
- Cause: The OIDC `subject` stored in Azure did not exactly match the subject GitHub was actually sending.
- Solution: Read the real subject from the GitHub Actions login output and recreated the federated credential with the exact immutable repository identifiers.
- Challenge: Temporary branches such as `kan-43`, `kan-44`, etc. would require separate branch-based federated credentials.
- Solution: Created a GitHub Environment called `development` and configured Azure to trust the environment instead of every individual temporary branch.
- Challenge: Setting `environment: development` on the only build job would also make `main` use the development OIDC identity.
- Solution: Split CI into separate `build-dev` and `build-prod` jobs so development and main can use different authentication contexts.


## 11-08-2026 - GitHub Actions CI for Dev & Prod

### What I worked on

- Updated the dev CI to automatically update the dev image tag after building and pushing a new image.
- Configured the dev CI to commit the updated image tag back to Git.
- Created a separate manually triggered workflow for promoting images to production.
- Added validation to the production workflow to verify that the requested image tag exists in ACR before promoting it.
- Created a production GitHub Environment.
- Created an Azure Federated Credential for the production GitHub Environment.
- Configured the production workflow to authenticate to Azure using OIDC.
- Verified that Argo CD automatically deploys the desired image version from Git to both dev and prod.

### What I learned

- A Federated Credential tells Azure which external identity is trusted to authenticate as an Azure application.
- OIDC federation allows GitHub Actions to authenticate to Azure without storing a long-lived Azure client secret.
- GitHub Actions generates a temporary OIDC token automatically when a workflow with `id-token: write` requests one.
- The `issuer` identifies the system that issued the OIDC token. For GitHub Actions, the issuer is `https://token.actions.githubusercontent.com`.
- The `subject` identifies the specific GitHub identity that Azure should trust, such as a repository and GitHub Environment.
- GitHub can use immutable repository and owner IDs in the OIDC subject instead of relying only on names.
- Microsoft Entra ID is Microsoft's identity and access management service, previously called Azure Active Directory.
- A tenant is an organization's Microsoft Entra ID identity boundary, while an Azure subscription is mainly a resource and billing boundary.
- An App Registration represents an application identity, and its Client ID identifies that application.
- The Git username and email configured in CI define the author of the Git commit; they are not the credentials used to authenticate the push.
- `workflow_dispatch` allows a GitHub Actions workflow to be triggered manually and can accept user inputs.
- Dev deployment can be automatic while production promotion remains manually controlled.
- Production should promote the exact immutable image that was already built and tested in dev instead of rebuilding the application.

### Challenges and solutions

- Updated the Federated Credential to use the exact subject generated by GitHub, which fixed Azure authentication.
- Production needed its own Federated Credential because the production workflow uses the `production` GitHub Environment, which produces a different OIDC subject from `development`.

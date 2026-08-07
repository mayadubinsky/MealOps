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

## 28-07-2026 - Planning a project

### What I learned

- How to write a project vision.

### What i tested

- Installing git on windows.
- Merging a branch.

- ## 29-07-2026 - FastAPI, Gemini

- ### What I worked on

- Select an AI provider.
- Create and work on phase 1 Jira Epic.
- Connected a basic FastAPI endpoint to Gemini.
- Explored Gemini’s free tier, API keys, quotas, and rate limits.
  
- ### What I learned

- Gemini’s free tier is a practical option for learning and small projects.
- Codex/ChatGPT tokens are separate from OpenAI API usage.
- AI output should be validated by the application instead of being trusted automatically.
- How a Python API receives and handles requests.

### What I tested

- Creating an API endpoint.
- Sending an API request to my app.
- Sending an API request to Gemini.

- ## 30-07-2026 - API requests, Vibe coding and health checks 

- ### What I worked on

- Improved and tested MealOps FastAPI application.
- Sent JSON requests using Postman, PowerShell and curl.
- Added a simple browser UI for MealOps.
- Planned the path from the local MVP to Docker, Azure/AKS, Terraform, Helm, and production.
- Created and started working on the KAN-25 — Containerize MealOps Epic.
- Added and ran automated tests with pytest and FastAPI TestClient.
  
- ### What I learned

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
  
- ## 31-07-2026 - Error handling, Docker

- ### What I worked on

- Containerize MealOps.
- Improved error handling.
- Add automated tests.
- Validated container security.
  
- ### What I learned

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

- ## 01-08-2026 - Azure and terraform basics

- ### What I worked on

- Creating Azure account.
- Installed terraform and azure cli.
- Learning the basics of Terraform and Azure.
- Creating Resource Group, Storage Account, Blob Container.
- Configured Terraform remote state.
  
- ### What I learned

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

- ### What I worked on

- Dividing my Terraform project into 2 modules: 'bootstrap' and 'infra'.
- Created an Azure Container Registry (ACR).
  
- ### What I learned

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


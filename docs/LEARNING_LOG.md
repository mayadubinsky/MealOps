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
  

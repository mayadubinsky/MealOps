# MealOps

MealOps is a browser-based seven-day meal planner that uses Google Gemini to
generate a meal plan and consolidated shopping list.

## Prerequisites

Install the following before using the container workflow:

- Git, for cloning the repository.
- Docker Desktop, with the Docker Engine running.
- PowerShell, for the commands in this guide.

Confirm that Docker is available:

```powershell
docker version
```

## Runtime configuration

MealOps reads its configuration from environment variables when it starts.
Never store a real API key in the Dockerfile, source code, or Git.

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `GEMINI_API_KEY` | Yes, for meal generation | None | Authenticates requests to Gemini. |
| `GEMINI_MODEL` | No | `gemini-3.1-flash-lite` | Selects the Gemini model. |
| `LOG_LEVEL` | No | `INFO` | Controls application log verbosity. |
| `PROVIDER_TIMEOUT_MS` | No | `30000` | Sets the Gemini request timeout in milliseconds. |

Set the required key in the PowerShell session that will run Docker:

```powershell
$env:GEMINI_API_KEY = "your-api-key"
```

The example value is a placeholder. Do not commit a real key.

## Build the image

From the repository root, build the local image:

```powershell
docker build -t mealops:local .
```

## Run the container

Run MealOps in the foreground and pass the API key from PowerShell at runtime:

```powershell
docker run --rm `
  --name mealops `
  -p 8000:8000 `
  --env GEMINI_API_KEY `
  --env GEMINI_MODEL `
  --env LOG_LEVEL `
  --env PROVIDER_TIMEOUT_MS `
  mealops:local
```

Unset optional variables are allowed because MealOps supplies safe defaults.
Open `http://127.0.0.1:8000` after the container starts.

To use a different host port, change only the value before the colon. For
example, `-p 8080:8000` exposes MealOps at `http://127.0.0.1:8080`.

## Verify application health

With the container running, use another PowerShell window:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health/live
Invoke-RestMethod http://127.0.0.1:8000/health/ready
```

The liveness endpoint should return `alive`, and the readiness endpoint should
return `ready`. Neither health check contacts Gemini.

## Run automated tests

The tests use mocked provider behavior and do not require a Gemini API key or
network access.

```powershell
python -m pip install -r requirements-dev.txt
Remove-Item Env:GEMINI_API_KEY -ErrorAction SilentlyContinue
python -m pytest
```

## Stop the container

For a foreground container, press `Ctrl+C`. Docker sends the application a
termination signal and Uvicorn performs a graceful shutdown.

If the container is running elsewhere or in detached mode, stop it by name:

```powershell
docker stop mealops
```

## Troubleshooting

### Missing or invalid Gemini API key

The UI and health endpoints can load without a key, but meal generation will
fail. Set `GEMINI_API_KEY` in the same PowerShell session used to start the
container, stop the old container, and start a new one. A running container
does not receive later changes made to PowerShell environment variables.

### Port 8000 is already in use

Identify the process listening on the port:

```powershell
Get-NetTCPConnection -LocalPort 8000 -State Listen
```

Stop the existing MealOps container with `docker stop mealops`, or publish the
new container on another host port with `-p 8080:8000`.

### Provider timeout or failure

MealOps returns a controlled error when Gemini is slow or unavailable. Check
the container logs for operational context:

```powershell
docker logs mealops
```

Confirm that the API key is valid and that the computer has network access. If
needed, set a larger `PROVIDER_TIMEOUT_MS` value and recreate the container.
Do not place exception details or API keys in client-visible messages.

### Docker cannot find `mealops:local`

List available images and verify the repository and tag:

```powershell
docker image ls
```

If the image is absent, return to the repository root and run the build command
again.

## Verify from a clean checkout

A developer validating a clean checkout should run, in order:

```powershell
python -m pip install -r requirements-dev.txt
python -m pytest
docker build --no-cache -t mealops:local .
docker run --rm --name mealops -p 8000:8000 --env GEMINI_API_KEY mealops:local
```

Then open the UI, check both health endpoints, and generate one meal plan.

## Updating dependencies

1. Update one direct dependency at a time.
2. Run the complete automated test suite.
3. Test MealOps locally.
4. Rebuild and test the Docker image.
5. Record the verified version in the appropriate requirements file.

# MealOps

A simple browser UI for the MealOps seven-day meal planner.

## Run it

Set the Google Gemini API key in the same PowerShell window used to run the
app:

```powershell
$env:GEMINI_API_KEY = "your-api-key"
uvicorn app:app --reload
```

Open `http://127.0.0.1:8000`.

## Updating dependencies

1. Update one direct dependency at a time.
2. Run the complete automated test suite.
3. Test MealOps locally.
4. Rebuild and test the Docker image.
5. Record the verified version in the appropriate requirements file.
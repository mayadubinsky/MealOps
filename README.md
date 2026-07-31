# MealOps

A simple browser UI for the MealOps seven-day meal planner.

## Run it

Set the Google Gemini API key in the same PowerShell window used to run the
app:

```powershell
$env:GEMINI_API_KEY = "your-api-key"
uvicorn --app-dir "MealOps" app:app --reload 
```

Open `http://127.0.0.1:8000`.

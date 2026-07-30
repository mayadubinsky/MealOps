# Type hints make request and response structures easier to understand.
from pathlib import Path
from typing import List

# FastAPI serves the API and the HTML page.
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
# Gemini generates the meal plan and shopping list.
from google import genai
from google.genai import types
# Pydantic validates incoming and generated data.
from pydantic import BaseModel, Field
# Read operating-system environment variables.
import os
# Configure application logging.
import logging


# Read the Gemini model name, or use this safe local default.
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite",)
# Read the logging level, or use INFO by default.
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
# Read the provider timeout in milliseconds, or use 30 seconds by default.
PROVIDER_TIMEOUT_MS = int(os.getenv("PROVIDER_TIMEOUT_MS", "30000"))
# Apply the selected logging level.
logging.basicConfig(level=LOG_LEVEL)


# Create the web application.
app = FastAPI(title="MealOps", description="AI-powered weekly meal planning")
# Allow browser requests to reach the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# Validate the user's meal-plan preferences.
class FoodRequest(BaseModel):
    res: str = Field(pattern="^(unrestricted|vegetarian|vegan)$")
    kosher: bool = False
    allergies: List[str] = []


# Describe one recipe ingredient.
class Ingredient(BaseModel):
    name: str
    quantity: str


# Describe one complete meal.
class Meal(BaseModel):
    name: str
    ingredients: List[Ingredient]
    instructions: str
    time_minutes: int


# Group the five meals for one day.
class Day(BaseModel):
    day_number: int
    breakfast: Meal
    morning_snack: Meal
    lunch: Meal
    afternoon_snack: Meal
    dinner: Meal


# Hold all days returned by Gemini.
class MealPlan(BaseModel):
    days: List[Day]


# Describe one consolidated shopping item.
class ShoppingItem(BaseModel):
    name: str
    quantity: str


# Hold the full shopping list.
class ShoppingList(BaseModel):
    items: List[ShoppingItem]


def get_client():
    """Create the client at request time so the UI can load without an API key."""
    # Gemini reads GEMINI_API_KEY from the environment.
    return genai.Client()


def gather_raw_ingredients(meal_plan: MealPlan) -> List[dict]:
    """Flatten every meal's ingredients into one list."""
    # Start with an empty collection.
    raw = []
    # Visit each day and each meal.
    for day in meal_plan.days:
        for meal in (
            day.breakfast,
            day.morning_snack,
            day.lunch,
            day.afternoon_snack,
            day.dinner,
        ):
            # Add the meal's ingredients without changing their values.
            raw.extend(
                {"name": ingredient.name, "quantity": ingredient.quantity}
                for ingredient in meal.ingredients
            )
    # Return the unmerged ingredient list.
    return raw


def consolidate_shopping_list(client, raw_ingredients: List[dict]) -> ShoppingList:
    """Ask Gemini to merge duplicate ingredients and quantities."""
    # Request a response that matches ShoppingList exactly.
    response = client.models.generate_content(
        model="gemini-3.1-flash-lite",
        contents=(
            "Consolidate this raw ingredient list from a seven-day meal plan. "
            "Merge preparation variants and singular/plural forms:\n"
            f"{raw_ingredients}"
        ),
        config=types.GenerateContentConfig(
            system_instruction=(
                "Return a clean shopping list. Sum compatible quantities, use sensible "
                "rounded totals for countable items, and exclude water. Each item must "
                "have a simple name and one human-readable quantity."
            ),
            response_mime_type="application/json",
            response_schema=ShoppingList,
        ),
    )
    # Return Gemini's validated structured result.
    return response.parsed


# Serve the browser interface at the site root.
@app.get("/", response_class=HTMLResponse)
def home():
    # Load the page beside app.py, independent of the launch directory.
    html_path = Path(__file__).with_name("index.html")
    return HTMLResponse(html_path.read_text(encoding="utf-8"))


# Provide a lightweight server health check.
@app.get("/health")
def health():
    return {"status": "ok"}


# Generate a complete meal plan from submitted preferences.
@app.post("/food")
def choose_food(request: FoodRequest):
    # Combine the diet and kosher choice for the prompt.
    restriction = f"{request.res}, kosher" if request.kosher else request.res
    # Create an authenticated Gemini client.
    client = get_client()

    try:
        # Ask Gemini for a structured seven-day plan.
        response = client.models.generate_content(
            model="gemini-3.1-flash-lite",
            contents=(
                f"Dietary restriction: {restriction}\n"
                f"Kosher requested: {request.kosher}\n"
                f"Allergies to avoid: {', '.join(request.allergies) or 'none'}\n"
            ),
            config=types.GenerateContentConfig(
                system_instruction=(
                    "You are a practical food-planning assistant. Create a healthy "
                    "seven-day meal plan for one person. Strictly follow the dietary "
                    "restriction and avoid every listed allergen. Allergy restrictions "
                    "always take priority. Include breakfast, morning snack, lunch, "
                    "afternoon snack, and dinner each day. For every meal give clear "
                    "ingredient quantities, concise instructions, and total time in "
                    "minutes. Use accessible ingredients and avoid repetition. "
                    "Vegetarian excludes meat, poultry, fish, and seafood. Vegan also "
                    "excludes dairy, eggs, honey, and all animal-derived ingredients. "
                    "When kosher is enabled, exclude non-kosher animals and seafood, "
                    "never combine meat and dairy, and recommend reliable certification "
                    "when an ingredient's status is uncertain."
                ),
                response_mime_type="application/json",
                response_schema=MealPlan,
            ),
        )
        # Read the validated plan and build its shopping list.
        meal_plan: MealPlan = response.parsed
        shopping_list = consolidate_shopping_list(
            client, gather_raw_ingredients(meal_plan)
        )
    except Exception as exc:
        # Convert provider failures into a useful API error.
        raise HTTPException(
            status_code=502,
            detail=(
                "Meal generation failed. Check that GEMINI_API_KEY is set, then try again."
            ),
        ) from exc

    # Send both generated sections back to the browser.
    return {
        "restriction": restriction,
        "meal_plan": meal_plan,
        "shopping_list": shopping_list,
    }

# SimpleNamespace creates small objects that behave like Gemini responses.
from types import SimpleNamespace

# Import the application module so its Gemini client can be replaced.
import app as app_module
from fastapi.testclient import TestClient


# Test MealOps without starting a real server.
client = TestClient(app_module.app)


class FakeModels:
    """Return predictable results instead of contacting Gemini."""

    def __init__(self):
        # Create one fake meal used throughout the test plan.
        meal = app_module.Meal(
            name="Vegetable soup",
            ingredients=[
                app_module.Ingredient(name="carrot", quantity="2"),
            ],
            instructions="Cook the vegetables.",
            time_minutes=30,
        )

        # Prepare the result for the first Gemini call.
        meal_plan = app_module.MealPlan(
            days=[
                app_module.Day(
                    day_number=1,
                    breakfast=meal,
                    morning_snack=meal,
                    lunch=meal,
                    afternoon_snack=meal,
                    dinner=meal,
                )
            ]
        )

        # Prepare the result for the second Gemini call.
        shopping_list = app_module.ShoppingList(
            items=[
                app_module.ShoppingItem(
                    name="carrot",
                    quantity="10",
                )
            ]
        )

        # Return these responses in the order MealOps requests them.
        self.responses = [
            SimpleNamespace(parsed=meal_plan),
            SimpleNamespace(parsed=shopping_list),
        ]

    def generate_content(self, **kwargs):
        # Return the next prepared response without using the network.
        return self.responses.pop(0)

class FailureModels:
    """Simulate a general Gemini provider failure."""

    def generate_content(self, **kwargs):
        # Pretend Gemini failed while processing the request.
        raise RuntimeError("Simulated Gemini failure")

class InvalidResponseModels:
    """Simulate Gemini returning a response MealOps cannot use."""

    def generate_content(self, **kwargs):
        # Gemini responded, but no valid structured result was parsed.
        return SimpleNamespace(parsed=None)


class FakeClient:
    """Provide any fake models implementation to MealOps."""

    def __init__(self, models):
        self.models = models


def test_successful_meal_generation(monkeypatch):
    """A valid request should return the mocked meal plan and shopping list."""
    # Replace the real Gemini client with the fake client.
    monkeypatch.setattr(
        app_module,
        "get_client",
        lambda: FakeClient(FakeModels())),

    # Submit a valid request to MealOps.
    response = client.post(
        "/food",
        json={
            "res": "vegetarian",
            "kosher": False,
            "allergies": [],
        },
    )

    # Confirm that MealOps processed the fake Gemini responses successfully.
    assert response.status_code == 200

    result = response.json()
    assert result["restriction"] == "vegetarian"
    assert result["meal_plan"]["days"][0]["breakfast"]["name"] == "Vegetable soup"
    assert result["shopping_list"]["items"][0]["name"] == "carrot"

def test_invalid_food_request_is_rejected():
    """An unsupported dietary restriction should fail validation."""
    # Send a value that is not allowed by the FoodRequest model.
    response = client.post(
        "/food",
        json={
            "res": "pescatarian",
            "kosher": False,
            "allergies": [],
        },
    )

    # FastAPI should reject it before contacting Gemini.
    assert response.status_code == 422

def test_general_Gemini_error():
    """General Gemini errors should fail validation."""
    # Send a value that is not allowed by the FoodRequest model.
    response = client.post(
        "/food",
        json={
            "res": "pescatarian",
            "kosher": False,
            "allergies": [],
        },
    )

    # FastAPI should reject it before contacting Gemini.
    assert response.status_code == 422

def test_provider_failure_returns_502(monkeypatch):
    """A Gemini failure should return a safe HTTP 502 response."""
    # Replace the real Gemini client with the failing fake client.
    monkeypatch.setattr(
        app_module,
        "get_client",
        lambda: FakeClient(FailureModels()),
    )

    # Send a valid request that reaches the fake Gemini client.
    response = client.post(
        "/food",
        json={
            "res": "vegetarian",
            "kosher": False,
            "allergies": [],
        },
    )

    # Confirm that MealOps handled the failure instead of crashing.
    assert response.status_code == 502

    # Confirm that the response contains only the safe public message.
    assert response.json() == {
        "detail": "Meal generation is temporarily unavailable. Please try again."
    }

    # Confirm that internal error information was not returned.
    assert "Simulated Gemini failure" not in response.text

def test_invalid_provider_response_returns_502(monkeypatch):
    """An invalid Gemini response should produce a safe HTTP 502 error."""
    # Replace Gemini with a client that returns invalid data.
    monkeypatch.setattr(
        app_module,
        "get_client",
        lambda: FakeClient(InvalidResponseModels()),
    )

    # Send a valid request so processing reaches the fake provider.
    response = client.post(
        "/food",
        json={
            "res": "vegetarian",
            "kosher": False,
            "allergies": [],
        },
    )

    # Confirm that MealOps treats the unusable response as a provider failure.
    assert response.status_code == 502

    # Confirm that the user receives only a safe public message.
    assert response.json() == {
        "detail": "Meal generation is temporarily unavailable. Please try again."
    }
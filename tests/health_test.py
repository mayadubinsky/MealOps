# FastAPI's test client sends requests without starting a real server.
from fastapi.testclient import TestClient

# Import the MealOps application that the tests will check.
from app import app


# Create one client shared by the health endpoint tests.
client = TestClient(app)


def test_liveness():
    """The liveness endpoint confirms that the API process is running."""
    # Send a request to the liveness endpoint.
    response = client.get("/health/live")

    # Confirm that the endpoint returns a successful and stable response.
    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_readiness():
    """The readiness endpoint confirms that MealOps can accept requests."""
    # Send a request to the readiness endpoint.
    response = client.get("/health/ready")

    # Confirm that the endpoint returns a successful and stable response.
    assert response.status_code == 200
    assert response.json() == {"status": "ready"}
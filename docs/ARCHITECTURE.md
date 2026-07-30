# MealOps MVP Architecture

## 1. Purpose

Describe the technical design of the MealOps MVP.

## 2. MVP scenario

A user select one of three dietary options: unrestricted, vegetarian, vegan.
The user can provide a list of allergies and indicate whether kosher restrictions should be applied.
MealOps generates a seven-day meal plan and a combined shopping list.

## 3. Architecture diagram

 User
  |
  v
Postman (API client)
  |  
  v
MealOps API
  |
  v
OpenAI API
  
## 4. Components

### MealOps API

Responsibilities:
- Accept user preferences and restrictions
- Request a meal plan from the AI provider
- Validate the generated result
- Return the result to the user
- Generate the combined shopping list from the validated recipes.
- The MVP exposes an API only; it does not include a graphical user interface.

### AI provider

Responsibilities:
- Generate a meal plan in a predefined format
- Follow the supplied preferences and restrictions
- Provide a recipe to any relevant meal

## 5. Main data flow

1. The user sends dietary restrictions and preferences through Postman.
2. The MealOps API validates the request.
3. The MealOps API requests a weekly meal plan from the OpenAI API.
4. The OpenAI API returns a structured meal plan and its recipes.
5. The MealOps API validates the response against a predefined schema.
6. The MealOps API generates a combined shopping list from the validated recipes.
7. The MealOps API returns the meal plan, recipes, and shopping list.
   
## 6. Data storage

The MVP does not use persistent storage. Input and generated data exist only
while processing the API request and in the response returned to the client.

Postman may display the latest response, but MealOps does not retain it.
Submitting another request generates a new result.

## 7. Important design decisions

- The MealOps API validates AI output instead of trusting it.
- The MVP supports one user.
- Meal-plan generation is manual in the MVP.
- The MVP has only API
- The OpenAI API will be used as the AI provider
- Recipes will be represented separately from the weekly meal-plan schedule 
- API keys will be provided through environment variables using an uncommitted .env file. No secrets will be stored in source code or Git.
- The MVP applies the simplified kosher rules defined in `REQUIREMENTS.md`.

## 8. In case of an error
- The MealOps API validates the AI response against a predefined schema.
- If validation fails, it retries the request once.
- If the second response is invalid, the API returns a clear error asking the
  user to try again later.
  
## 8. Out of scope

- Azure deployment
- Database
- Kubernetes
- Terraform
- Argo CD
- Complete LGTM monitoring
- Multiple users
- Authentication
- Automatic weekly scheduling
- Reminders

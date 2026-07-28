The initial version supports one user and one saves profile

## Initial User
The initial user is a single person using MealOps to plan their own weekly meals.
The user:
- Has one saved dietary profile
- Plans meals for themselves
- Uses one set of restrictions and preferences
- Generates one meal plan and shopping list per week
- Does not need registration or authentication
- Does not share the account or meal plan with other users

# Dietary restrictions and preferences - Must have
The user can configure:
- Allergies, such as peanuts or shellfish
- Intolerances, such as lactose or gluten
- A dietary pattern: unrestricted, vegetarian, or vegan
- Whether simplified kosher rules should also be applied
- Ingredients the user dislikes
- Favorite foods and cuisines
- Maximum preparation time per meal
- Preferred meal variety
- The number of times a meal is repeated consecutively.

Rules:
- Restrictions must be treated as mandatory.
- Preferences should influence the plan but do not always have to be satisfied.
- AI-generated meals must be validated against the saved restrictions.
- The user can update their profile.
- MealOps supports the following simplified dietary patterns:
  - Unrestricted: No exclusions based on a dietary pattern. Allergies, intolerances, and disliked ingredients still apply.
  - Vegetarian: Excludes meat, poultry, fish, seafood, and ingredients derived from slaughtered animals. Dairy, eggs, and honey are allowed.
  - Vegan: Excludes meat, poultry, fish, seafood, dairy, eggs, honey, and other animal-derived ingredients.
- If the kosher option is enabled, these simplified rules are added to the selected dietary pattern:
  - Non-kosher animals and seafood are excluded.
  - Meat and dairy cannot appear in the same meal.
  - Ingredient certification, kitchen equipment, preparation methods, and waiting periods between meat and dairy are outside the MVP.

> MealOps provides planning assistance and does not guarantee medical or allergen safety.

## Weekly meal plan — Must have
The application can:
- Generate a seven-day meal plan using the saved profile
- Provide one planned meal per day
- Include the meal name, ingredients, quantities, instructions, preparation time, and number of servings
- Display the complete weekly plan
- Report an error if a valid plan cannot be generated

## Shopping list — Must have
The application can:
- Generate a shopping list from the weekly meal plan
- Combine duplicate ingredients
- Add together quantities that use compatible units
- Associate the shopping list with its meal plan
- Display ingredient names, quantities, and units

# Schedule - Could have
The user can configure:
- The day and time or automatic weekly plan generation
- Preferred cooking or meal-preparation times
Note: maximum preparation time belongs under dietary preferences; scheduled preparation time belongs here.

# Meal editing and regeneration - Could have
The user can regenerate:
- One specific meal
- All meals for a specific day
- The entire weekly plan
Regenerated meals must still satisfy the saved restrictions.

# Reminders and notification channel - Could have
The user can configure:
- A notification channel: Email or Telegram
- When the weekly meal plan is delivered
- When meal-preparation reminders are deleivered 

# Security and privacy expectations - Must have
Even the initial version must:
- Keep API keys and credentials out of source control
- Avoid writing secrets to logs
- Avoid exposing the user's dietary information publicly
- Validate all user and AI-generated input

User authentication and advanced security controls are out of scope while the application supports only one local user.

## Success criteria
The initial version is successful when the user can:
1. Save and update one profile.
2. Generate a complete seven-day meal plan.
3. Receive meals that do not intentionally conflict with saved restrictions.
4. Generate a consolidated shopping list from that plan.
5. Close and restart the application without losing the profile or generated plan.
6. Complete the main workflow repeatedly without an unhandled error.

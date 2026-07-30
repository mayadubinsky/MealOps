from collections import defaultdict
from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from google import genai
from google.genai import types
from pydantic import BaseModel, Field

app = FastAPI(title="MealOps", description="AI-powered weekly meal planning")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class FoodRequest(BaseModel):
    res: str = Field(pattern="^(unrestricted|vegetarian|vegan)$")
    kosher: bool = False
    allergies: List[str] = []


class Ingredient(BaseModel):
    name: str
    quantity: str


class Meal(BaseModel):
    name: str
    ingredients: List[Ingredient]
    instructions: str
    time_minutes: int


class Day(BaseModel):
    day_number: int
    breakfast: Meal
    morning_snack: Meal
    lunch: Meal
    afternoon_snack: Meal
    dinner: Meal


class MealPlan(BaseModel):
    days: List[Day]


class ShoppingItem(BaseModel):
    name: str
    quantity: str


class ShoppingList(BaseModel):
    items: List[ShoppingItem]


def get_client():
    """Create the client at request time so the UI can load without an API key."""
    return genai.Client()


def gather_raw_ingredients(meal_plan: MealPlan) -> List[dict]:
    raw = []
    for day in meal_plan.days:
        for meal in (
            day.breakfast,
            day.morning_snack,
            day.lunch,
            day.afternoon_snack,
            day.dinner,
        ):
            raw.extend(
                {"name": ingredient.name, "quantity": ingredient.quantity}
                for ingredient in meal.ingredients
            )
    return raw


def consolidate_shopping_list(client, raw_ingredients: List[dict]) -> ShoppingList:
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
    return response.parsed


@app.get("/", response_class=HTMLResponse)
def home():
    return HTMLResponse(UI_HTML)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/food")
def choose_food(request: FoodRequest):
    restriction = f"{request.res}, kosher" if request.kosher else request.res
    client = get_client()

    try:
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
        meal_plan: MealPlan = response.parsed
        shopping_list = consolidate_shopping_list(
            client, gather_raw_ingredients(meal_plan)
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=(
                "Meal generation failed. Check that GEMINI_API_KEY is set, then try again."
            ),
        ) from exc

    return {
        "restriction": restriction,
        "meal_plan": meal_plan,
        "shopping_list": shopping_list,
    }


UI_HTML = r"""
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>MealOps — Your week, planned</title>
  <style>
    :root{--ink:#193126;--muted:#64746c;--cream:#f5f2e9;--paper:#fffdf7;--sage:#dce8d7;--green:#285c43;--orange:#e97745;--line:#d9ddd3;--shadow:0 18px 55px rgba(36,59,46,.12)}
    *{box-sizing:border-box} body{margin:0;background:var(--cream);color:var(--ink);font:15px/1.5 Inter,ui-sans-serif,system-ui,-apple-system,sans-serif}
    button,input{font:inherit}.shell{max-width:1180px;margin:auto;padding:26px}
    header{display:flex;align-items:center;justify-content:space-between;margin-bottom:44px}.brand{display:flex;align-items:center;gap:11px;font-size:20px;font-weight:800;letter-spacing:-.03em}.mark{width:34px;height:34px;border-radius:11px;background:var(--green);display:grid;place-items:center;color:white;font-size:18px}.tag{color:var(--muted);font-size:13px}
    .hero{display:grid;grid-template-columns:1.08fr .92fr;gap:48px;align-items:start;margin-bottom:45px}.eyebrow{text-transform:uppercase;letter-spacing:.14em;color:var(--orange);font-weight:800;font-size:12px}.hero h1{font:700 clamp(44px,7vw,78px)/.96 Georgia,serif;letter-spacing:-.055em;margin:14px 0 20px;max-width:700px}.hero-copy{font-size:18px;color:var(--muted);max-width:560px}
    .form-card{background:var(--paper);border:1px solid rgba(38,75,55,.12);padding:28px;border-radius:26px;box-shadow:var(--shadow)}.form-card h2{font:700 26px Georgia,serif;margin:0 0 22px}.label{display:block;font-size:12px;font-weight:800;text-transform:uppercase;letter-spacing:.08em;margin:20px 0 9px}
    .choices{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}.choice input{position:absolute;opacity:0}.choice span{display:block;text-align:center;padding:11px 8px;border:1px solid var(--line);border-radius:12px;cursor:pointer}.choice input:checked+span{background:var(--green);color:white;border-color:var(--green)}
    .toggle-row{display:flex;align-items:center;justify-content:space-between;padding:13px 0}.switch{position:relative;width:46px;height:26px}.switch input{opacity:0}.slider{position:absolute;inset:0;background:#cfd4cd;border-radius:99px;cursor:pointer}.slider:after{content:"";position:absolute;width:20px;height:20px;left:3px;top:3px;background:white;border-radius:50%;transition:.2s}.switch input:checked+.slider{background:var(--green)}.switch input:checked+.slider:after{transform:translateX(20px)}
    .allergy{width:100%;border:1px solid var(--line);border-radius:12px;background:white;padding:12px 14px;outline:none}.allergy:focus{border-color:var(--green);box-shadow:0 0 0 3px rgba(40,92,67,.12)}.hint{font-size:12px;color:var(--muted);margin:6px 0 0}
    .generate{width:100%;border:0;background:var(--orange);color:white;padding:14px;border-radius:13px;font-weight:800;margin-top:24px;cursor:pointer;box-shadow:0 8px 20px rgba(233,119,69,.24)}.generate:hover{filter:brightness(.96)}.generate:disabled{opacity:.65;cursor:wait}
    #status{display:none;margin:0 0 22px;padding:14px 18px;border-radius:14px;background:var(--sage)}#status.error{background:#f8ddd4;color:#842d20}.results{display:none}.result-head{display:flex;justify-content:space-between;align-items:end;margin-bottom:20px}.result-head h2{font:700 36px Georgia,serif;margin:0}.pill{background:var(--sage);padding:7px 11px;border-radius:99px;font-size:12px;font-weight:700;text-transform:capitalize}
    .layout{display:grid;grid-template-columns:1fr 310px;gap:22px;align-items:start}.days{display:grid;gap:14px}.day{background:var(--paper);border:1px solid var(--line);border-radius:18px;overflow:hidden}.day-head{display:flex;justify-content:space-between;align-items:center;padding:17px 20px;cursor:pointer}.day-head h3{font:700 21px Georgia,serif;margin:0}.day-body{display:none;border-top:1px solid var(--line);padding:6px 20px 18px}.day.open .day-body{display:block}.meal{padding:15px 0;border-bottom:1px solid #e8e8e1}.meal:last-child{border:0}.meal-top{display:flex;justify-content:space-between;gap:15px}.meal h4{margin:0 0 7px;font-size:15px}.meal-type{color:var(--orange);text-transform:uppercase;font-size:10px;letter-spacing:.1em;font-weight:800}.time{white-space:nowrap;color:var(--muted);font-size:12px}.ingredients{color:var(--muted);font-size:13px;margin:7px 0}.instructions{font-size:13px;margin:0}
    .shopping{position:sticky;top:20px;background:var(--green);color:white;border-radius:20px;padding:22px}.shopping h3{font:700 23px Georgia,serif;margin:0 0 5px}.shopping .sub{color:#c7d9cf;font-size:12px;margin-bottom:15px}.shop-list{list-style:none;padding:0;margin:0;max-height:64vh;overflow:auto}.shop-list li{display:flex;justify-content:space-between;gap:12px;padding:9px 0;border-bottom:1px solid rgba(255,255,255,.13);font-size:13px}.qty{color:#c7d9cf;text-align:right}
    .empty{border:1px dashed #bfc8bd;border-radius:18px;padding:30px;text-align:center;color:var(--muted)}
    @media(max-width:850px){.hero,.layout{grid-template-columns:1fr}.hero{gap:28px}.shopping{position:static}.hero h1{font-size:52px}.tag{display:none}}@media(max-width:500px){.shell{padding:18px}.choices{grid-template-columns:1fr}.hero h1{font-size:44px}.form-card{padding:20px}.result-head{align-items:start;flex-direction:column;gap:10px}}
  </style>
</head>
<body>
<main class="shell">
  <header><div class="brand"><div class="mark">◒</div>MealOps</div><div class="tag">Seven days. One smart shopping list.</div></header>
  <section class="hero">
    <div><div class="eyebrow">Meal planning, simplified</div><h1>Your week,<br>beautifully planned.</h1><p class="hero-copy">A thoughtful seven-day menu built around how you actually eat—complete with simple recipes and one organized shopping list.</p></div>
    <form class="form-card" id="meal-form">
      <h2>Build my plan</h2>
      <span class="label">Eating style</span>
      <div class="choices">
        <label class="choice"><input type="radio" name="res" value="unrestricted" checked><span>Everything</span></label>
        <label class="choice"><input type="radio" name="res" value="vegetarian"><span>Vegetarian</span></label>
        <label class="choice"><input type="radio" name="res" value="vegan"><span>Vegan</span></label>
      </div>
      <div class="toggle-row"><div><strong>Keep it kosher</strong><div class="hint">Apply simplified kosher rules</div></div><label class="switch"><input id="kosher" type="checkbox"><span class="slider"></span></label></div>
      <label class="label" for="allergies">Allergies to avoid</label>
      <input class="allergy" id="allergies" placeholder="e.g. peanuts, shellfish, sesame">
      <p class="hint">Separate multiple allergies with commas.</p>
      <button class="generate" id="generate" type="submit">Create my week →</button>
    </form>
  </section>
  <div id="status" role="status"></div>
  <section class="results" id="results">
    <div class="result-head"><div><div class="eyebrow">Your fresh plan</div><h2>Seven delicious days</h2></div><span class="pill" id="restriction"></span></div>
    <div class="layout"><div class="days" id="days"></div><aside class="shopping"><h3>Shopping list</h3><div class="sub">Everything you need for the week</div><ul class="shop-list" id="shopping"></ul></aside></div>
  </section>
</main>
<script>
const form=document.querySelector('#meal-form'),button=document.querySelector('#generate'),statusBox=document.querySelector('#status'),results=document.querySelector('#results');
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const labels={breakfast:'Breakfast',morning_snack:'Morning snack',lunch:'Lunch',afternoon_snack:'Afternoon snack',dinner:'Dinner'};
function mealCard(type,m){const ingredients=m.ingredients.map(i=>`${esc(i.quantity)} ${esc(i.name)}`).join(' · ');return `<article class="meal"><div class="meal-top"><div><div class="meal-type">${labels[type]}</div><h4>${esc(m.name)}</h4></div><span class="time">◷ ${esc(m.time_minutes)} min</span></div><p class="ingredients">${ingredients}</p><p class="instructions">${esc(m.instructions)}</p></article>`}
function render(data){document.querySelector('#restriction').textContent=data.restriction;document.querySelector('#days').innerHTML=data.meal_plan.days.map((d,i)=>`<section class="day ${i===0?'open':''}"><div class="day-head" role="button" tabindex="0" aria-expanded="${i===0}"><h3>Day ${d.day_number}</h3><span>＋</span></div><div class="day-body">${Object.keys(labels).map(k=>mealCard(k,d[k])).join('')}</div></section>`).join('');document.querySelector('#shopping').innerHTML=data.shopping_list.items.map(i=>`<li><span>${esc(i.name)}</span><span class="qty">${esc(i.quantity)}</span></li>`).join('');document.querySelectorAll('.day-head').forEach(h=>{const toggle=()=>{h.parentElement.classList.toggle('open');h.setAttribute('aria-expanded',h.parentElement.classList.contains('open'))};h.onclick=toggle;h.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();toggle()}}});results.style.display='block';results.scrollIntoView({behavior:'smooth',block:'start'})}
form.addEventListener('submit',async e=>{e.preventDefault();button.disabled=true;button.textContent='Planning your week…';statusBox.className='';statusBox.style.display='block';statusBox.textContent='Creating 35 meals and organizing your shopping list. This can take a minute.';results.style.display='none';const allergies=document.querySelector('#allergies').value.split(',').map(s=>s.trim()).filter(Boolean);try{const response=await fetch('/food',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({res:new FormData(form).get('res'),kosher:document.querySelector('#kosher').checked,allergies})});const raw=await response.text();let data;try{data=JSON.parse(raw)}catch{throw new Error(response.ok?'The server returned an unreadable response.':'The server failed to process the request. Check the terminal for details.')}if(!response.ok)throw new Error(data.detail||'Could not create your plan.');statusBox.style.display='none';render(data)}catch(err){statusBox.className='error';statusBox.textContent=err.message}finally{button.disabled=false;button.textContent='Create my week →'}});
</script>
</body></html>
"""

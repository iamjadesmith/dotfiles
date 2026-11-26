---
name: recipe
description: Generate, research, adapt, import, and save recipes for Jade (dairy-free) and Jade's fiancée (gluten-free), high-protein and low-fuss with Costco staples. Use for meal ideas, recipe creation or modification, importing a recipe from a URL, cooking methods, temperatures and timing, meal coordination, leftovers, and saving recipes to ~/projects/recipes or the Apple Notes Recipes folder.
---

# Recipe

The recipe collection and its conventions live in `~/projects/recipes`. Before writing or saving a recipe, read `~/projects/recipes/CLAUDE.md`. It holds the dietary rules, equipment, answer style, format template, and save procedure. Skip reading it for a quick cooking question you can answer directly.

Essentials if you can't read it:
- Shared meals are dairy-free **and** gluten-free; no dairy substitutes unless asked.
- High protein, simple spicy seasoning, minimal dishes; Costco ingredients.
- Precise quantities, °F, times, heat levels, and doneness cues; follow USDA food safety.
- Keep imported recipes' quantities and method unless asked to change them; link sources for adaptations.
- Search existing recipes in `~/projects/recipes/*.md` before inventing one Jade already has.
- **Save only when explicitly asked.** "Save" = repo file (commit + push) and `~/projects/recipes/scripts/save-to-notes.sh "<file>"` for Apple Notes, unless Jade names one destination.
- For nutrition targets, read `Nutrition Plan.md` in the Obsidian vault (read-only).

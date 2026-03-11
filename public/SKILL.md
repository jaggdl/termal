---
name: termal-api
description: API documentation for Termal meal tracking application. Provides endpoints for retrieving user meals, nutritional data, and daily targets. Use when working with meal tracking, nutritional information, or user meal history in the Termal application.
license: MIT
metadata:
  version: "1.0"
  author: termal-team
---

# Termal API

Base URL: `/api`

## Prerequisites

Set the `TERMAL_API_TOKEN` environment variable with your API key. Generate your API key from the `/profile` page in the Termal web application.

```bash
export TERMAL_API_TOKEN="your_api_key_here"
```

## Endpoints

### GET /api/user_meals

Retrieves meals consumed by the current user for a specific date.

**Parameters:**
- `date` (optional): Date in ISO 8601 format (YYYY-MM-DD). Defaults to today.

**Returns:**
- `date`: The requested date
- `meals`: Array of meals consumed, each containing consumption details and meal information (name, calories, proteins, carbs, fats)
- `totals`: Aggregated nutritional values (calories, proteins, carbs, fats) for all meals on the date
- `targets`: User's daily nutritional targets from their profile settings
- `percentages`: Percentage of daily targets achieved for each nutrient (calories, proteins, carbs, fats)

**Example:**
```bash
curl -H "Authorization: Bearer $TERMAL_API_TOKEN" \
  "https://example.com/api/user_meals?date=2026-03-10"
```

### GET /api/nutrition_summary

Retrieves daily nutrition summaries for a date range.

**Parameters:**
- `days` (optional): Number of days to look back. Defaults to 7, maximum 365.

**Returns:**
- `summaries`: Array of daily nutrition summaries, each containing:
  - `date`: The date (ISO 8601 format)
  - `calories`: Total calories consumed
  - `proteins`: Total protein in grams
  - `carbs`: Total carbohydrates in grams
  - `fats`: Total fats in grams
- `targets`: User's daily nutritional targets for each nutrient
- `averages`: Average daily consumption with percentage relative to targets:
  - For each nutrient (calories, proteins, carbs, fats):
    - `quantity`: Average daily amount
    - `percentage_of_target`: Percentage of daily target achieved

**Example:**
```bash
curl -H "Authorization: Bearer $TERMAL_API_TOKEN" \
  "https://example.com/api/nutrition_summary?days=7"
```

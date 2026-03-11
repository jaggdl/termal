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

## Authentication

All API endpoints require an API key. Generate your API key from the `/profile` page in the Termal web application.

Include the API key in the `Authorization` header:

```
Authorization: Bearer YOUR_API_KEY
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

## Additional Endpoints

More endpoints will be added to the API in future releases.

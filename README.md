# DeepSeek Nutrition Service

A dedicated service for handling DeepSeek AI API calls for nutrition analysis, ingredient calculation, and food modification.

## Features

- Specialized endpoints for different nutrition operations
- Error handling and fallback mechanisms
- Response normalization
- Proper JSON validation and extraction

## Setup

1. Install dependencies:
```
npm install
```

2. Create a `.env` file with the following content:
```
DEEPSEEK_API_KEY=your_deepseek_api_key
PORT=3000
```

3. Run locally:
```
npm run dev
```

## API Endpoints

### Health Check
```
GET /
```

### General Analysis
```
POST /api/analyze
```
Body:
```json
{
  "prompt": "Your instruction to DeepSeek AI",
  "operation_type": "general"
}
```

### Nutrition Calculation
```
POST /api/nutrition
```
Body:
```json
{
  "food_name": "Apple",
  "serving_size": "100g"
}
```

### Food Modification
```
POST /api/fix-food
```
Body:
```json
{
  "food_name": "Pasta dish",
  "current_data": {
    "calories": "450",
    "protein": "15",
    "fat": "12",
    "carbs": "65",
    "ingredients": [
      {
        "name": "Pasta",
        "amount": "200g",
        "calories": 300,
        "protein": 10,
        "fat": 2,
        "carbs": 60
      },
      {
        "name": "Olive Oil",
        "amount": "15ml",
        "calories": 120,
        "protein": 0,
        "fat": 14,
        "carbs": 0
      }
    ]
  },
  "instructions": "Remove the olive oil",
  "operation_type": "REMOVE_INGREDIENT"
}
```

## Deployment

This service is designed to be deployed to Render.com.

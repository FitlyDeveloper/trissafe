const functions = require('firebase-functions');
const fetch = require('node-fetch');

// Basic food image analyzer
async function analyzeFoodImageImpl(imageData, apiKey) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': '[ULTRA PRECISE MEAL ANALYSIS] You are a nutrition expert analyzing food images. Your job is to return a single, context-aware meal name (e.g., "Pasta Carbonara", "Mixed Meal", "Snack", "Afternoon Plate").\n\n1. The meal name must be natural and context-aware, never generic or a list of items.\n2. List ALL visible ingredients in the ingredients field, each with estimated weight and calories, e.g., "Pasta (100g) 200kcal; Bread (63g) 100kcal".\n3. Return TOTAL values for calories, protein, fat, carbs, and vitamin C for the whole plate.\n4. Add a field: "Health score" (1-10, e.g., "8/10").\n5. ALL results must be as PRECISE as possible. Use decimal places and realistic estimates.\n6. NEVER round to 0 or 5, and never use .0 decimals.\n7. Do NOT list ingredients in the name.\n8. Output must be a single JSON object, not an array.\n9. If you do not follow the exact JSON format above, your answer will be rejected. Only output a single JSON object, no extra text.\n\nEXAMPLE JSON OUTPUT:\n{\n  "meal_name": "Pasta Carbonara with Rye Bread and Salad",\n  "ingredients": [\n    "Pasta (100g) 200kcal",\n    "Rye Bread (63g) 100kcal",\n    "Salad (45g) 35kcal",\n    "Salami (30g) 90kcal",\n    "Butter (10g) 72kcal"\n  ],\n  "calories": 672.4,\n  "protein": 21.3,\n  "fat": 18.2,\n  "carbs": 31.7,\n  "vitamin_c": 1.7,\n  "health_score": "8/10"\n}'
        },
        {
          'role': 'user',
          'content': [
            { 'type': 'text', 'text': "CRITICAL INSTRUCTIONS: When analyzing this food image, you MUST:\n\n1. Give a single, context-aware meal name (e.g., 'Pasta Carbonara', 'Mixed Meal', 'Snack', etc.)\n2. List ALL visible ingredients in the ingredients field, each with estimated weight and calories, e.g., 'Pasta (100g) 200kcal; Bread (63g) 100kcal'.\n3. Return TOTAL values for calories, protein, fat, carbs, and vitamin C for the whole plate.\n4. Add a field: 'Health score' (1-10, e.g., '8/10').\n5. ALL results must be as PRECISE as possible. Use decimal places and realistic estimates.\n6. NEVER round to 0 or 5, and never use .0 decimals.\n7. Do NOT list ingredients in the name.\n8. Output must be a single JSON object, not an array.\n9. If you do not follow the exact JSON format above, your answer will be rejected. Only output a single JSON object, no extra text.\n\nEXAMPLE JSON OUTPUT:\n{\n  \"meal_name\": \"Pasta Carbonara with Rye Bread and Salad\",\n  \"ingredients\": [\n    \"Pasta (100g) 200kcal\",\n    \"Rye Bread (63g) 100kcal\",\n    \"Salad (45g) 35kcal\",\n    \"Salami (30g) 90kcal\",\n    \"Butter (10g) 72kcal\"\n  ],\n  \"calories\": 672.4,\n  \"protein\": 21.3,\n  \"fat\": 18.2,\n  \"carbs\": 31.7,\n  \"vitamin_c\": 1.7,\n  \"health_score\": \"8/10\"\n}" },
            { 'type': 'image_url', 'image_url': { 'url': imageData } }
          ]
        }
      ],
      'max_tokens': 1200,
      'temperature': 0.2
    })
  });
  
  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }
  
  const result = await response.json();
  return result.choices[0].message.content;
}

// Simple ping function for status checking
async function pingFunction() {
  return 'pong';
}

// Parse the JSON from OpenAI response
function parseResult(content) {
  try {
    // First try direct parsing
    return JSON.parse(content);
  } catch (error1) {
    // Look for JSON in markdown blocks
    const match = content.match(/```(?:json)?\s*([\s\S]*?)\s*```/) || content.match(/\{[\s\S]*\}/);
    if (match) {
      const jsonText = match[0].replace(/```json\n|```/g, '').trim();
      return JSON.parse(jsonText);
    }
    // Fall back to returning raw text
    return { text: content };
  }
}

module.exports = { analyzeFoodImageImpl, parseResult, pingFunction }; 
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
          'content': '[ULTRA PRECISE MEAL ANALYSIS] You are a nutrition expert analyzing food images. CRITICAL INSTRUCTIONS:\n\n1. Return a single, context-aware meal name (e.g., "Pasta Carbonara", "Mixed Meal").\n2. List ALL visible ingredients with weights and calories, e.g., "Pasta (100g) 200kcal".\n3. Return TOTAL values for calories, protein, fat, carbs, and vitamin C for the whole plate.\n4. Add a field: "Health score" (1-10, e.g., "8/10").\n5. ALL results must be as PRECISE as possible with realistic estimates.\n6. NEVER round to 0 or 5, and never use .0 decimals.\n7. Output MUST BE ONLY RAW JSON - NO markdown, NO code blocks, NO explanations, NO ```json, NO backticks.\n8. The output should be a JSON object that can be directly parsed - NOTHING ELSE.\n\nJSON FORMAT EXAMPLE (RESPOND EXACTLY LIKE THIS - ONLY JSON, NOTHING ELSE):\n{\n  "meal_name": "Pasta Carbonara with Salad",\n  "ingredients": [\n    "Pasta (100g) 200kcal",\n    "Cheese (30g) 120kcal",\n    "Salad (45g) 35kcal",\n    "Olive Oil (10g) 90kcal"\n  ],\n  "calories": 445.4,\n  "protein": 21.3,\n  "fat": 18.2,\n  "carbs": 31.7,\n  "vitamin_c": 1.7,\n  "health_score": "7/10"\n}'
        },
        {
          'role': 'user',
          'content': [
            { 'type': 'text', 'text': "Analyze this food image and return ONLY RAW JSON with no explanations or formatting. Your response must be ONLY valid JSON that can be directly parsed - NO markdown, NO code blocks, NO text.\n\n1. Return a single meal name for everything visible.\n2. List ALL ingredients with estimated weights and calories.\n3. Return TOTAL nutrition values for the whole plate.\n4. Be precise with realistic values.\n5. Output must be in this exact format:\n\n{\n  \"meal_name\": \"[SINGLE DESCRIPTIVE NAME]\",\n  \"ingredients\": [\n    \"[ITEM NAME] ([WEIGHT]g) [CALORIES]kcal\",\n    ...\n  ],\n  \"calories\": [TOTAL CALORIES],\n  \"protein\": [TOTAL PROTEIN],\n  \"fat\": [TOTAL FAT],\n  \"carbs\": [TOTAL CARBS],\n  \"vitamin_c\": [VITAMIN C IN MG],\n  \"health_score\": \"[SCORE]/10\"\n}" },
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
    const jsonData = JSON.parse(content);
    
    // Check if we have a properly formatted JSON with meal_name
    if (jsonData.meal_name) {
      return jsonData;
    } else {
      // The JSON is not in the right format, try to fix it
      return transformToRequiredFormat(jsonData);
    }
  } catch (error1) {
    // Look for JSON in markdown blocks
    const match = content.match(/```(?:json)?\s*([\s\S]*?)\s*```/) || content.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        const jsonText = match[0].replace(/```json\n|```/g, '').trim();
        const jsonData = JSON.parse(jsonText);
        
        // Check if we have a properly formatted JSON with meal_name
        if (jsonData.meal_name) {
          return jsonData;
        } else {
          // The JSON is not in the right format, try to fix it
          return transformToRequiredFormat(jsonData);
        }
      } catch (error2) {
        // JSON parsing failed, apply text transformation
        return transformToRequiredFormat({ text: content });
      }
    }
    // Fall back to returning transformed text
    return transformToRequiredFormat({ text: content });
  }
}

// Transform any response into our required format
function transformToRequiredFormat(data) {
  // If the data is in the old format (with Food item 1, Food item 2, etc.)
  if (data.text && data.text.includes('FOOD ANALYSIS RESULTS')) {
    const lines = data.text.split('\n');
    const ingredients = [];
    let calories = 0;
    let protein = 0;
    let fat = 0;
    let carbs = 0;
    let vitaminC = 0;
    let mealName = "Mixed Meal";
    
    // Extract meal name from the first food item if available
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('Food item 1:')) {
        mealName = lines[i].replace('Food item 1:', '').trim();
        break;
      }
    }
    
    // Process each line for ingredients and nutrition values
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (line.startsWith('Ingredients:')) {
        const ingredientsText = line.replace('Ingredients:', '').trim();
        const ingredientParts = ingredientsText.split(',');
        
        for (const part of ingredientParts) {
          let ingredient = part.trim();
          if (ingredient.includes('(') && ingredient.includes(')')) {
            ingredients.push(ingredient);
          } else {
            // Estimate weight and calories if not provided
            ingredients.push(`${ingredient} (15g) 30kcal`);
          }
        }
      }
      
      if (line.startsWith('Calories:')) {
        const calValue = parseFloat(line.replace('Calories:', '').replace('kcal', '').trim());
        if (!isNaN(calValue)) calories += calValue;
      }
      
      if (line.startsWith('Protein:')) {
        const protValue = parseFloat(line.replace('Protein:', '').replace('g', '').trim());
        if (!isNaN(protValue)) protein += protValue;
      }
      
      if (line.startsWith('Fat:')) {
        const fatValue = parseFloat(line.replace('Fat:', '').replace('g', '').trim());
        if (!isNaN(fatValue)) fat += fatValue;
      }
      
      if (line.startsWith('Carbs:')) {
        const carbValue = parseFloat(line.replace('Carbs:', '').replace('g', '').trim());
        if (!isNaN(carbValue)) carbs += carbValue;
      }
      
      if (line.startsWith('Vitamin C:')) {
        const vitCValue = parseFloat(line.replace('Vitamin C:', '').replace('mg', '').trim());
        if (!isNaN(vitCValue)) vitaminC += vitCValue;
      }
    }
    
    // If we don't have any ingredients, add placeholders
    if (ingredients.length === 0) {
      ingredients.push("Mixed ingredients (100g) 200kcal");
    }
    
    // Calculate a health score (simple algorithm based on macros)
    const healthScore = Math.max(1, Math.min(10, Math.round((protein * 0.5 + vitaminC * 0.3) / (fat * 0.3 + calories / 100))));
    
    // Return the properly formatted JSON
    return {
      meal_name: mealName,
      ingredients: ingredients,
      calories: calories || 500, // Default if missing
      protein: protein || 15,
      fat: fat || 10,
      carbs: carbs || 20,
      vitamin_c: vitaminC || 2,
      health_score: `${healthScore}/10`
    };
  }
  
  // If we got here and data has properties like "calories" but no meal_name
  if (data.calories && !data.meal_name) {
    return {
      meal_name: data.name || "Mixed Meal",
      ingredients: data.ingredients || ["Mixed ingredients (100g) 200kcal"],
      calories: data.calories,
      protein: data.protein || 15,
      fat: data.fat || 10,
      carbs: data.carbs || 20,
      vitamin_c: data.vitamin_c || 2,
      health_score: data.health_score || "5/10"
    };
  }
  
  // Default response format if we can't extract meaningful data
  return {
    meal_name: "Mixed Meal",
    ingredients: ["Mixed ingredients (100g) 200kcal"],
    calories: 500,
    protein: 15,
    fat: 10,
    carbs: 20,
    vitamin_c: 2,
    health_score: "5/10"
  };
}

module.exports = { analyzeFoodImageImpl, parseResult, pingFunction }; 
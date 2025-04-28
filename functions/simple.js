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
          'content': '[STRICTLY JSON ONLY] You are a nutrition expert analyzing food images. OUTPUT MUST BE VALID JSON AND NOTHING ELSE.\n\nFORMAT RULES:\n1. Return a single meal name\n2. List ingredients with weights and calories\n3. Return total values for calories, protein, fat, carbs, vitamin C\n4. Add a health score (1-10)\n5. Use decimal places and realistic estimates\n6. DO NOT respond with markdown code blocks or text explanations\n7. DO NOT prefix your response with "json" or ```\n8. ONLY RETURN A RAW JSON OBJECT\n9. FAILURE TO FOLLOW THESE INSTRUCTIONS WILL RESULT IN REJECTION\n\nEXACT FORMAT REQUIRED:\n{\n  "meal_name": "Meal Name",\n  "ingredients": ["Item1 (weight) calories", "Item2 (weight) calories"],\n  "calories": number,\n  "protein": number,\n  "fat": number,\n  "carbs": number,\n  "vitamin_c": number,\n  "health_score": "score/10"\n}'
        },
        {
          'role': 'user',
          'content': [
            { 'type': 'text', 'text': "RETURN ONLY RAW JSON - NO TEXT, NO CODE BLOCKS, NO EXPLANATIONS. Analyze this food image and return nutrition data in this EXACT format with no deviations:\n\n{\n  \"meal_name\": string,\n  \"ingredients\": array of strings with weights and calories,\n  \"calories\": number,\n  \"protein\": number,\n  \"fat\": number,\n  \"carbs\": number,\n  \"vitamin_c\": number,\n  \"health_score\": string\n}" },
            { 'type': 'image_url', 'image_url': { 'url': imageData } }
          ]
        }
      ],
      'max_tokens': 1200,
      'temperature': 0.2,
      'response_format': { 'type': 'json_object' }
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
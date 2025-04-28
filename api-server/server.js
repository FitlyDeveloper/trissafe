// Import required packages
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const fetch = require('node-fetch');

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Debug startup
console.log('Starting server...');
console.log('Node environment:', process.env.NODE_ENV);
console.log('Current directory:', process.cwd());
console.log('OpenAI API Key present:', process.env.OPENAI_API_KEY ? 'Yes' : 'No');

// Configure rate limiting
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: process.env.RATE_LIMIT || 30, // Limit each IP to 30 requests per minute
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    status: 429,
    message: 'Too many requests, please try again later.'
  }
});

// Get allowed origins from environment or use default
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',') 
  : ['http://localhost:3000'];

// Configure CORS
app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Check if the origin is allowed
    if (allowedOrigins.indexOf(origin) === -1) {
      const msg = 'The CORS policy for this site does not allow access from the specified Origin.';
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  },
  methods: ['POST'],
  credentials: true
}));

// Body parser middleware
app.use(express.json({ limit: '10mb' }));

// Middleware to check for OpenAI API key
const checkApiKey = (req, res, next) => {
  if (!process.env.OPENAI_API_KEY) {
    console.error('OpenAI API key not configured');
    return res.status(500).json({
      success: false,
      error: 'Server configuration error: OpenAI API key not set'
    });
  }
  console.log('OpenAI API key verified');
  next();
};

// Define routes
app.get('/', (req, res) => {
  console.log('Health check endpoint called');
  res.json({
    message: 'Food Analyzer API Server',
    status: 'operational'
  });
});

// OpenAI proxy endpoint for food analysis
app.post('/api/analyze-food', limiter, checkApiKey, async (req, res) => {
  try {
    console.log('Analyze food endpoint called');
    const { image } = req.body;

    if (!image) {
      console.error('No image provided in request');
      return res.status(400).json({
        success: false,
        error: 'Image data is required'
      });
    }

    // Debug logging
    console.log('Received image data, length:', image.length);
    console.log('Image data starts with:', image.substring(0, 50));

    // Call OpenAI API
    console.log('Calling OpenAI API...');
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        temperature: 0.2,
        messages: [
          {
            role: 'system',
            content: '[ULTRA PRECISE MEAL ANALYSIS] You are a nutrition expert analyzing food images. CRITICAL RULES:\n\n1. ALWAYS provide ONLY ONE meal name for the ENTIRE image, even if multiple separate foods are visible (e.g., "Pasta Carbonara with Side Salad" or "Continental Breakfast Plate" or "Afternoon Snack Plate").\n2. NEVER EVER use "Food item 1:", "Food item 2:", or any numbered food items in your response.\n3. The single meal name must be descriptive but concise (e.g., "Pasta Meal", "Breakfast Plate", "Salad with Protein").\n4. List ALL visible ingredients with weights and calories, e.g., "Pasta (100g) 200kcal".\n5. Return TOTAL values for calories, protein, fat, carbs, and vitamin C for the whole plate.\n6. Add a field: "Health score" (1-10, e.g., "7/10").\n7. ALL results must be as PRECISE as possible. Use decimal places and realistic estimates.\n8. NEVER round to 0 or 5, and never use .0 decimals.\n9. Output must be a single JSON object with a single meal_name field, not multiple dishes.\n\nEXAMPLE JSON OUTPUT for plate with multiple items:\n{\n  "meal_name": "Continental Breakfast Plate",\n  "ingredients": [\n    "Bread (60g) 150kcal",\n    "Butter (10g) 72kcal",\n    "Cheese (30g) 120kcal",\n    "Salami (30g) 90kcal",\n    "Juice (200ml) 90kcal"\n  ],\n  "calories": 522.4,\n  "protein": 21.3,\n  "fat": 18.2,\n  "carbs": 31.7,\n  "vitamin_c": 1.7,\n  "health_score": "6/10"\n}'
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: "CRITICAL INSTRUCTIONS: When analyzing this food image, you MUST:\n\n1. Provide ONLY ONE SINGLE meal name for the ENTIRE image (e.g., 'Pasta Dish', 'Breakfast Plate', 'Afternoon Snack').\n2. NEVER use 'Food item 1:', 'Food item 2:' or any numbered food items - always treat the entire image as ONE meal.\n3. List ALL visible ingredients in the ingredients field, each with estimated weight and calories, e.g., 'Pasta (100g) 200kcal'.\n4. Return TOTAL values for calories, protein, fat, carbs, and vitamin C for everything visible in the image.\n5. Add a field: 'Health score' (1-10, e.g., '8/10').\n6. ALL results must be as PRECISE as possible. Use decimal places and realistic estimates.\n7. NEVER round to 0 or 5, and never use .0 decimals.\n8. Output must be a single JSON object with a single meal_name.\n\nEXAMPLE OUTPUT for plate with multiple foods:\n{\n  \"meal_name\": \"Continental Breakfast Plate\",\n  \"ingredients\": [\n    \"Bread (60g) 150kcal\",\n    \"Butter (10g) 72kcal\",\n    \"Cheese (30g) 120kcal\",\n    \"Salami (30g) 90kcal\",\n    \"Juice (200ml) 90kcal\"\n  ],\n  \"calories\": 522.4,\n  \"protein\": 21.3,\n  \"fat\": 18.2,\n  \"carbs\": 31.7,\n  \"vitamin_c\": 1.7,\n  \"health_score\": \"6/10\"\n}"
              },
              {
                type: 'image_url',
                image_url: { url: image }
              }
            ]
          }
        ],
        max_tokens: 1000
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('OpenAI API error:', response.status, errorData);
      return res.status(response.status).json({
        success: false,
        error: `OpenAI API error: ${response.status}`
      });
    }

    console.log('OpenAI API response received');
    const data = await response.json();
    
    if (!data.choices || 
        !data.choices[0] || 
        !data.choices[0].message || 
        !data.choices[0].message.content) {
      console.error('Invalid response format from OpenAI:', JSON.stringify(data));
      return res.status(500).json({
        success: false,
        error: 'Invalid response from OpenAI'
      });
    }

    const content = data.choices[0].message.content;
    console.log('OpenAI API response content:', content.substring(0, 100) + '...');
    
    // Process and parse the response
    try {
      // First try direct parsing
      const parsedData = JSON.parse(content);
      console.log('Successfully parsed JSON response');
      
      // Check if we have the expected meal_name format
      if (parsedData.meal_name) {
        return res.json({
          success: true,
          data: parsedData
        });
      } else {
        // Transform the response to match our expected format
        const transformedData = transformToRequiredFormat(parsedData);
        console.log('Transformed data to required format');
        return res.json({
          success: true,
          data: transformedData
        });
      }
    } catch (error) {
      console.log('Direct JSON parsing failed, attempting to extract JSON from text');
      // Try to extract JSON from the text
      const jsonMatch = content.match(/```json\n([\s\S]*?)\n```/) || 
                      content.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) {
        const jsonContent = jsonMatch[0].replace(/```json\n|```/g, '').trim();
        try {
          const parsedData = JSON.parse(jsonContent);
          console.log('Successfully extracted and parsed JSON from text');
          
          // Check if we have the expected meal_name format
          if (parsedData.meal_name) {
            return res.json({
              success: true,
              data: parsedData
            });
          } else {
            // Transform the response to match our expected format
            const transformedData = transformToRequiredFormat(parsedData);
            console.log('Transformed extracted JSON to required format');
            return res.json({
              success: true,
              data: transformedData
            });
          }
        } catch (err) {
          console.error('JSON extraction failed:', err);
          // Transform the raw text
          const transformedData = transformTextToRequiredFormat(content);
          return res.json({
            success: true,
            data: transformedData
          });
        }
      } else {
        console.warn('No JSON pattern found in response');
        // Transform the raw text
        const transformedData = transformTextToRequiredFormat(content);
        return res.json({
          success: true,
          data: transformedData
        });
      }
    }
  } catch (error) {
    console.error('Server error:', error);
    return res.status(500).json({
      success: false,
      error: 'Server error processing request'
    });
  }
});

// Helper function to transform data to our required format
function transformToRequiredFormat(data) {
  // If it's the old meal array format
  if (data.meal && Array.isArray(data.meal) && data.meal.length > 0) {
    const mealItem = data.meal[0];
    
    return {
      meal_name: mealItem.dish || "Mixed Meal",
      ingredients: mealItem.ingredients.map(ingredient => {
        if (typeof ingredient === 'string') {
          // Try to estimate weights and calories
          if (ingredient.toLowerCase().includes('pasta')) {
            return `${ingredient} (100g) 200kcal`;
          } else if (ingredient.toLowerCase().includes('bread')) {
            return `${ingredient} (60g) 150kcal`;
          } else if (ingredient.toLowerCase().includes('salad')) {
            return `${ingredient} (50g) 25kcal`;
          } else if (ingredient.toLowerCase().includes('cheese')) {
            return `${ingredient} (30g) 120kcal`;
          } else if (ingredient.toLowerCase().includes('meat') || 
                    ingredient.toLowerCase().includes('chicken') ||
                    ingredient.toLowerCase().includes('salami')) {
            return `${ingredient} (85g) 250kcal`;
          } else {
            return `${ingredient} (30g) 75kcal`;
          }
        }
        return ingredient;
      }),
      calories: mealItem.calories || 0,
      protein: mealItem.macronutrients?.protein || 0,
      fat: mealItem.macronutrients?.fat || 0,
      carbs: mealItem.macronutrients?.carbohydrates || 0,
      vitamin_c: 1.5, // Default value
      health_score: "7/10" // Default value
    };
  }
  
  // Return a default format if nothing else works
  return {
    meal_name: "Mixed Meal",
    ingredients: [
      "Mixed ingredients (100g) 200kcal"
    ],
    calories: 500,
    protein: 20,
    fat: 15,
    carbs: 60,
    vitamin_c: 2,
    health_score: "6/10"
  };
}

// Helper function to transform raw text to our required format
function transformTextToRequiredFormat(text) {
  // Try to parse "Food item" format
  if (text.includes('Food item') || text.includes('FOOD ANALYSIS RESULTS')) {
    const lines = text.split('\n');
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
            ingredients.push(`${ingredient} (30g) 75kcal`);
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
      calories: calories || 500,
      protein: protein || 15,
      fat: fat || 10,
      carbs: carbs || 20,
      vitamin_c: vitaminC || 2,
      health_score: `${healthScore}/10`
    };
  }
  
  // Default response if we can't parse anything meaningful
  return {
    meal_name: "Mixed Meal",
    ingredients: [
      "Mixed ingredients (100g) 200kcal"
    ],
    calories: 500,
    protein: 20,
    fat: 15,
    carbs: 60,
    vitamin_c: 2,
    health_score: "6/10"
  };
}

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`API Key configured: ${process.env.OPENAI_API_KEY ? 'Yes' : 'No'}`);
  console.log(`Allowed origins: ${allowedOrigins.join(', ')}`);
});

// Error handling for unhandled promises
process.on('unhandledRejection', (error) => {
  console.error('Unhandled Promise Rejection:', error);
}); 
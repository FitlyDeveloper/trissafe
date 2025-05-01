const express = require('express');
const cors = require('cors');
const { OpenAI } = require('openai');
const app = express();
const port = process.env.PORT || 3000;

// Configure CORS - allow requests from any origin for development
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Initialize OpenAI client with explicit API key for testing
// IMPORTANT: In production, use environment variables instead
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || 'sk-your-api-key-here', // Replace with your actual key for testing
});

// API endpoint to calculate calories
app.post('/api/calculate-calories', async (req, res) => {
  try {
    console.log('Received nutrition calculation request:', req.body);
    
    const { foodName, servingSize } = req.body;

    if (!foodName || !servingSize) {
      console.log('Missing required fields:', { foodName, servingSize });
      return res.status(400).json({ 
        error: 'Food name and serving size are required',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0
      });
    }

    console.log(`Calculating nutrition for: ${foodName} (${servingSize})`);

    // Check if OpenAI API key is available
    if (!openai.apiKey || openai.apiKey === 'sk-your-api-key-here') {
      console.log('OpenAI API key not configured');
      // Return mock data for testing without API key
      return res.json({
        calories: 250,
        protein: 12,
        carbs: 30,
        fat: 8
      });
    }

    // Construct prompt for OpenAI
    const prompt = `I need to estimate the nutritional information of a food item based on its name and serving size.
Food Name: ${foodName}
Serving Size: ${servingSize}

Please provide a JSON object with the following structure:
{
  "calories": [number],
  "protein": [number in grams],
  "carbs": [number in grams],
  "fat": [number in grams]
}

For example: {"calories": 300, "protein": 10, "carbs": 45, "fat": 12}
Do not include any text before or after the JSON.`;

    // Call OpenAI API
    try {
      console.log('Sending request to OpenAI...');
      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [{"role": "user", "content": prompt}],
        max_tokens: 150,
        temperature: 0.2,
      });

      // Extract response
      const responseText = completion.choices[0].message.content.trim();
      console.log(`OpenAI response: ${responseText}`);
      
      try {
        // Try to parse JSON response
        const nutritionData = JSON.parse(responseText);
        
        // Validate and ensure all fields exist as numbers
        const nutrition = {
          calories: parseFloat(nutritionData.calories) || 0,
          protein: parseFloat(nutritionData.protein) || 0,
          carbs: parseFloat(nutritionData.carbs) || 0,
          fat: parseFloat(nutritionData.fat) || 0
        };
        
        console.log(`Nutrition calculated for ${foodName} (${servingSize}):`, nutrition);
        
        // Return the nutrition data
        return res.json(nutrition);
      } catch (jsonError) {
        console.error('Failed to parse OpenAI response as JSON:', jsonError);
        
        // Fallback: Try to extract just the calories as a number if JSON parsing fails
        const caloriesMatch = responseText.match(/\d+/);
        const calories = caloriesMatch ? parseInt(caloriesMatch[0]) : 0;
        
        console.log(`Fallback: Extracted calories: ${calories}`);
        
        return res.json({ 
          calories: calories,
          protein: 0, 
          carbs: 0,
          fat: 0
        });
      }
    } catch (openaiError) {
      console.error('OpenAI API error:', openaiError);
      
      // Return mock data in case of OpenAI API error
      return res.json({
        calories: 200,
        protein: 10,
        carbs: 25,
        fat: 5
      });
    }
  } catch (error) {
    console.error('Error calculating nutrition:', error);
    return res.status(500).json({ 
      error: 'Failed to calculate nutrition',
      calories: 0,
      protein: 0,
      carbs: 0, 
      fat: 0
    });
  }
});

// Server health check endpoint
app.get('/', (req, res) => {
  res.send('Nutrition calculation proxy server is running');
});

// Debug endpoint to test server without OpenAI
app.get('/test', (req, res) => {
  res.json({
    status: 'Server is working',
    calories: 200,
    protein: 10,
    carbs: 30,
    fat: 5
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Proxy server listening on port ${port}`);
  console.log(`OpenAI API key ${openai.apiKey ? 'is' : 'is NOT'} configured`);
}); 
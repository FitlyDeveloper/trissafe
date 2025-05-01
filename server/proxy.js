const express = require('express');
const cors = require('cors');
const { OpenAI } = require('openai');
const app = express();
const port = process.env.PORT || 3000;

// Configure CORS
app.use(cors());
app.use(express.json());

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// API endpoint to calculate calories
app.post('/api/calculate-calories', async (req, res) => {
  try {
    const { foodName, servingSize } = req.body;

    if (!foodName || !servingSize) {
      return res.status(400).json({ error: 'Food name and serving size are required' });
    }

    console.log(`Calculating nutrition for: ${foodName} (${servingSize})`);

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
      
      // Validate and ensure all fields exist
      const nutrition = {
        calories: nutritionData.calories || 0,
        protein: nutritionData.protein || 0,
        carbs: nutritionData.carbs || 0,
        fat: nutritionData.fat || 0
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

// Start the server
app.listen(port, () => {
  console.log(`Proxy server listening on port ${port}`);
}); 
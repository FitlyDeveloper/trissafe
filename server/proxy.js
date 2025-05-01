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

    console.log(`Calculating calories for: ${foodName} (${servingSize})`);

    // Construct prompt for OpenAI
    const prompt = `I need to estimate the calories in a food item based on its name and serving size.
Food Name: ${foodName}
Serving Size: ${servingSize}

Please provide only the estimated calories as a number (e.g., 300).`;

    // Call OpenAI API
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [{"role": "user", "content": prompt}],
      max_tokens: 100,
      temperature: 0.3,
    });

    // Extract calories from response
    const responseText = completion.choices[0].message.content.trim();
    console.log(`OpenAI response: ${responseText}`);
    
    // Try to extract just the number
    const caloriesMatch = responseText.match(/\d+/);
    const calories = caloriesMatch ? caloriesMatch[0] : "0";

    // Return the calories
    return res.json({ calories });
  } catch (error) {
    console.error('Error calculating calories:', error);
    return res.status(500).json({ error: 'Failed to calculate calories' });
  }
});

// Server health check endpoint
app.get('/', (req, res) => {
  res.send('Calorie calculation proxy server is running');
});

// Start the server
app.listen(port, () => {
  console.log(`Proxy server listening on port ${port}`);
}); 
const fetch = require('node-fetch');

// Replace with a valid OpenAI API key for testing
const API_KEY = 'your-openai-api-key';

async function testOpenAIJson() {
  console.log('Testing OpenAI API with response_format parameter...');
  
  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        temperature: 0.2,
        messages: [
          {
            role: 'system',
            content: 'You are a helpful assistant. Respond with a JSON object containing a greeting.'
          },
          {
            role: 'user',
            content: 'Say hello'
          }
        ],
        max_tokens: 100,
        response_format: { type: 'json_object' }
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('API error:', response.status, errorData);
      return;
    }

    console.log('API response received');
    const data = await response.json();
    console.log('Response content:', data.choices[0].message.content);
    
    try {
      const jsonData = JSON.parse(data.choices[0].message.content);
      console.log('Successfully parsed as JSON:', jsonData);
    } catch (error) {
      console.error('JSON parsing failed:', error);
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

// Alternative test without response_format
async function testOpenAIWithoutResponseFormat() {
  console.log('\nTesting OpenAI API WITHOUT response_format parameter...');
  
  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        temperature: 0.2,
        messages: [
          {
            role: 'system',
            content: 'You are a helpful assistant. Respond with a JSON object containing a greeting.'
          },
          {
            role: 'user',
            content: 'Say hello as a JSON object'
          }
        ],
        max_tokens: 100
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('API error:', response.status, errorData);
      return;
    }

    console.log('API response received');
    const data = await response.json();
    console.log('Response content:', data.choices[0].message.content);
    
    try {
      const jsonData = JSON.parse(data.choices[0].message.content);
      console.log('Successfully parsed as JSON:', jsonData);
    } catch (error) {
      console.error('JSON parsing failed:', error);
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

console.log(`
THIS IS A DIRECT TEST SCRIPT
----------------------------
Instructions:
1. Replace 'your-openai-api-key' with an actual OpenAI API key
2. Run this script on render.com shell to test if response_format works
3. Verify if the parameter is supported or if there's another issue

This test will help determine if the issue is with:
- OpenAI API compatibility
- Parameter formatting
- Response handling
`);

// Uncomment to run the tests
// testOpenAIJson();
// testOpenAIWithoutResponseFormat(); 
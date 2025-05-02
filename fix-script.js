// This is your fixed OpenAI API call code
const fixedOpenAIAPICode = `
// Call OpenAI API
console.log('Calling OpenAI API...');
const response = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': \`Bearer \${process.env.OPENAI_API_KEY}\`
  },
  body: JSON.stringify({
    model: 'gpt-4o',
    temperature: 0.2,
    messages: [
      {
        role: 'system',
        content: '[STRICTLY JSON ONLY] You are a nutrition expert analyzing food images. OUTPUT MUST BE VALID JSON AND NOTHING ELSE.\\n\\nFORMAT RULES:\\n1. Return a single meal name for the entire image (e.g., "Pasta Meal", "Breakfast Plate")\\n2. List ingredients with weights and calories (e.g., "Pasta (100g) 200kcal")\\n3. Return total values for calories, protein, fat, carbs, vitamin C\\n4. Add a health score (1-10)\\n5. Use decimal places and realistic estimates\\n6. DO NOT respond with markdown code blocks or text explanations\\n7. DO NOT prefix your response with "json" or \`\`\`\\n8. ONLY RETURN A RAW JSON OBJECT\\n9. FAILURE TO FOLLOW THESE INSTRUCTIONS WILL RESULT IN REJECTION\\n\\nEXACT FORMAT REQUIRED:\\n{\\n  "meal_name": "Meal Name",\\n  "ingredients": ["Item1 (weight) calories", "Item2 (weight) calories"],\\n  "calories": number,\\n  "protein": number,\\n  "fat": number,\\n  "carbs": number,\\n  "vitamin_c": number,\\n  "health_score": "score/10"\\n}'
      },
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: "RETURN ONLY RAW JSON - NO TEXT, NO CODE BLOCKS, NO EXPLANATIONS. Analyze this food image and return nutrition data in this EXACT format with no deviations:\\n\\n{\\n  \\"meal_name\\": string (single name for entire meal),\\n  \\"ingredients\\": array of strings with weights and calories,\\n  \\"calories\\": number,\\n  \\"protein\\": number,\\n  \\"fat\\": number,\\n  \\"carbs\\": number,\\n  \\"vitamin_c\\": number,\\n  \\"health_score\\": string\\n}"
          },
          {
            type: 'image_url',
            image_url: { url: image }
          }
        ]
      }
    ],
    max_tokens: 1000,
    response_format: { type: 'json_object' }
  })
});`;

console.log("HERE IS THE CODE YOU NEED TO ADD TO YOUR RENDER.COM SERVICE:");
console.log("-----------------------------------------------------------------");
console.log("MAKE SURE TO ADD THE response_format: { type: 'json_object' } PARAMETER");
console.log("TO YOUR OPENAI API CALL IN THE SERVER.JS FILE ON RENDER.COM!");
console.log("-----------------------------------------------------------------");
console.log(fixedOpenAIAPICode);
console.log("-----------------------------------------------------------------");
console.log(`
INSTRUCTIONS FOR RENDER.COM:

1. Go to the Render.com dashboard
2. Open your Snap-Food service 
3. Go to Shell tab (if available)
4. Edit the file at /opt/render/project/src/server.js
5. Find the OpenAI API call section
6. Add the response_format parameter
7. Save the file and restart the service

If shell access is not available, you'll need to:
1. Fix the deployment issue - make sure render.com is deploying from the correct branch
2. Make sure your GitHub repository has the latest code (master branch)
3. Manually redeploy on render.com

For immediate testing, you can click "Edit for render.com" below and open a support ticket
to have them check why the deployment isn't picking up your updated code.
`); 
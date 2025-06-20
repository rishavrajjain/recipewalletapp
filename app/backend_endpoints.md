# Backend API Endpoints for Health Analysis

## 1. Upload User Info (Already exists, just ensure blood_test_id is returned)

```
POST /upload-user-info
Content-Type: multipart/form-data

Form fields:
- kitchen_photos: multiple image files
- blood_test_pdf: single PDF file

Response:
{
  "success": true,
  "kitchen_id": "uuid-string",
  "blood_test_id": "uuid-string"  // THIS IS CRUCIAL - must be returned
}
```

## 2. Health Analysis (New endpoint needed)

```
POST /analyze-health-impact
Content-Type: application/json

Request:
{
  "recipe": {
    "id": "string",
    "name": "string", 
    "description": "string",
    "imageUrl": "string",
    "ingredients": ["string", "string"],
    "cookTime": number,
    "isFromReel": boolean,
    "steps": ["string", "string"],
    "createdAt": "ISO-date-string"
  },
  "blood_test_id": "uuid-string"
}

Response:
{
  "success": true,
  "analysis": {
    "overall_score": 45,
    "risk_level": "high",
    "personal_message": "Yo bro! 👋 I know your cholesterol was high in your last test (LDL: 145 mg/dL). This cheese is the fucking culprit that's gonna spike it even more! 📈😤",
    "main_culprits": [
      {
        "ingredient": "Cheese",
        "impact": "Could spike your cholesterol by 15-20%",
        "severity": "high"
      }
    ],
    "health_boosters": [
      {
        "ingredient": "Tomato",
        "impact": "Great for heart health & cholesterol",
        "severity": "low"
      }
    ],
    "recommendations": {
      "should_avoid": true,
      "modifications": [
        "Replace cheese with nutritional yeast",
        "Use olive oil spray instead of butter"
      ],
      "alternative_recipes": ["Heart-Healthy Pasta"]
    },
    "blood_markers_affected": [
      {
        "marker": "LDL Cholesterol",
        "current_level": 145.0,
        "predicted_impact": "+18% increase",
        "target_range": "< 100 mg/dL",
        "is_out_of_range": true
      }
    ]
  },
  "error": null
}
```

## Implementation Notes

1. **Blood Test Processing**: When a PDF is uploaded, extract key health markers (cholesterol, glucose, etc.) and store with the blood_test_id

2. **LLM Integration**: Send the recipe + extracted blood markers to your LLM with a prompt like:
   ```
   "Analyze this recipe for someone with these blood test results: [blood_data]
   Recipe: [recipe_data]
   
   Respond in a casual, friendly tone like talking to a bro. Be specific about health impacts.
   Focus on cholesterol, blood sugar, inflammation markers, etc.
   Give specific percentage impacts and actionable advice."
   ```

3. **Error Handling**: Return proper error messages if blood_test_id is not found or invalid

4. **Response Format**: Make sure all field names match exactly with the Swift model (snake_case in JSON) 
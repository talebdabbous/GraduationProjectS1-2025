# Letter Sounds API Documentation

## Endpoint
```
GET /api/letter-sounds
```

## Expected Response Structure

The backend should return a JSON response in one of these formats:

### Format 1: With `data` wrapper
```json
{
  "data": [
    {
      "letter": "ب",
      "order": 1,
      "difficulty": "easy",
      "difficultyLevel": 1,
      "sounds": {
        "fatha": "بَ",
        "kasra": "بِ",
        "damma": "بُ",
        "sukun": "بْ",
        "fathaTransliteration": "ba",
        "kasraTransliteration": "bi",
        "dammaTransliteration": "bu",
        "sukunTransliteration": "b",
        "fathaAudioUrl": "http://example.com/audio/ba.mp3",
        "kasraAudioUrl": "http://example.com/audio/bi.mp3",
        "dammaAudioUrl": "http://example.com/audio/bu.mp3",
        "sukunAudioUrl": "http://example.com/audio/b.mp3"
      }
    },
    {
      "letter": "ت",
      "order": 2,
      "difficulty": "easy",
      "difficultyLevel": 1,
      "sounds": {
        "fatha": "تَ",
        "kasra": "تِ",
        "damma": "تُ",
        "sukun": "تْ",
        "fathaTransliteration": "ta",
        "kasraTransliteration": "ti",
        "dammaTransliteration": "tu",
        "sukunTransliteration": "t",
        "fathaAudioUrl": "http://example.com/audio/ta.mp3",
        "kasraAudioUrl": "http://example.com/audio/ti.mp3",
        "dammaAudioUrl": "http://example.com/audio/tu.mp3",
        "sukunAudioUrl": "http://example.com/audio/t.mp3"
      }
    }
  ]
}
```

### Format 2: Direct array
```json
[
  {
    "letter": "ب",
    "order": 1,
    "difficulty": "easy",
    "difficultyLevel": 1,
    "sounds": { ... }
  }
]
```

## Field Requirements

### Required Fields:
- `letter` (string): The Arabic letter (e.g., "ب", "ت", "ج")
- `order` (number): Alphabetical order (1, 2, 3, ...)
- `difficulty` (string): "easy" | "medium" | "hard"
- `difficultyLevel` (number): 1 (easy) | 2 (medium) | 3 (hard)
- `sounds` (object): Object containing sound information

### Sounds Object:
Each letter must have a `sounds` object with the following fields (all optional, but recommended):
- `fatha`, `kasra`, `damma`, `sukun` (string): Arabic form with diacritic
- `fathaTransliteration`, `kasraTransliteration`, `dammaTransliteration`, `sukunTransliteration` (string): Latin transliteration
- `fathaAudioUrl`, `kasraAudioUrl`, `dammaAudioUrl`, `sukunAudioUrl` (string): URL to audio file

## Alternative Field Names (Supported)

The frontend also supports these alternative field names:
- `difficulty_level` instead of `difficultyLevel`
- `fatha_transliteration` instead of `fathaTransliteration`
- `fatha_audio_url` or `fathaAudio` or `fatha_audio` instead of `fathaAudioUrl`
- Same for kasra, damma, sukun

## Response Status Codes

- `200 OK`: Success, returns array of letters
- `404 Not Found`: Endpoint not found
- `500 Internal Server Error`: Server error

## Example Backend Implementation (Node.js/Express)

```javascript
app.get('/api/letter-sounds', async (req, res) => {
  try {
    const letters = await LetterSound.find({});
    res.json({
      data: letters
    });
  } catch (error) {
    res.status(500).json({
      message: 'Failed to load letter sounds',
      error: error.message
    });
  }
});
```

## Testing

To test if the endpoint is working, you can use:

```bash
curl http://localhost:4000/api/letter-sounds
```

Or in the browser:
```
http://localhost:4000/api/letter-sounds
```

The response should be a JSON array or object with a `data` field containing the letters.


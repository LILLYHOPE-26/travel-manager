const express = require('express');
const { requireFields } = require('../utils/validators');
const { generateItinerary } = require('../services/itineraryEngine');

const router = express.Router();

router.post('/', async (req, res) => {
  const missingFields = requireFields(req.body, ['destination', 'totalDays', 'startDate', 'endDate', 'transport']);
  if (missingFields.length > 0) {
    return res.status(400).json({ error: '필수 정보가 부족합니다.', missingFields });
  }

  try {
    const result = await generateItinerary(req.body);
    if (result.error) return res.status(404).json(result);
    res.json(result);
  } catch (err) {
    console.error('[itinerary] 생성 실패:', err.message);
    res.status(502).json({ error: '확인 불가 (일정 생성 실패)', detail: err.message });
  }
});

module.exports = router;

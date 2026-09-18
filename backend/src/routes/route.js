const express = require('express');
const { requireFields } = require('../utils/validators');
const { calculateRoute } = require('../services/routeService');

const router = express.Router();

router.post('/', async (req, res) => {
  const { origin, destination, waypoints, transport } = req.body;
  const missingFields = requireFields(req.body, ['origin', 'destination', 'transport']);
  if (missingFields.length > 0) {
    return res.status(400).json({ error: '필수 정보가 부족합니다.', missingFields });
  }

  try {
    const result = await calculateRoute(origin, destination, Array.isArray(waypoints) ? waypoints : [], transport);
    if (result.error) return res.status(404).json(result);
    res.json(result);
  } catch (err) {
    console.error('[route] 계산 실패:', err.message);
    res.status(502).json({ error: '확인 불가 (경로 계산 실패)', detail: err.message });
  }
});

module.exports = router;

const express = require('express');
const { requireFields } = require('../utils/validators');
const { searchPlaces, searchPlacesByCoords } = require('../services/placesService');

const router = express.Router();

router.get('/', async (req, res) => {
  const { region, lat, lng } = req.query;

  // 동명 지역 후보 중 하나를 사용자가 선택하면 좌표로 직접 재검색한다.
  if (lat && lng) {
    try {
      const result = await searchPlacesByCoords(parseFloat(lat), parseFloat(lng));
      return res.json(result);
    } catch (err) {
      console.error('[places] 검색 실패:', err.message);
      return res.status(502).json({ error: '확인 불가 (장소 검색 실패)', detail: err.message });
    }
  }

  const missingFields = requireFields(req.query, ['region']);
  if (missingFields.length > 0) {
    return res.status(400).json({ error: '필수 정보가 부족합니다.', missingFields });
  }

  try {
    const result = await searchPlaces(region);
    res.json(result);
  } catch (err) {
    console.error('[places] 검색 실패:', err.message);
    res.status(502).json({ error: '확인 불가 (장소 검색 실패)', detail: err.message });
  }
});

module.exports = router;

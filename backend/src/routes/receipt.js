const express = require('express');
const multer = require('multer');
const { parseReceipt } = require('../services/receiptEngine');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });
const router = express.Router();

// OCR(무료, 로컬 Tesseract)만 수행하고 환율은 별도 /api/exchange-rate 에서 처리한다.
// (사용자가 OCR 결과의 날짜/통화를 수정할 수 있으므로 환율 조회를 분리)
router.post('/', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: '필수 정보가 부족합니다.', missingFields: ['image'] });
  }

  try {
    const parsed = await parseReceipt(req.file.buffer);
    res.json(parsed);
  } catch (err) {
    console.error('[receipt] 인식 실패:', err.message);
    res.status(502).json({ error: '확인 불가 (영수증 인식 실패)', detail: err.message });
  }
});

module.exports = router;

const express = require('express');
const { requireFields } = require('../utils/validators');
const { getRate } = require('../services/fxService');

const router = express.Router();

// 영수증 인식 직후, 또는 사용자가 날짜/통화/금액을 직접 수정한 뒤 다시 계산할 때 호출한다.
router.get('/', async (req, res) => {
  const { date, currency, amount } = req.query;
  const missingFields = requireFields(req.query, ['date', 'currency', 'amount']);
  if (missingFields.length > 0) {
    return res.status(400).json({ error: '필수 정보가 부족합니다.', missingFields });
  }

  const parsedAmount = parseFloat(amount);
  if (Number.isNaN(parsedAmount)) {
    return res.status(400).json({ error: '확인 불가 (금액 형식 오류)' });
  }

  if (currency === 'KRW') {
    return res.json({ exchangeRate: 1, krwAmount: Math.round(parsedAmount), needManualRate: false });
  }

  try {
    const fx = await getRate(date, currency, 'KRW');
    if (fx.needManualRate) {
      return res.json({ exchangeRate: null, krwAmount: null, needManualRate: true, fxReason: fx.reason });
    }
    const krwAmount = Math.round(parsedAmount * fx.rate);
    res.json({ exchangeRate: fx.rate, krwAmount, needManualRate: false });
  } catch (err) {
    res.status(502).json({ error: '확인 불가 (환율 조회 실패)', detail: err.message });
  }
});

module.exports = router;

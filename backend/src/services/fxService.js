const axios = require('axios');

const FRANKFURTER_BASE = 'https://api.frankfurter.app';

// 결제일자 기준 해당일 환율을 조회한다. 원화(KRW)가 아닌 통화에만 사용.
// 절대 임의로 환율을 추정하지 않고, 조회 실패 시 needManualRate 플래그로 상위 계층에 알린다.
async function getRate(date, fromCurrency, toCurrency = 'KRW') {
  if (fromCurrency === toCurrency) {
    return { rate: 1, source: 'same-currency' };
  }

  try {
    const { data } = await axios.get(`${FRANKFURTER_BASE}/${date}`, {
      params: { from: fromCurrency, to: toCurrency },
      timeout: 8000,
    });

    const rate = data?.rates?.[toCurrency];
    if (!rate) {
      return { rate: null, needManualRate: true, reason: `${fromCurrency}->${toCurrency} 환율 미지원 (확인 불가)` };
    }

    return { rate, source: 'frankfurter', date: data.date };
  } catch (err) {
    return { rate: null, needManualRate: true, reason: '환율 조회 실패 (확인 불가)' };
  }
}

module.exports = { getRate };

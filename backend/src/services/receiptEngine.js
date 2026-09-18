const Tesseract = require('tesseract.js');

// 원본 기획서 STEP B-2 키워드 표를 그대로 반영한 무료(로컬) 규칙 기반 분류기.
const CATEGORY_KEYWORDS = {
  식비: ['restaurant', 'cafe', '식당', 'food', 'bar', '카페', '레스토랑'],
  교통: ['uber', 'taxi', '지하철', 'airline', 'gas station', '택시', '주유소', '버스', '항공'],
  숙박: ['hotel', 'airbnb', 'motel', '호텔', '모텔'],
  쇼핑: ['mall', 'store', 'duty free', '마트', '몰', '스토어', '면세점'],
  '입장료/관광': ['museum', 'park', 'ticket', 'tour', '박물관', '공원', '티켓', '투어'],
};

function classifyCategory(text) {
  const lower = text.toLowerCase();
  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((k) => lower.includes(k))) {
      return { category, confident: true };
    }
  }
  return { category: '기타', confident: false };
}

function extractMerchant(lines) {
  const candidate = lines.find((l) => l.trim().length >= 2 && !/^[\d\s.,:/-]+$/.test(l.trim()));
  return candidate ? candidate.trim().slice(0, 60) : '(인식불가-확인필요)';
}

function extractDate(text) {
  const patterns = [
    { re: /(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})/, order: 'ymd' },
    { re: /(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})/, order: 'mdy' },
  ];
  for (const { re, order } of patterns) {
    const m = text.match(re);
    if (m) {
      if (order === 'ymd') return `${m[1]}-${m[2].padStart(2, '0')}-${m[3].padStart(2, '0')}`;
      return `${m[3]}-${m[1].padStart(2, '0')}-${m[2].padStart(2, '0')}`;
    }
  }
  return '(인식불가-확인필요)';
}

function extractAmountAndCurrency(text) {
  const totalLineMatch = text.match(/(total|합계|총액|금액)[^\d]{0,10}([\d,]+\.?\d*)/i);
  let amountStr = totalLineMatch ? totalLineMatch[2] : null;

  if (!amountStr) {
    const numbers = [...text.matchAll(/(\d[\d,]{1,}\.?\d{0,2})/g)].map((m) => m[1]);
    if (numbers.length) {
      amountStr = numbers.sort((a, b) => parseFloat(b.replace(/,/g, '')) - parseFloat(a.replace(/,/g, '')))[0];
    }
  }

  const amount = amountStr ? parseFloat(amountStr.replace(/,/g, '')) : null;

  const currencyPatterns = [
    { re: /₩|KRW|원/i, code: 'KRW' },
    { re: /\$|USD/i, code: 'USD' },
    { re: /CAD/i, code: 'CAD' },
  ];
  let currency = null;
  for (const { re, code } of currencyPatterns) {
    if (re.test(text)) {
      currency = code;
      break;
    }
  }

  if (amount == null || currency == null) {
    return { amount: amount ?? 0, currency: '(인식불가-확인필요)' };
  }
  return { amount, currency };
}

// 별도 유료 OCR API 없이 Tesseract.js(로컬/무료)로 텍스트를 추출한 뒤 규칙 기반으로 파싱한다.
// 정확도는 유료 비전 API 대비 낮을 수 있어, 앱에서 인식 결과를 사용자가 직접 수정할 수 있게 한다.
async function parseReceipt(imageBuffer) {
  const { data } = await Tesseract.recognize(imageBuffer, 'eng+kor');
  const text = data.text || '';
  const lines = text.split('\n').filter((l) => l.trim());

  const merchant = extractMerchant(lines);
  const date = extractDate(text);
  const { amount, currency } = extractAmountAndCurrency(text);
  const { category, confident } = classifyCategory(text);

  return { merchant, date, amount, currency, items: [], category, categoryConfident: confident };
}

module.exports = { parseReceipt };

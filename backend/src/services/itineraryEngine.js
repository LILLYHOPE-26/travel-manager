const osm = require('./osmService');

const DURATION_BY_FEATURE = {
  museum: 90,
  gallery: 60,
  viewpoint: 30,
  attraction: 60,
  zoo: 120,
  theme_park: 180,
  default: 60,
};
const COST_BY_FEATURE = {
  museum: 15000,
  gallery: 10000,
  viewpoint: 0,
  attraction: 10000,
  zoo: 25000,
  theme_park: 45000,
  default: 10000,
};
const MEAL_DURATION = 75;
const TRANSPORT_SPEED_M_PER_MIN = { 도보: 67, 대중교통: 250, 렌터카: 330 };
// 이동수단별 변동성 버퍼: 도보 > 대중교통 > 렌터카 순으로 변동성이 크다는 원본 규칙 반영
const TRANSPORT_VARIANCE = { 도보: 1.3, 대중교통: 1.15, 렌터카: 1.05 };

function haversine(a, b) {
  return osm.haversineMeters(a.lat, a.lng, b.lat, b.lng);
}

function travelMinutes(distanceM, transport) {
  if (distanceM <= 0) return 0;
  const speed = TRANSPORT_SPEED_M_PER_MIN[transport] || 200;
  const variance = TRANSPORT_VARIANCE[transport] || 1.2;
  return Math.round((distanceM / speed) * variance);
}

function addMinutes(hhmm, min) {
  const [h, m] = hhmm.split(':').map(Number);
  const total = h * 60 + m + min;
  const nh = Math.floor(total / 60) % 24;
  const nm = total % 60;
  return `${String(nh).padStart(2, '0')}:${String(nm).padStart(2, '0')}`;
}

// 도시를 권역으로 나눈다: 중심점 기준 각도로 정렬 후 연속 구간으로 슬라이스 -> "같은 날 = 같은 권역" 근사 구현
function clusterByAngle(points, k) {
  if (!points.length) return Array.from({ length: k }, () => []);
  const centerLat = points.reduce((s, p) => s + p.lat, 0) / points.length;
  const centerLng = points.reduce((s, p) => s + p.lng, 0) / points.length;
  const sorted = [...points].sort((a, b) => {
    const angleA = Math.atan2(a.lat - centerLat, a.lng - centerLng);
    const angleB = Math.atan2(b.lat - centerLat, b.lng - centerLng);
    return angleA - angleB;
  });
  const clusters = Array.from({ length: k }, () => []);
  const chunkSize = Math.ceil(sorted.length / k);
  sorted.forEach((p, idx) => {
    const clusterIdx = Math.min(Math.floor(idx / chunkSize), k - 1);
    clusters[clusterIdx].push(p);
  });
  return clusters;
}

function orderByNearestNeighbor(points, start) {
  const remaining = [...points];
  const ordered = [];
  let current = start;
  while (remaining.length) {
    remaining.sort((a, b) => haversine(current, a) - haversine(current, b));
    const next = remaining.shift();
    ordered.push(next);
    current = next;
  }
  return ordered;
}

function nearestUnused(restaurants, used, from) {
  const key = (r) => `${r.name}_${r.lat}`;
  const candidates = restaurants.filter((r) => !used.has(key(r)));
  if (!candidates.length) return null;
  candidates.sort((a, b) => haversine(from, a) - haversine(from, b));
  return candidates[0];
}

async function generateItinerary(payload) {
  const { destination, city, totalDays, transport, styles = [] } = payload;
  const query = [destination, city].filter(Boolean).join(' ');

  const geoResults = await osm.geocode(query);
  if (!geoResults.length) {
    return { error: '확인 불가 (여행지를 찾을 수 없음, 여행지명을 다시 확인해주세요)', days: [], dailySummary: [] };
  }
  const { lat, lng } = geoResults[0];

  const radius = Math.min(3000 + totalDays * 1500, 10000);
  // Geoapify 무료 요금제 레이트리밋 방지를 위해 순차 호출한다.
  const attractionsRaw = await osm.findAttractions(lat, lng, radius, 60);
  const restaurantsRaw = await osm.findRestaurants(lat, lng, Math.min(radius, 4000), 60);

  if (!attractionsRaw.length) {
    return {
      error: '확인 불가 (해당 지역의 관광지 오픈데이터가 부족합니다)',
      days: [],
      dailySummary: [],
    };
  }

  const clusters = clusterByAngle(attractionsRaw, totalDays);
  const usedRestaurants = new Set();
  const days = [];
  const dailySummary = [];

  for (let d = 0; d < totalDays; d++) {
    const dayNum = d + 1;
    const dayPoints = orderByNearestNeighbor(clusters[d] || [], { lat, lng });
    const activities = [];
    let time = '09:00';
    let cursor = { lat, lng };
    let totalTransportMin = 0;
    let totalCost = 0;
    let pointIdx = 0;

    const visitPoint = (p) => {
      const distanceM = Math.round(haversine(cursor, p));
      const travelMin = travelMinutes(distanceM, transport);
      if (travelMin > 0) time = addMinutes(time, travelMin);
      totalTransportMin += travelMin;
      const duration = DURATION_BY_FEATURE[p.feature] || DURATION_BY_FEATURE.default;
      const cost = COST_BY_FEATURE[p.feature] ?? COST_BY_FEATURE.default;
      totalCost += cost;
      activities.push({
        time,
        activity: osm.translateFeature(p.feature),
        place: p.name,
        durationMin: duration,
        transport,
        memo: `입장료 약 ${cost.toLocaleString()}원 (추정)`,
      });
      time = addMinutes(time, duration);
      cursor = p;
    };

    // 오전 (09:00-12:00)
    while (pointIdx < dayPoints.length && time < '12:00') {
      visitPoint(dayPoints[pointIdx++]);
      if (time >= '12:00') break;
    }

    // 점심 (12:00-13:30) - 반드시 인근 맛집 배치
    time = time < '12:00' ? '12:00' : time;
    const lunch = nearestUnused(restaurantsRaw, usedRestaurants, cursor);
    if (lunch) {
      usedRestaurants.add(`${lunch.name}_${lunch.lat}`);
      const distanceM = Math.round(haversine(cursor, lunch));
      totalTransportMin += travelMinutes(distanceM, transport);
      totalCost += 15000;
      activities.push({ time, activity: '점심 식사', place: lunch.name, durationMin: MEAL_DURATION, transport, memo: '예상 15,000원 (추정)' });
      time = addMinutes(time, MEAL_DURATION);
      cursor = lunch;
    } else {
      activities.push({ time, activity: '점심 식사', place: '확인 불가 (주변 식당 데이터 없음)', durationMin: MEAL_DURATION, transport, memo: '확인 불가' });
      time = addMinutes(time, MEAL_DURATION);
    }

    // 오후 (13:30-17:30)
    time = time < '13:30' ? '13:30' : time;
    while (pointIdx < dayPoints.length && time < '17:30') {
      visitPoint(dayPoints[pointIdx++]);
      if (time >= '17:30') break;
    }

    // 저녁 (17:30-19:30) - 반드시 인근 맛집 배치
    time = time < '17:30' ? '17:30' : time;
    const dinner = nearestUnused(restaurantsRaw, usedRestaurants, cursor);
    if (dinner) {
      usedRestaurants.add(`${dinner.name}_${dinner.lat}`);
      const distanceM = Math.round(haversine(cursor, dinner));
      totalTransportMin += travelMinutes(distanceM, transport);
      totalCost += 20000;
      activities.push({ time, activity: '저녁 식사', place: dinner.name, durationMin: MEAL_DURATION, transport, memo: '예상 20,000원 (추정)' });
      time = addMinutes(time, MEAL_DURATION);
      cursor = dinner;
    } else {
      activities.push({ time, activity: '저녁 식사', place: '확인 불가 (주변 식당 데이터 없음)', durationMin: MEAL_DURATION, transport, memo: '확인 불가' });
      time = addMinutes(time, MEAL_DURATION);
    }

    // 야간 (19:30~)
    time = time < '19:30' ? '19:30' : time;
    const nightActivity = styles.includes('쇼핑 중심') ? '자유 쇼핑 시간' : '자유 시간 (숙소 복귀)';
    activities.push({
      time,
      activity: nightActivity,
      place: '-',
      durationMin: 90,
      transport,
      memo: '확인 불가 (야간 명소 오픈데이터 없음, 자유 일정 권장)',
    });

    days.push({ day: dayNum, activities });
    dailySummary.push({ day: dayNum, totalTransportMin, estimatedCost: `${totalCost.toLocaleString()}원 (추정)` });
  }

  return { days, dailySummary };
}

module.exports = { generateItinerary };

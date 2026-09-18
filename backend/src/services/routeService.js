const axios = require('axios');
const osm = require('./osmService');

const GEOAPIFY_BASE = 'https://api.geoapify.com';
const API_KEY = () => process.env.GEOAPIFY_API_KEY;

// 이동수단을 Geoapify Routing API의 mode 값으로 매핑한다.
const MODE_MAP = { 도보: 'walk', 렌터카: 'drive', 대중교통: 'transit' };
// 실제 경로 조회가 불가능할 때(주로 대중교통) 쓰는 직선거리 기반 추정 속도(m/분).
// 대중교통은 근거리(도시 내 버스/지하철)와 장거리(KTX/시외버스)의 평균 속도 차이가 커서 거리 구간별로 다르게 가정한다.
function fallbackSpeedMPerMin(transport, distanceM) {
  if (transport === '도보') return 67; // 약 4km/h
  if (transport === '렌터카') return 330; // 약 20km/h (시내 주행 기준)
  // 대중교통
  if (distanceM < 3000) return 250; // 약 15km/h, 도보+근거리 버스 혼합
  if (distanceM < 30000) return 333; // 약 20km/h, 도시 내 지하철/버스
  return 1333; // 약 80km/h, KTX/시외버스 등 장거리 대중교통 평균(대기시간 포함 추정)
}

async function geocodeOne(placeName) {
  const results = await osm.geocode(placeName);
  if (!results.length) return null;
  return results[0];
}

async function routeBetween(a, b, transport) {
  const geoapifyMode = MODE_MAP[transport] || 'drive';
  try {
    const { data } = await axios.get(`${GEOAPIFY_BASE}/v1/routing`, {
      params: {
        waypoints: `${a.lat},${a.lng}|${b.lat},${b.lng}`,
        mode: geoapifyMode,
        apiKey: API_KEY(),
      },
      timeout: 15000,
    });

    const props = data.features?.[0]?.properties;
    if (!props || typeof props.distance !== 'number') {
      throw new Error('빈 경로 응답');
    }

    return {
      distanceM: Math.round(props.distance),
      durationMin: Math.round(props.time / 60),
      source: '도로 경로 (Geoapify Routing)',
    };
  } catch (err) {
    // 대중교통 등 실제 경로 조회가 안 되면 직선거리 기반으로 추정하고, 그 사실을 명시한다.
    const distanceM = Math.round(osm.haversineMeters(a.lat, a.lng, b.lat, b.lng));
    const speed = fallbackSpeedMPerMin(transport, distanceM);
    const durationMin = Math.round(distanceM / speed);
    return {
      distanceM,
      durationMin,
      source: '(추정) 실제 경로 데이터 없음 - 직선거리 기반 추정',
    };
  }
}

// origin -> waypoints... -> destination 순서로 구간별 거리/시간을 계산한다.
async function calculateRoute(originName, destinationName, waypointNames = [], transport) {
  const names = [originName, ...waypointNames.filter((w) => w && w.trim()), destinationName];

  const points = [];
  for (const name of names) {
    const geocoded = await geocodeOne(name);
    if (!geocoded) {
      return { error: `확인 불가 (위치를 찾을 수 없음: ${name})` };
    }
    points.push({ inputName: name, name: geocoded.name, lat: geocoded.lat, lng: geocoded.lng });
  }

  const legs = [];
  let totalDistanceM = 0;
  let totalDurationMin = 0;

  for (let i = 0; i < points.length - 1; i++) {
    const leg = await routeBetween(points[i], points[i + 1], transport);
    legs.push({ from: points[i].inputName, to: points[i + 1].inputName, ...leg });
    totalDistanceM += leg.distanceM;
    totalDurationMin += leg.durationMin;
  }

  return {
    points: points.map((p) => ({ name: p.name, lat: p.lat, lng: p.lng })),
    legs,
    totalDistanceM,
    totalDurationMin,
    transport,
  };
}

module.exports = { calculateRoute };

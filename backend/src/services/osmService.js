const axios = require('axios');

const NOMINATIM_BASE = 'https://nominatim.openstreetmap.org';
// 공용 Overpass 서버는 트래픽이 몰리면 429/504를 반환하는 경우가 잦아, 여러 미러를 순서대로 시도한다.
const OVERPASS_MIRRORS = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://lz4.overpass-api.de/api/interpreter',
];
// OpenStreetMap 사용 정책상 식별 가능한 User-Agent가 필요하다 (키 발급은 불필요, 무료).
const USER_AGENT = 'TravelAllInOneManagerApp/1.0 (personal/educational project)';

const FEATURE_LABEL_KO = {
  attraction: '관광명소',
  museum: '박물관',
  viewpoint: '전망대',
  gallery: '갤러리',
  zoo: '동물원',
  theme_park: '테마파크',
  memorial: '기념비',
  monument: '기념물',
  archaeological_site: '유적지',
  castle: '성',
  ruins: '유적',
  yes: '역사 유적',
};

// OSM historic/tourism 태그값은 "yes"처럼 영문 코드로만 오는 경우가 많아 한글 라벨로 변환한다.
function translateFeature(feature) {
  return FEATURE_LABEL_KO[feature] || feature || '관광지';
}

function haversineMeters(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const toRad = (v) => (v * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// 지역명을 좌표로 변환 (무료, 키 불필요). 여러 결과가 5km 이상 떨어져 있으면 동명 지역으로 간주.
async function geocode(query) {
  const { data } = await axios.get(`${NOMINATIM_BASE}/search`, {
    params: { q: query, format: 'json', addressdetails: 1, limit: 5, 'accept-language': 'ko' },
    headers: { 'User-Agent': USER_AGENT },
    timeout: 10000,
  });

  return data.map((d) => ({
    name: d.display_name,
    lat: parseFloat(d.lat),
    lng: parseFloat(d.lon),
    placeId: d.place_id?.toString(),
  }));
}

function dedupeFarApart(results) {
  const kept = [];
  for (const r of results) {
    if (!kept.some((k) => haversineMeters(k.lat, k.lng, r.lat, r.lng) < 5000)) {
      kept.push(r);
    }
  }
  return kept;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// 공용 Overpass 서버는 트래픽이 몰리면 429/504를 반환하는 경우가 잦다.
// 여러 미러를 순서대로 시도하고, 그래도 실패하면 잠시 대기 후 1회 더 전체를 재시도한다.
async function overpassQuery(query, roundAttempt = 0) {
  let lastError;
  for (const base of OVERPASS_MIRRORS) {
    try {
      const { data } = await axios.post(base, `data=${encodeURIComponent(query)}`, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': USER_AGENT },
        timeout: 10000,
      });
      // 일부 미러는 과부하 시 200 상태로 빈 본문/에러 텍스트를 반환하기도 하므로 형식을 검증한다.
      if (!data || !Array.isArray(data.elements)) {
        throw new Error(`Overpass 응답 형식 오류 (${base})`);
      }
      return data.elements;
    } catch (err) {
      lastError = err;
    }
  }

  if (roundAttempt < 1) {
    await sleep(4000);
    return overpassQuery(query, roundAttempt + 1);
  }
  throw lastError;
}

function aroundQuery(lat, lng, radius, tagFilters) {
  const parts = tagFilters
    .map((f) => `node${f}(around:${radius},${lat},${lng});way${f}(around:${radius},${lat},${lng});`)
    .join('');
  return `[out:json][timeout:25];(${parts});out center 60;`;
}

// 관광지: tourism/historic 태그 기반 (OpenStreetMap은 무료지만 평점/리뷰수 데이터는 없음 - 거리/카테고리로만 선정)
async function findAttractions(lat, lng, radius, limit = 30) {
  const query = aroundQuery(lat, lng, radius, [
    '["tourism"~"attraction|museum|viewpoint|gallery|zoo|theme_park"]',
    '["historic"]',
  ]);
  const elements = await overpassQuery(query);
  return elements
    .map((e) => {
      const elat = e.lat ?? e.center?.lat;
      const elng = e.lon ?? e.center?.lon;
      if (!elat || !elng || !e.tags?.name) return null;
      return {
        name: e.tags.name,
        feature: e.tags.tourism || e.tags.historic || 'attraction',
        lat: elat,
        lng: elng,
      };
    })
    .filter(Boolean)
    .slice(0, limit);
}

// 맛집/카페: amenity 태그 기반
async function findRestaurants(lat, lng, radius, limit = 30) {
  const query = aroundQuery(lat, lng, radius, ['["amenity"~"restaurant|cafe|fast_food"]']);
  const elements = await overpassQuery(query);
  return elements
    .map((e) => {
      const elat = e.lat ?? e.center?.lat;
      const elng = e.lon ?? e.center?.lon;
      if (!elat || !elng || !e.tags?.name) return null;
      const category = e.tags.amenity === 'cafe' ? '카페' : e.tags.amenity === 'fast_food' ? '패스트푸드' : '로컬맛집';
      return { name: e.tags.name, category, cuisine: e.tags.cuisine, lat: elat, lng: elng };
    })
    .filter(Boolean)
    .slice(0, limit);
}

module.exports = { geocode, dedupeFarApart, findAttractions, findRestaurants, haversineMeters, translateFeature };

const axios = require('axios');

const GEOAPIFY_BASE = 'https://api.geoapify.com';
const API_KEY = () => process.env.GEOAPIFY_API_KEY;

// Geoapify 카테고리 문자열(예: "entertainment.museum")을 한글 라벨로 변환한다.
function translateFeature(category) {
  if (!category) return '관광지';
  if (category.includes('museum')) return '박물관';
  if (category.includes('gallery') || category.includes('culture')) return '갤러리';
  if (category.includes('park')) return '공원';
  if (category.includes('viewpoint')) return '전망대';
  if (category.includes('zoo')) return '동물원';
  if (category.includes('theme_park')) return '테마파크';
  if (category.includes('castle')) return '성';
  if (category.includes('attraction') || category.includes('sights')) return '관광명소';
  return '관광지';
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

// 지역명을 좌표로 변환 (Geoapify Geocoding API). 여러 결과가 5km 이상 떨어져 있으면 동명 지역으로 간주.
async function geocode(query) {
  const { data } = await axios.get(`${GEOAPIFY_BASE}/v1/geocode/search`, {
    params: { text: query, apiKey: API_KEY(), lang: 'ko', limit: 5 },
    timeout: 10000,
  });

  return (data.features || [])
    .map((f) => ({
      name: f.properties.formatted,
      lat: f.properties.lat,
      lng: f.properties.lon,
      placeId: f.properties.place_id,
    }))
    .filter((r) => r.lat != null && r.lng != null);
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

async function placesSearch(lat, lng, radius, categories, limit) {
  const { data } = await axios.get(`${GEOAPIFY_BASE}/v2/places`, {
    params: {
      categories,
      filter: `circle:${lng},${lat},${radius}`,
      bias: `proximity:${lng},${lat}`,
      limit,
      apiKey: API_KEY(),
      lang: 'ko',
    },
    timeout: 10000,
  });
  return data.features || [];
}

// 관광지: tourism/entertainment 카테고리 (Geoapify Places API, 평점/리뷰 데이터는 제공하지 않음)
async function findAttractions(lat, lng, radius, limit = 30) {
  const features = await placesSearch(
    lat,
    lng,
    radius,
    'tourism.sights,tourism.attraction,entertainment.museum,entertainment.culture',
    limit
  );
  return features
    .map((f) => ({
      name: f.properties.name,
      feature: (f.properties.categories || [])[0] || 'tourism.attraction',
      lat: f.properties.lat,
      lng: f.properties.lon,
    }))
    .filter((a) => a.name && a.lat != null && a.lng != null);
}

// 맛집/카페: catering 카테고리
async function findRestaurants(lat, lng, radius, limit = 30) {
  const features = await placesSearch(lat, lng, radius, 'catering.restaurant,catering.cafe,catering.fast_food', limit);
  return features
    .map((f) => {
      const cats = f.properties.categories || [];
      const category = cats.includes('catering.cafe') ? '카페' : cats.includes('catering.fast_food') ? '패스트푸드' : '로컬맛집';
      return {
        name: f.properties.name,
        category,
        cuisine: f.properties.catering?.cuisine,
        lat: f.properties.lat,
        lng: f.properties.lon,
      };
    })
    .filter((r) => r.name && r.lat != null && r.lng != null);
}

module.exports = { geocode, dedupeFarApart, findAttractions, findRestaurants, haversineMeters, translateFeature };

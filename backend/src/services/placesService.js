const osm = require('./osmService');

async function buildPlaceResult(lat, lng, formattedAddress) {
  // Geoapify 무료 요금제 레이트리밋 방지를 위해 순차 호출한다.
  const attractionsRaw = await osm.findAttractions(lat, lng, 3000, 30);
  const restaurantsRaw = await osm.findRestaurants(lat, lng, 1500, 30);

  const attractions = attractionsRaw
    .map((a) => {
      const distanceM = Math.round(osm.haversineMeters(lat, lng, a.lat, a.lng));
      return {
        name: a.name,
        feature: osm.translateFeature(a.feature),
        distanceM,
        walkMin: Math.round(distanceM / 67), // 도보 약 4km/h 기준 (추정)
      };
    })
    .sort((a, b) => a.distanceM - b.distanceM)
    .slice(0, 8);

  const sortedRestaurants = restaurantsRaw
    .map((r) => ({ ...r, distanceM: Math.round(osm.haversineMeters(lat, lng, r.lat, r.lng)) }))
    .sort((a, b) => a.distanceM - b.distanceM);

  // 카테고리 다양성 확보: 카페가 하나도 없으면 마지막 자리에 카페를 끼워 넣는다.
  const cafePick = sortedRestaurants.find((r) => r.category === '카페');
  const top = [];
  for (const r of sortedRestaurants) {
    if (top.length >= 5) break;
    if (top.length === 4 && cafePick && !top.includes(cafePick) && r.category !== '카페') continue;
    top.push(r);
  }

  const restaurants = top.slice(0, 5).map((r, idx) => ({
    rank: idx + 1,
    name: r.name,
    mainMenu: r.cuisine || r.category,
    distanceM: r.distanceM,
    reason: `${r.category} · 평점 확인 불가(무료 오픈데이터 특성상 리뷰 정보 없음) · 거리 기준 상위`,
  }));

  return { ambiguous: false, attractions, restaurants, center: { lat, lng, formattedAddress } };
}

async function searchPlaces(region) {
  const geoResults = await osm.geocode(region);
  if (!geoResults.length) return { error: '확인 불가 (지역을 찾을 수 없음)' };

  const distinct = osm.dedupeFarApart(geoResults);
  if (distinct.length > 1) {
    return { ambiguous: true, candidates: distinct };
  }

  const { lat, lng, name } = distinct[0];
  return buildPlaceResult(lat, lng, name);
}

async function searchPlacesByCoords(lat, lng) {
  return buildPlaceResult(lat, lng, undefined);
}

module.exports = { searchPlaces, searchPlacesByCoords };

class ApiConfig {
  // Render.com에 배포된 백엔드 (무료 플랜). PC를 켜두지 않아도 동작합니다.
  // 무료 플랜은 일정 시간 요청이 없으면 슬립 상태로 전환되어, 첫 요청 응답이
  // 최대 50초 정도 걸릴 수 있습니다 (이후 요청부터는 빨라짐).
  static const String backendBaseUrl = 'https://travel-manager-backend-xnhg.onrender.com';
}

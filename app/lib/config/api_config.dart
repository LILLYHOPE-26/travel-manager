class ApiConfig {
  // 현재 설정: USB로 연결한 실기기 + `adb reverse tcp:3000 tcp:3000` 사용 (PC의 백엔드를
  // 휴대폰의 localhost:3000으로 그대로 연결). USB를 다시 연결하면 `adb reverse` 를 다시 실행해야 합니다.
  //
  // 다른 환경에서 테스트할 때는 아래 중 하나로 바꿔주세요.
  // - 안드로이드 에뮬레이터: http://10.0.2.2:3000
  // - Wi-Fi로 연결한 실기기(같은 공유기): http://<PC의 로컬 IP>:3000 (Windows에서 `ipconfig`로 확인)
  static const String backendBaseUrl = 'http://localhost:3000';
}

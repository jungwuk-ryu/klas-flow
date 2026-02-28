# 로그인 흐름

`KlasClient.login(id, password)`는 아래 단계를 순차 실행한다.

1. 보안키 조회
- 로그인 암호화에 필요한 RSA 공개키와 로그인 토큰을 조회한다.

2. 로그인 토큰 암호화
- `id`, `password`, `loginToken`을 조합해 RSA(PKCS#1)로 암호화한다.

3. 캡차 단계 호출
- 서버의 로그인 검증 상태를 초기화한다.

4. 로그인 확인
- 암호화 토큰을 전달해 로그인 여부를 확정한다.
- OTP/캡차 추가 인증 여부를 판정한다.

5. 프레임 초기화
- 로그인 이후 포털 프레임 페이지를 호출해 세션 상태를 고정한다.

6. 세션 확인
- 세션 정보 API를 호출해 인증 상태를 검증한다.

7. 과목 컨텍스트 자동 초기화
- 학기/과목 목록 API를 호출하고 기본 컨텍스트를 자동 선택한다.

## 실패 처리

- 로그인 실패: `InvalidCredentialsException`
- OTP 필요: `OtpRequiredException`
- 캡차 필요: `CaptchaRequiredException`
- 세션 만료: `SessionExpiredException`
- 서버 장애: `ServiceUnavailableException`
- 네트워크 오류: `NetworkException`
- 응답 파싱 오류: `ParsingException`

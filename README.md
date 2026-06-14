# PoE1 Leveling Overlay(Korean)

Path of Exile1 한국어 레벨링 노트를 화면 위에 띄워주는 가벼운 AutoHotkey v2 오버레이입니다.

게임 클라이언트 로그를 감시해 지역 이동을 감지하고, 현재 액트의 가이드와 지역별 노트를 자동으로 표시합니다.

## 주요 기능

- 한국어 레벨링 가이드 및 지역별 노트 표시
- `Client.txt` / `KakaoClient.txt` 기반 지역 자동 감지
- 현재 액트에 맞는 노트 자동 전환
- 투명한 Always-on-top 가이드/노트 오버레이
- 수동 액트 선택
- 폰트, 투명도, 토글 단축키 설정
- 주요 Path of Exile 클라이언트 로그 경로 자동 탐색

## 요구 사항

- Windows
- AutoHotkey v2
- AutoHotkey 오버레이가 보이는 Path of Exile 화면 모드

## 사용 방법

1. AutoHotkey v2를 설치합니다.
2. `Main.ahk`를 실행합니다.
3. 로그 파일을 자동으로 찾지 못하면 안내에 따라 Path of Exile 로그 파일을 선택합니다.
4. 가이드 창의 핸들을 드래그해 오버레이 위치를 이동합니다.
5. `F5`를 눌러 오버레이를 숨기거나 다시 표시할 수 있습니다.
6. `Notes/Korean/Act */` 아래의 가이드와 노트 파일을 수정해 내용을 바꿀 수 있습니다.

## 노트 형식

각 액트 폴더에는 다음 파일이 있습니다.

- `guide.txt`: 액트 전체에 표시할 가이드
- `notes.txt`: 지역별로 표시할 노트

지역별 노트는 `zone:` 마커로 구분합니다.

```text
zone:지역 이름
이 지역에 표시할 노트입니다.
```

## 설정

설정은 `config.ini`에 저장됩니다.

시스템 트레이 아이콘의 `프로그램 설정` 메뉴에서 폰트, 글자 크기, 투명도, 오버레이 토글 단축키를 변경할 수 있습니다.

가이드 창 위치는 `guideX`, `guideY`로 저장됩니다. 노트 창은 가이드 창의 왼쪽에 자동으로 붙습니다.

기본 오버레이 토글 단축키는 `F5`이며, 설정 창이나 `config.ini`의 `[Hotkey] Toggle` 값으로 변경할 수 있습니다.

## License

This project is licensed under the MIT License. See [LICENSE.md](./LICENSE.md).

## Credits

This project uses or references MIT-licensed work, including `JXON_ahk2` and `JusKillmeQik/PoE-Leveling-Guide`.

See [THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md) for copyright notices, license text, and attribution details.

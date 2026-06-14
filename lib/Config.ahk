#Requires AutoHotkey v2.0

; 전역 경로 및 상태 변수
global baseDataPath := "Notes\Korean\"
global currentAct := "Act 1"
global currentPart := "Part 1"
global guidePath := baseDataPath . currentAct . "\guide.txt"
global notesPath := baseDataPath . currentAct . "\notes.txt"
global iniPath := "config.ini"
global toggleHotkey := ""
global adminAutoRun := 0

; 설정 초기화 및 로드 함수
LoadSettings() {
    global iniPath, guideX, guideY
    global fontName, fontSizeTitle, fontSizeContent, winTransparency
    global currentAct, currentPart, guidePath, notesPath, baseDataPath, toggleHotkey, adminAutoRun

    ; config.ini 파일이 없으면 기본 설정값으로 자동 생성
    if !FileExist(iniPath) {
        IniWrite(1229, iniPath, "WindowPos", "guideX")
        IniWrite(251, iniPath, "WindowPos", "guideY")
        IniWrite("Segoe UI", iniPath, "Font", "Name")
        IniWrite(13, iniPath, "Font", "SizeTitle")
        IniWrite(11, iniPath, "Font", "SizeContent")
        IniWrite(128, iniPath, "Style", "Transparency")
        IniWrite("F5", iniPath, "Hotkey", "Toggle") ; 기본 단축키 설정
        IniWrite("Act 1", iniPath, "Status", "lastAct")
        IniWrite(0, iniPath, "General", "AdminAutoRun") ; 기본값 비활성화
    }

    ; 값 로드
    guideX := IniRead(iniPath, "WindowPos", "guideX", 1229)
    guideY := IniRead(iniPath, "WindowPos", "guideY", 251)
    fontName := IniRead(iniPath, "Font", "Name", "Segoe UI")
    fontSizeTitle := IniRead(iniPath, "Font", "SizeTitle", 13)
    fontSizeContent := IniRead(iniPath, "Font", "SizeContent", 11)
    winTransparency := IniRead(iniPath, "Style", "Transparency", 128)
    toggleHotkey := IniRead(iniPath, "Hotkey", "Toggle", "F10")
    adminAutoRun := IniRead(iniPath, "General", "AdminAutoRun", 0)
    
    ; 마지막 액트 정보 로드 및 경로 동기화
    currentAct := IniRead(iniPath, "Status", "lastAct", "Act 1")
    local actNum := SubStr(currentAct, 5) + 0
    currentPart := (actNum <= 5) ? "Part 1" : "Part 2"
    guidePath := baseDataPath . currentAct . "\guide.txt"
    notesPath := baseDataPath . currentAct . "\notes.txt"
}

; 특정 키 설정 저장 함수
SaveSetting(section, key, value) {
    global iniPath
    IniWrite(value, iniPath, section, key)
}

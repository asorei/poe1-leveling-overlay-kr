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
global lastZone := "해안 지대"

; 설정 초기화 및 로드 함수
LoadSettings() {
    global iniPath, guideX, guideY
    global fontName, fontSizeTitle, fontSizeContent, winTransparency
    global currentAct, currentPart, guidePath, notesPath, baseDataPath, toggleHotkey, adminAutoRun, lastZone, logPath

    ; config.ini 파일이 없으면 기본 설정값으로 자동 생성
    if !FileExist(iniPath) {
        WriteDefaultSettings()
    }

    ; 값 로드
    guideX := ReadSetting("WindowPos", "guideX", 1229)
    guideY := ReadSetting("WindowPos", "guideY", 251)
    fontName := ReadSetting("Font", "Name", "Segoe UI")
    fontSizeTitle := ReadSetting("Font", "SizeTitle", 13)
    fontSizeContent := ReadSetting("Font", "SizeContent", 11)
    winTransparency := ReadSetting("Style", "Transparency", 128)
    toggleHotkey := ReadSetting("Hotkey", "Toggle", "F10")
    adminAutoRun := ReadSetting("General", "AdminAutoRun", 0)
    logPath := ReadSetting("General", "LogPath", logPath)
    
    ; 마지막 액트 정보 로드 및 경로 동기화
    currentAct := ReadSetting("Status", "lastAct", "Act 1")
    lastZone := ReadSetting("Status", "lastZone", "해안 지대")
    local actNum := SubStr(currentAct, 5) + 0
    currentPart := (actNum <= 5) ? "Part 1" : "Part 2"
    guidePath := baseDataPath . currentAct . "\guide.txt"
    notesPath := baseDataPath . currentAct . "\notes.txt"
}

; 기본 설정 파일을 UTF-8로 생성합니다.
WriteDefaultSettings() {
    global iniPath

    defaultText := "[WindowPos]`n"
        . "guideX=1229`n"
        . "guideY=251`n"
        . "[Font]`n"
        . "Name=Segoe UI`n"
        . "SizeTitle=13`n"
        . "SizeContent=11`n"
        . "[Style]`n"
        . "Transparency=128`n"
        . "[Hotkey]`n"
        . "Toggle=F5`n"
        . "[Status]`n"
        . "lastAct=Act 1`n"
        . "lastZone=해안 지대`n"
        . "[General]`n"
        . "AdminAutoRun=0`n"
        . "LogPath=C:\Kakaogames\Path of Exile\logs\KakaoClient.txt`n"

    FileAppend(defaultText, iniPath, "UTF-8")
}

; UTF-8 설정 파일에서 값을 읽습니다.
ReadSetting(section, key, defaultValue := "") {
    global iniPath

    if !FileExist(iniPath)
        return defaultValue

    try {
        text := FileRead(iniPath, "UTF-8")
        if (SubStr(text, 1, 1) = Chr(0xFEFF))
            text := SubStr(text, 2)
    } catch {
        return defaultValue
    }

    inTargetSection := false
    Loop parse, text, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue

        if (SubStr(line, 1, 1) = "[" && SubStr(line, StrLen(line), 1) = "]") {
            inTargetSection := (SubStr(line, 2, StrLen(line) - 2) = section)
            continue
        }

        if !inTargetSection
            continue

        equalPos := InStr(line, "=")
        if (equalPos = 0)
            continue

        currentKey := Trim(SubStr(line, 1, equalPos - 1))
        if (currentKey = key)
            return Trim(SubStr(line, equalPos + 1))
    }

    return defaultValue
}

; 특정 키 설정 저장 함수
SaveSetting(section, key, value) {
    global iniPath

    text := FileExist(iniPath) ? FileRead(iniPath, "UTF-8") : ""
    if (SubStr(text, 1, 1) = Chr(0xFEFF))
        text := SubStr(text, 2)
    lines := text != "" ? StrSplit(text, "`n", "`r") : []
    output := []
    inTargetSection := false
    sectionFound := false
    keyWritten := false

    for line in lines {
        trimmed := Trim(line)
        if (SubStr(trimmed, 1, 1) = "[" && SubStr(trimmed, StrLen(trimmed), 1) = "]") {
            if (inTargetSection && !keyWritten) {
                output.Push(key . "=" . value)
                keyWritten := true
            }
            inTargetSection := (SubStr(trimmed, 2, StrLen(trimmed) - 2) = section)
            if inTargetSection
                sectionFound := true
            output.Push(line)
            continue
        }

        if inTargetSection {
            equalPos := InStr(line, "=")
            currentKey := equalPos ? Trim(SubStr(line, 1, equalPos - 1)) : ""
            if (currentKey = key) {
                if !keyWritten {
                    output.Push(key . "=" . value)
                    keyWritten := true
                }
                continue
            }
        }

        output.Push(line)
    }

    if !sectionFound {
        if (output.Length > 0 && Trim(output[output.Length]) != "")
            output.Push("")
        output.Push("[" . section . "]")
        output.Push(key . "=" . value)
    } else if (inTargetSection && !keyWritten) {
        output.Push(key . "=" . value)
    }

    newText := ""
    for line in output
        newText .= line . "`n"

    if FileExist(iniPath)
        FileDelete(iniPath)
    FileAppend(newText, iniPath, "UTF-8")
}

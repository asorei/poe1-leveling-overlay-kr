#Requires AutoHotkey v2.0

global logPath := "C:\Kakaogames\Path of Exile\logs\KakaoClient.txt"
global logFile := ""

; 로그 감시 시작 함수
InitLogMonitor() {
    global logFile, logPath
    
    ; 1. 먼저 실행 중인 게임에서 로그 경로를 자동으로 찾음
    autoPath := GetAutoLogPath()
    if (autoPath != "") {
        logPath := autoPath
    }
    ; 2. 자동 감지 실패 시 기존 설정값 확인
    else if !FileExist(logPath) {
        MsgBox("게임을 실행 중이 아니거나 로그 파일(Client.txt)을 찾을 수 없습니다. 파일 위치를 직접 선택해주세요.")
        selectedPath := FileSelect(3, , "Client.txt 선택", "로그 파일 (*.txt)")
        if (selectedPath = "") {
            MsgBox("로그 감시를 시작할 수 없습니다.")
            return
        }
        logPath := selectedPath
    }
    
    try {
        logFile := FileOpen(logPath, "r", "UTF-8")
        logFile.Seek(0, 2)
        SetTimer(WatchLog, 1000)
    } catch as e {
        MsgBox("로그 파일을 열 수 없습니다: " e.Message)
    }
}

WatchLog() {
    global logFile
    if !IsObject(logFile)
        return
        
    newContent := logFile.Read()
    if (newContent != "") {
        ProcessLogLines(newContent)
    }
}

global isLevel1Generating := false ; 신규 캐릭터 시작 감지 플래그

ProcessLogLines(logText) {
    global isLevel1Generating
    Loop parse, logText, "`n", "`r" {
        l := Trim(A_LoopField)
        if (l = "") 
            continue
        
        ; 신규 캐릭터 생성 시 발생하는 로그 감지
        if InStr(l, 'Generating level 1 area "1_1_1"') {
            isLevel1Generating := true
            continue
        }
        
        if RegExMatch(l, "\]\s*:\s*(.*?)\s*에 진입했습니다\.", &m) {
            zoneName := Trim(m[1])
            
            ; 신규 캐릭터 시작 패턴 완성 시
            if (isLevel1Generating && zoneName = "황혼의 해안") {
                isLevel1Generating := false ; 플래그 리셋
                ManualSetAct(1) ; 강제로 1장으로 변경
                SetNote(zoneName)
                RememberLastZone(zoneName)
                continue
            }
            
            isLevel1Generating := false ; 다른 지역 진입 시 플래그 리셋

            if IsTownZone(zoneName)
                continue
            UpdateActInfo(zoneName)
            SetNote(zoneName)
            RememberLastZone(zoneName)
        }
        else if InStr(l, "레벨이 되었습니다") {
            ;ToolTip("Level Up!")
            ;SetTimer(() => ToolTip(), -3000)
        }
        else if InStr(l, "사망했습니다") {
            ;ToolTip("사망하였습니다.")
            ;SetTimer(() => ToolTip(), -3000)
        }
    }
}

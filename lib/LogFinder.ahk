#Requires AutoHotkey v2.0

; 게임 프로세스 이름과 로그 파일 정보 맵
; [프로세스 이름, 로그파일명]
global POE_PROCESSES := [
    ["PathOfExile_x64_KG.exe", "KakaoClient.txt"],
    ["PathOfExile_KG.exe", "KakaoClient.txt"],
    ["PathOfExile.exe", "Client.txt"],
    ["PathOfExileSteam.exe", "Client.txt"],    
    ["PathOfExile_EGS.exe", "Client.txt"],
    ["PathOfExileEGS.exe", "Client.txt"],
    ["PathOfExile_x64.exe", "Client.txt"],
    ["PathOfExile_x64Steam.exe", "Client.txt"],    
    ["PathOfExile_x64EGS.exe", "Client.txt"],
    ["PathOfExilex64EGS.exe", "Client.txt"]
]

; 실행 중인 게임의 로그 파일 경로를 자동으로 찾는 함수
GetAutoLogPath() {
    for item in POE_PROCESSES {
        exeName := item[1]
        logName := item[2]
        
        if ProcessExist(exeName) {
            fullPath := GetProcessPath(exeName)
            if (fullPath != "") {
                ; 실행 파일 경로에서 디렉토리 추출 (마지막 \ 기준)
                SplitPath(fullPath,, &dir)
                logPath := dir . "\logs\" . logName
                
                if FileExist(logPath) {
                    return logPath
                }
            }
        }
    }
    return ""
}

; 게임이 실행 중인지 확인하는 함수
IsGameRunning() {
    for item in POE_PROCESSES {
        if ProcessExist(item[1])
            return true
    }
    return false
}

; 프로세스 이름을 통해 실행 파일의 전체 경로를 가져오는 함수 (WMI 사용)
GetProcessPath(exeName) {
    try {
        wmi := ComObjGet("winmgmts:")
        query := "Select ExecutablePath from Win32_Process where Name = '" . exeName . "'"
        for process in wmi.ExecQuery(query) {
            return process.ExecutablePath
        }
    } catch {
        return ""
    }
    return ""
}

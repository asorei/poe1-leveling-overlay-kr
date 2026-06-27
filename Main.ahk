#Requires AutoHotkey v2.0
#SingleInstance Force

; License: MIT

global toggleHotkey := "" ; 초기값 할당으로 unassigned 에러 방지
; 라이브러리 및 모듈 포함
#Include _jxon.ahk
#Include lib\Config.ahk
#Include lib\Data.ahk
#Include lib\Logic.ahk
#Include lib\LogMonitor.ahk
#Include lib\LogFinder.ahk
#Include lib\GUI.ahk

; --- 초기화 시퀀스 ---

; 프로젝트 전용 트레이 아이콘 설정
trayIconPath := A_ScriptDir "\assets\tray-icon.ico"
if FileExist(trayIconPath)
    TraySetIcon(trayIconPath)

; 1. 설정 로드
LoadSettings()

; 1.1 관리자 권한 자동 승인 체크 (설정이 활성화된 경우에만 실행)
if adminAutoRun && !A_IsAdmin {
    Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

; 2. 데이터 로드
LoadKData()
LoadNotesToMap(notesPath)

; 3. GUI 생성
CreateWindows()

; 4. 로그 감시 시작
InitLogMonitor()

; 5. 토글 단축키 등록
if (toggleHotkey != "")
    Hotkey(toggleHotkey, ToggleOverlay)

; --- 트레이 메뉴 설정 ---
A_TrayMenu.Delete()
A_TrayMenu.Add("프로그램 설정", (*) => ShowSettingsGui())
A_TrayMenu.Add("관리자 권한 자동 실행", ToggleAdminSetting)
if adminAutoRun
    A_TrayMenu.Check("관리자 권한 자동 실행")

A_TrayMenu.Add() ; 구분선
A_TrayMenu.Add("재시작", (*) => Reload())
A_TrayMenu.Add("종료", (*) => ExitApp())

; --- 내부 함수 ---
ToggleAdminSetting(itemName, itemPos, menuObj) {
    global adminAutoRun
    adminAutoRun := !adminAutoRun
    menuObj.ToggleCheck(itemName)
    SaveSetting("General", "AdminAutoRun", adminAutoRun)
    if adminAutoRun
        MsgBox("다음 실행부터 관리자 권한 승인을 자동으로 요청합니다.", "설정 완료", "Iconi T3")
}

#Requires AutoHotkey v2.0

; 전역 GUI 변수
global guideWin := unset, notesWin := unset, actSelectorGui := unset, actDDL := unset
global guideHandle := unset

global toggleHotkey := ""
global overlayManualOff := false
; 디자인 상수 정의
global HANDLE_SIZE := 30
global HANDLE_COLOR := "FFD700" ; Gold (더 밝고 선명한 금색)
global TRANSPARENT_KEY := "EEAA99"
global WINDOW_MAX_WIDTH := 600
global ATTACHED_WINDOW_GAP := 10

; GUI 생성 및 초기화 함수
CreateWindows() {
    global guideWin, notesWin, actSelectorGui, actDDL, guideHandle
    global guideX, guideY, winTransparency, fontName, currentAct, guidePath, lastZone, noteMap

    ; 메인 창 생성 (+E0x20: 클릭 통과)
    guideWin := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20")
    guideWin.BackColor := "000000"
    WinSetTransparent(winTransparency, guideWin)

    notesWin := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20")
    notesWin.BackColor := "000000"
    WinSetTransparent(winTransparency, notesWin)

    ; 가이드 창만 드래그할 수 있도록 핸들을 생성합니다.
    guideHandle := CreateHandle()

    ; 액트 선택용 GUI 생성
    actSelectorGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x08000000")
    actSelectorGui.BackColor := "EEAA99"
    actSelectorGui.SetFont("s9 cFFD700", fontName) ; 드롭다운 폰트 골드로 변경
    actList := ["Act 1","Act 2","Act 3","Act 4","Act 5","Act 6","Act 7","Act 8","Act 9","Act 10"]
    actDDL := actSelectorGui.Add("DropDownList", "x5 y2 w80 Choose" . SubStr(currentAct, 5), actList)
    actDDL.OnEvent("Change", (ctrl, *) => ManualSetAct(SubStr(ctrl.Text, 5)))

    ; 초기 배치 및 데이터 로드
    ; 1. 가이드 창을 먼저 저장된 위치에 띄워둡니다.
    guideWin.Show("NoActivate x" . guideX . " y" . guideY . " Hide")
    notesWin.Show("NoActivate x" . guideX . " y" . guideY . " Hide")
    WinSetTransColor(TRANSPARENT_KEY, actSelectorGui)

    ; 2. 데이터 로드 및 핸들 동기화
    if FileExist(guidePath)
        UpdateNativeGui(guideWin, currentAct, FileRead(guidePath, "UTF-8"))
    initialZone := Trim(lastZone)
    if (initialZone != "" && noteMap.Has(initialZone))
        SetNote(initialZone)
    else
        SetNote("해안 지대")

    ; 메시지 핸들러 등록
    OnMessage(0x0232, WM_EXITSIZEMOVE)
    OnMessage(0x0201, WM_LBUTTONDOWN)
}

; 드래그 핸들 생성을 담당하는 헬퍼 함수
CreateHandle() {
    handle := Gui("+AlwaysOnTop -Caption +ToolWindow")
    handle.BackColor := TRANSPARENT_KEY
    handle.SetFont("s15 bold w700", "Segoe UI Symbol")
    handle.Add("Text", "x0 y0 w" HANDLE_SIZE " h" HANDLE_SIZE " c" HANDLE_COLOR " Center", "✥")
    WinSetTransColor(TRANSPARENT_KEY, handle)
    return handle
}

; 기본 GUI 내용을 업데이트하는 함수
UpdateNativeGui(guiObj, title, content) {
    global fontSizeTitle, fontName, fontSizeContent, notesWin, guideWin, WINDOW_MAX_WIDTH, overlayManualOff

    ; 스타일 정의 맵 (리팩토링 포인트: if-else 제거)
    static STYLES := Map(
        "G,", {color: "c39FF14", skip: 3}, ; Neon Green
        "Y,", {color: "cFFFF33", skip: 3}, ; Neon Yellow
        "R,", {color: "cFF3131", skip: 3}, ; Neon Red
        "B,", {color: "c00FFFF", skip: 3}, ; Cyan (물색보다 선명)
        "<",  {color: "cFF9999", skip: 2}, ; 부드러운 빨강
        "+",  {color: "c99FF99", skip: 2}, ; 부드러운 녹색
        ">",  {color: "c99CCFF", skip: 2}  ; 부드러운 파랑
    )

    local maxW := 0, tw := 0, lines := StrSplit(content, "`n", "`r")
    local cleanLine := "", actualW := 0

    ; 1. 기존 GUI 파괴 및 재건설 (API 직접 호출로 인한 메모리 릭 및 크래시 방지)
    ; 파괴하기 전에 기존 윈도우의 위치를 획득하여 위치 이동 문제를 방지합니다.
    local prevX := "", prevY := ""
    if (guiObj == guideWin) {
        if (IsSet(guideWin) && guideWin.Hwnd)
            try guideWin.GetPos(&prevX, &prevY)
        guideWin.Destroy()
        guideWin := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20")
        guideWin.BackColor := "000000"
        WinSetTransparent(winTransparency, guideWin)
        guiObj := guideWin
    } else if (guiObj == notesWin) {
        if (IsSet(notesWin) && notesWin.Hwnd)
            try notesWin.GetPos(&prevX, &prevY)
        notesWin.Destroy()
        notesWin := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20")
        notesWin.BackColor := "000000"
        WinSetTransparent(winTransparency, notesWin)
        guiObj := notesWin
    }

    ; 2. 측정 전용 임시 Gui 생성 (독립적 측정을 위함)
    local measureGui := Gui()

    ; 제목 너비 측정
    measureGui.SetFont("s" . fontSizeTitle . " bold", fontName)
    local tTemp := measureGui.Add("Text", , title)
    tTemp.GetPos(,, &tw)
    ; 드래그 핸들(약 40px) 공간을 미리 확보하여 제목 너비 계산
    if (tw + 40 > maxW)
        maxW := tw + 40

    ; 내용 너비 측정
    measureGui.SetFont("s" . fontSizeContent . " w700", fontName)
    for line in lines {
        if (line == "")
            continue
        
        cleanLine := line
        ; 스타일 마커 제거 후 너비 측정
        for prefix, style in STYLES {
            if (SubStr(line, 1, StrLen(prefix)) = prefix) {
                cleanLine := SubStr(line, style.skip)
                break
            }
        }

        local cTemp := measureGui.Add("Text", , cleanLine)
        cTemp.GetPos(,, &tw)
        if (tw > maxW)
            maxW := tw
    }
    measureGui.Destroy() ; 측정 도구 즉시 파괴

    ; 3. 너비 결정
    if (maxW > WINDOW_MAX_WIDTH)
        maxW := WINDOW_MAX_WIDTH
    actualW := maxW + 20 ; 좌우 10px씩 여백

    ; 4. 실제 GUI 구성
    ; 제목 및 구분선
    guiObj.SetFont("s" . fontSizeTitle . " bold", fontName)
    ; 제목 너비에서 핸들 공간(40px)을 제외하여 겹침 방지
    guiObj.Add("Text", "x10 y10 cFFD700 Center w" . (maxW - 40) . " +E0x20", title)
    guiObj.Add("Text", "x10 y+2 w" . maxW . " h1 BackgroundFFD700 +E0x20")

    ; 내용 행 추가
    local isFirstLine := true
    for line in lines {
        if (line == "") {
            guiObj.Add("Text", "h2 +E0x20", "")
            isFirstLine := false
            continue
        }

        local color := "cE0E0E0", weight := "700" ; 기본 텍스트를 순백색보다 가독성 좋은 플래티넘 화이트로 변경
        cleanLine := line
        
        ; 스타일 적용
        for prefix, style in STYLES {
            if (SubStr(line, 1, StrLen(prefix)) = prefix) {
                color := style.color
                cleanLine := SubStr(line, style.skip)
                break
            }
        }

        guiObj.SetFont("s" . fontSizeContent . " w" . weight, fontName)
        local yPos := isFirstLine ? "y+5" : "y+2"
        guiObj.Add("Text", color . " x10 " . yPos . " w" . maxW . " +BackgroundTrans +E0x20", cleanLine)
        isFirstLine := false
    }

    ; 5. 창 크기 자동 조절 및 출력
    ; 수동 숨김 상태에서도 내용과 AutoSize는 갱신하되 화면에는 표시하지 않습니다.
    local showOptions := "AutoSize NoActivate"
    if overlayManualOff
        showOptions .= " Hide"

    if (guiObj == guideWin) {
        ; 기존 위치가 확보되었으면 그 위치로, 없다면 ini 설정 위치로 설정
        local targetX := (prevX !== "") ? prevX : guideX
        local targetY := (prevY !== "") ? prevY : guideY
        guiObj.Show(showOptions . " x" . targetX . " y" . targetY)
    } else {
        guiObj.Show(showOptions)
    }

    ; 6. 가이드 창을 기준으로 노트/핸들/액트 선택창을 일괄 재배치
    PositionAttachedWindows()
}

; 가이드 창을 기준으로 노트 창과 보조 UI를 고정 배치합니다.
PositionAttachedWindows() {
    global guideWin, notesWin, actSelectorGui, actDDL, guideHandle, overlayManualOff
    global HANDLE_SIZE, ATTACHED_WINDOW_GAP

    if !(IsSet(guideWin) && IsSet(notesWin))
        return

    local gx, gy, gw, gh, nx, ny, nw, nh
    guideWin.GetPos(&gx, &gy, &gw, &gh)
    notesWin.GetPos(,, &nw, &nh)

    nx := gx - nw - ATTACHED_WINDOW_GAP
    ny := gy

    ; 왼쪽 화면 밖으로 나가면 가이드 창을 오른쪽으로 밀어 노트 창의 왼쪽 배치를 유지합니다.
    if (nx < 0) {
        gx += -nx
        nx := 0
        guideWin.Move(gx, gy)
    }

    if overlayManualOff {
        notesWin.Move(nx, ny)
    } else {
        notesWin.Show("NoActivate x" . nx . " y" . ny)
    }

    local offset := HANDLE_SIZE + 5
    if IsSet(guideHandle) {
        if overlayManualOff
            guideHandle.Move(gx + gw - offset, gy + 5, HANDLE_SIZE, HANDLE_SIZE)
        else
            guideHandle.Show("NoActivate x" . (gx + gw - offset) . " y" . (gy + 5) . " w" HANDLE_SIZE " h" HANDLE_SIZE)
    }

    if IsSet(actSelectorGui) && IsSet(actDDL) {
        local dw, dh, ax, ay
        actDDL.GetPos(,, &dw, &dh)
        ax := nx + nw - dw
        ay := ny - dh
        if (ay < 0)
            ay := ny

        if overlayManualOff
            actSelectorGui.Move(ax, ay)
        else
            actSelectorGui.Show("NoActivate x" . ax . " y" . ay)
    }
}

; 창 이동 종료 시 위치 저장
WM_EXITSIZEMOVE(wParam, lParam, msg, hwnd) {
    global guideWin, guideHandle
    SetTimer(SyncFollow, 0) ; 동기화 타이머 정지

    if (IsSet(guideHandle) && hwnd == guideHandle.Hwnd) {
        PositionAttachedWindows()
        WinGetPos(&x, &y, &w, &h, "ahk_id " guideWin.Hwnd)
        SaveSetting("WindowPos", "guideX", x), SaveSetting("WindowPos", "guideY", y)
    }
}

; 드래그 이동 보조 (제목 영역만 허용)
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global guideHandle
    
    if (IsSet(guideHandle) && hwnd == guideHandle.Hwnd) {
        PostMessage(0xA1, 2, , , hwnd) ; 핸들 드래그 시작
        SetTimer(SyncFollow, 10) ; 메인 창이 따라오도록 타이머 시작
    }
}

; 핸들을 따라 메인 창 이동시키는 함수
SyncFollow() {
    global guideWin, guideHandle, HANDLE_SIZE
    local offset := HANDLE_SIZE + 5
    
    if IsSet(guideHandle) && WinExist("ahk_id " guideHandle.Hwnd) {
        guideHandle.GetPos(&hx, &hy, &hw, &hh)
        guideWin.GetPos(,, &ww, &wh)
        guideWin.Move(hx - ww + offset, hy - 5)
        PositionAttachedWindows()
    }
}

; 설정 GUI 출력
ShowSettingsGui() {
    global fontName, fontSizeTitle, fontSizeContent, winTransparency, treeTransparency, toggleHotkey, toggleTreeHotkey, toggleTreeLockHotkey, treePrevHotkey, treeNextHotkey

    fontList := Map()
    Loop Reg, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" {
        name := RegExReplace(A_LoopRegName, "\s\(.*?\)$")
        fontList[name] := 1
    }

    sortedFonts := ""
    for name in fontList
        sortedFonts .= name "`n"
    fontsArray := StrSplit(Sort(Trim(sortedFonts, "`n")), "`n")

    currentIdx := 1
    for i, name in fontsArray {
        if (name = fontName) {
            currentIdx := i
            break
        }
    }

    fontGui := Gui("+AlwaysOnTop", "프로그램 설정")
    fontGui.SetFont("s10", "Malgun Gothic")
    
    ; 설정창이 열려있는 동안 기존 단축키 오동작 방지 및 단축키 변경이 원활하도록 핫키를 일시 중지합니다.
    Suspend(true)
    
    fontGui.OnEvent("Close", (*) => OnSettingsClose())
    fontGui.OnEvent("Escape", (*) => OnSettingsClose())
    
    OnSettingsClose() {
        Suspend(false)
        fontGui.Destroy()
    }
    
    fontGui.Add("Text",, "시스템 폰트 선택:")
    ddlName := fontGui.Add("DropDownList", "w250 Choose" . currentIdx, fontsArray)
    fontGui.Add("Text",, "제목 크기:")
    editTitleSize := fontGui.Add("Edit", "w50", fontSizeTitle)
    fontGui.Add("Text",, "내용 크기:")
    editContentSize := fontGui.Add("Edit", "w50", fontSizeContent)
    fontGui.Add("Text",, "배경 투명도 (0: 투명, 255: 불투명):")
    sliderTrans := fontGui.Add("Slider", "w250 Range0-255", winTransparency)
    fontGui.Add("Text",, "스킬트리 오버레이 투명도 (0: 투명, 255: 불투명):")
    sliderTreeTrans := fontGui.Add("Slider", "w250 Range0-255", treeTransparency)
    fontGui.Add("Text",, "온/오프 단축키:")
    hkCtrl := fontGui.Add("Hotkey", "w250", toggleHotkey)
    fontGui.Add("Text",, "스킬트리 오버레이 단축키:")
    hkTreeCtrl := fontGui.Add("Hotkey", "w250", toggleTreeHotkey)
    fontGui.Add("Text",, "스킬트리 잠금/해제 단축키:")
    hkTreeLockCtrl := fontGui.Add("Hotkey", "w250", toggleTreeLockHotkey)
    fontGui.Add("Text",, "스킬트리 이전 이미지 단축키:")
    hkTreePrevCtrl := fontGui.Add("Hotkey", "w250", treePrevHotkey)
    fontGui.Add("Text",, "스킬트리 다음 이미지 단축키:")
    hkTreeNextCtrl := fontGui.Add("Hotkey", "w250", treeNextHotkey)
    
    btnSave := fontGui.Add("Button", "w250 h40 Default", "저장 및 적용")
    btnSave.OnEvent("Click", (*) => SaveAndApply(ddlName.Text, editTitleSize.Value, editContentSize.Value, sliderTrans.Value, sliderTreeTrans.Value, hkCtrl.Value, hkTreeCtrl.Value, hkTreeLockCtrl.Value, hkTreePrevCtrl.Value, hkTreeNextCtrl.Value))

    fontGui.Show()

    SaveAndApply(n, st, sc, tr, ttr, hk, hkt, hktl, hktp, hktn) {
        ; 입력값 검증 (비정상 입력값으로 인한 재부팅 무한 크래시 락 방지)
        if (!IsInteger(st) || Integer(st) <= 0 || Integer(st) > 100) {
            MsgBox("제목 폰트 크기는 1에서 100 사이의 정수여야 합니다.", "설정 오류", "Icon! 4096")
            return
        }
        if (!IsInteger(sc) || Integer(sc) <= 0 || Integer(sc) > 100) {
            MsgBox("내용 폰트 크기는 1에서 100 사이의 정수여야 합니다.", "설정 오류", "Icon! 4096")
            return
        }
        if (!IsInteger(tr) || Integer(tr) < 0 || Integer(tr) > 255) {
            MsgBox("투명도는 0에서 255 사이의 정수여야 합니다.", "설정 오류", "Icon! 4096")
            return
        }
        if (!IsInteger(ttr) || Integer(ttr) < 0 || Integer(ttr) > 255) {
            MsgBox("스킬트리 투명도는 0에서 255 사이의 정수여야 합니다.", "설정 오류", "Icon! 4096")
            return
        }

        SaveSetting("Font", "Name", n)
        SaveSetting("Font", "SizeTitle", Integer(st))
        SaveSetting("Font", "SizeContent", Integer(sc))
        SaveSetting("Style", "Transparency", Integer(tr))
        SaveSetting("Style", "treeTransparency", Integer(ttr))
        SaveSetting("Hotkey", "Toggle", hk)
        SaveSetting("Hotkey", "ToggleTree", hkt)
        SaveSetting("Hotkey", "ToggleTreeLock", hktl)
        SaveSetting("Hotkey", "TreePrev", hktp)
        SaveSetting("Hotkey", "TreeNext", hktn)
        
        fontGui.Opt("-AlwaysOnTop") ; 설정창의 AlwaysOnTop 속성을 일시적으로 해제
        MsgBox("설정이 저장되었습니다. 프로그램을 재시작합니다.", "설정 저장", 4096)
        Reload()
    }
}

; 오버레이 창들을 숨기는 함수
HideOverlayWindows() {
    global guideWin, notesWin, actSelectorGui, guideHandle
    global treeWin
    
    ; 각 창이 존재하고 유효한 경우에만 숨김 처리
    if IsSet(guideWin) && guideWin.Hwnd
        guideWin.Hide()
    if IsSet(notesWin) && notesWin.Hwnd
        notesWin.Hide()
    if IsSet(actSelectorGui) && actSelectorGui.Hwnd
        actSelectorGui.Hide()
    if IsSet(guideHandle) && guideHandle.Hwnd
        guideHandle.Hide()
    if IsSet(treeWin) && treeWin.Hwnd
        treeWin.Hide()
}

; 오버레이 창들을 다시 보이게 하는 함수
ShowOverlayWindows() {
    global guideWin, notesWin, actSelectorGui, guideHandle, overlayManualOff
    global treeWin, treeVisible
    
    ; 사용자가 수동으로 끈 상태라면 다시 보여주지 않음
    if overlayManualOff
        return

    ; 각 창이 존재하고 유효한 경우에만 보이게 처리 (포커스를 뺏지 않음)
    if IsSet(guideWin) && guideWin.Hwnd
        guideWin.Show("NoActivate")
    if IsSet(notesWin) && notesWin.Hwnd
        notesWin.Show("NoActivate")
    if IsSet(actSelectorGui) && actSelectorGui.Hwnd
        actSelectorGui.Show("NoActivate")
    if IsSet(guideHandle) && guideHandle.Hwnd
        guideHandle.Show("NoActivate")
    if IsSet(treeWin) && treeWin.Hwnd && treeVisible
        treeWin.Show("NoActivate")
    PositionAttachedWindows()
}

; 단축키 토글 함수
ToggleOverlay(*) {
    global overlayManualOff
    overlayManualOff := !overlayManualOff
    
    if overlayManualOff
        HideOverlayWindows()
    else
        ShowOverlayWindows()
}

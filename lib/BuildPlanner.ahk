#Requires AutoHotkey v2.0

; 스킬트리 오버레이 (슬라이드쇼 빌드 플래너) 모듈
global treeWin := unset
global treePicCtrl := unset
global treeLockStatusText := unset
global btnPrev := unset, btnNext := unset, txtPageIndicator := unset

; (참고: treeX, treeY, treeW, treeH, treeTransparency, toggleTreeHotkey, treeLocked는 lib\Config.ahk에 전역 선언되어 있습니다.)
global treeVisible := false

global treeImages := []
global currentTreeIndex := 1
global treeFolder := A_ScriptDir "\tree"

; 초기화 함수
InitBuildPlanner() {
    global treeWin, treePicCtrl, treeLockStatusText, btnPrev, btnNext, txtPageIndicator
    global treeX, treeY, treeW, treeH, treeTransparency, toggleTreeHotkey, treeLocked
    global treeFolder

    ; 1. tree 폴더 자동 생성
    if !DirExist(treeFolder) {
        try DirCreate(treeFolder)
    }

    ; 2. config.ini 설정은 lib\Config.ahk의 LoadSettings()에서 일괄적으로 로드됩니다.

    ; 3. GUI 창 설정 생성
    ; 잠금 상태에 따라 클릭 통과(+E0x20) 및 크기 조절(+Resize) 설정 적용
    guiOptions := "+AlwaysOnTop -Caption +ToolWindow +LastFound"
    if !treeLocked {
        guiOptions .= " +Resize"
    } else {
        guiOptions .= " +E0x20"
    }

    treeWin := Gui(guiOptions)
    treeWin.BackColor := "1E1E1E" ; 어두운 회색 배경
    WinSetTransparent(treeTransparency, treeWin)

    ; 레이아웃 계산 (하단 버튼 영역 확보)
    buttonH := 30
    navY := treeH - buttonH - 10
    imageH := navY - 10

    ; 이미지 컨트롤 추가 (초기에는 숨김)
    treePicCtrl := treeWin.Add("Picture", "x0 y0 w" . treeW . " h" . imageH . " +BackgroundTrans +Hidden", "")

    ; 안내 텍스트 추가 (이미지가 없을 때나 잠금/해제 안내용)
    treeLockStatusText := treeWin.Add("Text", "x10 y10 w" . (treeW - 20) . " h" . imageH . " cFFD700 Center +BackgroundTrans", "")

    ; 하단 내비게이션 컨트롤 추가
    treeWin.SetFont("s10 bold", "Segoe UI")
    btnPrev := treeWin.Add("Button", "x10 y" . navY . " w50 h" . buttonH, "<")
    btnPrev.OnEvent("Click", (*) => PrevTreeImage())

    txtPageIndicator := treeWin.Add("Text", "x" . (treeW // 2 - 100) . " y" . (navY + 5) . " w200 h" . buttonH . " cFFD700 Center +BackgroundTrans", "0 / 0")

    btnNext := treeWin.Add("Button", "x" . (treeW - 60) . " y" . navY . " w50 h" . buttonH, ">")
    btnNext.OnEvent("Click", (*) => NextTreeImage())

    ; GUI 이벤트 및 윈도우 메시지 핸들러 등록
    treeWin.OnEvent("Size", TreeWin_Size)
    OnMessage(0x0201, TreeWinLButtonDown)
    OnMessage(0x0232, TreeWinExitSizeMove)

    ; 폴더 내 이미지 스캔
    ScanTreeImages()

    ; 잠금 상태에 따른 버튼 비활성화 초기화
    if treeLocked {
        btnPrev.Enabled := false
        btnNext.Enabled := false
    }
}

; tree 폴더의 모든 이미지를 스캔하여 정렬
ScanTreeImages() {
    global treeImages, treeFolder, currentTreeIndex
    treeImages := []
    
    Loop Files, treeFolder "\*.*" {
        ext := String(A_LoopFileExt)
        if (ext = "png" || ext = "jpg" || ext = "jpeg" || ext = "PNG" || ext = "JPG" || ext = "JPEG") {
            treeImages.Push(A_LoopFileFullPath)
        }
    }

    if (treeImages.Length > 0) {
        ; 스캔된 이미지 경로 목록을 파일명 알파벳/숫자 순서로 안전하게 정렬합니다.
        tempStr := ""
        for path in treeImages
            tempStr .= path . "`n"
        tempStr := Sort(Trim(tempStr, "`n"))
        treeImages := StrSplit(tempStr, "`n")

        if (currentTreeIndex > treeImages.Length)
            currentTreeIndex := treeImages.Length
        if (currentTreeIndex < 1)
            currentTreeIndex := 1
        ShowCurrentImage()
    } else {
        ShowPlaceholder()
    }
}

; 현재 선택된 이미지 표시
ShowCurrentImage() {
    global treePicCtrl, treeLockStatusText, btnPrev, btnNext, txtPageIndicator
    global treeImages, currentTreeIndex, treeW, treeH

    if (treeImages.Length = 0) {
        ShowPlaceholder()
        return
    }

    imgPath := treeImages[currentTreeIndex]
    SplitPath(imgPath, &fileName)

    buttonH := 30
    navY := treeH - buttonH - 10
    imageH := navY - 10

    treeLockStatusText.Opt("+Hidden")
    treePicCtrl.Opt("-Hidden")
    
    ; 이미지 설정 및 크기 조절
    treePicCtrl.Value := imgPath
    treePicCtrl.Move(,, treeW, imageH)

    ; 하단 페이지 텍스트 업데이트 (파일명 일부 포함)
    txtPageIndicator.Text := currentTreeIndex . " / " . treeImages.Length . " (" . fileName . ")"
}

; 이미지가 없을 때의 플레이스홀더 텍스트 표시
ShowPlaceholder() {
    global treePicCtrl, treeLockStatusText, txtPageIndicator
    global treeW, treeH, treeFolder, toggleTreeHotkey

    buttonH := 30
    navY := treeH - buttonH - 10
    imageH := navY - 10

    treePicCtrl.Opt("+Hidden")
    treeLockStatusText.Opt("-Hidden")
    
    treeLockStatusText.Text := "스킬트리 오버레이 (빌드 플래너)`n`n[ " . toggleTreeHotkey . " ] : 오버레이 표시/숨김`n[ Shift + " . toggleTreeHotkey . " ] : 드래그 이동 잠금/해제`n[ Ctrl + [ / ] ] : 오버레이가 잠겨있을 때 이전/다음 이미지`n`n"
        . "tree 폴더에 이미지 파일이 없습니다.`n`n폴더 경로: " . treeFolder . "`n`n이 폴더에 png 또는 jpg 이미지를 넣어주세요.`n(예: 1.png, 2.png, act1.jpg 등)"
    
    treeLockStatusText.Move(,, treeW - 20, imageH - 20)
    txtPageIndicator.Text := "0 / 0"
}

; 이전 이미지
PrevTreeImage(*) {
    global treeImages, currentTreeIndex
    if (treeImages.Length = 0)
        return
    currentTreeIndex--
    if (currentTreeIndex < 1)
        currentTreeIndex := treeImages.Length
    ShowCurrentImage()
}

; 다음 이미지
NextTreeImage(*) {
    global treeImages, currentTreeIndex
    if (treeImages.Length = 0)
        return
    currentTreeIndex++
    if (currentTreeIndex > treeImages.Length)
        currentTreeIndex := 1
    ShowCurrentImage()
}

; 오버레이 토글
ToggleTreeOverlay(*) {
    global treeWin, treeVisible, treeX, treeY, treeW, treeH
    if !IsSet(treeWin)
        return

    treeVisible := !treeVisible
    if treeVisible {
        ; 켤 때 폴더 내 이미지를 새로 스캔 (실시간 파일 감지)
        ScanTreeImages()
        treeWin.Show("NoActivate x" . treeX . " y" . treeY . " w" . treeW . " h" . treeH)
    } else {
        treeWin.Hide()
    }
}

; 위치 고정 / 잠금 토글
ToggleTreeLock(*) {
    global treeWin, treeLocked, treeVisible, treeX, treeY, treeW, treeH
    global btnPrev, btnNext
    if !IsSet(treeWin)
        return

    treeLocked := !treeLocked
    SaveSetting("General", "TreeLocked", treeLocked)

    if treeLocked {
        ; 잠금: 클릭 통과 모드, 크기 변경 비활성화, 버튼 클릭 비활성화
        treeWin.Opt("+E0x20 -Resize")
        if IsSet(btnPrev)
            btnPrev.Enabled := false
        if IsSet(btnNext)
            btnNext.Enabled := false
        MsgBox("스킬트리 오버레이 창이 잠겼습니다.`n(게임 중 마우스 클릭이 오버레이를 통과합니다.)`n`n잠금 해제: " . toggleTreeLockHotkey . "`n잠긴 상태에서 단축키 Ctrl + [ / ] 로 스킬트리를 넘겨볼 수 있습니다.", "스킬트리 잠금", "Iconi T2 4096")
    } else {
        ; 해제: 마우스 클릭 인식, 크기 변경 및 버튼 클릭 활성화
        treeWin.Opt("-E0x20 +Resize")
        if IsSet(btnPrev)
            btnPrev.Enabled := true
        if IsSet(btnNext)
            btnNext.Enabled := true
        MsgBox("스킬트리 오버레이 잠금이 해제되었습니다.`n`n드래그하여 이동하고 창 모서리를 끌어 크기를 조절할 수 있습니다.", "스킬트리 잠금 해제", "Iconi T2 4096")
    }

    if treeVisible {
        treeWin.Show("NoActivate x" . treeX . " y" . treeY . " w" . treeW . " h" . treeH)
    }
}

; 창 크기가 변경될 때 하단 영역과 이미지를 재배치
TreeWin_Size(guiObj, minMax, width, height) {
    global treePicCtrl, treeLockStatusText, btnPrev, btnNext, txtPageIndicator
    global treeW, treeH
    
    treeW := width
    treeH := height
    
    buttonH := 30
    navY := height - buttonH - 10
    imageH := navY - 10

    if IsSet(treePicCtrl)
        treePicCtrl.Move(,, width, imageH)
    if IsSet(treeLockStatusText)
        treeLockStatusText.Move(,, width - 20, imageH - 20)
    
    if IsSet(btnPrev)
        btnPrev.Move(, navY,, buttonH)
    if IsSet(txtPageIndicator)
        txtPageIndicator.Move(width // 2 - 100, navY + 5, 200, buttonH)
    if IsSet(btnNext)
        btnNext.Move(width - 60, navY,, buttonH)
}

; 마우스 좌클릭 드래그로 캡션 없는 창 이동 처리
TreeWinLButtonDown(wParam, lParam, msg, hwnd) {
    global treeWin, treeLocked
    if (IsSet(treeWin) && hwnd == treeWin.Hwnd && !treeLocked) {
        PostMessage(0xA1, 2, , , hwnd) ; WM_NCLBUTTONDOWN (0xA1) & HTCAPTION (2)
    }
}

; 창 이동 또는 크기 조절 종료 시 위치 및 크기 정보 저장
TreeWinExitSizeMove(wParam, lParam, msg, hwnd) {
    global treeWin, treeX, treeY, treeW, treeH
    if (IsSet(treeWin) && hwnd == treeWin.Hwnd) {
        try {
            WinGetPos(&x, &y, &w, &h, "ahk_id " treeWin.Hwnd)
            treeX := x
            treeY := y
            treeW := w
            treeH := h
            SaveSetting("WindowPos", "treeX", x)
            SaveSetting("WindowPos", "treeY", y)
            SaveSetting("WindowPos", "treeW", w)
            SaveSetting("WindowPos", "treeH", h)
        }
    }
}

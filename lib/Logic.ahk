#Requires AutoHotkey v2.0

; 마을 지역 여부를 판별하는 함수
IsTownZone(zoneName) {
    global townZones
    target := Trim(zoneName)
    for town in townZones {
        if (town = "은신처") {
            if InStr(target, "은신처")
                return true
        } else if (target = town) {
            return true
        }
    }
    return false
}

; 액트를 수동으로 설정하는 함수
ManualSetAct(actNum) {
    global currentAct, currentPart, guidePath, notesPath, baseDataPath, guideWin, notesWin, actDDL
    actNum := Integer(actNum)
    
    newAct := "Act " . actNum
    newPart := (actNum <= 5 ? "Part 1" : "Part 2")
    
    currentAct := newAct
    currentPart := newPart
    guidePath := baseDataPath . currentAct . "\guide.txt"
    notesPath := baseDataPath . currentAct . "\notes.txt"
    
    ; 메모리 캐시 업데이트
    LoadNotesToMap(notesPath)
    
    UpdateNativeGui(guideWin, currentAct, FileExist(guidePath) ? FileRead(guidePath, "UTF-8") : "가이드 파일을 찾을 수 없습니다.")
    UpdateNativeGui(notesWin, "[" . currentAct . "] 수동 전환", "지역에 진입하면 해당 구역의 노트가 표시됩니다.")

    if IsSet(actDDL)
        actDDL.Choose(actNum)
    
    SaveSetting("Status", "lastAct", currentAct)
}

; 현재 존을 바탕으로 Act와 Part 정보를 업데이트하고 경로를 재설정하는 함수
UpdateActInfo(zoneName) {
    global currentAct, currentPart, guidePath, notesPath, baseDataPath, guideWin, zoneData, townZones, actDDL
    
    ; 현재 액트의 데이터 찾기
    currentActData := ""
    for data in zoneData {
        if (data.act = currentAct) {
            currentActData := data
            break
        }
    }

    ; --- 액트 전환 로직 개선 ---
    ; 1. 현재 구역이 마을인 경우: 
    ;    - 만약 이 마을이 현재 액트의 '거점(town)'이라면, 현재 액트를 유지합니다.
    ;    - 만약 다른 액트의 거점이라면 해당 액트로 이동을 고려할 수 있지만, 
    ;      일반적으로 다음 액트의 첫 지역 진입 시점에 전환하는 것이 더 정확합니다.
    if IsTownZone(zoneName) {
        ; 현재 액트의 마을인지 확인
        if (currentActData != "" && Trim(zoneName) = Trim(currentActData.town)) {
            return ; 현재 액트 마을이므로 업데이트 불필요
        }
        ; 다른 마을인 경우에도 일단 유지 (다음 구역 진입 시 판단)
        return 
    }
    
    candidates := []
    for i, data in zoneData {
        for z in data.zones {
            if InStr(Trim(z), Trim(zoneName)) {
                candidates.Push(i)
                break
            }
        }
    }

    if (candidates.Length = 0)
        return

    currentActNum := SubStr(currentAct, 5) + 0
    chosenIdx := -1

    ; 우선순위 로직:
    ; 1. 현재 액트에 해당 구역이 있으면 현재 액트 우선 (진행 중)
    for idx in candidates {
        candidateActNum := SubStr(zoneData[idx].act, 5) + 0
        if (candidateActNum = currentActNum) {
            chosenIdx := idx
            break
        }
    }

    ; 2. 현재 액트에 구역이 없고, 다음 액트에 있다면 전환 (순차 진행)
    if (chosenIdx = -1) {
        for idx in candidates {
            candidateActNum := SubStr(zoneData[idx].act, 5) + 0
            if (candidateActNum = currentActNum + 1) {
                chosenIdx := idx
                break
            }
        }
    }

    ; 3. 그 외 (이전 액트로 돌아가거나 건너뛰는 경우) 가장 가까운 액트 선택
    if (chosenIdx = -1) {
        minDist := 999
        for idx in candidates {
            candidateActNum := SubStr(zoneData[idx].act, 5) + 0
            dist := Abs(candidateActNum - currentActNum)
            if (dist < minDist) {
                minDist := dist
                chosenIdx := idx
            }
        }
    }

    if (chosenIdx = -1)
        return

    target := zoneData[chosenIdx]
    if (target.act != currentAct) {
        ; 액트 전환 확정
        currentAct := target.act
        currentPart := target.part
        guidePath := baseDataPath . currentAct . "\guide.txt"
        notesPath := baseDataPath . currentAct . "\notes.txt"
        
        ; 메모리 캐시 업데이트
        LoadNotesToMap(notesPath)

        if FileExist(guidePath) {
            UpdateNativeGui(guideWin, currentAct, FileRead(guidePath, "UTF-8"))
        }

        if IsSet(actDDL)
            actDDL.Choose(SubStr(currentAct, 5) + 0)
            
        ; 자동 변경된 액트 정보 저장
        SaveSetting("Status", "lastAct", currentAct)
    }
}

; 특정 존의 내용만 필터링하여 표시 (메모리 캐시 사용)
SetNote(zoneName) {
    global noteMap, notesWin, currentAct
    
    targetZoneName := Trim(zoneName)
    
    if noteMap.Has(targetZoneName) {
        UpdateNativeGui(notesWin, "[" . currentAct . "] " . zoneName, noteMap[targetZoneName])
    } else {
        UpdateNativeGui(notesWin, zoneName, "현재 액트(" . currentAct . ")에서 정보를 찾을 수 없습니다.")
    }
}

; 실제 지역 진입 시 마지막 지역을 저장합니다.
RememberLastZone(zoneName) {
    global lastZone

    lastZone := Trim(zoneName)
    if (lastZone != "")
        SaveSetting("Status", "lastZone", lastZone)
}

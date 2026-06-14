#Requires AutoHotkey v2.0

; 전역 데이터 변수
global zoneData := []
global townZones := []
global noteMap := Map()

; 해당 액트의 노트를 메모리에 캐싱하는 함수
LoadNotesToMap(filePath) {
    global noteMap
    noteMap := Map() ; 맵 초기화

    try {
        if !FileExist(filePath)
            return
            
        fullText := FileRead(filePath, "UTF-8")
        lines := StrSplit(fullText, "`n", "`r")
        
        currentZone := ""
        currentContent := ""
        
        for line in lines {
            cleanLine := Trim(line)
            if (SubStr(cleanLine, 1, 5) = "zone:") {
                ; 이전 존 데이터 저장
                if (currentZone != "") {
                    noteMap[currentZone] := Trim(currentContent, "`n`r ")
                }
                ; 새로운 존 시작
                currentZone := Trim(SubStr(cleanLine, 6))
                currentContent := ""
            } else {
                if (currentZone != "") {
                    currentContent .= line . "`n"
                }
            }
        }
        
        ; 마지막 존 저장
        if (currentZone != "") {
            noteMap[currentZone] := Trim(currentContent, "`n`r ")
        }
    } catch {
        ; 읽기 실패 시 무시
    }
}

; kdata.json 로드 함수
LoadKData() {
    global zoneData, townZones
    
    try {
        if !FileExist("kdata.json") {
            MsgBox("kdata.json 파일을 찾을 수 없습니다.")
            return
        }
        
        kDataRaw := FileRead("kdata.json", "UTF-8")
        jsonParsedData := Jxon_Load(&kDataRaw)

        for zoneEntry in jsonParsedData["zones"] {
            zoneData.Push({
                act: zoneEntry["act"], 
                part: zoneEntry["part"], 
                town: zoneEntry.Has("town") ? zoneEntry["town"] : "", ; 액트별 마을/거점 정보 추가
                zones: zoneEntry["list"]
            })
        }
        
        if jsonParsedData.Has("town_zones") {
            for townName in jsonParsedData["town_zones"] {
                townZones.Push(townName)
            }
        }
    } catch as e {
        MsgBox("kdata.json 파일을 읽거나 분석하는 데 실패했습니다: " . e.Message)
    }
}

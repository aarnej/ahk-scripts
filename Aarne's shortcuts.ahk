#WinActivateForce
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#!^+1:: Run "msedge.exe --new-window"
#!^+3:: PreviousWindow()
#!^+4:: WinActivate "ahk_exe code.exe"
#!^+5:: WinActivate "ahk_exe msedge.exe"
#!^+7:: WinMinimize "A"
#!^+8:: WinActivate "ahk_exe alacritty.exe"
#!^+a:: WinActivate "ahk_exe Spotify.exe"
#!^+Left:: MoveFocus("left")
#!^+Up:: MoveFocus("up")
#!^+Down:: MoveFocus("down")
#!^+Right:: MoveFocus("right")

SortCallback(first, second, offset) {

}

MoveFocus(direction) {
    curr_id := WinGetId("A")
    WinGetPos &curr_x, &curr_y, &curr_w, &curr_h, curr_id
    ; OutputDebug "curr_id=" curr_id " curr_x=" curr_x " curr_y=" curr_y " curr_w=" curr_w " curr_h=" curr_h

    curr_cx := curr_x + (curr_w / 2)
    curr_cy := curr_y + (curr_h / 2)

    bestid := 0
    best_distance := -1

    ids := WinGetList()
    for id in ids {
        if (id == curr_id) {
            continue
        }
        minmax := WinGetMinMax(id)
        if (minmax == -1) {
            ; Ignore minimized windows
            continue
        }
        if (!IsWindow(id)) {
            ; Not a good window
            continue
        }
        WinGetPos &x, &y, &w, &h, id
        cx := x + (w / 2)
        cy := y + (h / 2)
        title := wingettitle(id)
        ; OutputDebug "id=" id " minmax=" minmax " x=" x " y=" y " title=" title
        if (direction == "left") {
            if (cx >= curr_cx - 50) {
                continue
            }
        }
        else if (direction == "up") {
            if (cy >= curr_cy - 50) {
                continue
            }
        }
        else if (direction == "down") {
            if (cy < curr_cy + 50) {
                continue
            }
        }
        else if (direction == "right") {
            if (cx < curr_cx + 50) {
                continue
            }
        }

        distance := sqrt((curr_cx - cx)**2 + (curr_cy - cy)**2)
        if (best_distance == -1 || distance < best_distance) {
            bestid := id
            best_distance := distance
        }
    }

    if (bestid != 0) {
        ; outputdebug "selected=" bestid
        WinActivate(bestid)
    }
}

PreviousWindow() {
    ids := WinGetList()
    for id in ids {
        if WinActive(id)
            continue
        title := WinGetTitle(id)
        If (title = "")
            continue
        If (!IsWindow(WinExist(id)))
            continue
        WinActivate(id)
            break
    }
}

;-----------------------------------------------------------------
; Check whether the target window is activation target
;-----------------------------------------------------------------
IsWindow(hWnd){
    dwStyle := WinGetStyle(hWnd)
    if ((dwStyle&0x08000000) || !(dwStyle&0x10000000)) {
        return false
    }
    dwExStyle := WinGetExStyle(hWnd)
    if (dwExStyle & 0x00000080) {
        return false
    }
    szClass := WinGetClass(hWnd)
    if (szClass = "TApplication") {
        return false
    }
    return true
}

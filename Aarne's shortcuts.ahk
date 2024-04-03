#SingleInstance
#Requires AutoHotkey v2
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

InitGlobals()
RegisterShellHooks()
RegisterWinEventCallbacks()

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitGlobals() {
    global EVENT_OBJECT_LOCATIONCHANGE := 0x800B
    global EVENT_SYSTEM_MOVESIZEEND := 0x000B
    global EVENT_SYSTEM_MOVESIZESTART := 0x000A
    global WINEVENT_OUTOFCONTEXT := 0x0
    global WINEVENT_SKIPOWNPROCESS := 0x2
}

DrawBorder(hwnd) {
    static g := gui()

    if (hwnd != -1) {
        dwStyle := wingetstyle(hwnd)
        dwExtStyle := wingetexstyle(hwnd)
        ; outputdebug(format("{:08x} {:08x}", dwStyle, dwExtStyle))

        pos := wingetpos(&x, &y, &w, &h, hwnd)
        g.backcolor := "0094fc"
        g.marginx := 0
        g.marginy := 0
        g.opt("-DPIScale -Caption +ToolWindow")
        showopts := "x" x+4 " y" y-4 "  w" w-8 " h" h " hide"
        g.show(showopts)
        WinMoveBelow(g.hwnd, hwnd)
        g.restore()
    } else {
        g.hide()
    }
}

RegisterShellHooks() {
    static dummy := gui()
    dummy.opt("+LastFound")
    hwnd := WinExist()
    ret := DllCall("RegisterShellHookWindow", "uint", hwnd)
    ; outputdebug(ret)
    MsgNum := DllCall("RegisterWindowMessage", "str", "SHELLHOOK")
    ; outputdebug(msgnum)
    OnMessage(MsgNum, ShellMessage)
}

ShellMessage(wParam, lParam, *) {
    ; outputdebug(wparam " " lparam)
    if (wParam == 32772 || wParam == 4) {
        if (lParam != 0 and IsWindow(lParam))
            DrawBorder(lparam)
        else
            DrawBorder(-1)
    }
    ; outputdebug(lParam)
}

SetWinEventHook(eventmin, eventmax, callback) {
    DllCall("SetWinEventHook"
    , "UInt",   eventmin                                        ;_In_  UINT eventMin
    , "UInt",   eventmax                                        ;_In_  UINT eventMax
    , "Ptr" ,   0x0                                             ;_In_  HMODULE hmodWinEventProc
    , "Ptr" ,   callback                                        ;_In_  WINEVENTPROC lpfnWinEventProc
    , "UInt",   0                                               ;_In_  DWORD idProcess
    , "UInt",   0x0                                             ;_In_  DWORD idThread
    , "UInt",   WINEVENT_OUTOFCONTEXT|WINEVENT_SKIPOWNPROCESS)  ;_In_  UINT dwflags
}

RegisterWinEventCallbacks() {
    static callback := CallbackCreate(WinEventProc)
    SetWinEventHook(EVENT_SYSTEM_MOVESIZESTART, EVENT_SYSTEM_MOVESIZEEND, callback)
    SetWinEventHook(EVENT_OBJECT_LOCATIONCHANGE, EVENT_OBJECT_LOCATIONCHANGE, callback)
}

WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    static moving := false

    if (event == EVENT_SYSTEM_MOVESIZESTART) {
        drawborder(-1)
        moving := true
    } else if (event == EVENT_SYSTEM_MOVESIZEEND) {
        drawborder(hwnd)
        moving := false
    } else if (event == EVENT_OBJECT_LOCATIONCHANGE) {
        if (!moving && idobject == 0 && IsWindow(hwnd)) {
            ; outputdebug(idobject)
            drawborder(hwnd)
        }
    }
    ; outputdebug(event)
    return
}

MoveFocus(direction) {
    curr_id := WinExist("A")
    if (curr_id == 0) {
        curr_id := WinGetList()[1]
    }
    if (curr_id == 0) {
        return
    }
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
        title := wingettitle(id)
        ; OutputDebug "id=" id " minmax=" minmax " x=" x " y=" y " title=" title

        cy := y + (h / 2)
        cx := x + (w / 2)

        if (direction == "left") {
            if cx >= curr_cx
                continue
            if y + h < curr_y + 50 or y > curr_y + curr_h - 50
                cy := cy + 10000
        }
        else if (direction == "up") {
            if cy >= curr_cy
                continue
            if x + w < curr_x + 50 or x > curr_x + curr_w - 50
                cx := cx + 10000
        }
        else if (direction == "down") {
            if cy <= curr_cy
                continue
            if x + w < curr_x + 50 or x > curr_x + curr_w - 50
                cx := cx + 10000
        }
        else if (direction == "right") {
            if cx <= curr_cx
                continue
            if y + h < curr_y + 50 or y > curr_y + curr_h - 50
                cy := cy + 10000
        }

        distance := sqrt((curr_cx - cx)**2 + (curr_cy - cy)**2)
        if (best_distance == -1 || distance < best_distance) {
            bestid := id
            best_distance := distance
        }
    }

    if (bestid != 0) {
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

WinMoveBelow(hwnd, hwndBelow) {
	errorlevel := DllCall("SetWindowPos", "uint", hwnd, "uint", hwndBelow
		, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)
}

IsWindow(hWnd){
    dwStyle := WinGetStyle(hWnd)
    dwExStyle := WinGetExStyle(hWnd)
    ; outputdebug(format("{:8x} {:8x}", dwStyle, dwExStyle))
    if ((dwStyle & 0xC8000000) || !(dwStyle & 0x10000000)) {
        return false
    }
    if (dwExStyle & 0x00000088) {
        return false
    }
    szClass := WinGetClass(hWnd)
    if (szClass = "TApplication") {
        return false
    }
    return true
}

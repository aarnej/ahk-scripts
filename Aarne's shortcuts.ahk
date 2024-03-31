﻿#SingleInstance
#Requires AutoHotkey v2
#Warn  ; Enable warnings to assist with detecting common errors.
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

DrawBorder(hwnd) {
    static g := gui()

    if (hwnd != -1) {
        dwStyle := wingetstyle(hwnd)
        dwExtStyle := wingetexstyle(hwnd)
        ; outputdebug(format("{:08x} {:08x}", dwStyle, dwExtStyle))

        pos := wingetpos(&x, &y, &w, &h, hwnd)
        g.backcolor := "5070f0"
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

dummy := gui()
dummy.opt("+LastFound")
hwnd := WinExist()
ret := DllCall("RegisterShellHookWindow", "uint", hwnd)
; outputdebug(ret)
MsgNum := DllCall("RegisterWindowMessage", "str", "SHELLHOOK")
; outputdebug(msgnum)
OnMessage(MsgNum, ShellMessage)

ShellMessage(wParam, lParam, *) {
    ; outputdebug(wparam)
    if (winexist(lparam) && iswindow(lparam)) {
        if (wparam == 32772 || wparam == 4) {
            drawborder(lparam)
        } else if (wparam == 32774 || wparam == 6) {
            ; outputdebug("clear")
            ; drawborder(-1)
        }
    }
    ; outputdebug(lParam)
}


EVENT_OBJECT_LOCATIONCHANGE := 0x800B
EVENT_SYSTEM_MOVESIZEEND := 0x000B
EVENT_SYSTEM_MOVESIZESTART := 0x000A
WINEVENT_OUTOFCONTEXT := 0x0
WINEVENT_SKIPOWNPROCESS := 0x2
callback := CallbackCreate(WinEventProc)

DllCall("SetWinEventHook"
    , "UInt",   EVENT_SYSTEM_MOVESIZESTART                      ;_In_  UINT eventMin
    , "UInt",   EVENT_SYSTEM_MOVESIZEEND                        ;_In_  UINT eventMax
    , "Ptr" ,   0x0                                             ;_In_  HMODULE hmodWinEventProc
    , "Ptr" ,   callback                                        ;_In_  WINEVENTPROC lpfnWinEventProc
    , "UInt",   0                                               ;_In_  DWORD idProcess
    , "UInt",   0x0                                             ;_In_  DWORD idThread
    , "UInt",   WINEVENT_OUTOFCONTEXT|WINEVENT_SKIPOWNPROCESS)  ;_In_  UINT dwflags

DllCall("SetWinEventHook"
    , "UInt",   EVENT_OBJECT_LOCATIONCHANGE                     ;_In_  UINT eventMin
    , "UInt",   EVENT_OBJECT_LOCATIONCHANGE                     ;_In_  UINT eventMax
    , "Ptr" ,   0x0                                             ;_In_  HMODULE hmodWinEventProc
    , "Ptr" ,   callback                                        ;_In_  WINEVENTPROC lpfnWinEventProc
    , "UInt",   0                                               ;_In_  DWORD idProcess
    , "UInt",   0x0                                             ;_In_  DWORD idThread
    , "UInt",   WINEVENT_OUTOFCONTEXT|WINEVENT_SKIPOWNPROCESS)  ;_In_  UINT dwflags

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
            best_coords := { x: x, y: y, w: w, h: h }
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
;-----------------------------------------------------------------
; Check whether the target window is activation target
;-----------------------------------------------------------------
IsWindow(hWnd){
    dwStyle := WinGetStyle(hWnd)
    if ((dwStyle & 0xC8000000) || !(dwStyle & 0x10000000)) {
        return false
    }
    dwExStyle := WinGetExStyle(hWnd)
    if (dwExStyle & 0x00000088) {
        return false
    }
    szClass := WinGetClass(hWnd)
    if (szClass = "TApplication") {
        return false
    }
    return true
}

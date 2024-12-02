#Include VD.ahk\VD.ah2
#SingleInstance
#Requires AutoHotkey v2 64-bit
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

InitGlobals()
RegisterShellHooks()
RegisterWinEventCallbacks()

#!^+1:: Run "msedge.exe --new-window"
#!^+3:: PreviousWindow()
#!^+4:: {
    if WinExist("ahk_exe code.exe")
        WinActivate
}
#!^+5:: {
    if WinExist("ahk_exe msedge.exe")
        WinActivate
}
#!^+6:: {
    if WinExist("slack ahk_exe msedge.exe")
        WinActivate
}
#!^+7:: WinMinimize "A"
#!^+8:: {
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate
}
#!^+a:: {
    if WinExist("ahk_exe Spotify.exe")
        WinActivate
}
#!^+b:: {
    if WinExist("ahk_exe Obsidian.exe")
        WinActivate
}
#!^+c:: {
    if WinExist("ahk_exe ms-teams.exe")
        WinActivate
}
#!^+d:: SetDefaultKeyboard(0x0409) ; English (US)
#!^+e:: SetDefaultKeyboard(0x20419) ; Russian mnemonic
#!^+Left:: MoveFocus("left")
#!^+Up:: MoveFocus("up")
#!^+Down:: MoveFocus("down")
#!^+Right:: MoveFocus("right")
#^+Left:: MoveWindowToDesktop(-1)
#^+Right:: MoveWindowToDesktop(+1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitGlobals() {
    global EVENT_OBJECT_LOCATIONCHANGE := 0x800B
    global EVENT_SYSTEM_MOVESIZEEND := 0x000B
    global EVENT_SYSTEM_MOVESIZESTART := 0x000A
    global WINEVENT_OUTOFCONTEXT := 0x0
    global WINEVENT_SKIPOWNPROCESS := 0x2
}

MoveWindowToDesktop(offset) {
    handle := WinExist("A")
    if handle {
        VD.MoveWindowToRelativeDesktopNum(handle, offset)
        n := VD.getDesktopNumOfWindow(handle)
        VD.goToDesktopNum(n)
        WinActivate(handle)
    }
}

DrawBorder(hwnd) {
    static g := gui()

    try {
        if (hwnd > 0 && IsWindow(hwnd)) {
            WinGetPos &x, &y, &w, &h, hwnd
            g.backcolor := "20b4fc"
            g.marginx := 0
            g.marginy := 0
            g.opt("-DPIScale -Caption +ToolWindow")
            showopts := "x" x-4 " y" y-4 "  w" w+8 " h" h+8 " hide"
            g.show(showopts)
            g.restore()
            WinMoveBelow(g.hwnd, hwnd)
            MouseCenter(hwnd, x, y, w, h)
        }
        else {
            throw Error("")
        }
    } catch {
        g.hide()
    }
}

RegisterShellHooks() {
    static dummy := gui()
    dummy.opt("+LastFound")
    hwnd := WinExist()
    ret := DllCall("RegisterShellHookWindow", "uint", hwnd)
    MsgNum := DllCall("RegisterWindowMessage", "str", "SHELLHOOK")
    OnMessage(MsgNum, ShellMessage)
}

ShellMessage(wParam, lParam, *) {
    Log(Format("ShellMessage: wParam={}, lParam={}", wParam, lParam))
    if (wParam == 32772 || wParam == 4) {
        DrawBorder(lparam)
    }
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

    try {
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
    }
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
        try {
            minmax := WinGetMinMax(id)
            if (minmax == -1) {
                ; Ignore minimized windows
                continue
            }
            if (!IsWindow(id)) {
                ; Not a good window
                continue
            }
            WinGetClientPos &x, &y, &w, &h, id
            ; title := wingettitle(id)
            ; OutputDebug "id=" id " minmax=" minmax " x=" x " y=" y " title=" title
        }
        catch {
            continue
        }

        ; Make sure the center of the window is mostly uncovered by other windows
        coveredCount := 0
        for tx in [2,3] {
            for ty in [2,3] {
                coveredCount += (id != WindowFromPoint(x + tx*w//5, y + ty*h//5) ? 1 : 0)
            }
        }
        if (coveredCount > 2) {
            continue
        }

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
        try {
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
}

WinMoveBelow(hwnd, hwndBelow) {
	errorlevel := DllCall("SetWindowPos", "uint", hwnd, "uint", hwndBelow
		, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)
}

IsWindow(hWnd){
    styles := GetStyle(hWnd)
    pass := true

    if (styles.style == 0x14cf0000 && styles.exStyle == 0x00200100) {
        ; = Windows Terminal
    }
    else {
        ; (WS_CHILD | WS_DISABLED) || !WS_VISIBLE
        if ((styles.style & 0x48000000) || !(styles.style & 0x10000000)) {
            pass := false
        }
        ;  WS_EX_NOACTIVATE | WS_EX_NOREDIRECTIONBITMAP | S_EX_TOOLWINDOW | WS_EX_TOPMOST
        if (styles.exStyle & 0x08200088) {
            pass := false
        }
    }
    title := WinGetTitle(hWnd)
    Log(Format("{} {:08x}/{:08x} pass={}", title, styles.style, styles.exStyle, pass))
    return pass
}

GetStyle(hWnd) {
    styles := {
        style: WinGetStyle(hWnd),
        exStyle: WinGetExStyle(hWnd)
    }
    return styles
}

WindowFromPoint(X, Y) { ; by SKAN and Linear Spoon
    return DllCall( "GetAncestor", "UInt"
            , DllCall( "WindowFromPoint", "UInt64", X | (Y << 32))
            , "UInt", GA_ROOT := 2 )
}

Log(text) {
    try {
        ; FileAppend text "`n", A_Desktop "/" SubStr(A_ScriptName, 1, -4) ".log"
    }
}

SetDefaultKeyboard(LocaleID){
	Static SPI_SETDEFAULTINPUTLANG := 0x005A, SPIF_SENDWININICHANGE := 2

	Lan := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", LocaleID), "Int", 0)
    binaryLocaleID := Buffer(4, 0)
    NumPut("UInt", LocaleID, binaryLocaleID)
	DllCall("SystemParametersInfo", "UInt", SPI_SETDEFAULTINPUTLANG, "UInt", 0, "Ptr", binaryLocaleID, "UInt", SPIF_SENDWININICHANGE)

	ids := WinGetList()
	for id in ids {
		PostMessage 0x50, 0, Lan, , "ahk_id " id
	}
}

MouseCenter(hwnd, wx, wy, ww, wh) {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    Log(Format("wx={},wy={},ww={},wh={},mx={},my={}", wx, wy, ww, wh, mx, my))
    if mx < wx or mx > wx + ww or my < wy or my > wy + wh {
        Log(Format("moving to x={},y={}", wx + ww/2, wy + wh/2))
        DllCall("SetCursorPos", "int", wx + ww/2, "int", wy + wh/2)
        ;MouseMove wx + ww/2, wy + wh/2
    }
}

WinGetPosEx(hWindow, &X := "", &Y := "", &Width := "", &Height := ""
;, &Offset_X := "", &Offset_Y := ""
) {
   Static DWMWA_EXTENDED_FRAME_BOUNDS := 9
   ;-- Get the window's dimensions
   ;   Note: Only the first 16 bytes of the RECTPlus structure are used by the
   ;   DwmGetWindowAttribute and GetWindowRect functions.
   RECTPlus := Buffer(24,0)
    DWMRC := DllCall("dwmapi\DwmGetWindowAttribute",
                    "Ptr",  hWindow,                     ;-- hwnd
                    "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, ;-- dwAttribute
                    "Ptr",  RECTPlus,                    ;-- pvAttribute
                    "UInt", 16,                          ;-- cbAttribute
                    "UInt")
   ;-- Populate the output variables
   X := NumGet(RECTPlus,  0, "Int") ; left
   Y := NumGet(RECTPlus,  4, "Int") ; top
   R := NumGet(RECTPlus,  8, "Int") ; right
   B := NumGet(RECTPlus, 12, "Int") ; bottom
   Width    := R - X ; right - left
   Height   := B - Y ; bottom - top
;    OffSet_X := 0
;    OffSet_Y := 0
;    ;-- Collect dimensions via GetWindowRect
;    RECT := Buffer(16, 0)
;    DllCall("GetWindowRect", "Ptr", hWindow,"Ptr", RECT)
;    ;-- Right minus Left
;    GWR_Width := NumGet(RECT,  8, "Int") - NumGet(RECT, 0, "Int")
;    ;-- Bottom minus Top
;    GWR_Height:= NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
;    ;-- Calculate offsets and update output variables
;    NumPut("Int", Offset_X := (Width  - GWR_Width)  // 2, RECTPlus, 16)
;    NumPut("Int", Offset_Y := (Height - GWR_Height) // 2, RECTPlus, 20)
   Return RECTPlus
}

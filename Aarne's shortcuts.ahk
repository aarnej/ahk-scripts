﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#!^+1:: Run "msedge.exe" "--new-window"

#!^+3:: PreviousWindow()

#!^+4:: WinActivate ahk_exe code.exe

#!^+5:: WinActivate ahk_exe msedge.exe

#!^+6:: return

#!^+7:: WinMinimize A

#!^+8:: WinActivate ahk_exe alacritty.exe

#!^+a:: WinActivate ahk_exe Spotify.exe

#!^+b:: return

#!^+c::
	Edit
      SetTitleMatchMode 2
      WinWaitActive Aarne's shortcuts.ahk ahk_exe notepad.exe
	WinWaitClose
	Reload
      return

#!^+d:: return

#!^+e:: return

#!^+f:: return

; #!^{:: RunWait, komorebic.exe move left, , Hide
; #!^-:: RunWait, komorebic.exe move right, , Hide
; #!^*:: RunWait, komorebic.exe move up, , Hide
; #!^}:: RunWait, komorebic.exe move down, , Hide

; #!^j:: RunWait, komorebic.exe focus left, , Hide
; #!^l:: RunWait, komorebic.exe focus right, , Hide
; #!^i:: RunWait, komorebic.exe focus up, , Hide
; #!^k:: RunWait, komorebic.exe focus down, , Hide

; #!^+j:: RunWait, komorebic.exe stack left, , Hide
; #!^+l:: RunWait, komorebic.exe stack right, , Hide
; #!^+i:: RunWait, komorebic.exe stack up, , Hide
; #!^+k:: RunWait, komorebic.exe stack down, , Hide

; #!^u:: RunWait, komorebic.exe cycle-stack previous, , Hide
; #!^m:: RunWait, komorebic.exe cycle-stack next, , Hide

; #!^+.:: RunWait, komorebic.exe unstack, , Hide


PreviousWindow(){
    list := ""
    WinGet, id, list
    Loop, %id%
    {
        this_ID := id%A_Index%
        IfWinActive, ahk_id %this_ID%
            continue
        WinGetTitle, title, ahk_id %this_ID%
        If (title = "")
            continue
        If (!IsWindow(WinExist("ahk_id" . this_ID)))
            continue
        WinActivate, ahk_id %this_ID%, ,2
            break
    }
}

;-----------------------------------------------------------------
; Check whether the target window is activation target
;-----------------------------------------------------------------
IsWindow(hWnd){
    WinGet, dwStyle, Style, ahk_id %hWnd%
    if ((dwStyle&0x08000000) || !(dwStyle&0x10000000)) {
        return false
    }
    WinGet, dwExStyle, ExStyle, ahk_id %hWnd%
    if (dwExStyle & 0x00000080) {
        return false
    }
    WinGetClass, szClass, ahk_id %hWnd%
    if (szClass = "TApplication") {
        return false
    }
    return true
}
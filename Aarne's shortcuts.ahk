#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#!^+1:: Run "msedge.exe" "--new-window"

#!^+3:: PreviousWindow()

#!^+4:: 
      SetTitleMatchMode 2
	WinActivate GNU Emacs
	return

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
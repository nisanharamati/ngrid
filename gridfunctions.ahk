;===============================================================================
;
;   ngrid
;   Move windows over grid
;
;   Nisan Haramati 
;   hanisan@gmail.com
;
;   This work is licensed under a 
;   Creative Commons Attribution 3.0 Unported License.
;   http://creativecommons.org/licenses/by/3.0/
; 
;===============================================================================
VersionString = 0.0.1
NameString    = ngrid
AuthorString  = Nisan Haramati

;-------------------------------------------------------------------------------
;
;
;     Startup
;
;
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Global Settings
;-------------------------------------------------------------------------------
#SingleInstance force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%

;; GridSize is per monitor.
GridSizeX = 2
GridSizeY = 3
EdgeBehavior = "Block"

;; Get virtual desktop data
SysGet, VirtualWidth, 78
SysGet, VirtualHeight, 79
SysGet, VirtualLeft, 76
SysGet, VirtualTop, 77

;; Primary monitor workarea (e.g. excl taskbar)
;; we're assuming all other monitors are identical (e.g. taskbar is either on top or bottom
;; and spans all monitors)
SysGet, MonitorPrimary, MonitorPrimary
SysGet, MonitorWorkArea, MonitorWorkArea, %MonitorPrimary%


YStep := Round((MonitorWorkAreaBottom-MonitorWorkAreaTop)/GridSizeY)
XStep := Round((MonitorWorkAreaRight-MonitorWorkAreaLeft)/GridSizeX)

;; Compute virtual screen boundary coordinates
VirtualRight := VirtualLeft + VirtualWidth
VirtualBottom := VirtualTop + VirtualHeight


;-------------------------------------------------------------------------------
;
;
;     Keyboard Hooks
;
; # = Win | + = Shift | ^ = Ctrl | ! = Alt
;-------------------------------------------------------------------------------
MoveLeftKey = #Left
MoveRightKey = #Right
MoveUpKey = #Up
MoveDownKey = #Down
SizeLeftKey = #+Left
SizeRightKey = #+Right
SizeUpKey = #+Up
SizeDownKey = #+Down

HomeW = 1080
HomeH = 470


;-------------------------------------------------------------------------------
; Key Bindings
;-------------------------------------------------------------------------------
;Hotkey %MoveLeftKey%, %MoveLeft%
;-------------------------------------------------------------------------------
; Moving by Keyboard 
;-------------------------------------------------------------------------------
^#!Left::
MoveLeft:
  MoveWindow( -1, 0 )
Return

^#!Right::
MoveRight:
  MoveWindow( 1, 0 )
Return

^#!Up::
MoveUp:
  MoveWindow( 0, -1)
Return

^#!Down::
MoveDown:
  MoveWindow( 0, 1)
Return



;-------------------------------------------------------------------------------
;
;
;     Keyboard Snapping Routines
;
;
;-------------------------------------------------------------------------------



MoveWindow( XOffset, YOffset ) {
  Global XStep, YStep, VirtualTop, VirtualBottom, VirtualLeft, VirtualRight
  WinGetPos WX, WY, WWidth, WHeight, A
  WinGet, active_id, ID, A
  NewMon := GetMonitor(active_id)
  SysGet, MWA, MonitorWorkArea, %NewMon%
  
  reduce := 0
  NewWX := WX
  NewWY := WY
  NewWHeight := WHeight
  NewWWidth := WWidth
;; IF current width is full screen width, just reduce to half in the XOffset direction
  if (WWidth = MWALeft-MWARight)
    reduce := 1
    NewWWidth := XStep
    if (XOffset > 0) ;; right
      NewWX := MWARight - XStep
    if (XOffset < 0) ;; left
      NewWX := MWALeft
;; IF current height is full or 2/3 height, reduce height by 1/3
  if (WHeight >= 2*YStep) ;; reduce to 2*YStep
    reduce := 1
    NewWHeight := 2*YStep
    if (YOffset > 0) ;; down
      NewWY := MWABottom - NewWHeight
      ;; IF distance to either top or bottom edge is less than YStep, bridge it
      if (MWABottom - NewWY - NewWHeight < YStep)
        NewWHeight := MWABottom - NewWY
    
  if (WHeight < 2*YStep and WHeight => YStep) ;; reduce to YStep
    reduce := 1
    NewWHeight := YStep
    if (YOffset > 0) ;; down
      NewWY := MWABottom - NewWHeight
      ;; IF distance to either top or bottom edge is less than YStep, bridge it
      if (MWABottom - NewWY - NewWHeight < YStep)
        NewWHeight := MWABottom - NewWY
    if (YOffset < 1) ;; up
      if (MWATop - NewWY < YStep)
        NewWY := MWATop

  if (reduce == 1)
    WinMove A,, %NewWX%, %NewWY%, %NewWWidth%, %NewWHeight%
    
  if (reduce == 0)
  ;; otherwise, no reduction, just move window as is.
    NewWX := WX + ( XStep*XOffset )
    NewWY := WY + ( YStep*YOffset )
  
  ;; stay in virtual screen boundaries.
    if (NewWX > (VirtualRight-XStep))
      NewWX := VirtualRight - XStep
    if (NewWX < VirtualLeft)
      NewWX := VirtualLeft
    if (NewWY < VirtualTop)
      NewWY := VirtualTop
    if (NewWY > (VirtualBottom-YStep))
      NewWY := VirtualBottom-YStep
  
  ;; move window
    
    WinMove A,,%NewWX%, %NewWY%, %WWidth%, %WHeight%
  
;; if width still goes over monitor work area boundaries, trim it to fit.
  WinGetPos NewWX, NewWY, NewWWidth, NewWHeight, A
  WinGet, active_id, ID, A
  NewMon := GetMonitor(active_id)
  SysGet, MWA, MonitorWorkArea, %NewMon%
  if (NewWX + NewWWidth > MWALeft)
    NewWWidth := MWARight - NewWX
  if (NewWY + NewWHeight > MWABottom)
    NewWHeight := MWABottom - NewWY
  
  WinMove A,, %NewWX%, %NewWY%, %NewWWidth%, %NewWHeight%
  
}


GetMonitor(hwnd := 0) {
; If no hwnd is provided, use the Active Window
  if (hwnd)
    WinGetPos, winX, winY, winW, winH, ahk_id %hwnd%
  else
    WinGetActiveStats, winTitle, winW, winH, winX, winY

  SysGet, numDisplays, MonitorCount
  SysGet, idxPrimary, MonitorPrimary

  Loop %numDisplays%
  {  SysGet, mon, MonitorWorkArea, %a_index%
  ; Left may be skewed on Monitors past 1
    if (a_index > 1)
      monLeft -= 10
  ; Right overlaps Left on Monitors past 1
    else if (numDisplays > 1)
      monRight -= 10
  ; Tracked based on X. Cannot properly sense on Windows "between" monitors
    if (winX >= monLeft && winX < monRight)
      return %a_index%
  }
; Return Primary Monitor if can't sense
  return idxPrimary
}
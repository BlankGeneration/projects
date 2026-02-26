#Requires AutoHotkey v2
#SingleInstance Force
#NoTrayIcon

arg := A_Args.Length ? A_Args[1] : ""

if (arg = "/s" || arg = "/S") {
    RunScreensaver()
} else if (arg = "/c" || arg = "/C") {
    MsgBox "No settings available.", "Grafana Screensaver"
    ExitApp
} else if (SubStr(arg, 1, 2) = "/p" || SubStr(arg, 1, 2) = "/P") {
    ExitApp
} else {
    RunScreensaver()
}

RunScreensaver() {
    url := "http://grafana.home:3000/d/Dp7Cd57Zza/proxmox-via-prometheus?orgId=1&from=now-6h&to=now&timezone=browser&var-instance=192.168.1.214&refresh=10s"
    userDataDir := EnvGet("LOCALAPPDATA") "\ChromeGrafanaKiosk"
    chromePID := 0

    Run '"C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk --disk-cache-size=1 --user-data-dir="' userDataDir '" "' url '"',, , &chromePID

    WinWait "ahk_pid " chromePID,, 10
    Sleep 1000

    ; Record initial mouse position after launch settles
    MouseGetPos(&startX, &startY)

    ; Install a low-level keyboard hook — any key press exits
    ih := InputHook("L0 T0.1")
    
    Loop {
        Sleep 200

        ; Check for any keyboard input
        ih.Start()
        ih.Wait()
        if (ih.EndReason = "Match" || ih.EndReason = "EndKey" || ih.Input != "") {
            Shutdown(chromePID)
        }

        ; Check for mouse movement (with a small threshold to ignore jitter)
        MouseGetPos(&currentX, &currentY)
        if (Abs(currentX - startX) > 5 || Abs(currentY - startY) > 5) {
            Shutdown(chromePID)
        }

        ; Check for mouse clicks
        if (GetKeyState("LButton", "P") || GetKeyState("RButton", "P") || GetKeyState("MButton", "P")) {
            Shutdown(chromePID)
        }
    }
}

Shutdown(pid) {
    try WinClose "ahk_pid " pid
    if !ProcessWaitClose(pid, 3)
        ProcessClose pid
    ; Force full screen repaint
    hDesktop := DllCall("user32\GetDesktopWindow", "Ptr")
    DllCall("user32\RedrawWindow", "Ptr", hDesktop, "Ptr", 0, "Ptr", 0, "UInt", 0x0085)
    DllCall("user32\SystemParametersInfo", "UInt", 0x0014, "UInt", 0, "Ptr", 0, "UInt", 0x02)
    Sleep 200
    ExitApp
}

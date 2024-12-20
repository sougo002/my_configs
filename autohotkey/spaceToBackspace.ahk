#Requires AutoHotkey v2.0

; SpaceをBackspace, Space+shiftをDelに
F13 & Space:: {
    if GetKeyState("Shift", "P") {
        Send("{Delete}")
    } else {
        Send("{Backspace}")
    }
    return
}

#Requires AutoHotkey v2.0

SinglePress(lastKey, sendKey) {
    Send("{Blind}{" lastKey " down}")
    KeyWait(lastKey)
    if (A_PriorKey = lastKey) {
        Send(sendKey)
    }
    Send("{Blind}{" lastKey " up}")
    return
}

;左Alt単押しのみをひらがな
LAlt:: SinglePress("LAlt", "{sc070}")

;右Altを単押しのみを英数
RAlt:: SinglePress("RAlt", "{sc1F1}")

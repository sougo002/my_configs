; ChangeKeyでCapsLockをF13に変更

; 矢印キー:
F13 & @::Send, {Blind}{Up}
F13 & /::Send, {Blind}{Down}
F13 & `;::Send, {Blind}{Left}
F13 & sc028::Send, {Blind}{Right}

; 削除
sc07B::Send, {BS}
F13 & sc07B::Send, {Del}
; 英数
sc079::Send, {sc1F1}
; ひらがな
sc070::Send, {sc070}
; ChangeKeyでCapsLockをF13に変更

; 数字
F13 & Z::Send, {0}
F13 & A::Send, {1}
F13 & S::Send, {2}
F13 & D::Send, {3}
F13 & Q::Send, {4}
F13 & W::Send, {5}
F13 & E::Send, {6}
F13 & 1::Send, {7}
F13 & 2::Send, {8}
F13 & 3::Send, {9}

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

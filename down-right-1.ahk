; Define a hotkey to trigger the sequence (e.g., F2)
F2::
    ; The 'SendMode Input' command is generally faster and more reliable
    SendMode Input
    ; Set a small delay between keystrokes to ensure the target application can keep up
    SetKeyDelay, 6, 6

    ; Loop the sequence of keystrokes 99999 times
    Loop 99999
    {
        Send {Down}
        Send {Right}
    }
    ; Optional: Show a message when the loop is complete
    MsgBox, 99999 iterative keystrokes complete.
Return

; Define a hotkey to exit the script (e.g., Escape)
Esc::
    ExitApp
Return
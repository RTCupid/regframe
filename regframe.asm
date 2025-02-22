;------------------------------------------------------------------------------
;                               Second Task
;                        Frame with info about registers
;                            "Resident Frame"
;                         (c) 2025 Muratov Artyom
;------------------------------------------------------------------------------

.model tiny
.code
org 100h

Start:
                xor  ax, ax                     ; ax = 0
                mov  es, ax                     ; es = ax
                mov  bx, 09h * 4                ;

                int  09h                        ; call old keyboard handler

                cli
                mov  es:[bx], offset MY_ISR_09h ; offset of my interrupt 09h
                                                ; service routiny
                push cs
                pop  ax                         ; ax = cs
                mov  es:[bx + 2], ax            ; es:[bx + 2] = ax (= segment
                                                ; with code)
                sti

                int  09h                        ; call old ISR 09h

                mov  ax, 3100h                  ; DOS Fn 31H: Terminate & Stay
                                                ; Resident
                mov  dx, offset EOP             ; dx = &EOP
                shr  dx, 4                      ; dx /= 16
                inc  dx                         ; dx++
                int  21h

;------------------------------------------------------------------------------
; MY_ISR_09h - new handler for interrupt 09h
; Entry:        None
; Exit:         None
; Destroy:      None
;------------------------------------------------------------------------------
MY_ISR_09h      proc
                push ax                         ; save ax in stack
                push bx                         ; save bx in stack
                push es                         ; save es in stack

                mov  bx, 0b800h                 ; bx = VIDEOSEG
                mov  es, bx                     ; es = VIDEOSEG
                mov  bx, 5 * 80 * 2 + 40 * 2    ; bx = offset in screen
                mov  ah, 4eh                    ; ah = color of text

                in   al, 60h                    ; read data from PPI port
                mov  es:[bx], ax                ; al to videoseg

                in   al,  61h                   ; al = port 61h
                or   al,  80h                   ; al |= 10000000b
                out  61h, al                    ; out to 61h PPI
                and  al, not 80h                ; al &= 01111111b
                out  61h, al                    ; out to 61h PPI
                mov  al,  20h                   ; al = 20h
                out  20h, al                    ; out to interrupt controller

                pop  es                         ; back es from stack
                pop  bx                         ; back bx from stack
                pop  ax                         ; back ax from stack

                iret                            ; interrupt return
MY_ISR_09h      endp

EOP:
end             Start
;------------------------------------------------------------------------------

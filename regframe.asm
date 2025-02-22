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
                mov  bx, 0b800h                 ; bx = VIDEOSEG
                mov  es, bx                     ; es = VIDEOSEG
                mov  bx, 5 * 80 * 2 + 40 * 2    ; bx = offset in screen
                mov  ah, 4eh                    ; ah = color of text
NextSymbol:
                in   al, 60h                    ; read data from PPI port
                mov  es:[bx], ax                ; al to videoseg
                cmp  al, 1                      ; if (al != 'Escape'){
                jne  NextSymbol                 ; goto NextSymbol }

                mov  ax, 4c00h
                int  21h

end             Start
;------------------------------------------------------------------------------

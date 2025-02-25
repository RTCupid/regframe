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
                mov  bx, 09h * 4                ; offset for ptr to ISR_09h

                mov  ax, es:[bx]                ; Ofs_old_09h and Seg_old_09h
                mov  Ofs_old_09h, ax            ; from array with
                mov  ax, es:[bx + 2]            ; ptrs to interrupt service
                mov  Seg_old_09h, ax            ; routine

                ;call ShowRegisters


                int  09h                        ; call old ISR 09h

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
                nop
                nop
                nop
                nop
                push si                         ; save si in stack
                push di                         ; save di in stack
                push es                         ; save es in stack
                push ds                         ; save ds in stack
                push dx                         ; save dx in stack
                push cx                         ; save cx in stack
                push bx                         ; save bx in stack
                push ax                         ; save ax in stack

                push cs
                pop  ds                         ; ds = cs

                in   al, 60h                    ; read data from PPI port
                cmp  al, 21h                    ; if (al != 'Press F'){
                jne  NotPressF                 ; goto NotPressF }

                mov  ah, 09h                    ;-----------------
                mov  cx, 14                     ;                |
                mov  dx, 17                     ; attributes for |
                lea  si, Style                  ; frame          |
                add  si, 9 * 2                  ;                |
                mov  di, (80 - 18) * 2          ;-----------------
                call MakeFrame                  ; Make frame for registers

                pop  ax                         ;------------------------
                pop  bx                         ; return parrent value  |
                pop  cx                         ; of registers          |
                pop  dx                         ;------------------------
                push dx                         ;------------------------
                push cx                         ; save ax bx cx dx in   |
                push bx                         ; stack again           |
                push ax                         ;------------------------

                call ShowRegisters              ; Show info about registers

                jmp  NotPressG                  ; goto NotPressG

NotPressF:
                cmp  al, 22h                    ; if (al != 'Press G'){
                jne  NotPressG                  ; goto NotPressG }

                mov  ah, 09h                    ;-----------------
                mov  cx, 14                     ;                |
                mov  dx, 17                     ; attributes for |
                lea  si, Style                  ; frame          |
                add  si, 9 * 7                  ;                |
                mov  di, (80 - 18) * 2          ;-----------------
                call MakeFrame                  ; Make empty box

NotPressG:
                in   al,  61h                   ; al = port 61h
                or   al,  80h                   ; al |= 10000000b
                out  61h, al                    ; out to 61h PPI
                and  al, not 80h                ; al &= 01111111b
                out  61h, al                    ; out to 61h PPI

                ;mov  al,  20h                   ; al = 20h
                ;out  20h, al                    ; out to interrupt controller

                pop  ax                         ; back ax from stack
                pop  bx                         ; back bx from stack
                pop  cx                         ; back cx from stack
                pop  dx                         ; back dx from stack
                pop  ds                         ; back ds from stack
                pop  es                         ; back es from stack
                pop  di                         ; back di from stack
                pop  si                         ; back si from stack

                db   0eah                       ; jmp
Ofs_old_09h     dw   0                          ; offset
Seg_old_09h     dw   0                          ; segment
                nop
                nop
                nop
                nop
                nop
                iret                            ; interrupt return
MY_ISR_09h      endp

;------------------------------------------------------------------------------
; ShowRegisters Func to show information about registers
; Entry:        ax - parrent value of ax
;               bx - parrent value of bx
;               cx - parrent value of cx
;               dx - parrent value of dx
; Exit:         None
; Destroy:      si, cx, di, es
;------------------------------------------------------------------------------
ShowRegisters   proc
                push ds                         ; save ds in stack
                                                ;------------------------
                push dx                         ;                       |
                push cx                         ; registers to print    |
                push bx                         ;                       |
                push ax                         ;------------------------


                push cs
                pop  ds                         ; ds = cs

                mov  di, 0b800h                 ; VIDEOSEG
                mov  es, di                     ; es = videoseg

                mov  di, 80 * 2 * 2 + (80 - 15) * 2  ; third string + offset
                                                ; di - start pos of text
;---------------displaying just text on the screen-----------------------------

                lea  si, TextReg                ; si = start of TextReg
                mov  ah, 09h                    ; color of text

                mov  dx, 4                      ; number of registers
NewRegisters:
                mov  cx, 3                      ; number of symbols in string
NewChar:
                lodsb                           ; mov al, ds:[si]
                                                ; inc si
                stosw                           ; mov es:[di], ax && di += 2
                loop NewChar                    ; goto NewChar}

                add  di, (80 - 3) * 2           ; new string

                dec  dx                         ; if (--dx == 0) {
                jne  NewRegisters               ; goto NewRegisters }

;---------------displaying the register status on the screen-------------------

                mov  di, 80 * 2 * 2 + (80 - 12) * 2  ; third string + offset
                mov  cx, 4                      ; cx = number of registers
NewRegValue:
                pop  bx                         ; bx = value of some register
                                                ; from stack
                call PrintHex                   ; value bx to videoseg

                add  di, (80 - 1) * 2           ; new string

                loop NewRegValue                ; if (--cx) goto NewRegValue

                pop  ds                         ; back ds from stack

                ret
ShowRegisters   endp

;------------------------------------------------------------------------------
; PrintHex      Func to print to videoseg hex number
; Entry:        ah - color of print
;               bx - value to videoseg
;               di - start of print
;               es - videoseg
; Exit:         None
; Destroy:
;------------------------------------------------------------------------------
PrintHex        proc
;-----------------------------------------
;               For example:     19a4    |
;-----------------------------------------                 ---------------
                mov  al, bh                     ; al  = bh | ex: al = 19 |
;                                                          ---------------
;---------------First-number---------------------------------------------------
;                                                          ---------------
                shr  al, 4                      ; al /= 16 | ex: al = 1  |
;                                                          ---------------
                cmp  al, 9                      ; if (al > 9) {

                ja   IsHexLetter                ; goto IsHexLetter }

                add  al, 30h                    ; ax = hex of number

                stosw                           ; mov es:[di], ax && di += 2

                jmp  SecondNumber               ; goto SecondNumber

IsHexLetter:
                add  al, 31h                    ; hex of letter A - F in number

                stosw                           ; mov es:[di], ax && di += 2

;---------------Second-Number--------------------------------------------------
SecondNumber:                                   ;          ---------------
                ;mov  al, bh                     ; al  = bh | ex: al = 19 |
;                                                          ---------------
                ;or   al,
                ret
PrintHex        endp

;------------------------------------------------------------------------------

TextReg         db "ax bx cx dx "

;------------------------------------------------------------------------------
;                               2D Array of frame's symbols
;                   1.1   1.2   1.3   2.1   2.2   2.3   3.1   3.2   3.3
Style           db 0c9h, 0cdh, 0bbh, 0bah,  00h, 0bah, 0c8h, 0cdh, 0bch
                db  03h,  03h,  03h,  03h,  00h,  03h,  03h,  03h,  03h
                db 0dah, 0c4h, 0bfh, 0b3h,  00h, 0b3h, 0c0h, 0c4h, 0d9h
                db "123456789"
                db 0dch, 0dch, 0dch, 0ddh,  00h, 0deh, 0dfh, 0dfh, 0dfh
                db 024h, 024h, 024h, 024h,  00h, 024h, 024h, 024h, 024h
                db 0e0h, 0e1h, 0e7h, 0e1h, 0e0h, 0e7h, 0e7h, 0e1h, 0e0h
                db 00h,   00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

; 1.1 - start  symbol of first  string
; 1.2 - middle symbol of first  string
; 1.3 - end    symbol of first  string
; 2.1 - start  symbol of middle strings
; 2.2 - middle symbol of middle strings
; 2.3 - end    symbol of middle strings
; 3.1 - start  symbol of end    string
; 3.2 - middle symbol of end    string
; 3.3 - end    symbol of end    string
;------------------------------------------------------------------------------

include frame.asm

EOP:
end             Start
;------------------------------------------------------------------------------

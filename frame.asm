;------------------------------------------------------------------------------
;                             Frame functions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; MakeFrame     Func to make frame
; Entry:        ah     - color of frame
;               si     - ptr   of array of the symbols for frame
;               cx     - len   of frame
;               dx     - high  of frame
;               di     - start of print (upper left cornel)
; Exit:         None
; Destroy:      ax, si, cx, dx, di, es
;------------------------------------------------------------------------------
MakeFrame       proc

                push di                         ; save start of print in stack
                mov  di, 0b800h                 ; VIDEOSEG
                mov  es, di                     ; es = videoseg
                pop  di                         ; back start of print

                push cx                         ; save cx in stack
                call MakeStrFrame               ; make first string of frame
                pop  cx                         ; pop cx from stack
                sub  dx, 2                      ; dx -= 2; dx = number
                                                ; of middle strings
MakeMiddle:
                add  di, 80 * 2                 ; di to next string
                push cx                         ; save cx
                push si                         ; save si
                call MakeStrFrame               ; make middle string
                pop si                          ; si = &(start symbol of
                                                ; middle strings)
                pop  cx                         ; cx = len of frame
                dec  dx                         ; dx--;
                jne  MakeMiddle                 ; loop

                add  si, 3                      ; si = &(start symbol of
                                                ; end string)
                add  di, 80 * 2                 ; di to next string

                call MakeStrFrame               ; make end string of frame

                ret
MakeFrame       endp

;------------------------------------------------------------------------------
; MakeStrFrame  Func to make string of frame
; Entry:        ah     - color of string
;               si     - array of symbol for string
;               cx     - len of string
;               di     - start of print string
;               es     - videoseg
; Exit:         None
; Destroy:      ax, cx, si
;------------------------------------------------------------------------------
MakeStrFrame    proc
                push di                         ; save di = start of string

                lodsb                           ; ax = first symbol of string
                                                ; mov al, ds:[si] && inc si
                stosw                           ; mov es:[di], ax && di += 2

                lodsb                           ; ax = middle symbol of string
                                                ; mov al, ds:[si] && inc si
                sub  cx, 2                      ; cx -= 2; cx = number
                                                ; of middle symbols
                rep stosw                       ; mov es:[di], ax && di += 2
                                                ; cx -= 1; cx = 0?; make loop
                                                ; put all middle symbols
                lodsb                           ; ax = end symbol of string
                                                ; mov al, ds:[si] && inc si
                stosw                           ; mov es:[di], ax && di += 2
                pop  di                         ; back di = start of string

                ret
MakeStrFrame    endp



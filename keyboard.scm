(define keyboard-asm
  `((label wait-key)
    (label local-label20)
    (call get-key)
    (or a)
    (jr z local-label20)
    (ret)

    (label flush-keys)
    (push af)
    (label local-label21)
    (call get-key)
    (or a)
    (jr nz local-label21)
    (pop af)
    (ret)

    (label get-key)
    ,@(push* '(bc de hl))
    (label gs-getk2)
    (ld b 7)
    (label gs-getk-loop)
    (ld a 7)
    (sub b)
    (ld hl gs-keygroups)
    (ld d 0)
    (ld e a)
    (add hl de)
    (ld a (hl))
    (ld c a)
    (ld a #xff)
    (out (1) a)
    (ld a c)
    (out (1) a)
    (nop)
    (nop)
    (nop)
    (nop)
    (in a (1))

    (ld de 0)
    ,@(apply append (map (lambda (x)
                           (let ((dest (string->symbol (format #f "gs-getk-~a" x))))
                             `((cp ,x)
                               (jr z ,dest))))
                         '(254 253 251 247 239 223 191 127)))

    (label gs-getk-loopend)
    (djnz gs-getk-loop)
    (xor a)
    (ld (#x8000) a)
    (jr gs-getk-end)

    ,@(apply append (map (lambda (x)
                           (let ((dest (string->symbol (format #f "gs-getk-~a" x))))
                             `((label ,dest)
                               (inc e))))
                         '(127 191 223 239 247 251 253)))

    (label gs-getk-254)
    (push de)
    (ld a 7)
    (sub b)
    (add a a)
    (add a a)
    (add a a)
    (ld d 0)
    (ld e a)
    (ld hl gs-keygroup1)
    (add hl de)
    (pop de)
    (add hl de)
    (ld a (hl))
    (ld d a)
    (ld a (flash-executable-ram))
    (cp d)
    (jr z gs-getk-end)
    (ld a d)
    (ld (flash-executable-ram) a)

    (label gs-getk-end)
    (pop hl)
    (pop de)
    (pop bc)
    (ret)

    (label gs-keygroups)
    (db (#xFE #xFD #xFB #xF7 #xEF #xDF #xBF))
    (label gs-keygroup1)
    (db (#x03 #x02 #x01 #x04 #x00 #x00 #x00 #x00))
    (label gs-keygroup2)
    (db (#x09 #x0A #x0B #x0C #x0D #x0E #x0F #x00))
    (label gs-keygroup3)
    (db (#x11 #x12 #x13 #x14 #x15 #x16 #x17 #x00))
    (label gs-keygroup4)
    (db (#x19 #x1A #x1B #x1C #x1D #x1E #x1F #x20))
    (label gs-keygroup5)
    (db (#x21 #x22 #x23 #x24 #x25 #x26 #x27 #x28))
    (label gs-keygroup6)
    (db (#x00 #x2A #x2B #x2C #x2D #x2E #x2F #x30))
    (label gs-keygroup7)
    (db (#x31 #x32 #x33 #x34 #x35 #x36 #x37 #x38))))

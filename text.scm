;; Text functions

(define text-asm
  `((label newline)
    (push af)
    (ld a e)
    (add a 6)
    (ld e a)
    (ld d b)
    (pop af)
    (ret)

    (label wrap-char)
    (push ix)
    (db (#xdd))
    (ld l 0)
    (call wrap-char-shared)
    (pop ix)
    (ret)

    (label wrap-char-and)
    (push ix)
    (db (#xdd))    
    (ld l 1)
    (call wrap-char-shared)
    (pop ix)
    (ret)

    (label wrap-char-xor)
    (push ix)
    (db (#xdd))
    (ld l 2)
    (call wrap-char-shared)
    (pop ix)
    (ret)

    (label draw-char)
    (push ix)
    (db (#xdd))
    (ld l 0)
    (call draw-char-shared)
    (pop ix)
    (ret)

    (label draw-char-and)
    (push ix)
    (db (#xdd))
    (ld l 1)
    (call draw-char-shared)
    (pop ix)
    (ret)

    (label draw-char-xor)
    (push ix)
    (db (#xdd))
    (ld l 2)
    (call draw-char-shared)
    (pop ix)
    (ret)

    (label draw-char-shared)
    ,@(push* '(af hl bc))
    (cp ,(char->integer #\newline))
    (jr nz local-labeldcs)
    (ld a e)
    (add a 6)
    (ld e a)
    (ld d b)
    (jr dcs-exit)
    (label local-labeldcs)

    (cp ,(char->integer #\tab))
    (jr nz local-label22)
    (ld a d)
    (add a 6)
    (ld d a)
    (jr dcs-exit)
    
    (label local-label22)
    (push de)
    (sub #x20)
    (ld l a)
    (ld h 0)
    (add hl hl)
    (ld d h)
    (ld e l)
    (add hl hl)
    (add hl de)
    ((ex de hl))
    (ld hl kernel-font)
    (add hl de)
    (ld a (hl))
    (inc hl)
    (pop de)
    (ld b 5)
    (push af)
    (ld a d)
    (cp 95)
    (jr nc local-label23)
    (db (#xdd))
    (ld a l)
    (or a)
    (call z put-sprite-or)
    (dec a)
    (call z put-sprite-and)
    (dec a)
    (call z put-sprite-xor)
    (pop af)
    (add a d)
    (ld d a)
    
    (label dcs-exit)
    ,@(pop* '(bc hl af))
    (ret)
    (label local-label23)
    ,@(pop* '(af bc hl af))
    (ret)

    (label wrap-char-shared)
    ,@(push* '(af bc hl))
    (cp ,(char->integer #\newline))
    (jr nz local-label24)
    (add a 6)
    (ld e a)
    (db (#xdd))
    (ld d h)
    (jr wcs-exit)

    (label local-label24)
    (cp ,(char->integer #\tab))
    (jr nz local-label25)
    (ld a d)
    (add a 6)
    (ld d a)
    (jr wcs-exit)

    (label local-label25)
    (push de)
    (sub #x20)
    (ld l a)
    (ld h 0)
    (add hl hl)
    (ld d h)
    (ld e l)
    (add hl hl)
    (add hl de)
    ((ex de hl))
    (ld hl kernel-font)
    (add hl de)
    (ld a (hl))
    (inc hl)
    (pop de)

    (add a d)
    (cp b)
    (jr c local-label26)
    (ld a e)
    (add a 6)
    (ld e a)
    (db (#xdd))
    (ld d h)
    
    (label local-label26)
    (ld a e)
    (cp c)
    (jr nc local-label27)
    (ld b 5)
    (db (#xdd))
    (ld a l)
    (or a)
    (call z put-sprite-or)
    (dec a)
    (call z put-sprite-and)
    (dec a)
    (call z put-sprite-xor)
    (dec hl)
    (ld a (hl))
    (add a d)
    (ld d a)

    (label wcs-exit)
    ,@(pop* '(hl bc af))
    (ret)
    
    (label local-label27)
    (ld e c)
    (jr wcs-exit)

    (label draw-str)
    (push ix)
    (db (#xdd))
    (ld l 0)
    (call draw-str-shared)
    (pop ix)
    (ret)

    (label draw-str-and)
    (push ix)
    (db (#xdd))
    (ld l 1)
    (call draw-str-shared)
    (pop ix)
    (ret)

    (label draw-str-xor)
    (push ix)
    (db (#xdd))
    (ld l 2)
    (call draw-str-shared)
    (pop ix)
    (ret)

    (label draw-str-shared)
    (push hl)
    (push af)
    (label local-label28)
    (ld a (hl))
    (or a)
    (jr z local-label29)
    (call draw-char-shared)
    (inc hl)
    (jr local-label28)
    
    (label local-label29)
    (pop af)
    (pop hl)
    (ret)
    ))

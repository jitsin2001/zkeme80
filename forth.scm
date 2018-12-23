;; Forth portion of the operating system.

(define next
  `((jp next-sub)))

(define push-bc-rs
  `((dec ix)
    (ld (+ ix 0) b)
    (dec ix)
    (ld (+ ix 0) c)))

(define pop-bc-rs
  `((ld c (+ ix 0))
    (inc ix)
    (ld b (+ ix 0))
    (inc ix)))

(define push-hl-rs
  `((dec ix)
    (ld (+ ix 0) h)
    (dec ix)
    (ld (+ ix 0) l)))

(define pop-hl-rs
  `((ld l (+ ix 0))
    (inc ix)
    (ld h (+ ix 0))
    (inc ix)))

(define push-de-rs
  `((dec ix)
    (ld (+ ix 0) d)
    (dec ix)
    (ld (+ ix 0) e)))

(define pop-de-rs
  `((ld e (+ ix 0))
    (inc ix)
    (ld d (+ ix 0))
    (inc ix)))

(define hl-to-bc
  `((ld b h)
    (ld c l)))

(define hl-to-de
  `((ld d h)
    (ld e l)))

(define reset-link
  (lambda ()
    (set! *link-pointer* 0)
    '()))

(define make-link
  (lambda ()
    ;; We need to compute and return the instruction record for the
    ;; previous byte, but perform the side effect of changing the link
    ;; pointer as well.
    (let ((out (assemble-expr `(dw (,*link-pointer*)))))
      (set! *link-pointer* *pc*)
      out)))

(define (string->bytes x)
  `(,@(bytevector->u8-list (string->utf8 x)) 0))

(define (defcode name flags label)
  (let ((len (string-length name)))
    `(,make-link
      (db (,(+ len flags)))
      (db ,(string->bytes name))
      (label ,label))))

(define (defword name flags label)
  `(,@(defcode name flags label)
    (call docol)))

(define *link-pointer* 0)

(define next-sub
  `((label next-sub)
    (ld a (de))
    (ld l a)
    (inc de)
    (ld a (de))
    (ld h a)
    (inc de)
    (jp (hl))))

(define docol-sub
  `((label docol)
    ,@push-de-rs
    (pop de)
    ,@next))

(define forth-prog
  `(,reset-link
    ;; Reasonable settings for Forth's stacks.
    (ld de main)
    (ld ix #xc000)
    (ld sp 0)
    ,@next
    ,@next-sub

    ,@docol-sub

    (label tru)
    (ld bc 1)
    ,@next
    
    (label fal)
    (ld bc 0)
    ,@next

    ,@(defcode "EXIT" 0 'exit)
    ,@pop-de-rs
    ,@next

    ,@(defcode "DUP" 0 'dup)
    (push bc)
    ,@next

    ,@(defcode "?DUP" 0 '?dup)
    (ld hl 0)
    (call cp-hl-bc)
    (jp nz dup)
    ,@next

    ,@(defcode "+" 0 '+)
    (pop hl)
    (add hl bc)
    ,@hl-to-bc
    ,@next

    ,@(defcode "-" 0 '-)
    (xor a)
    (pop hl)
    (sbc hl bc)
    ,@hl-to-bc
    ,@next

    ,@(defcode "*" 0 '*)
    ,@push-de-rs
    (pop de)
    (call mul-16-by-16)
    ,@hl-to-bc
    ,@pop-de-rs
    ,@next

    ,@(defcode "LIT" 0 'lit)
    (ld a (de))
    (ld l a)
    (inc de)
    (ld a (de))
    (ld h a)
    (inc de)
    (push bc)
    ,@hl-to-bc
    ,@next

    ,@(defcode "BRANCH" 0 'branch)
    (ld a (de))
    (ld l a)
    (inc de)
    (ld a (de))
    (ld h a)
    (dec de)
    (add hl de)
    ,@hl-to-de
    ,@next

    ,@(defcode "0BRANCH" 0 '0branch)
    (ld a c)
    (cp 0)
    (jp z zbranch-maybe)
    (jp nz zbranch-fail)
    
    (label zbranch-maybe)
    (ld a b)
    (cp 0)
    (jp nz zbranch-fail)
    (pop bc)
    (jp branch)
    
    (label zbranch-fail)
    (inc de)
    (inc de)
    (pop bc)
    ,@next

    ,@(defcode "=" 0 '=)
    (pop hl)
    (call cp-hl-bc)
    (jp z tru)
    (jp fal)
    
    ,@(defcode "<>" 0 '<>)
    (pop hl)
    (call cp-hl-bc)
    (jp z fal)
    (jp tru)    

    ,@(defcode "KEYC" 0 'keyc)
    (call get-key)
    (push bc)
    (ld b 0)
    (ld c a)
    ,@next

    ,@(defcode "KEY" 0 'key)
    (call flush-keys)
    (call wait-key)
    (push bc)
    (ld b 0)
    (ld c a)
    ,@next

    ,@(defcode "DROP" 0 'drop)
    (pop bc)
    ,@next

    ,@(defcode "SWAP" 0 'swap)
    (pop hl)
    (push bc)
    ,@hl-to-bc
    ,@next

    ,@(defcode "OVER" 0 'over)
    (pop hl)
    (push hl)
    (push bc)
    ,@hl-to-bc
    ,@next

    ,@(defcode "ROT" 0 'rot)
    ,@push-de-rs
    (pop hl)
    (pop de)
    (push hl)
    (push bc)
    ((ex de hl))
    ,@hl-to-bc
    ,@pop-de-rs
    ,@next

    ,@(defcode "-ROT" 0 '-rot)
    ,@push-de-rs
    (pop hl)
    (pop de)
    (push bc)
    (push de)
    ,@hl-to-bc
    ,@pop-de-rs
    ,@next

    ,@(defcode "1+" 0 '1+)
    (inc bc)
    ,@next

    ,@(defcode "1-" 0 '1-)
    (dec bc)
    ,@next
    
    ,@(defcode "!" 0 '!)
    (pop hl)
    (ld a l)
    (ld (bc) a)
    (inc bc)
    (ld a h)
    (ld (bc) a)
    (pop bc)
    ,@next

    ,@(defcode "@" 0 '@)
    (ld a (bc))
    (ld l a)
    (inc bc)
    (ld a (bc))
    (ld h a)
    ,@hl-to-bc

    ;; Draw a region of memory to the screen.
    ;; ( addr --  )
    ,@(defcode "DRAW" 0 'draw)
    (push bc)
    (pop iy)
    (pop bc)
    (call fast-copy)
    ,@next

    ;; Plot the default memory screen (starting at address #x8100)
    ,@(defcode "PLOT" 0 'plot)
    (ld iy screen-buffer)
    (call fast-copy)
    ,@next    

    ;; Shut down the calculator.
    ,@(defcode "POWEROFF" 0 'poweroff)
    (jp shutdown)

    ;; Draw a rectangle using OR
    ;; ( x y width height -- )
    ,@(defcode "RECT-OR" 0 'rect-or-forth)
    (ld b c)
    (pop hl)
    (ld c l)
    (pop hl)
    ,@push-de-rs
    (pop de)
    (ld iy screen-buffer)
    (call rect-or)
    ,@pop-de-rs
    (pop bc)
    ,@next

    ;; Draw a rectangle using XOR
    ;; ( x y width height -- )
    ,@(defcode "RECT-XOR" 0 'rect-xor-forth)
    (ld b c)
    (pop hl)
    (ld c l)
    (pop hl)
    ,@push-de-rs
    (pop de)
    (ld iy screen-buffer)
    (call rect-xor)
    ,@pop-de-rs
    (pop bc)
    ,@next

    ,@(defcode "CLEAR-SCREEN" 0 'clear-screen)
    (ld iy screen-buffer)
    (call clear-buffer)
    ,@next

    ;; Draw a sprite to the screen.
    ;; ( sprite_addr height x y -- )
    ,@(defcode "PUT-SPRITE-OR" 0 'put-sprite-or-forth)
    (ld iy screen-buffer)
    ,@push-de-rs
    (ld e c)
    (pop bc)
    (ld d c)
    (pop bc)
    (ld b c)
    (pop hl)
    (call put-sprite-or)
    ,@pop-de-rs
    ,@next

    ,@(defcode ">R" 0 '>r)
    ,@push-bc-rs
    (pop bc)
    ,@next
    
    ,@(defcode ">R" 0 'r>)    
    (push bc)
    ,@pop-bc-rs
    ,@next

    ;; Plot a character to the screen.
    ;; ( char x y -- )
    ,@(defword "PLOT-CHAR" 0 'plot-char)
    (dw (>r >r lit 6 * lit 1+ lit kernel-font + lit 5 r> r>))
    (dw (put-sprite-or-forth))
    (dw (exit))

    ;; Draw a string to the screen
    ;; ( str_addr x y -- )
    ,@(defcode "PLOT-STR" 0 'plot-str)
    ,@push-de-rs
    (ld e c)
    (pop bc)
    (ld d c)
    (pop hl)
    (ld iy screen-buffer)
    (call draw-str-xor)
    ,@pop-de-rs
    (pop bc)
    ,@next

    (label title1)
    (db ,(string "Welcome to Ben's"))
    (label title2)
    (db ,(string "Forth-based OS!"))

    (label main)
    (dw (lit title1 lit 16 lit 0 plot-str))
    (dw (lit title2 lit 18 lit 8 plot-str))
    (dw (lit smiley-face lit 4 lit 40 lit 20 put-sprite-or-forth plot key))
    (dw (lit 30 lit 30 lit 20 lit 20 rect-xor-forth
        lit 40 lit 40 lit 20 lit 20 rect-xor-forth plot key
        clear-screen plot poweroff))
    ;; Keep trying to read a key until one is pressed.
    ;; (dw (keyc ?dup zbranch ,(- 65536 6) poweroff))
    ,(lambda ()
       (format #t "End of forth.asm: 0x")
       (PRINT-PC))
    ))

(define fast-memview-forth-prog
  `(dw (lit 0 keyc drop lit 12 + draw branch ,(- 65536 14))))

;; Decompiled with SEE from
;; https://github.com/siraben/ti84-forth/blob/9088ae05a28f037f2ec6995c1fa817dea59c91a4/programs/memview.fs
;; You may need to define more words (e.g. one, two, three, stepl... )
;; to get this to work.
(define memview-arrow-keys-forth-prog
  `(dw (key dup five <> 0branch 92 over
             draw three over = 0branch 12
             drop step + branch 64 four over =
             0branch 12 drop step - branch 44
             one over = 0branch 12 drop
             stepl + branch 24 two over =
             0branch 12 drop stepl - branch 4
             drop branch 65436 drop)))

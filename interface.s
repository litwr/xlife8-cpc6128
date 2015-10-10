dispat2  proc
         local cont2,cont3,cont4,cont5,cont6,cont7,cont8,cont10,cont11,cont12
         local cont14,cont15,cont16,cont16b,cont16c,cont16x,cont17,cont17a
         local cont17b,cont17c,cont17d,cont17e,cont17f,cont17g,cont17h,cont17i
         local cont17j,cont17q,cont17t,cont17w,cont18,cont40,cont41,cont42,cont42w,cont43,cont44
         local cxdown,cxright,cxleft,cxup,cm4,cm5,contcur1,contcur2,contcur3
         local lsp1,lsp2,l2,l4,l5,l8,l11,l77,cm4v,cm5v,zoomin,zoomout
         local exitload,ltopo,yesclear

         cp "g"
         jr nz,cont3

         ld a,(mode)
         or a
         jr z,cont2

         dec a
         ld (mode),a
         jr z,setbg0

l5       call initxt
         call xyout
cont2    ld a,(bggo)
         call setbg
         ld a,1
l4       ld (mode),a
         ret

setbg0   ld a,(bgedit)
setbg    ld c,a
         ld b,a
         xor a
         jp SCR_SET_INK

cont3    cp "Q"
         jr nz,cont5

         ld a,3
         jr l4

cont5    cp "h"
         jr nz,cont4

         ld a,(mode)
         cp 2
         jr z,l5

         ld a,2
         ld (mode),a
         call SCR_CLEAR
setbg1   ld a,(bggo)
         jr setbg

cont4    cp "T"
         jr nz,cont6

         ld a,(topology)
         or a
         jr z,ltopo

         xor a
         ld (topology),a
         ld hl,torus
         call calllo
         ld a,(bordertc)
         jr chgbr

ltopo    inc a
         ld (topology),a
         ld hl,plain
         call calllo
         ld a,(borderpc)
chgbr    ld b,a
         ld c,a
         jp SCR_SET_BORDER

cont6    cp "o"
         jr nz,cont7

         ld a,(mode)
         or a
         ret nz

         ld a,(startp+1)
         or a
         jr nz,l8

         call incgen
         jp infoout

l8       call zerocc
         ld hl,generate
         call calllo
         ld hl,showscn
         call calllo
         ld hl,cleanup 
         jp calllo

cont7    cp "?"
         jr nz,cont8

         ld a,(mode)
         cp 2
         ret z

help0    call totext
         call help
         jp difinish

cont8    cp "C"
         jr nz,cont10

         ld a,(startp+1)
         or a
         jr nz,yesclear

         call zerogc
         jp infoout

yesclear ld hl,clear
         jp calllo

cont10   cp "E"
         jr nz,cont11

         ld a,(pseudoc)
         dec a
         jr z,l11

         ld a,1
l11      ld (pseudoc),a
l77      ld hl,showscn
         jp calllo

cont11   cp "!"
         jr nz,cont12

;*         jsr random
         ld hl,random
         call calllo
;*         jmp showscn
         jr l77

cont12   cp "%"
         jr nz,cont14

         ld a,(mode)
         cp 2
         ret z

         call totext
         call indens
         jr difinish

cont14   cp "B"
         jr nz,cont15

         call totext
         call insteps
         jr z,difinish

         call steps2bin
         ld hl,decint
         call calllo
         jr c,difinish

         call inmode
         call setbench
         call KL_TIME_PLEASE      ;get timer
         ld (stringbuf),hl
         ld (stringbuf+2),de
         ld hl,bloop
         call calllo
         call KL_TIME_PLEASE      ;get timer
         push hl
         push de
         call exitbench
         pop de
         pop hl
         call calcspd
         ld hl,calccells
         call calllo
         jr difinish

cont15   cp "R"
         jr nz,cont16

         call totext
         call inborn
         jr z,difinish

         ld ix,born
         call setrconst
         call instay
         ld ix,live
         call setrconst
         call fillrt
difinish   call tograph
         call SCR_CLEAR
         call initxt
         ld hl,showscn
         call calllo
         call showrules
         jp xyout

cont16   cp $f3        ;cursor right
         jr nz,cont16x

         call crsrclr
         ld hl,vptilecx
         inc (hl)
         ld a,(crsrbit)
         cp 1
         jr z,cxright

         rrca
cont17q  ld (crsrbit),a
         jp crsrupd

cxright  ld b,$80
         ld a,right
contcur1 add a,iyl
         ld iyl,a
         ld a,0 
         adc a,iyh
         ld iyh,a
         ld hl,readhl
         call calllo
         ld a,low(plainbox)
         cp l
         jr nz,cm4

         ld a,high(plainbox)
         cp h
         jr nz,cm4

         ld a,(crsrbit)
         jr cont17q

cm4      ld (crsrtile),hl
cm5      ld a,b
         jr cont17q

cont16x  cp $f2        ;cursor left
         jr nz,cont40

         call crsrclr
         ld hl,vptilecx
         dec (hl)
         ld a,(crsrbit)
         cp $80
         jr z,cxleft

         rlca
         jr cont17q

cxleft   ld b,1
         ld a,left
         jr contcur1
;*cxleft   lda #1
;*cm6      ldx #0
;*cm1      sta t1
;*         stx i2
;*         lda (crsrtile),y
;*         tax
;*         iny
;*         lda (crsrtile),y
;*         cmp #>plainbox
;*         bne cm4
;*
;*         cpx #<plainbox
;*         bne cm4

;*         ldx i2
;*         lda crsrbit,x
;*         sta t1
;*         bcs cm5

;*cm4      sta crsrtile+1
;*         stx crsrtile
;*cm5      lda t1
;*         ldx i2
;*         sta crsrbit,x
;*         jmp crsrset

cont40   cp $f4       ;shifted cursor up
         jr nz,cont41

         ld d,a
         ld ix,(vptilecx)
         ld a,ixh
         sub 8
         ld (vptilecy),a
         ld c,up
cont42   call shift
         jr z,cont42w

         push hl
         call crsrclr
         pop hl
         ld (crsrtile),hl
         jp crsrupd

cont42w  ld a,d
         sub 4
         ld (vptilecx),ix
         jp cont16

cont41   cp $f5       ;shifted cursor down
         jr nz,cont43

         ld d,a
         ld ix,(vptilecx)
         ld a,ixh
         add a,8
         ld (vptilecy),a
         ld c,down
         jr cont42

cont43   cp $f6       ;shifted cursor left
         jr nz,cont44

         ld d,a
         ld ix,(vptilecx)
         ld a,ixl
         sub 8
         ld (vptilecx),a
         ld c,left
         jr cont42

cont44   cp $f7       ;shifted cursor right
         jr nz,cont16b

         ld d,a
         ld ix,(vptilecx)
         ld a,ixl
         add a,8
         ld (vptilecx),a
         ld c,right
         jr cont42

cont16b  cp $f0      ;cursor up
         jr nz,cont16c

         call crsrclr
         ld hl,vptilecy
         dec (hl)
         ld a,(crsrbyte)
         or a
         jr z,cxup

         dec a
contcur2 ld (crsrbyte),a
         jp crsrupd

;*cxup     lda #7
;*cm3      ldx #1
;*         bpl cm1
cxup     ld b,7
         ld a,up
contcur3 add a,iyl
         ld iyl,a
         ld a,0
         adc a,iyh
         ld iyh,a
         ld hl,readhl
         call calllo
         ld a,low(plainbox)
         cp l
         jr nz,cm4v

         ld a,high(plainbox)
         cp h
         jp z,crsrupd

cm4v     ld (crsrtile),hl
cm5v     ld a,b
         jr contcur2

cont16c  cp $f1         ;cursor down
         jr nz,cont17

         call crsrclr
         ld hl,vptilecy
         inc (hl)
         ld a,(crsrbyte)
         cp 7
         jr z,cxdown

         inc a
         jr contcur2

cxdown   ld b,0
         ld a,down
         jr contcur3

cont17   cp 32          ;space
         jr nz,cont17c

;*         #assign16 adjcell,crsrtile
;*         jsr chkadd
         ld bc,(crsrtile)
         ld hl,chkadd
         call calllo

;*         ldy crsrbyte
;*         lda (crsrtile),y
;*         eor crsrbit
;*         sta (crsrtile),y
;*         ldy #sum
;*         and crsrbit
;*         beq lsp1
         ld a,(crsrbyte)
         add a,c
         ld iyl,a
         ld a,b
         adc a,0
         ld iyh,a
         ld a,(crsrbit)
         ld d,a
         ld hl,xoriy
         call calllo
         push bc
         pop iy
         and d
         jr z,lsp1

         ld hl,cellcnt+4
         call inctsum
lsp2     ld hl,setiy
         call calllo
         ld a,(zoom)
         or a
         push af
         call z,crsrclr
         pop af

         ld hl,showscnz
         call nz,calllo

;*lsp3     jsr infoout
;*         jmp crsrset
         call infoout
         ld hl,crsrset
         jp calllo

lsp1     call dectsum
         jr lsp2

cont17c  cp "."
         jr nz,cont17f

;*         jsr crsrclr
;*         lda #<tiles+(tilesize*249)
;*         sta crsrtile
;*         lda #>tiles+(tilesize*249)
;*         sta crsrtile+1
;*         lda #1
;*         sta crsrbyte
;*cont17t  sta crsrbit
         call crsrclr
         ld hl,tiles+(tilesize*249)
         ld (crsrtile),hl
         ld a,1
         ld (crsrbyte),a
cont17t  ld (crsrbit),a
         call crsrupd
         ld a,(zoom)
         or a
         jr z,crsrupd

         call setviewport
         ld hl,showscnz
         call calllo
;*cont17u  jmp crsrset
crsrupd  ld hl,crsrset
         call calllo
         jp crsrcalc

cont17f  cp "H"           ;home
         jr nz,cont17a

         call crsrclr
         ld hl,tiles
         ld (crsrtile),hl
         xor a
         ld (crsrbyte),a
         ld a,$80
         jr cont17t

cont17a  cp "l"
         jr nz,cont17b

         ld a,(zoom)
         or a
         push af
         call nz,zoomout
         call totext
         call loadmenu
         jr z,exitload

cont17w  call loadpat
         ld hl,calccells
         call calllo
exitload call difinish
         pop af
         jr nz,zoomin

         ret

cont17b  cp "L"
         jr nz,cont17d

         ld a,(fnlen)
         or a
         ret z

         ld a,(zoom)
         or a
         push af
         call nz,zoomout
         call totext
         jr cont17w

cont17d  cp "+"
         jr nz,cont17e

         ld a,(zoom)
         or a
         ret nz

zoomin   ;call crsrclr
         call split_off
         ld a,1
         ld (zoom),a
         call SCR_CLEAR
         call setviewport
         jp difinish

cont17e  cp "-"
         jr nz,cont17g

         ld a,(zoom)
         or a
         ret z

zoomout  call split_on
         xor a
         ld (zoom),a
         jp difinish

cont17g  cp "V"
         jr nz,cont17h

;*         jsr totext
;*         jsr $ff4f
;*         .byte 144,147,0
         call totext
         call printn
         db 4,2,15,1,"$"   ;80 columns

;*         jsr curoff
;*         jsr showcomm
         call showcomm

         ld a,1
         call SCR_SET_MODE
         jp difinish

cont17h  cp "v"
         jr nz,cont17i

;*         jsr totext
;*         jsr curoff
;*         jsr infov
;*         jmp finish
         call totext
         call infov
         jp difinish

cont17i  cp "Z"
         jr nz,cont17j

         call totext
         call chgcolors
l2       call setcolor
         jp difinish

cont17j  cp "X"
         jr nz,cont18

         call totext
         call loadcf
         jr l2

cont18   cp "S"
         ret nz

;*         jsr boxsz
;*         beq cont20
         call boxsz
         ret z

         push bc
         push de
         push hl
;*         jsr totext
         call totext
;*         jsr getsvfn
         call getsvfn
;*         beq exitsave
         pop hl
         pop de
         pop bc
         jp z,difinish

;*         jsr savepat
         call savepat
;*exitsave jmp finish
         jp difinish

;*cont20   clc
;*         rts
         endp

;*shift    lda $543   ;shift st
;*         beq cont20

;*         lda (crsrtile),y
;*         tax
;*         iny
;*         lda (crsrtile),y
;*         dey
;*         cmp #>plainbox
;*         bne cm4x
;*
;*         cpx #<plainbox
;*         beq cont20

;*cm4x     sta crsrtile+1
;*         stx crsrtile
;*         sec
;*         rts
;*         .bend
shift      proc     ;in: c - direction
           ld iy,(crsrtile)
           ld b,0
           add iy,bc
           ld hl,readhl
           call calllo
           ld a,l
           cp low(plainbox)
           ret nz

           ld a,h
           cp high(plainbox)
           ret
           endp

setbench jp p,difinish

         call SCR_CLEAR
         ld a,(mode)
         ld (temp+1),a
         ld a,2
         ld (mode),a
         ret

exitbench call totext 
         ld a,(temp+1)
         ld (mode),a
         ret


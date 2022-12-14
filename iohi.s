savecf   proc
         local loop

         ld b,live-cfn
         ld hl,cfn
         call erasefile
         ld de,$7800
         call CAS_OUT_OPEN
         jr nc,ioerror

         ld hl,borderpc
         ld b,tentc-borderpc+1
loop     ld a,(hl)
         inc hl
         push hl
         push bc
         call CAS_OUT_CHAR
         pop bc
         pop hl
         jr nc,ioerror

         djnz loop
         jp CAS_OUT_CLOSE
         endp

ioerror  ;ld b,a          ;in: a
         ld a,(errst)
         or a
         ret z

         ;call printn
         ;db "i/o error #$"
         ;ld a,b
         ;printhex
         jp KM_WAIT_CHAR

erasefile proc
         local params,param
         ld (param+1),hl
         ld a,b
         ld (param),a
         push bc
         push hl
         ld hl,$40
         ld ix,params
         ld a,1
         call $23
         pop hl
         pop bc
         ret

params   dw param
param    db 0
         dw 0
         endp

loadcf   proc
         local loop

         ld b,live-cfn
         ld hl,cfn
         ld de,$7800
         call CAS_IN_OPEN
         jr nc,ioerror

         ld hl,borderpc
         ld b,tentc-borderpc+1
loop     call readchar
         ld (hl),a
         inc hl
         djnz loop
         jp CAS_IN_CLOSE
         endp

copyr    ld b,6
         ld hl,copyleft

showtxt  proc
         local loop,loop2,next
         ld de,$7800
         call CAS_IN_OPEN
         jr nc,ioerror

loop     call CAS_IN_CHAR
         jr c,next

         call CAS_IN_CLOSE
         jp KM_WAIT_CHAR

next     call TXT_OUTPUT
loop2    call KM_READ_CHAR
         jr nc,loop

         call KM_WAIT_CHAR
         jr loop
         endp

savedhl  db 0,0
vhandler proc
         local l1,l2
         push hl
         ld hl,(savedhl)
         cp $a
         jr nz,l1

         ld hl,$8000-80
         jr l2

l1       ld (hl),a
         inc hl
l2       ld (savedhl),hl
         pop hl
         ret
         endp

vector1  macro
         ld hl,(TXT_OUTPUT)
         push hl
         ld a,(TXT_OUTPUT+2)
         push af
         ld a,$c3              ;JP
         ld (TXT_OUTPUT),a
         ld hl,vhandler
         ld (TXT_OUTPUT+1),hl
         ld hl,$8000-80
         ld (savedhl),hl
         endm

vector2  macro
         pop af
         ld (TXT_OUTPUT+2),a
         pop hl
         ld (TXT_OUTPUT),hl
         endm

showdir  proc
         local loop,fnloop,prloop,subloop,nextfn,l1,l2,l3,l4,l5,l5a,l6,l7,l8,l9,l10
         call printn
         db 12,$d,$a,"$"
         vector1
         ld de,$7780
         xor a
         ld (de),a
         call CAS_CATALOG
         vector2
         ld iy,$7780
         ld c,0
fnloop   ld a,(iy)
         cp $ff
         jr z,l7

         ld a,c
         rrca
         jr nc,l8

         call printn
         db $d,$a,"$"

l8       ld hl,$8000-80+1
l10      ld a,(hl)
         cp $d
         jr z,l9

         call TXT_OUTPUT
         inc hl
         jr l10

l9       call printn
         db $d,$a,"$"
         ret

l7       inc iy
         push iy
         pop hl
         ld a,"8"
         cp (iy+8)
         jp nz,nextfn

         ld a,"L"
         cp (iy+9)
         jp nz,nextfn

         ld a," "
         cp (iy+10)
         jp nz,nextfn

         ld de,dirname
         ld b,8
loop     ld a,(de)
         cp (iy)
         jr z,l1

         cp "?"
         jp nz,nextfn

         ld a,(iy)
         cp " "
         jr z,l3

l1       inc iy
         inc de
         djnz loop

l3       call printn
         db 15,3,"$"
         ld a,8
         sub b
         ld b,a
         ld a,c
         ld ixh,c
         cp 10
         jr nc,l5

         ld a," "
         jr l6

l5       ld ixl,$ff
         ld a,c
l5a      inc ixl
         sub 10
         jr nc,l5a

         add a,10
         ld ixh,a
         ld a,ixl
         xor $30
l6       call TXT_OUTPUT
         ld a,ixh
         xor $30
         call TXT_OUTPUT
         call printn
         db 15,1," $"
         push hl
prloop   ld a,(hl)
         inc hl
         call TXT_OUTPUT
         djnz prloop

         call printn
         db " ",15,2,24,"$"
         pop hl
         push hl
         ld a,l
         add a,11
         ld l,a
         ld a,h
         adc a,0
         ld h,a
         ld a,(hl)
         ld b,$30
subloop  cp 10
         jr c,l2

         inc b
         sub 10
         jr subloop

l2       push af
         ld a,b
         cp $30
         call nz,TXT_OUTPUT
         pop af
         xor $30
         call TXT_OUTPUT
         inc c
         call printn
         db 24,15,1,"$"
         inc hl
         ld (hl),c
         pop hl
         ld a,c
         rrca
         jr nc,l4

         push hl
         ld a,20
         call TXT_SET_COLUMN
         pop hl
         jr nextfn

l4       call printn
         db $d,$a,"$"
nextfn   ld a,l
         add a,13
         ld l,a
         ld a,h
         adc a,0
         ld h,a
         push hl
         pop iy
         jp fnloop
         endp

findfn   proc   ;in: c - length
         local loop,nextfn,cont,ext,cploop,addloop,noadd
         ld iy,$7780
         ld hl,stringbuf
         ld a,(hl)
         xor $30
         dec c
         jr z,cont

         or a
         jr z,noadd

         ld b,a
         xor a
addloop  add a,10
         djnz addloop

noadd    inc hl
         ld c,a
         ld a,(hl)
         xor $30
         add a,c
cont     ld c,a
         inc c
loop     ld a,(iy)
         cp $ff
         ret nz

         ld a,(iy+13)
         cp c
         jr nz,nextfn

         push iy
         pop de
         inc de
         ld hl,fn
         ld b,8
cploop   ld a,(de)
         cp " "
         jr z, ext

         ld (hl),a
         inc hl
         inc de
         djnz cploop

ext      ld (hl),"."
         inc hl
         ld (hl),"8"
         inc hl
         ld (hl),"L"
         ld a,11
         sub b
         ld (fnlen),a
         xor a
         ret  ;ZF

nextfn   ld de,14
         add iy,de
         jr loop
         endp

readchar proc
         local ok
         call CAS_IN_CHAR
         jr c,ok

         cp $1a
         jr z,ok

         ;call CAS_IN_CLOSE
         pop bc
         jp ioerror

ok       ret
         endp

loadpat  proc
         local eof,cont1,cont7,loop5
         ld a,(fnlen)
         ld b,a
         ld hl,fn
         ld de,$7800
         call CAS_IN_OPEN
         jp nc,ioerror

         call readchar
         ld iyl,a
         call readchar
         ld iyh,a           ;iy - number of (x,y)-pairs
         cp $78             ;192*160 = $7800
         jp nc,eof

         or iyl
         jp z,eof

         call readchar
         cp 193
         jr nc,eof

         ld (x0),a
         call readchar
         cp 193
         jr nc,eof

         ld (y0),a
         call readchar
         ld l,a
         call readchar
         ld h,a
         call readchar
         ld ixl,a
         call readchar
         ld ixh,a
         or h
         cp 2
         jr nc,eof

         ld a,1
         and ixl
         jr nz,eof

         push hl
         push ix
         call readtent
         push iy
         call showrect
         pop de
         pop bc
         pop hl
         jr nc,eof

         push de
         ld a,(live)
         cp l
         jr nz,cont1

         ld a,(live+1)
         cp h
         jr nz,cont1

         ld a,(born)
         cp c
         jr nz,cont1

         ld a,(born+1)
         cp b
         jr z,cont7

cont1    ld (live),hl
         ld (born),bc
         call fillrt
cont7    call totext     ;it's inserted due to problems with interrupts during long io
         call puttent
         pop de
         jr nc,eof

loop5    call readchar
         ld (x0),a
         call readchar
         ld (y0),a
         push de
         ld hl,putpixel
         call calllo
         pop de
         dec de
         ld a,e
         or d
         jr nz,loop5

eof      jp CAS_IN_CLOSE
         endp

readtent proc                    ;in: iy - total cells to read
         local loop,exit         ;out: iy
         ld hl,EOP
         ld de,0
loop     call readchar
         ld (hl),a
         call readchar
         inc h
         inc h
         inc h
         inc h
         ld (hl),a
         dec h
         dec h
         dec h
         dec h
         inc hl
         inc de
         dec iy
         ld a,iyl
         or iyh
         jr z,exit

         xor a
         or e
         jr nz,loop

         ld a,3
         cp d
         jr nc,loop

exit     ld (memb8),de
         ret
         endp

savepat  proc         ;readlow -> (jsrfar+1) after boxsz
         local sizex,loop0,loop1,loop2,loop3,loop4,cont1,cont4,error,eof

         ;xmin - d, ymin - e
         ;xmax - b, ymax - c
sizex     equ t1     ;connected to curx at boxsz
         ;cury - sizey - h

         push de
         push hl
         ld a,(svfnlen)
         ld b,a
         ld hl,svfn
         call erasefile
         ld de,$7800
         call CAS_OUT_OPEN
         pop hl
         pop de
         jp nc,ioerror

         push de
         push hl
         call calccells1
         ld a,l
         call CAS_OUT_CHAR
         ld a,h
         pop hl
         pop de
         jr nc,error

         call CAS_OUT_CHAR
         jr nc,error

         ld a,(sizex)
         call CAS_OUT_CHAR
         jr nc,error

         ld a,h
         call CAS_OUT_CHAR
         jr nc,error

         ld b,4
         ld hl,live
loop1    ld a,(hl)
         call CAS_OUT_CHAR
         jr nc,error

         inc hl
         djnz loop1

         ld iy,tiles
         ld bc,0
loop0    ld l,0
loop2    ld a,l
         call calllo1
         or a
         jr nz,cont1

loop4    inc l
         ld a,l
         cp 8
         jr nz,loop2

         call inccurrp
         inc b
         ld a,b
         cp hormax
         jr nz,loop0

         ld b,0
         inc c
         ld a,c
         cp vermax
         jr nz,loop0
         jr eof

error    ;ld b,a          ;in: a
         ld a,(errst)
         or a
         call nz,KM_WAIT_CHAR

         ;call printn
         ;db "i/o error #$"
         ;ld a,b
         ;printhex
eof      jp CAS_OUT_CLOSE

cont1    ld h,$ff
loop3    inc h
         sla a
         jr c,cont4
         jr z,loop4
         jr loop3

cont4    ld (sizex),a
         ld a,b
         rlca
         rlca
         rlca
         add a,h
         sub d
         call CAS_OUT_CHAR
         jr nc,error

         ld a,c
         rlca
         rlca
         rlca
         add a,l
         sub e
         call CAS_OUT_CHAR
         jr nc,error
         ld a,(sizex)
         jr loop3
         endp

showcomm proc
         ld a,(fnlen)
         or a
         ret z

         ld b,a
         inc b
         ld hl,fn
         sub 2
         add a,l
         ld l,a
         ld a,0
         adc a,h
         ld h,a
         push hl
         ld (hl),"T"
         inc hl
         ld (hl),"X"
         inc hl
         ld (hl),"T"
         ld hl,fn
         call showtxt
         pop hl
         ld (hl),"8"
         inc hl
         ld (hl),"L"
         ret
         endp


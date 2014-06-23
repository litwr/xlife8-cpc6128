savecf   proc
         local loop

         ld b,live-cfn
         ld hl,cfn
         ld de,$7800
         call CAS_OUT_OPEN
         jr nc,ioerror

         ld hl,borderpc
         ld b,bggo-borderpc+1
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

ioerror  ld b,a          ;in: a
         ld a,(errst)
         or a
         ret z

         ;call printn
         ;db "i/o error #$"
         ;ld a,b
         ;printhex
         jp KM_WAIT_CHAR

loadcf   proc
         local loop

         ld b,live-cfn
         ld hl,cfn
         ld de,$7800
         call CAS_IN_OPEN
         jr nc,ioerror

         ld hl,borderpc
         ld b,bggo-borderpc+1
loop     call readchar
         ld (hl),a
         inc hl
         djnz loop
         jp CAS_IN_CLOSE
         endp

copyr    ld b,6
         ld hl,copyleft

showtxt  proc
         local loop,next
         ld de,$7800
         call CAS_IN_OPEN
         jr nc,ioerror

loop     call CAS_IN_CHAR
         jr c,next
         call CAS_IN_CLOSE
         jp KM_WAIT_CHAR
         
next     call TXT_OUTPUT
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
         local loop,fnloop,prloop,subloop,nextfn,l1,l2,l3,l4,l5,l6,l7,l8,l9,l10
         call printn
         db 12,$d,$a,"$"
         vector1
         ld de,$6000
         xor a
         ld (de),a
         call CAS_CATALOG
         vector2
         ld iy,$6000
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
         and $f0
         jr nz,l5

         ld a," "
         jr l6

l5       rrca
         rrca
         rrca
         rrca
         xor $30
l6       call TXT_OUTPUT
         ld a,c
         and $f
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
         ld iy,$6000
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
         local eof,cont1,loop5
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
         jr z,eof

         call readchar
         cp 193
         jr nc,eof

         ld (x0),a
         call readchar
         cp 193
         jr nc,eof

         ld (y0),a
         push iy
         call showrect
         pop iy
         jr c,eof

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

         ld a,(live)
         cp l
         jr nz,cont1

         ld a,(live+1)
         cp h
         jr nz,cont1

         ld a,(born)
         cp ixl
         jr nz,cont1

         ld a,(born+1)
         cp ixh
         jr z,loop5

cont1    ld (live),hl
         ld (born),ix
         call fillrt
loop5    call readchar
         ld (x0),a
         call readchar
         ld (y0),a
         push iy
         ld hl,putpixel
         call calllo
         pop iy
         dec iy
         ld a,iyl
         or iyh
         jr nz,loop5

eof      jp CAS_IN_CLOSE
         endp


	;; Programa reaguoja i perduodamus parametrus
;; isveda pagalba, jei nera nurodyti reikiami parametrai
;; source failas skaitomas dalimis
;; destination failas rasomas dalimis
;; jei destination failas jau egzistuoja, jis yra isvalomas
;; jei source failas nenurodytas - skaito iš stdin iki tuščios naujos eilutės
;; galima nurodyti daugiau nei vieną source failą - juos sujungia

;skaitomos komandos
;div	   1111 011w mod 110 r/m [poslinkis]
;idiv    1111 011w mod 111 r/m [poslinkis]
;in      1110 110w arba 1110 010w portas (vieno baito dydzio betarpiskas operandas)
;iret	   1100 1111
;int	   1100 1100 (INT 3) 11001101 kodas (visi kiti int kur kodas-1 baitas)
;les     1100 0100 mod reg r/m [poslinkis]  reg-<atm
;xchg	   1001 0000 (NOP/XCHG ax,ax) 1001 0xxx (x-registras, kai is x i ax)
;xchg      1000 011w mod reg r/m [poslinkis] – XCHG registras  registras/atmintis
;test	   1000 010w mod reg r/m [poslinkis]

.model small
.stack 100H

.data

;pranesimai
apie    		db 'mini disasembleris'
err_d    		db 'Destination failo nepavyko atidaryti rasymui',13,10,'$'
err_s    		db 'Source failo nepavyko atidaryti skaitymui',13,10,'$'

;skaitomos eilutes numerio formavimas
lineCount 	dw 0   ;desinys  baitas eiles nr skaiciaus
lineCountH	dw 1   ;kairys  baitas eiles nr skaiciaus

;hex skaiciaus spausdinimas
HEX_Map   DB  '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
HEX_Out   DB  "00", 13, 10, '$'   ; string with line feed and '$'-terminator
lineStringAdd db ':  ', '$'
hexBuffer db ' ', '$'


;formatavimas
line_doubleTab db 9, 9, '$'
line_hNewLine db 'h',13,10, '$'
line_NewLine db 13,10,'$'
line_OperandSeparator db ',', ' ', '$'
;neatpazinta komanda
line_unkn db 9, 9, 'Neatpazinta komanda',13,10, '$'

;komandos-------------------------------

line_in db 9,'in',9,'$'
						;offset
com_names 	db	'DIV '	;0
			db	'IDIV '	;4
			db	'IN$'	;9
			db	'IRET$'	;12
			db	'INT$'	;17
			db	'LES '	;21
			db	'XCHG ' ;26
			db	'TEST ' ;31
;---------------------------------------

;registrai------------------------------
					;offset
mod11w0reg	db 'al$';0
			db 'cl$';3
			db 'dl$';6
			db 'bl$';9
			db 'ah$';12
			db 'ch$';15
			db 'dh$';18
			db 'bh$';21
mod11w1reg	db 'ax$';0
			db 'cx$';3
			db 'dx$';6
			db 'bx$';9
			db 'sp$';12
			db 'bp$';15
			db 'si$';18
			db 'di$';21
			db ', $';24
EAdress		db '[bx+si$' ;0
			db '[bx+di$' ;7
			db '[bp+si$' ;14
			db '[bp+di$' ;21
			db '[si   $' ;28
			db '[di   $' ;35
			db '[bp   $' ;42
			db '[bx   $' ;49

format db '[' ;0
       db ']' ;1
			 db '+' ;2
;---------------------------------------




sourceF   	db 'test.exe'
sourceFHandle	dw ?

destF   	db 'asm.asm'
destFHandle 	dw ?

buffer    db 100 dup (?)
regBuffer db 100 dup (?)
regBufferCount db 0

; poslinkio bitai
dLow	db 0
dHigh db 0

temp db 'abc'
wFlag db 0

.code

START:
mov	ax, @data
mov	es, ax			; es kad galetume naudot stosb funkcija: Store AL at address ES:(E)DI

lea	di, destF
lea	di, sourceF

push	ds
push	si

mov	ax, @data
mov	ds, ax

;; rasymui
mov	dx, offset destF	; ikelti i dx destF - failo pavadinima
mov	ah, 3ch	      		; isvalo/sukuria faila - komandos kodas
mov	cx, 0			; normal - no attributes
int	21h			; INT 21h / AH= 3Ch - create or truncate file.


mov	ah, 3dh			; atidaro faila - komandos kodas
mov	al, 1			; rasymui
int	21h			; INT 21h / AH= 3Dh - open existing file.

mov	destFHandle, ax		; issaugom handle

jmp	startConverting


startConverting:
mov	dx, offset sourceF	; failo pavadinimas
mov	ah, 3dh            	; atidaro faila - komandos kodas
mov	al, 0              	; 0 - reading, 1-writing, 2-abu
int	21h			            ; INT 21h / AH= 3Dh - open existing file
jnc	not_err_source		      ; CF set on error AX = error code.
jmp err_source
not_err_source:
mov	sourceFHandle, ax	  ; issaugojam filehandle

skaitom:

call readToBuff

jne	_6			; tai ne pabaiga

mov	bx, sourceFHandle	; pabaiga skaitomo failo
mov	ah, 3eh			; uzdaryti
int	21h
jmp closeF

_6:
mov	si, offset buffer	; skaitoma is cia
mov	bx, destFHandle		; rasoma i cia

; cia prasideda pagrindine logika (apdoroja kiekviena baita)
atrenka:
lodsb  				; Load byte at address DS:(E)SI into AL


lea di, regBuffer
call printLineNumber

;in portas****************************
mov bl, al
and bl, 11111110b
cmp bl, 11100100b
jne not_in2
call com_in2
jmp com_recognized
not_in2:

;in be porto**************************
mov bl, al
cmp bl, 11101100b
jne not_in
call com_in
jmp com_recognized
not_in:

;XCHG********************************
mov bl, al
and bl, 11111000b
cmp bl, 10010000b
jne not_xchg
call com_xchg
jmp com_recognized
not_xchg:

;IRET********************************
cmp al, 11001111b
jne not_iret
call com_iret
jmp com_recognized
not_iret:

;INT su kodu************************
cmp al, 11001101b
jne not_int2
call com_int2
jmp com_recognized
not_int2:

; INT 3*****************************
cmp al, 11001100b
jne not_int
call com_int
jmp com_recognized
not_int:

; LES*******************************
cmp al, 11000100b
jne not_les
call com_les
;jmp not_les
jmp com_recognized
not_les:

mov bl, al
and bl, 11111110b
cmp bl, 11110110b
jne not_div
call com_div
jmp com_recognized
not_div:

mov bl, al
and bl, 11111110b
cmp bl, 10000100b
jne not_test1
call com_test1
jmp com_recognized
not_test1:

mov bl, al
and bl, 11111110b
cmp bl, 10000110b
jne not_xchg2
call com_xchg2
jmp com_recognized
not_xchg2:


; Nezinoma komanda******************
call com_unk

com_recognized:

inc_lineCount:
call incLineNumber


dec cx
cmp cx, 0
je baigemLoop
jmp	atrenka

baigemLoop:

jmp skaitom




;----------------------------------
help:
mov	ax, @data
mov	ds, ax

mov	dx, offset apie
mov	ah, 09h
int	21h

jmp	_end

closeF:
;; uzdaryti dest
mov	ah, 3eh			; uzdaryti
mov	bx, destFHandle
int	21h

_end:
mov	ax, 4c00h
int	21h

err_source:
mov	ax, @data
mov	ds, ax

mov	dx, offset err_s
mov	ah, 09h
int	21h

mov	dx, offset sourceF
int	21h

mov	ax, 4c01h
int	21h

err_destination:
mov	ax, @data
mov	ds, ax

mov	dx, offset err_d
mov	ah, 09h
int	21h

mov	dx, offset destF
int	21h

mov	ax, 4c02h
int	21h


;; procedures

skip_spaces PROC near

skip_spaces_loop:
cmp byte ptr ds:[si], ' '
jne skip_spaces_end
inc si
jmp skip_spaces_loop
skip_spaces_end:
ret

skip_spaces ENDP

read_filename PROC near

push	ax
call	skip_spaces
read_filename_start:
cmp	byte ptr ds:[si], 13	; jei nera parametru
je	read_filename_end	; tai taip, tai baigtas failo vedimas
cmp	byte ptr ds:[si], ' '	; jei tarpas
jne	read_filename_next	; tai praleisti visus tarpus, ir sokti prie kito parametro
read_filename_end:
mov	al, '$'			; irasyti '$' gale
stosb                           ; Store AL at address ES:(E)DI, di = di + 1
pop	ax
ret
read_filename_next:
lodsb				; uzkrauna kita simboli
stosb                           ; Store AL at address ES:(E)DI, di = di + 1
jmp read_filename_start

read_filename ENDP


IntegerToHexFromMap PROC
		push si
		push di

    mov si, OFFSET Hex_Map          ; Pointer to hex-character table

    mov bx, ax                      ; BX = argument AX
    and bx, 00FFh                   ; Clear BH (just to be on the safe side)
    shr bx, 4                       ; Isolate high nibble (i.e. 4 bits)
    mov dl, [si+bx]                 ; Read hex-character from the table
    mov [di+0], dl                  ; Store character at the first place in the output string

    mov bx, ax                      ; BX = argument AX (just to be on the safe side)
    and bx, 00FFh                   ; Clear BH (just to be on the safe side)
    and bl, 0Fh                     ; Isolate low nibble (i.e. 4 bits)
    mov dl, [si+bx]                 ; Read hex-character from the table
    mov [di+1], dl                  ; Store character at the second place in the output string

		pop di
		pop si
    ret
IntegerToHexFromMap ENDP

printLineNumber PROC

  push cx
  push si
	push ax
	push di

  mov di, OFFSET HEX_Out          ; First argument: pointer
  mov ax, lineCountH               ; Second argument: Integer
  call IntegerToHexFromMap

  mov cx, 2
  mov	ah, 40h
  mov bx, destFHandle
  lea dx, HEX_Out
  int 21h

  mov di, OFFSET HEX_Out          ; First argument: pointer
  mov ax, lineCount               ; Second argument: Integer
  call IntegerToHexFromMap

  mov cx, 2
  mov	ah, 40h
  mov bx, destFHandle
  lea dx, HEX_Out
  int 21h

  mov cx, 3
  mov ah, 40h
  mov bx, destFHandle
  lea dx, lineStringAdd
  int 21h

	pop di
	pop ax
  pop si
  pop cx
  ret
printLineNumber ENDP

incLineNumber PROC
	; --- jei lineCount=255 ir norim INC, reikia ji prilygint 0 ir lineCountH ++
	cmp [lineCount], 255
	jne nereikTvarkytiDidelioHex
	mov [lineCount], 0
	inc [lineCountH]
	dec [lineCount]
	nereikTvarkytiDidelioHex:
	inc [lineCount]
	; ---
	ret
incLineNumber ENDP


com_unk PROC
push di
call printHexByte
push cx
push ax

 mov cx, 23
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_unkn
 int 21h

 pop ax
 pop cx
 pop di
 ret
com_unk ENDP

readToBuff PROC
mov	bx, sourceFHandle
mov	dx, offset buffer       ; address of buffer in dx
mov	cx, 100            		; kiek baitu nuskaitysim
mov	ah, 3fh               	; function 3Fh - read from file
int	21h

mov	cx, ax                	; bytes actually read
cmp	ax, 0
ret
readToBuff ENDP

printHexByte PROC
push cx
push ax
push di
push bx

mov di, OFFSET HEX_Out
call IntegerToHexFromMap
mov cx, 2
mov ah, 40h
mov bx, destFHandle
lea dx, HEX_Out
int 21h

pop bx
pop di
pop ax
pop cx
ret
printHexByte ENDP


;------------- IN su portu
com_in2 PROC
call printHexByte
cmp cx, 1
jne skipRefillin2
call readToBuff
skipRefillin2:
lodsb
push ax
dec cx
call printHexByte
call incLineNumber
call printDoubleTab
;TODO normalia printString funkcija, suskaiciuot cx fja
push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle
mov dx, offset com_names + 9
int 21h
pop cx

call printDoubleTab

push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle
mov dx, offset mod11w0reg + 0
int 21h
pop cx

call printOperandSeparator

pop ax
call printHexByte
call printHNewline
jmp inc_lineCount
com_in2 ENDP
;---------

;------------- INT su kodu
com_int2 PROC
call printHexByte
cmp cx, 1
jne skipRefillint2
call readToBuff
skipRefillint2:
lodsb
push ax
dec cx
call printHexByte
call incLineNumber
call printDoubleTab
;TODO normalia printString funkcija, suskaiciuot cx fja
push cx
mov cx, 3
mov ah, 40h
mov bx, destFHandle
mov dx, offset com_names + 17
int 21h
pop cx

call printDoubleTab
pop ax
call printHexByte
call printHNewline
jmp inc_lineCount
ret
com_int2 ENDP
;---------

;----------------------IRET
com_iret PROC
 call printHexByte
 call printDoubleTab
 push cx
 mov cx, 4
 mov ah, 40h
 mov bx, destFHandle
 mov dx, offset com_names + 12
 int 21h
 pop cx
 call printNewline
 jmp inc_lineCount
 ret
com_iret ENDP
;---------

;----------------------INT 3
com_int PROC
 call printHexByte
 call printDoubleTab
 push cx
 mov cx, 3
 mov ah, 40h
 mov bx, destFHandle
 mov dx, offset com_names + 17
 int 21h
 pop cx
 call printDoubleTab
 mov al, 03h
 call printHexByte
 call printNewline
 jmp inc_lineCount
 ret
com_int ENDP
;---------

;----------------------IN
com_in PROC
 and bl, 00000001b
 cmp bl, 0
 jne in_ax
 mov dx, offset mod11w0reg+0
 jmp print_in
 in_ax:
 mov dx, offset mod11w1reg+0
 print_in:
 push dx
 call printHexByte
 call printDoubleTab
 push cx
 mov cx, 2
 mov ah, 40h
 mov bx, destFHandle
 mov dx, offset com_names + 9
 int 21h
 pop cx
 call printDoubleTab

pop dx
push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle
int 21h
pop cx
call printOperandSeparator
push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle
mov dx, offset mod11w1reg + 6
int 21h
pop cx

 call printNewline
 jmp inc_lineCount
 ret
com_in ENDP
;---------

;----------------------XCHG
com_xchg PROC
push ax
call printHexByte
call printDoubleTab
pop ax
mov bl, al
and bl, 00000111b
cmp bl, 00000000b ; ax is ax
jne xchgnotax
mov dx, offset mod11w1reg + 0
jmp xchgprint
xchgnotax:
cmp bl, 00000001b ; cx is ax
jne xchgnotcx
mov dx, offset mod11w1reg + 3
jmp xchgprint

xchgnotcx:
cmp bl, 00000010b ; dx is ax
jne xchgnotdx
mov dx, offset mod11w1reg + 6
jmp xchgprint

xchgnotdx: ; turi buti bx
mov dx, offset mod11w1reg + 9
jmp xchgprint

xchgprint:
push dx

push cx
mov cx, 4
mov ah, 40h
mov bx, destFHandle
mov dx, offset com_names + 25
int 21h
pop cx


call printDoubleTab

pop dx
push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle

int 21h
pop cx


call printOperandSeparator

push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle
mov dx, offset mod11w1reg + 0
;mov dx, offset com_names
int 21h
pop cx
call printNewline
jmp inc_lineCount

ret
com_xchg ENDP

; ------------------------------ TEST!

com_test1 proc
call printHexByte

mov bl, al
and bl, 00000001b
cmp bl, 00000001b
je w1
mov [wFlag], 0
jmp continue1
w1:
mov [wFlag], 1
continue1:

cmp cx, 1
jne skipRefilldiv
call readToBuff
skipRefilldiv:
lodsb
dec cx

call printHexByte
call incLineNumber

push si
mov bh, 5
mov si, offset com_names + 30
call fillRegBuffer
pop si


call modregrm


mov [regBufferCount], 0
ret
com_test1  ENDP


; ------------------------------ DIV
com_div proc
call printHexByte

mov bl, al
and bl, 00000001b
cmp bl, 00000001b
je w1DIV
mov [wFlag], 0
jmp continue1DIV
w1DIV:
mov [wFlag], 1
continue1DIV:

cmp cx, 1
jne skipRefilldiv5
call readToBuff
skipRefilldiv5:
lodsb
dec cx

call printHexByte
call incLineNumber

; ziurim DIV ar IDIV
mov bl, al
and bl, 00111000b
cmp bl, 00110000b
jne itsIDIV
;its div ->
push si
mov bh, 4
mov si, offset com_names + 0
call fillRegBuffer
pop si
jmp continue2
itsIDIV:
;idiv
push si
mov bh, 5
mov si, offset com_names + 4
call fillRegBuffer
pop si
continue2:


;;;;;;------------tikrinamMod
mov bl, al
and bl, 11000000b
cmp bl, 11000000b
jne DIVmodnot11

;-------------------mod11
; ziurim w0 ar w1
mov bl, [wFlag]
cmp bl, 1
jne not1
call scanRM00w1
jmp continue3
not1:
call scanRM00w0
continue3:

call printDoubleTab
call printDIstring
call printNewline
;-------------------
DIVmodnot11:

;;;;;;;;;;;;;;;;;;;;;;;;;;;; mod 10
mov bl, al
and bl, 11000000b
cmp bl, 10000000b
jne DIVmodnot10

cmp cx, 1
jne skipRefilldiv2
call readToBuff
skipRefilldiv2:
lodsb
dec cx

call printHexByte
call incLineNumber

DIVmodnot10:

;;;;;;;;;;;;;;;;;;;;; mod00
mov bl, al
and bl, 11000000b
cmp bl, 00000000b
jne DIVmodnot00

;nuskaitome reg, cia kai w=1
call scanRM

mov bl, al
and bl, 00000111b
cmp bl, 00000110b
jne DIVrmNot110



DIVrmNot110:
DIVmodnot00:


mov [regBufferCount], 0
ret
com_div endp

com_les PROC

call printHexByte
cmp cx, 1
jne skipRefillLes
call readToBuff
skipRefillLes:
lodsb
dec cx

call printHexByte
call incLineNumber

; i rbuff idedu komandos pav.
push si
mov bh, 4
mov si, offset com_names + 21
call fillRegBuffer
pop si

call modregrm


mov [regBufferCount], 0
ret
com_les ENDP


scanREG PROC
push si

mov bl, al
and bl, 00111000b
cmp bl, 00111000b
jne LESregnot111
mov bh, 2 ; nusakom kiek simboliu
mov si, offset mod11w1reg + 21 ; di bus nukreipta i bufferReg
call fillRegBuffer
LESregnot111:

mov bl, al
and bl, 00111000b
cmp bl, 00110000b
jne LESregnot110
mov bh, 2
mov si, offset mod11w1reg + 18
call fillRegBuffer
LESregnot110:

mov bl, al
and bl, 00111000b
cmp bl, 00101000b
jne LESregnot101
mov bh, 2
mov si, offset mod11w1reg + 15
call fillRegBuffer
LESregnot101:

mov bl, al
and bl, 00111000b
cmp bl, 00100000b
jne LESregnot100
mov bh, 2
mov si, offset mod11w1reg + 12
call fillRegBuffer
LESregnot100:

mov bl, al
and bl, 00111000b
cmp bl, 00011000b
jne LESregnot011
mov bh, 2
mov si, offset mod11w1reg + 9
call fillRegBuffer
LESregnot011:

mov bl, al
and bl, 00111000b
cmp bl, 00010000b
jne LESregnot010
mov bh, 2
mov si, offset mod11w1reg + 6
call fillRegBuffer
LESregnot010:

mov bl, al
and bl, 00111000b
cmp bl, 00001000b
jne LESregnot001
mov bh, 2
mov si, offset mod11w1reg + 3
call fillRegBuffer
LESregnot001:

mov bl, al
and bl, 00111000b
cmp bl, 00000000b
jne LESregnot000
mov bh, 2
mov si, offset mod11w1reg + 0
call fillRegBuffer
LESregnot000:

mov bh, 2
mov si, offset mod11w1reg + 24
call fillRegBuffer

pop si
ret
scanREG ENDP

scanRM00w1 proc

push si

mov bl, al
and bl, 00000111b
cmp bl, 00000000b
jne w0rmNot000
mov bh, 2
mov si, offset mod11w1reg + 0
call fillRegBuffer
w0rmNot000:

mov bl, al
and bl, 00000111b
cmp bl, 00000001b
jne w0rmNot001
mov bh, 2
mov si, offset mod11w1reg + 3
call fillRegBuffer
w0rmNot001:

mov bl, al
and bl, 00000111b
cmp bl, 00000010b
jne w0rmNot010
mov bh, 2
mov si, offset mod11w1reg + 6
call fillRegBuffer
w0rmNot010:

mov bl, al
and bl, 00000111b
cmp bl, 00000011b
jne w0rmNot011
mov bh, 2
mov si, offset mod11w1reg + 9
call fillRegBuffer
w0rmNot011:

mov bl, al
and bl, 00000111b
cmp bl, 00000100b
jne w0rmNot100
mov bh, 2
mov si, offset mod11w1reg + 12
call fillRegBuffer
w0rmNot100:

mov bl, al
and bl, 00000111b
cmp bl, 00000101b
jne w0rmNot101
mov bh, 2
mov si, offset mod11w1reg + 15
call fillRegBuffer
w0rmNot101:

mov bl, al
and bl, 00000111b
cmp bl, 00000110b
jne w0rmNot110
mov bh, 2
mov si, offset mod11w1reg + 18
call fillRegBuffer
w0rmNot110:

mov bl, al
and bl, 00000111b
cmp bl, 00000111b
jne w0rmNot111
mov bh, 2
mov si, offset mod11w1reg + 21
call fillRegBuffer
w0rmNot111:

pop si

ret
scanRM00w1 ENDP

scanRM00w0 proc

push si

mov bl, al
and bl, 00000111b
cmp bl, 00000000b
jne w0rmNot000w0
mov bh, 2
mov si, offset mod11w0reg + 0
call fillRegBuffer
w0rmNot000w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000001b
jne w0rmNot001w0
mov bh, 2
mov si, offset mod11w0reg + 3
call fillRegBuffer
w0rmNot001w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000010b
jne w0rmNot010w0
mov bh, 2
mov si, offset mod11w0reg + 6
call fillRegBuffer
w0rmNot010w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000011b
jne w0rmNot011w0
mov bh, 2
mov si, offset mod11w0reg + 9
call fillRegBuffer
w0rmNot011w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000100b
jne w0rmNot100w0
mov bh, 2
mov si, offset mod11w0reg + 12
call fillRegBuffer
w0rmNot100w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000101b
jne w0rmNot101w0
mov bh, 2
mov si, offset mod11w0reg + 15
call fillRegBuffer
w0rmNot101w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000110b
jne w0rmNot110w0
mov bh, 2
mov si, offset mod11w0reg + 18
call fillRegBuffer
w0rmNot110w0:

mov bl, al
and bl, 00000111b
cmp bl, 00000111b
jne w0rmNot111w0
mov bh, 2
mov si, offset mod11w0reg + 21
call fillRegBuffer
w0rmNot111w0:

pop si

ret
scanRM00w0 ENDP

; cia be 110 rm, nes ten keicias logika nuo mod
scanRM PROC

push si
mov bl, al
and bl, 00000111b
cmp bl, 00000000b
jne rmNot000
mov bh, 6
mov si, offset EAdress + 0
call fillRegBuffer
rmNot000:

mov bl, al
and bl, 00000111b
cmp bl, 00000001b
jne rmNot001
mov bh, 6
mov si, offset EAdress + 7
call fillRegBuffer
rmNot001:

mov bl, al
and bl, 00000111b
cmp bl, 00000010b
jne rmNot010
mov bh, 6
mov si, offset EAdress + 14
call fillRegBuffer
rmNot010:

mov bl, al
and bl, 00000111b
cmp bl, 00000011b
jne rmNot011
mov bh, 6
mov si, offset EAdress + 21
call fillRegBuffer
rmNot011:

mov bl, al
and bl, 00000111b
cmp bl, 00000100b
jne rmNot100
mov bh, 6
mov si, offset EAdress + 28
call fillRegBuffer
rmNot100:

mov bl, al
and bl, 00000111b
cmp bl, 00000101b
jne rmNot101
mov bh, 6
mov si, offset EAdress + 35
call fillRegBuffer
rmNot101:

mov bl, al
and bl, 00000111b
cmp bl, 00000111b
jne rmNot111
mov bh, 6
mov si, offset EAdress + 49
call fillRegBuffer
rmNot111:

pop si
ret
scanRM ENDP


scanRMwhenMod00 PROC

mov bl, al
and bl, 00000111b
cmp bl, 00000110b
jne rmNot110


; skaitom poslinkio LowByte
cmp cx, 1
jne skipRefillLes2
call readToBuff
skipRefillLes2:
lodsb
mov [dLow], al
dec cx
call incLineNumber

;Skaitom poslinkio HighByte
cmp cx, 1
jne skipRefillLes3
call readToBuff
skipRefillLes3:
lodsb
mov [dHigh], al
dec cx
call incLineNumber

mov al, [dLow]
call printHexByte
mov al, [dHigh]
call printHexByte



call printDoubleTab
call printDIstring
call PrintLeftBracket
call printWordInBrackets
call PrintRightBracket

rmNot110:

ret
scanRMwhenMod00 ENDP




;---------

;formatavimo proceduros
printDoubleTab PROC
 push cx
 push ax

 mov cx, 2
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_doubleTab
 int 21h

 pop ax
 pop cx
 ret
printDoubleTab ENDP

printHNewline PROC
 push cx
 mov cx, 3
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_hNewLine
 int 21h
 pop cx
 ret
printHNewline ENDP

printNewline PROC
 push cx
 mov cx, 2
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_NewLine
 int 21h
 pop cx
 ret
printNewline ENDP

PrintLeftBracket PROC
push cx
mov cx, 1
mov ah, 40h
mov bx, destFHandle
lea dx, format
int 21h
pop cx
ret
PrintLeftBracket ENDP

PrintRightBracket PROC
push cx
mov cx, 1
mov ah, 40h
mov bx, destFHandle
lea dx, format +1
int 21h
pop cx
ret

PrintRightBracket ENDP
push cx
mov cx, 1
mov ah, 40h
mov bx, destFHandle
lea dx, format+1
int 21h
pop cx
ret

printWordInBrackets PROC

mov al, [dHigh]
call printHexByte

mov al, [dLow]
call printHexByte

ret
printWordInBrackets ENDP

printByteInBrackets PROC
push cx

mov al, 0
call printHexByte

mov al, [dLow]
call printHexByte

mov cx, 1
lea dx, format + 1
mov ah, 40h
mov bx, destFHandle
int 21h

pop cx

ret
printByteInBrackets ENDP

printDIstring PROC
 push cx
 push ax

 mov al, [regBufferCount]

 mov ch, 0
 mov cl, [regBufferCount]


 mov ah, 40h
 mov bx, destFHandle
 lea dx, regBuffer
 int 21h

pop ax
 pop cx
 ret
printDIstring ENDP

printOperandSeparator PROC
 push cx
 mov cx, 2
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_OperandSeparator
 int 21h
 pop cx
 ret
printOperandSeparator ENDP

fillRegBuffer PROC

;aprasysiu tai pradzioj scan ciklo
	;lea di, regBuffer
	push cx
	push si

	mov ch, 0
	mov cl, bh

	pushToBuffer2:
	push bx
	mov bl, [si]
	mov [di], bl
	pop bx
	inc si
	inc di
	inc [regBufferCount]
	loop pushToBuffer2

	pop si
	pop cx

	ret
fillRegBuffer ENDP



modregrm proc


mov bl, al
and bl, 11000000b
cmp bl, 00000000b
jne LESmodnot00

;nuskaitome reg, cia kai w=1
call scanREG
call scanRM

call scanRMwhenMod00

LESmodnot00:

mov bl, al
and bl, 11000000b
cmp bl, 10000000b
jne modNot10

call scanREG
call scanRM

mov bl, al
and bl, 00000111b
cmp bl, 00000110b
jne rmNot110v2
mov bh, 6
mov si, offset EAdress + 42
call fillRegBuffer
rmNot110v2:

; skaitom poslinkio LowByte
cmp cx, 1
jne skipRefillLes4
call readToBuff
skipRefillLes4:
lodsb
mov [dLow], al
dec cx
call incLineNumber

cmp cx, 1
jne skipRefillLes5
call readToBuff
skipRefillLes5:
lodsb
mov [dHigh], al
dec cx
call incLineNumber

call printHexByte
mov al, [dLow]
call printHexByte

call printDoubleTab

push si
mov bh, 1
mov si, offset format + 2
call fillRegBuffer
pop si

call printDIstring
call printWordInBrackets
call PrintRightBracket
modNot10:

mov bl, al
and bl, 11000000b
cmp bl, 01000000b
jne modNot01

;;----------------------------- 1byte
call scanREG
call scanRM

mov bl, al
and bl, 00000111b
cmp bl, 00000110b
jne rmNot110v3
mov bh, 6
mov si, offset EAdress + 42
call fillRegBuffer
rmNot110v3:

; skaitom poslinkio LowByte
cmp cx, 1
jne skipRefillLes6
call readToBuff
skipRefillLes6:
lodsb
mov [dLow], al
dec cx
call incLineNumber

mov [dHigh], 0
mov al, 0

call printHexByte
mov al, [dLow]
call printHexByte

call printDoubleTab

push si
mov bh, 1
mov si, offset format + 2
call fillRegBuffer
pop si

call printDIstring
call printWordInBrackets
call PrintRightBracket
modNot01:

mov bl, al
and bl, 11000000b
cmp bl, 11000000b
jne modNot11

call scanREG

;-------------------mod11
; ziurim w0 ar w1
mov bl, [wFlag]
cmp bl, 1
jne LESnot1
call scanRM00w1
jmp LEScontinue3
LESnot1:
call scanRM00w0
LEScontinue3:

call printDoubleTab
call printDIstring

modNot11:

call printNewline

ret
modregrm ENDP

com_xchg2 PROC
call printHexByte

mov bl, al
and bl, 00000001b
cmp bl, 00000001b
je w11
mov [wFlag], 0
jmp continue11
w11:
mov [wFlag], 1
continue11:

cmp cx, 1
jne skipRefilldiv1
call readToBuff
skipRefilldiv1:
lodsb
dec cx

call printHexByte
call incLineNumber

push si
mov bh, 5
mov si, offset com_names + 25
call fillRegBuffer
pop si


call modregrm


mov [regBufferCount], 0


ret
com_xchg2  ENDP


end START

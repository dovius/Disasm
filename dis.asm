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
com_names 	db	'DIV$'	;0
			db	'IDIV$'	;4
			db	'IN$'	;9
			db	'IRET$'	;12
			db	'INT$'	;17
			db	'LES$'	;21
			db	'XCHG$' ;25
			db	'TEST$' ;30
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
			db 'bp$';12
			db 'sp$';15
			db 'si$';18
			db 'di$';21
EAdress		db '[bx+si$' ;0
			db '[bx+di$' ;7
			db '[bp+si$' ;14
			db '[bp+di$' ;21
			db '[si   $' ;28
			db '[di   $' ;35
			db '[bp   $' ;42
			db '[bx   $' ;49
;---------------------------------------




sourceF   	db 'test.com'
sourceFHandle	dw ?

destF   	db 'asm.asm'
destFHandle 	dw ?

buffer    db 100 dup (?)



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

call printLineNumber

;in portas****************************
mov bl, al
and bl, 11111110b
cmp bl, 11100100b
jne not_in2
call com_in2

;in be porto**************************
not_in2:
cmp bl, 11101100b
jne not_in
call com_in

;XCHG********************************
not_in:
and bl, 11111000b
cmp bl, 10010000b
jne not_xchg
call com_xchg

;IRET********************************
not_xchg:
cmp al, 11001111b
jne not_iret
call com_iret

;INT su kodu************************
not_iret:
cmp al, 11001101b
jne not_int2
call com_int2

; INT 3*****************************
not_int2:
cmp al, 11001100b
jne not_int
call com_int

; Nezinoma komanda******************
not_int:
call com_unk


inc_lineCount:
call incLineNumber

loop	atrenka
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

		pop si
    ret
IntegerToHexFromMap ENDP

printLineNumber PROC

  push cx
  push si
	push ax

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
	nereikTvarkytiDidelioHex:
	inc [lineCount]
	; ---
	ret
incLineNumber ENDP


com_unk PROC
call printHexByte
push cx
 mov cx, 23
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_unkn
 int 21h
 pop cx
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
ret              	; jei nenuskaite
readToBuff ENDP

printHexByte PROC
push cx
mov di, OFFSET HEX_Out
call IntegerToHexFromMap
mov cx, 2
mov ah, 40h
mov bx, destFHandle
lea dx, HEX_Out
int 21h
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
 
push cx
mov cx, 2
mov ah, 40h
mov bx, destFHandle
mov dx, offset mod11w1reg + 0
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
com_xchg ENDP
;---------

;formatavimo proceduros
printDoubleTab PROC
 push cx
 mov cx, 2
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_doubleTab
 int 21h
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


end START

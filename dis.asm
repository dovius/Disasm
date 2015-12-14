;; Programa reaguoja i perduodamus parametrus
;; isveda pagalba, jei nera nurodyti reikiami parametrai
;; source failas skaitomas dalimis
;; destination failas rasomas dalimis
;; jei destination failas jau egzistuoja, jis yra isvalomas
;; jei source failas nenurodytas - skaito iš stdin iki tuščios naujos eilutės
;; galima nurodyti daugiau nei vieną source failą - juos sujungia
.model small
.stack 100H

.data

apie    		db 'mini disasembleris'
err_d    		db 'Destination failo nepavyko atidaryti rasymui',13,10,'$'
err_s    		db 'Source failo nepavyko atidaryti skaitymui',13,10,'$'
lineCount 	dw 0   ;desinys  baitas eiles nr skaiciaus
lineCountH	dw 1   ;kairys  baitas eiles nr skaiciaus


HEX_Map   DB  '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
HEX_Out   DB  "00", 13, 10, '$'   ; string with line feed and '$'-terminator

spaceString  db '     '
lineStringAdd db ':  ', '$'

line_iret db 'CF', 9, 'IRET',13,10,'$'
line_unkn db 9, 'Neatpazinta komanda',13,10, '$'


sourceF   	db 'test.com'
sourceFHandle	dw ?

destF   	db 'asm.asm'
destFHandle 	dw ?

buffer    db 100 dup (?)

.code

;div	   1111 011w mod 110 r/m [poslinkis]
;idiv    1111 011w mod 111 r/m [poslinkis]
;in      1110 110w arba 1110 010w portas (vieno baito dydzio betarpiskas operandas)
;iret	   1100 1111
;int	   1100 1100 (INT 3) 11001101 kodas (visi kiti int kur kodas-1 baitas)
;les     1100 0100 mod reg r/m [poslinkis]  reg-<atm
;xchg	   1001 0000 (NOP/XCHG ax,ax) 1001 0xxx (x-registras, kai is x i ax)
;test	   1000 010w mod reg r/m [poslinkis]


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
jc	err_source		      ; CF set on error AX = error code.
mov	sourceFHandle, ax	  ; issaugojam filehandle

skaitom:
mov	bx, sourceFHandle
mov	dx, offset buffer       ; address of buffer in dx
mov	cx, 20              		; kiek baitu nuskaitysim
mov	ah, 3fh               	; function 3Fh - read from file
int	21h

mov	cx, ax                	; bytes actually read
cmp	ax, 0		               	; jei nenuskaite
jne	_6			; tai ne pabaiga

mov	bx, sourceFHandle	; pabaiga skaitomo failo
mov	ah, 3eh			; uzdaryti
int	21h
jmp _end

_6:
mov	si, offset buffer	; skaitoma is cia
mov	bx, destFHandle		; rasoma i cia


; cia prasideda pagrindine logika (apdoroja kiekviena baita)
atrenka:
lodsb  				; Load byte at address DS:(E)SI into AL

call printLineNumber


;cmp al, 11001111b
;jne not_iret
;call com_iret
;jmp inc_lineCount
;not_iret:

call com_unk


call incLineNumber

loop	atrenka
loop	skaitom

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
com_unk:

 push cx

 ;mov ah, 0
 mov di, OFFSET HEX_Out
 call IntegerToHexFromMap
 mov cx, 2
 mov ah, 40h
 mov bx, destFHandle
 lea dx, HEX_Out
 int 21h

	mov cx, 4
	lea dx, spaceString
	 mov bx, destFHandle
	 mov ah, 40h

	int 21h

 mov cx, 21
 mov ah, 40h
 mov bx, destFHandle
 lea dx, line_unkn
 int 21h

 pop cx

 ret
com_unk ENDP

end START

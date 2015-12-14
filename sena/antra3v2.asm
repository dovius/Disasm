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

apie    	db ''
err_s    	db ''
err_d    	db ''
testui    db 'ABC'

html1			db '<!DOCTYPE html> <html>',13,'<head>',13,'<title> </title>',13,'</head>',13,'<body> <code>',13,10,'$'
html2     db '</code> </body>',13,'</html>',13

sourceF  	db 'antra3.asm$'
sourceFHandle	dw ?
buffD		  DB 20 DUP("$")

destF   	db 'antra2.html$'
destFHandle 	dw ?

buffer    db 200 dup (?)
wordB     db 20 dup (0)
match     db 0
testS     db 0
testD			db 0
point			dw ?
temp      db 0
simbolis  db 0
bxFlag		db 0


newline 	 db '<br>'
commentD 	 db '<code style=color:grey>',3bh
redD		 	 db '<code style=color:red>',3bh
endcodeD   db '</code>'

red				 db 'ax ', 13, 13

.code

START:
mov	ax, @data
mov	es, ax			; es kad galetume naudot stosb funkcija: Store AL at address ES:(E)DI

;; destination failo pavadinimas
lea	di, destF

;; source failo pavadinimas
lea	di, sourceF

push	ds ; duom is .data
push	si ; duom is komandine eilute

mov	ax, @data
mov	ds, ax

;; rasymui
mov	dx, offset destF	; ikelti i dx destF - failo pavadinima
mov	ah, 3ch			; isvalo/sukuria faila - komandos kodas
mov	cx, 0			; normal - no attributes
int	21h			; INT 21h / AH= 3Ch - create or truncate file.
				;   Jei nebus isvalytas - tai perrasines senaji,
				;   t.y. jei pries tai buves failas ilgesnis - like simboliai isliks.

mov	ah, 3dh			; atidaro faila - komandos kodas
mov	al, 1			; rasymui
int	21h			; INT 21h / AH= 3Dh - open existing file.

mov	destFHandle, ax		; issaugom handle


; parasom pradzia i html ----
mov bx, destFHandle
mov cx, 70
mov ah, 40h
mov dx, offset html1
int 21h;
; ---------------------------

jmp	startConverting

startConverting:
mov [bxFlag], 0
mov	dx, offset sourceF	; failo pavadinimas
mov	ah, 3dh                	; atidaro faila - komandos kodas
mov	al, 0                  	; 0 - reading, 1-writing, 2-abu
int	21h			; INT 21h / AH= 3Dh - open existing file

mov	sourceFHandle, ax	; issaugojam filehandle

;-----------------------SKAITOM---------------------------------

skaitom:
call inputConfig

mov	cx, ax    			      	; bytes actually read
cmp	ax, 0										; jei nenuskaite
jne	_6											; tai ne pabaiga

;;;;; kai jau nebenuskaito nieko
call nothingToRead
jmp closeF

_6:
mov	si, offset buffer				; skaitoma is cia
mov	bx, destFHandle					; rasoma i cia

cmp	sourceFHandle, 0
jne	_7
cmp	byte ptr ds:[si], 13
jne	_7
jmp closeF

_7:

;-----------------------ATRENKA---------------------------------
mov al, [bxFlag]
cmp al, 0
jne cont12
mov bx, 0
mov [bxFlag], 1

cont12:
pop bx
atrenka:
lodsb  				; Load byte at address DS:(E)SI into AL

cmp al, 41h               ; compare al with "A"
jl next_char               ; jump to next character if less
cmp al, 5Ah               ; compare al with "Z"
jle found_letter           ; if al is >= "A" && <= "Z" -> found a letter
cmp al, 61h               ; compare al with "a"
jl next_char               ; jump to next character if less (since it's between "Z" & "a")
cmp al, 7Ah               ; compare al with "z"
jg next_char               ; above "Z" -> not a character
found_letter:

mov [wordB+bx], al
inc bx
jmp cont2

next_char:
mov [simbolis], al
cmp bx, 0
je cont1

;kai reikia atpazinti zodi
jmp checkRed
checkRedReturn:
cmp match,1
jne cont8
;atspausdint zodi su apdorojimu

call printCodeWithSpan
call printSimbol
;print last simbol
;
mov bx, 0
jmp cont9

cont8:
;atspausdinam zodi paprastai
call printCodeNoSpan
call printSimbol
;print las simbol
mov bx, 0
cont9:
jmp clearWordBuffer
afterClear:
jmp cont2

cont1:
; cia atspausdint viena char (ne raide)
call printSimbol

cont2:
mov match, 0
loop	atrenka
push bx


cmp cx, 0
dec cx
je skaitomBaige
jmp skaitom

;loop	skaitom

skaitomBaige:

clearWordBuffer:
push bx
mov bx, 0
loop1:
mov [wordB+bx], 1
inc bx
cmp bx, 20
jne loop1
pop bx
jmp afterClear


checkRed:
;mov si, redD
push bx
push ax
push si

; pradzioj
mov ax, 0 ; syntaxes
mov bx, 0 ; bufferio
lea si, red

; tesiam lyginima
cont7:
; lyginam data buffer su syntax buffer

mov al, [si]
mov ah, [wordB+bx]
cmp al, ' '
je cont10
cmp [wordB+bx], al
jne cont5

cont10:
; lyginam ar sutampa zodziai (galas_)
cmp [wordB+bx], 1
jne cont6
cmp al, ' '
jne cont6

; turim zodi
mov [match], 1
jmp exit3


cont6: ; jei dar ne pilnas syntax zodis

inc si
inc bx
jmp cont7 ; i tikrinimo pradzia, tesiam

cont5:

mov bx, 0

skipSpaces:
cmp al, ' '
je exit2
cmp al, 13
je exit4
inc si
mov al, [si]
jmp skipSpaces

exit2:
inc si
mov al, [si]
cmp al, 13
je exit3
jmp cont7
exit4:
mov [match], 0
jmp _7

exit3:
;surade zodi


pop si
pop ax
pop bx

jmp checkRedReturn

help:
mov	ax, @data
mov	ds, ax

mov	dx, offset apie
mov	ah, 09h
int	21h

jmp	_end

closeF:
;; uzdaryti dest
mov bx, destFHandle
mov ah, 40h
mov cx, 16
mov dx, offset html2
int 21h


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


;; procedures --------------------------------------------

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




printCodeWithSpan PROC near
push cx
push ax
push bx
push bx

mov bx, destFHandle
mov cx, 22
mov ah, 40h
mov dx, offset redD
int 21h;

pop bx
mov cx, bx
mov bx, destFHandle
mov ah, 40h
mov dx, offset wordB
int 21h;

mov bx, destFHandle
mov cx, 7
mov ah, 40h
mov dx, offset endcodeD
int 21h;

pop bx
pop ax
pop cx
ret
printCodeWithSpan ENDP

printCodeNoSpan PROC near
push cx
push ax
push bx
push bx

pop bx
mov cx, bx
mov bx, destFHandle
mov ah, 40h
mov dx, offset wordB
int 21h;

pop bx
pop ax
pop cx
ret
printCodeNoSpan ENDP

printSimbol PROC near
push cx
push ax
push bx

mov al, [simbolis]
cmp al, 10
jne cont11

mov cx, 4
mov	ah, 40h
mov bx, destFHandle
lea dx, newline
int 21h

cont11:

mov bx, destFHandle
mov cx, 1
lea dx, [simbolis]
mov	ah, 40h			; INT 21h / AH= 40h - write to file
int	21h

pop bx
pop ax
pop cx
ret
printSimbol ENDP

;netelpa loop
inputConfig PROC near
mov	bx, sourceFHandle
mov	dx, offset buffer       ; address of buffer in dx
mov	cx, 20       			  		; kiek baitu nuskaitysim
mov	ah, 3fh      				   	; function 3Fh - read from file
int	21h
ret
inputConfig ENDP



nothingToRead PROC near
mov	bx, sourceFHandle				; pabaiga skaitomo failo
mov	ah, 3eh									; uzdaryti
int	21h
ret
nothingToRead ENDP

end START

.model small ;asdasd 1
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

buffer    db 202 dup (?)
wordB     db 20 dup (0)
match     db 0
testS     db 0
testD			db 0
point			dw ?
temp      db 0
simbolis  db 0
bxFlag    db 0
commentFlag db 0
tagFlag 	db 0

newline 	 db '<br>'
commentD 	 db '<code style=color:#B2B2B2>' ; dvigubos kabutes
redD		 	 db '<code style=color:#9F3538>',59
blueD		 	 db '<code style=color:#406C81>',59
orangeD	 	 db '<code style=color:#CE6E2D>',59
pinkD	 	 db '<code style=color:#A859F2>',59
endcodeD   db '</code>'
less			 db '&lt'
more			 db '&gt'
color 		 db 0  ; 0 -raudona, 1 - zalia 2- geltona 3 - ruzavai
count      db 0
numFlag    db 0

red				 db 'ax bx dx cx si di es sp ah al bh bl dh dl ds ', 13, 13
orange     db 'cmp ret mov jmp push lea pop int jmp call inc dec xor or and jne je jz jc lodsb jl jg loop stosb ', 13, 13


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

mov [bxFlag], 0
mov [commentFlag], 0

jmp	startConverting

startConverting:
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
mov	bx, sourceFHandle				; pabaiga skaitomo failo
mov	ah, 3eh									; uzdaryti
int	21h
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

mov al, [bxFlag]
cmp al, 0
je popint
pop bx
jmp atrenka


popint:
mov bx, 0
mov [bxFlag], 1

atrenka:
;-----------------------ATRENKA---------------------------------
lodsb  				; Load byte at address DS:(E)SI into AL

mov ah, [commentFlag]
cmp ah, 0
jne cont13
cmp al, 59 ; tikrinam del ';'
jne cont13
; suradom ; ir pries tai nebuvo
mov [commentFlag] , 1
call printComment

cont13:

cmp al, 41h               ; compare al with "A"
jl next_char               ; jump to next character if less
cmp al, 5Ah               ; compare al with "Z"
jle found_letter           ; if al is >= "A" && <= "Z" -> found a letter
cmp al, 61h               ; compare al with "a"
jl next_char               ; jump to next character if less (since it's between "Z" & "a")
cmp al, 7Ah               ; compare al with "z"
jg next_char               ; above "Z" -> not a character
found_letter:

push ax
mov [simbolis], al
mov ah, [commentFlag]
cmp ah, 1
pop ax
jne forJump
jmp cont1
forJump:

mov [wordB+bx], al
inc bx
jmp cont2

next_char:
mov ah, [commentFlag]
cmp ah, 1
je neskaicius

; jeigu _ tai pridedam pr zodzio
cmp al, 95
je found_letter

;tikrinam, kad pirmas nebutu skaicius
cmp bx, 0
je neraide

cmp al, 48             ; compare
jl neskaicius      ; jump to next character if less
cmp al, 57             ; compare al
jle found_letter


neraide:

cmp al, 48             ; compare al
jl neskaicius
cmp al, 57             ; compare al
jle skaicius2
jmp neskaicius

skaicius2:
mov [numFlag], 1
mov [color], 3
jmp found_letter

neskaicius:

cmp al, ':'
jne cont15
mov [wordB+bx], al
mov [tagFlag], 1
inc bx
mov [match], 1
mov [color], 1
jmp checkRedReturn

cont15:

mov [simbolis], al
cmp bx, 0
je cont1

mov ah, [numFlag]
cmp ah, 1
je printWithS

;kai reikia atpazinti zodi
jmp checkRed
checkRedReturn:



cmp match,1
jne cont8
;atspausdint zodi su apdorojimu
printWithS:
call printCodeWithSpan
mov [numFlag], 0
mov [color], 0

push ax
mov al, [tagFlag]
cmp [tagFlag], 1
je cont19
pop ax
;je cont16

call printSimbol
;print last simbol
cont19:
mov [tagFlag], 0

cont16:

;
mov bx, 0
jmp cont9

cont8:
;atspausdinam zodi paprastai
call printCodeNoSpan
call printSimbol

;print last simbol
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
; ------- loop atrenka
;loop	atrenka

cmp cx, 0
dec cx
je atrenkaBaige
jmp atrenka

atrenkaBaige:

push bx

; ------- loop skaito
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
mov [count], 0
lea si, red
mov [color], 0


checkloop:
mov ah, [count]
inc ah
mov [count],ah
;inc [count]

; pradzioj
mov ax, 0 ; syntaxes
mov bx, 0 ; bufferio


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

jmp exit5


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

mov [color], 2
mov ax, 0 ; syntaxes
mov bx, 0 ; bufferio
lea si, orange
cmp [count],2
je exit5

jmp checkloop

exit5:

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


mov al, [color]
cmp al, 0
je raudonai

cmp al, 1
je melynai

cmp al, 2
je oranzinei

cmp al, 3
je ruzavai

melynai:
mov dx, offset blueD
mov cx, 26
jmp setDestination

oranzinei:
mov dx, offset orangeD
mov cx, 26
jmp setDestination

raudonai:
mov cx, 26
mov dx, offset redD
jmp setDestination

ruzavai:
mov cx, 26
mov dx, offset pinkD


setDestination:
mov bx, destFHandle
mov ah, 40h

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

mov ah, [commentFlag]
cmp ah, 1
jne cont14

mov cx, 7
mov	ah, 40h
mov bx, destFHandle
lea dx, endcodeD
int 21h

mov [commentFlag], 0

cont14:

mov cx, 4
mov	ah, 40h
mov bx, destFHandle
lea dx, newline
int 21h

cont11:


cmp al, 60
jne cont17

mov bx, destFHandle
mov cx, 3
lea dx, less
mov	ah, 40h			; INT 21h / AH= 40h - write to file
int	21h
jmp pabaiga2


cont17:

cmp al, 62
jne cont18

mov bx, destFHandle
mov cx, 3
lea dx, more
mov	ah, 40h			; INT 21h / AH= 40h - write to file
int	21h
jmp pabaiga2



cont18:

mov bx, destFHandle
mov cx, 1
lea dx, [simbolis]
mov	ah, 40h			; INT 21h / AH= 40h - write to file
int	21h

pabaiga2:
pop bx
pop ax
pop cx
ret
printSimbol ENDP

inputConfig PROC near
mov	bx, sourceFHandle
mov	dx, offset buffer       ; address of buffer in dx
mov	cx, 100       			  		; kiek baitu nuskaitysim
mov	ah, 3fh      				   	; function 3Fh - read from file
int	21h
ret
inputConfig ENDP

printComment PROC near
push cx
push ax
push bx

mov [numFlag], 0
mov bx, destFHandle
mov cx, 26
mov ah, 40h
mov dx, offset commentD
int 21h;

pop bx
pop ax
pop cx
ret;nu nx
printComment ENDP;bbz

end START

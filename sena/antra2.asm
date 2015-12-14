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

sourceF  	db 'a2.asm$'
sourceFHandle	dw ?

destF   	db 'antra2.html$'
destFHandle 	dw ?

buffer    db 200 dup (?)
bffScan   db 20
bufferStart dw ?
buffer2   db 20 dup (?)
counter   dw 0   ;skaiciuos kelintas simbolis is .data->info apie sintakse dalies
matchTest dw 1   ;
simbolis 	db ?
handler   db 0
sum				db 0
flag1			db 0


newline 	 db '<br>',10
commentD 	 db '<code style=color:grey>',3bh
redD       db '<code style=color:red>',3bh
endcodeD   db '</code>'

red				 db 'ax bx cx dx ', 13, 13

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
mov	dx, offset sourceF	; failo pavadinimas
mov	ah, 3dh                	; atidaro faila - komandos kodas
mov	al, 0                  	; 0 - reading, 1-writing, 2-abu
int	21h			; INT 21h / AH= 3Dh - open existing file

mov	sourceFHandle, ax	; issaugojam filehandle

skaitom:
mov	bx, sourceFHandle
mov	dx, offset buffer       ; address of buffer in dx
mov	cx, 20       			  		; kiek baitu nuskaitysim
mov	ah, 3fh      				   	; function 3Fh - read from file
int	21h

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

mov bufferStart, si
atrenka:
lodsb  				; Load byte at address DS:(E)SI into AL
push	cx			; pasidedam cx;

call	replace

;mov	ah, 40h			; INT 21h / AH= 40h - write to file
;int	21h

pop	cx
cmp matchTest, 0
je reset

continue:
mov flag1, 0
;jc	help			; CF set on error; AX = error code.


mov sum, 0
loop	atrenka
loop	skaitom

reset:
cmp sum, 1
je sum_ne_1
mov si, bufferStart
sum_ne_1:
; syntax buffery praleisti tarpus
push bx

next_command_loop:
mov bx, counter
cmp [red+bx], ' '
je next_command_end
inc [counter]
cmp [red+bx], 13
je loopforbuffer
jmp next_command_loop
next_command_end:
inc [counter]

mov bx, counter
cmp [red+bx], 13
jne cont

loopforbuffer:
; reikes http://stackoverflow.com/questions/9617877/assembly-jg-jnle-jl-jnge-after-cmp panaudot
mov [counter], 0
lodsb

;tikrinam ar al yra raidziu intervale, jas praleidziam

cmp flag1, 1
je next_char

cmp al, 41h               ; compare al with "A"
jl next_char               ; jump to next character if less
cmp al, 5Ah               ; compare al with "Z"
jle found_letter           ; if al is >= "A" && <= "Z" -> found a letter
cmp al, 61h               ; compare al with "a"
jl next_char               ; jump to next character if less (since it's between "Z" & "a")
cmp al, 7Ah               ; compare al with "z"
jg next_char               ; above "Z" -> not a character
found_letter:
jmp loopas
next_char:
mov flag1, 1

cmp al, ' '
je loopas
cmp al, ','
je loopas
jmp exit
loopas:
loop loopforbuffer

exit:
dec si
mov bufferStart, si

pop bx
jmp continue

cont: ; (syntax)  TODO next word from buffer
pop bx
jmp continue

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
replace PROC near

;push dx
;lea dx red

;tikrinam simboli is bufferio su sintakses buferiu
push bx
mov bx, counter
inc [counter]
cmp al, [red+bx]
jne setMTzero
inc [matchTest]

; dvigubas cmp
cmp al, ' '
jne compareNext
cmp [red+bx], ' '
jne compareNext
;cmp al, ','
;jne compareNext

mov sum, 1
dec si ;(jei bugins) ->loop for buffer lodsb

mov matchTest, 0



compareNext:
;jei rastas endline zenklas
pop bx
cmp al, 10
je newl

;jei rastas comment zenklas
cmp al, 3bh
je cmt

;atspausdina simboli (al) atejusi i funkcija replace
symbol:
mov cx, 1
mov simbolis, al
lea dx, simbolis
ret

;; newline detected
newl:
cmp handler, 1 ; jei komentaro eilutei rastas endline
je endcode ; dedam, </code> (komentarui)
lea dx, newline ; dedam br
mov cx, 5
mov handler, 0 ; baigiasi eilute tuo paciu ir komentaras
ret

newl_next: ; kai ateinam su "</code>" dx'e
mov ah, 40h ; atspausdinam "</code>"
int 21h

lea dx,newline  ;atspausdinam <br>
mov cx, 5
mov handler, 0 ;isjungiam komentaro handler
ret

;isvedam </code>
endcode:
lea dx, endcodeD
mov cx, 7
cmp handler, 1 ;jei komentaro eilutes pabaigoj newline
je newl_next
ret

;jei rastas komentaro simbolis
cmt:
cmp handler, 1 ;jeigu is eiles keli komentaro simboliai
je symbol
lea dx, commentD ;dedam komentaro tag'a
mov cx, 24
mov handler, 1 ; isimenam kad komentaras jau naudotas
ret


testing:
mov cx, 3
lea dx, testui
ret

setMTzero:
mov matchTest, 0 ; if al != buffer
jmp compareNext

replace ENDP

end START

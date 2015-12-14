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

apie    	db 'Programa pakeicia skaitmenis zodziais',13,10,9,'2_num_z.exe [/?] destinationFile [ - | sourceFile1 [sourceFile2] [...] ]',13,10,13,10,9,'/? - pagalba',13,10,'$'
err_s    	db 'Source failo nepavyko atidaryti skaitymui',13,10,'$'
err_d    	db 'Destination failo nepavyko atidaryti rasymui',13,10,'$'

sourceF   	db 12 dup (0)
sourceFHandle	dw ?

destF   	db 12 dup (0)
destFHandle 	dw ?



buffer  	db 20 dup (?)
simbolis 	db ?

nulis   	db 'nulis$'
vienas  	db 'vienas$'
du      	db 'du$'
trys    	db 'trys$'
keturi  	db 'keturi$'
penki   	db 'penki$'
sesi    	db 'sesi$'
septyni 	db 'septyni$'
astuoni 	db 'astuoni$'
devyni  	db 'devyni$'


.code

START:
mov	ax, @data
mov	es, ax			; es kad galetume naudot stosb funkcija: Store AL at address ES:(E)DI

mov	si, 81h        		; programos paleidimo parametrai rasomi segmente es pradedant 129 (arba 81h) baitu

call	skip_spaces

mov	al, byte ptr ds:[si]	; nuskaityti pirma parametro simboli
cmp	al, 13			; jei nera parametru
jne	_1
jmp	help			; tai isvesti pagalba
_1:

;; ar reikia isvesti pagalba
mov	ax, word ptr ds:[si]
cmp	ax, 3F2Fh        	; jei nuskaityta "/?" - 3F = '?'; 2F = '/'
jne	_2
jmp	help                 	; rastas "/?", vadinasi reikia isvesti pagalba
_2:

;; destination failo pavadinimas
lea	di, destF
call read_filename		; perkelti is parametro i eilute
cmp	byte ptr es:[destF], '$' ; jei nieko nenuskaite
jne	_3
jmp	help
_3:

;; source failo pavadinimas
lea	di, sourceF
call	read_filename		; perkelti is parametro i eilute

push	ds
push	si

mov	ax, @data
mov	ds, ax

;; rasymui
mov	dx, offset destF	; ikelti i dx destF - failo pavadinima
mov	ah, 3ch			; isvalo/sukuria faila - komandos kodas
mov	cx, 0			; normal - no attributes
int	21h			; INT 21h / AH= 3Ch - create or truncate file.
				;   Jei nebus isvalytas - tai perrasines senaji,
				;   t.y. jei pries tai buves failas ilgesnis - like simboliai isliks.
jnc	_4			; CF set on error AX = error code.
jmp	err_destination
_4:
mov	ah, 3dh			; atidaro faila - komandos kodas
mov	al, 1			; rasymui
int	21h			; INT 21h / AH= 3Dh - open existing file.
jnc	_5			; CF set on error AX = error code.
jmp	err_destination
_5:
mov	destFHandle, ax		; issaugom handle

jmp	startConverting

readSourceFile:
pop	si
pop	ds

;; source failo pavadinimas
lea	di, sourceF
call	read_filename		; perkelti is parametro i eilute

push	ds
push	si

mov	ax, @data
mov	ds, ax

cmp	byte ptr ds:[sourceF], '$' ; jei nieko nenuskaite
jne	startConverting
jmp	closeF

startConverting:
;; atidarom
cmp	byte ptr ds:[sourceF], '$' ; jei nieko nenuskaite
jne	source_from_file

mov	sourceFHandle, 0
jmp	skaitom

source_from_file:
mov	dx, offset sourceF	; failo pavadinimas
mov	ah, 3dh                	; atidaro faila - komandos kodas
mov	al, 0                  	; 0 - reading, 1-writing, 2-abu
int	21h			; INT 21h / AH= 3Dh - open existing file
jc	err_source		; CF set on error AX = error code.
mov	sourceFHandle, ax	; issaugojam filehandle

skaitom:
mov	bx, sourceFHandle
mov	dx, offset buffer       ; address of buffer in dx
mov	cx, 20         		; kiek baitu nuskaitysim
mov	ah, 3fh         	; function 3Fh - read from file
int	21h

mov	cx, ax          	; bytes actually read
cmp	ax, 0			; jei nenuskaite
jne	_6			; tai ne pabaiga

mov	bx, sourceFHandle	; pabaiga skaitomo failo
mov	ah, 3eh			; uzdaryti
int	21h
jmp	readSourceFile		; atidaryti kita skaitoma faila, jei yra
_6:
mov	si, offset buffer	; skaitoma is cia
mov	bx, destFHandle		; rasoma i cia

cmp	sourceFHandle, 0
jne	_7
cmp	byte ptr ds:[si], 13
je	closeF
_7:
push	cx			; save big loop CX

atrenka:
lodsb  				; Load byte at address DS:(E)SI into AL
push	cx			; pasidedam cx
call	replace
mov	ah, 40h			; INT 21h / AH= 40h - write to file
int	21h
pop	cx
jc	help			; CF set on error; AX = error code.
loop	atrenka

pop	cx
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

replace PROC near

cmp al, '0'
je sk0
cmp al, '1'
je sk1
cmp al, '2'
je sk2
cmp al, '3'
je sk3
cmp al, '4'
je sk4
cmp al, '5'
je sk5
cmp al, '6'
je sk6
cmp al, '7'
je sk7
cmp al, '8'
je sk8
cmp al, '9'
je sk9
mov cx, 1
mov simbolis, al
lea dx, simbolis
ret

sk0:
lea dx, nulis
mov cx, 5        ;nurodom kiek baitu spauzdinsim
ret
sk1:
lea dx, vienas
mov cx, 6
ret
sk2:
lea dx, du
mov cx, 2
ret
sk3:
lea dx, trys
mov cx, 4
ret
sk4:
lea dx, keturi
mov cx, 6
ret
sk5:
lea dx, penki
mov cx, 5
ret
sk6:
lea dx, sesi
mov cx, 4
ret
sk7:
lea dx, septyni
mov cx, 7
ret
sk8:
lea dx, astuoni
mov cx, 7
ret
sk9:
lea dx, devyni
mov cx, 6
ret

replace ENDP

end START

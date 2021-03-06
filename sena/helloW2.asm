.model small			;http://alexfru.narod.ru/os/c16/c16.html#MemoryModels
.stack 100h

.data
	TimePrompt 		db "Is it after 12 noon (Y/N)? $" 
	GoodMorningMessage 	db 13,10,"Good morning, world!",13,10,"$"                 ; ka daro 13, 10?????
	GoodAfternoonMessage 	db 13,10,"Good afternoon, world!",13,10,"$"
	DefaultMessage 		db 13,10,"Good day, world!",13,10,"$"
.code

start:
	mov 	dx, @data            	; perkelti data i registra ax
	mov 	ds, dx               	; nustatyti ds rodyti i data segmenta

	mov     dx, offset TimePrompt 	; rodyti i pranesima
        mov     ah, 09h		      	; int: komanda, isvesti i ekrana
        int     21h			; isvesti klausima

	mov 	ah, 1			; int: komanda, nuskaityti 1 simboli
	int 	21h			; gauti simboli
	or	al, 20h			; padaryti mazaja raide, kitaip sakant 00100000b, t.y. mazosios yra: 01100001b, diziosios yra nuo: 001000001b

	cmp	al, "y"			; jei ivede y
	je	IsAfternoon		; sokti i IsAfternoon

	cmp	al, "n"			; jei ivede n
	je	IsMorning		; sokti i IsMorning

	mov	dx, offset DefaultMessage ;kitu atveju standartinis pranesimas
	jmp	DisplayGreeting		  ;sokti i atvaizdavima

IsAfternoon:
	mov	dx, offset GoodAfternoonMessage ;afternoon pranesimas
	jmp	DisplayGreeting			;sokti i atvaizdavima

IsMorning:
	mov	dx, offset GoodMorningMessage 	;morning pranesimas

DisplayGreeting:
        mov     ah, 09h		      	; int: komanda, isvesti i ekrana
        int     21h			; isvesti klausima
        
	mov 	ah, 4ch 		; griztame i dos'a
	mov 	al, 0 		        ; be klaidu
	int 	21h                     ; dos'o INTeruptas
end start

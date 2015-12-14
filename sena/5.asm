.model small
.stack 100h

.data
	output	db	10 dup(0)
.code

start:
	mov 	dx, @data       ; perkelti data i registra ax
	mov 	ds, dx          ; nustatyti ds rodyti i data segmenta

	mov	si, offset output + 9 	; si nurodyti á eilutës paskutiná simbolá
	mov	byte ptr [si], '$'     	; ákelti ten pabaigos simbolá

	mov	ax, 65535	; paruoðti iðvedimui deðimtainá skaièiø, max 2 baitai, t.y. 2^16 - 1 = 65536 - 1 = 65535
	mov	bx, 10		; dalinti reikës ið 10

	PUSH si
	PUSH ax
	PUSH bx
	PUSH es
	mov ah, 1h
	mov si, 1h
	POP bx
	POP ax
	POP si

asc2:	
	mov	dx, 0		; iðvalyti dx, nes èia bus liekana po div
	div	bx              ; div ax/bx, ir liekana padedama dx
	add 	dx, '0'         ; pridëti 48, kad paruoðti simbolá iðvedimui
	dec 	si		; sumaþinti si - èia bus padëtas skaitmuo
	mov	[si], dl	; padëti skaitmená
	
	cmp 	ax, 0		; jei jau skaièius iðdalintas
        jz 	print  	        ; tai eiti á pabaigà
        jmp 	asc2            ; kitu atveju imti kità skaitmená

print:
        mov	ah, 9            ; atspausdinti skaitmenis
        mov	dx, si
        int	21h
	
	mov 	ah, 4ch 	; sustabdyti programa - http://www.computing.dcu.ie/~ray/teaching/CA296/		notes/8086_bios_and_dos_interrupts.html#int21h_4Ch
	mov 	al, 0 		; be klaidu = 0
	int 	21h             ; 21h -  dos pertraukimmas - http://www.computing.dcu.ie/~ray/teaching/CA296/notes/8086_bios_and_dos_interrupts.html#int21h
end start

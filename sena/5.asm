.model small
.stack 100h

.data
	output	db	10 dup(0)
.code

start:
	mov 	dx, @data       ; perkelti data i registra ax
	mov 	ds, dx          ; nustatyti ds rodyti i data segmenta

	mov	si, offset output + 9 	; si nurodyti � eilut�s paskutin� simbol�
	mov	byte ptr [si], '$'     	; �kelti ten pabaigos simbol�

	mov	ax, 65535	; paruo�ti i�vedimui de�imtain� skai�i�, max 2 baitai, t.y. 2^16 - 1 = 65536 - 1 = 65535
	mov	bx, 10		; dalinti reik�s i� 10

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
	mov	dx, 0		; i�valyti dx, nes �ia bus liekana po div
	div	bx              ; div ax/bx, ir liekana padedama dx
	add 	dx, '0'         ; prid�ti 48, kad paruo�ti simbol� i�vedimui
	dec 	si		; suma�inti si - �ia bus pad�tas skaitmuo
	mov	[si], dl	; pad�ti skaitmen�
	
	cmp 	ax, 0		; jei jau skai�ius i�dalintas
        jz 	print  	        ; tai eiti � pabaig�
        jmp 	asc2            ; kitu atveju imti kit� skaitmen�

print:
        mov	ah, 9            ; atspausdinti skaitmenis
        mov	dx, si
        int	21h
	
	mov 	ah, 4ch 	; sustabdyti programa - http://www.computing.dcu.ie/~ray/teaching/CA296/		notes/8086_bios_and_dos_interrupts.html#int21h_4Ch
	mov 	al, 0 		; be klaidu = 0
	int 	21h             ; 21h -  dos pertraukimmas - http://www.computing.dcu.ie/~ray/teaching/CA296/notes/8086_bios_and_dos_interrupts.html#int21h
end start

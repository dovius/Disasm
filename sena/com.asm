cseg segment 'code'
    assume cs:cseg, ds:cseg, es:cseg, ss:cseg
    org 100h
start:

	; TODO - neina sukurt failo, kai naudoju ptr_str2 kintamaji

	;IN AL,imm8   immed - paprastas sk.
	in al, 4h
	IN AL,DX

	test al, ah
	test al, 4
	test al, trecias

	xchg al, ah
	xchg bx, ax
	xchg ketvirtas, ax

;	les DI, ptr_str2

		mov dx, 0
		mov ax, 1234
		mov bx, 10
	div bx

	MOV AX,-21             ;put -21 into AX for dividend
	MOV BH,5               ;put 5 into BH for divisor
	IDIV BH                ;divide AX by BH: AL=-4, AH=-1 - correct

	mov ah, 4
	mov al, 3
	int 21h


	mov    ax,4c00H
	int    21H

	trecias  db 0
	ketvirtas dw ?
	str2 db 'My second string. $'
;	ptr_str2 dd str2

	cseg ends

end start

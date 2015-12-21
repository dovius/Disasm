.model small
.code
org    100H

begin:
	jmp    main

	pirmas   	DB  	 "Labas", 10, 13, "$"
	antras   	DB  	 "Pranesimas$"
	trecias  	db 			0
	ketvirtas	dw 			?
	str2     	db 			'My second string. $'
	x        	dw      10
	y     	 	dw      15
	adr_x  	 	dd      x
	adr_y  	 	dd      y
	ptr_str2 	dd 			str2

main    proc    far        ; <=== Entry point (main function)

mov     ax,cs
mov     ds,ax
		;IN AL,imm8   immed - paprastas sk.
		in al, 4h
		IN AL,DX

		xchg ketvirtas, ax

		test al, ah
		test al, 4
		test al, trecias

		xchg ketvirtas, ax
		xchg al, ah

		xchg	ax, bx
		xchg	ax, dx
		xchg	ax, bp


		MOV AX,-21
		MOV BH,5
		IDIV BH

		xchg bx, ax



		; del situ negaliu segeneruoti .COM failo ========
		les di,adr_y
		mov dx, 0
		mov ax, 1234
		MOV AX,-21
		MOV BH,5
		IDIV BH
		les DI, ptr_str2
	;	les si, adr_y
		; =================================================

		mov dx, 0
		mov ax, 1234
		mov bx, 10
		div bx

		MOV AX,-21
		MOV BH,5
		IDIV BH

		mov ah, 4
		mov al, 3
		int 21h

		call func

    mov    ax,4c00H
    int    21H

main    endp                ;<=== End function

func PROC near
in al, dx
iret
func ENDP


end begin                ;<=== End program


	;; tasm mk_com
	;; tlink /t mk_com

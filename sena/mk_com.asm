.model small
.code
org    100H

begin:
	jmp    main

	pirmas   DB   "Labas", 10, 13, "$"
	antras   DB   "Pranesimas$"
	trecias  db 0
	ketvirtas dw ?
	str2 db 'My second string. $'
	res db 1000010101b
;	ptr_str2 dd str2

main    proc    far        ; <=== Entry point (main function)

		;IN AL,imm8   immed - paprastas sk.
		in al, 4h
		in AL,DX

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

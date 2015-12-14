; Programa: Nr. 11
; Užduoties sąlyga: Parašykite programą, kuri įveda simbolių eilutę ir atspausdina pozicijas rastų skaitmenų. Pvz.: įvedus abs daa52dd turi atspausdinti 7 8
; Atliko: Dovydas Vilimas III grupe 2 pogrupis

.model small
.stack 100h
	 
.data
	request		db 'Programa isveda pozicijas rastu skaitmenu', 0Dh, 0Ah, 'Iveskite simboliu eilute:', 0Dh, 0Ah, '$'
	error_len	db 'Jus neivedete nieko $'
	result    	db 0Dh, 0Ah, 'Rezultatas:', 0Dh, 0Ah, '$'
	buffer		db 255, ?, 255 dup (0)
	output		db 11 dup(0)

.code
 
start:
	MOV ax, @data                   ; perkelti data i registra ax
	MOV ds, ax                      ; perkelti ax (data) i data segmenta
	 
	; Isvesti uzklausa
	MOV ah, 09h
	MOV dx, offset request
	int 21h

	; skaityti eilute
	MOV dx, offset buffer           ; skaityti i buffer offseta 
	MOV ah, 0Ah                     ; eilutes skaitymo subprograma
	INT 21h                         ; dos'o INTeruptas

	; kartoti
	MOV si, offset buffer           ; priskirti source index'ui bufferio koordinates
	INC si                          ; pridedam 1 prie si , nes pirmas kiek simboliu ish viso
	MOV bh, [si]                    ; idedam i bh kiek simboliu is viso
	CMP bh, 0
	JZ error
	INC si                          ; pereiname prie pacio simbolio
	
	 
	; isvesti: rezultatas
	MOV ah, 09h
	MOV dx, offset result
	int 21h

	MOV bl, 0 			; nuo cia skaiciuosim pozicija /////
	
char:
	LODSB                        	; imti is es:si stringo dali ir dedame i al 
	
	CMP al, 30h			; ar skaicius ///
	JZ count			; sokam i skaiciavima //
	
	CMP al, 31h			
	JZ count
	
	CMP al, 32h			
	JZ count

	CMP al, 33h			
	JZ count
	
	CMP al, 34h			
	JZ count
	
	CMP al, 35h			
	JZ count
	
	CMP al, 36h			
	JZ count
	
	CMP al, 37h			
	JZ count
	
	CMP al, 38h			
	JZ count
	
	CMP al, 39h			
	JZ count

postcount:				; grizus is skaiciaus isvedimo ciklo
	 
	DEC bh                          ; atimti 1 is eilutes simboliu kiekio
	JZ ending                      	; jei bh = 0 , programa baigia darba
	INC bl							; einam prie sekancios pozicijos, isaugom reiksme
	JMP char                        ; kitaip sokti link kito simbolio
	 
error:
	MOV ah, 09h
	MOV dx, offset error_len
	INT 21h
	JMP start
	
count:								; isveda skaiciu
	
	PUSH ax
	PUSH bx
	PUSH dx ;ar tikrai reikia?
	PUSH si
	PUSH es
	
	mov	si, offset output + 9 	; si nurodyti á eilutës paskutiná simbolá
	mov	byte ptr [si], '$'     	; ákelti ten pabaigos simbolá
	
	mov ah, 0h  ; paruosiam ax registra
	mov al, bl  ; skaicius kuri noresim isvesti
	mov bx, 10  ; is ko dalinsime
	
asc2:
	
	mov	dx, 0		; iðvalyti dx, nes èia bus liekana po div
	div	bx              ; div ax/bx, ir liekana padedama dx
	add dx, '0'         ; pridëti 48, kad paruoðti simbolá iðvedimui
	dec si		; sumaþinti si - èia bus padëtas skaitmuo
	mov	[si], dl	; padëti skaitmená
	
	cmp ax, 0		; jei jau skaièius iðdalintas
    jz print  	        ; tai eiti á pabaigà
    jmp asc2            ; kitu atveju imti kità skaitmená

print:
    mov	ah, 09h         ; atspausdinti skaitmenis
    mov	dx, si
    int	21h

    mov	ah, 02h         ; atspausdinti skaitmenis
    mov	dl, ' '
    int	21h

	POP es
	POP si
	POP dx
	POP bx
	POP ax
	JMP postcount					; griztam i stringo apdorojimo cikla
	 
ending:
	MOV ax, 4c00h 		        ; griztame i dos'a
	INT 21h                        	; dos'o INTeruptas
	 
end start

; Programa: Nr. 11
; Užduoties sąlyga: Programa isveda skaitmenu pozicijas
; Atliko: Dovydas Vilimas

.model small
.stack 100h
	 
.data
	request		db 'Programa isveda pozicijas rastu skaitmenu', 0Dh, 0Ah, 'Iveskite simboliu eilute:', 0Dh, 0Ah, '$'
	error_len	db 'Ivesti galite ne daugiau 5 simboliu $'
	result    	db 0Dh, 0Ah, 'Rezultatas:', 0Dh, 0Ah, '$'
	buffer		db 100, ?, 100 dup (0)
	output		db	11 dup(0)

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
	INC si                          ; pereiname prie pacio simbolio
	 
	; isvesti: rezultatas
	MOV ah, 09h
	MOV dx, offset result
	int 21h

	MOV bl, 0 			; nuo cia skaiciuosim pozicija /////
	
char:
	LODSB                        	; imti is es:si stringo dali ir dedame i al 
	CMP al, 0dh                    	; jei char 0
	JZ error                    	; tai sokame i klaida
	
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
	INC bl
	JMP char                        ; kitaip sokti link kito simbolio
	 
error:
	MOV ah, 09h
	MOV dx, offset error_len
	INT 21h
	JMP start
	
count:								; isveda skaiciu
	MOV ah, 2
	MOV dl, bl
	INT 21h
	
	MOV ah, 2						; tarpas
	MOV dl, 20h
	INT 21h
	
	JMP postcount					; griztam i stringo apdorojimo cikla
	 
ending:
	MOV ax, 4c00h 		        ; griztame i dos'a
	INT 21h                        	; dos'o INTeruptas
	 
end start

; Programa: Nr. ---
; Užduoties sąlyga: ---
; Atliko: Vardas Pavardė

.model small
.stack 100h
	 
.data
	request		db 'Programa isveda binarini koda', 0Dh, 0Ah, 'Iveskite simboliu eilute:', 0Dh, 0Ah, '$'
	error_len	db 'Ivesti galite ne daugiau 5 simboliu $'
	result    	db 0Dh, 0Ah, 'Rezultatas:', 0Dh, 0Ah, '$'
	buffer		db 100, ?, 100 dup (0)
	eol       	db 0Dh, 0Ah, '$'

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
	
char:
	LODSB                        	; imti is es:si stringo dali ir dedame i al 
	CMP al, 0dh                    	; jei char 0
	JZ error                    	; tai sokame i klaida
	 
	; isvesti binarine sistema
	MOV bl, al                    	; perkelti simboli i bl
	MOV cx, 7                    	; nustatyti skaitliuka, kiek kartu suksis ciklas
	SHL bl, 1                    	; binarineje sistemoje perstumiame per viena vieta i kaire

print:
	MOV ah, 2                    	; isvedimui vieno simbolio
	MOV dl, '0'                    	; ideti '0' is anksto
	TEST bl, 10000000b            	; isvesti '0' arba '1' pagal pirmaji bita
	JZ zero                    	; jei nulis sokam, keisti nieko nereikia
	MOV dl, '1'                    	; kitokiu atveju ideti '1'
	 
zero:
	INT 21h                        	; dos'o INTeruptas
	SHL bl, 1                    	; binarineje sistemoje perstumti per viena vieta i kaire
	 
	loop print              	; kartoti kol cx = 7 kartus
	 
	MOV dl, " "                     ; iterpti tarpa, kad atskirtti simbolius
	INT 21h                         ; dos'o INTerruptas
	DEC bh                          ; atimti 1 is eilutes simboliu kiekio
	JZ ending                      	; jei bh = 0 , programa baigia darba
	JMP char                        ; kitaip sokti link kito simbolio
	 
error:
	MOV ah, 09h
	MOV dx, offset error_len
	INT 21h
	JMP start
	 
ending:
	MOV ax, 4c00h 		        ; griztame i dos'a
	INT 21h                        	; dos'o INTeruptas
	 
end start

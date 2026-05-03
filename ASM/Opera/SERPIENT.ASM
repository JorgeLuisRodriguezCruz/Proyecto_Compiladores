; =========================================================================
; Archivo: Serpiente.asm (Operaciones para Strings)
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; Descripción: Bitácora de operaciones del tipo Serpiente (Strings). 
;              Demuestra funciones de largo (escamas), busqueda (acechar) 
;              y concatenacion (enroscar).
; =========================================================================

pila segment stack 'STACK'
    dw 256 dup(0)
pila ends

datos segment
    msg_inicio DB "Iniciando Tour de Operaciones SERPIENTE (Strings V1.3)...", 10, 13, 10, 13, "$"
    
    ; Strings de prueba (Terminadas en $ para DOS)
    str_prueba1 DB "PasCat$"
    str_prueba2 DB " Compilador$"
    buffer_dest DB 50 DUP('$') ; Espacio en memoria para concatenar
    
    ; Mensajes del Tour
    msg_escamas DB " -> Prueba escamas ('PasCat')          | Largo = $"
    msg_acechar DB " -> Prueba acechar ('PasCat', 'C')     | Pos   = $"
    msg_enrosc  DB " -> Prueba enroscar ('PasCat' + 'Compilador') | Str   = $"
    
    msg_salto   DB 10, 13, "$"
    msg_fin     DB 10, 13, "Tour finalizado con exito.", 10, 13, "$"
datos ends

codigo segment
    assume cs:codigo, ds:datos, ss:pila

; =========================================================================
; 1. ESCAMAS (Largo del String) -> Retorna longitud en AX
; =========================================================================
EscamasSerpiente proc near
    push bp
    mov bp, sp
    mov bx, [bp+4]      ; Extrae el puntero (dirección) del string de la pila
    xor ax, ax          ; AX será nuestro contador (inicia en 0)

contar_escamas:
    mov cl, [bx]        ; Copia el carácter actual a CL
    cmp cl, '$'         ; ¿Es el fin del string?
    je fin_escamas      ; Si es $, termina
    inc ax              ; Aumenta contador
    inc bx              ; Mueve el puntero a la siguiente letra
    jmp contar_escamas

fin_escamas:
    pop bp
    ret 2               ; Limpia 2 bytes (1 puntero)
EscamasSerpiente endp

; =========================================================================
; 2. ACECHAR (Encontrar carácter) -> Retorna índice en AX (o -1 si no halla)
; =========================================================================
AcecharSerpiente proc near
    push bp
    mov bp, sp
    mov bx, [bp+6]      ; Puntero al string
    mov dx, [bp+4]      ; Carácter a buscar (está en DL)
    xor ax, ax          ; Índice actual = 0

buscar_letra:
    mov cl, [bx]
    cmp cl, '$'         ; ¿Fin del string sin encontrarlo?
    je no_encontrado
    cmp cl, dl          ; ¿El carácter actual es igual al buscado?
    je fin_acechar      ; ¡Lo encontró! Termina y AX tiene el índice
    
    inc ax              ; Aumenta índice
    inc bx              ; Siguiente letra
    jmp buscar_letra

no_encontrado:
    mov ax, -1          ; Retorna -1 si no existe

fin_acechar:
    pop bp
    ret 4               ; Limpia 4 bytes (Puntero + Carácter)
AcecharSerpiente endp

; =========================================================================
; 3. ENROSCAR (Concatenar) -> Copia Str1 y Str2 en un Buffer Destino
; =========================================================================
EnroscarSerpiente proc near
    push bp
    mov bp, sp
    mov di, [bp+8]      ; Puntero al Buffer Destino (donde quedará el resultado)
    mov si, [bp+6]      ; Puntero al String 1

copiar_str1:
    mov al, [si]
    cmp al, '$'
    je iniciar_str2
    mov [di], al        ; Copia letra al destino
    inc si
    inc di
    jmp copiar_str1

iniciar_str2:
    mov si, [bp+4]      ; Puntero al String 2

copiar_str2:
    mov al, [si]
    cmp al, '$'
    je fin_enroscar
    mov [di], al
    inc si
    inc di
    jmp copiar_str2

fin_enroscar:
    mov byte ptr [di], '$'  ; Asegura que el destino termine en $
    pop bp
    ret 6               ; Limpia 6 bytes (3 punteros)
EnroscarSerpiente endp

; =========================================================================
; 4. RUTINAS DE E/S Y UTILIDADES
; =========================================================================
rugirSerpiente proc near
    push bp
    mov bp, sp
    push ax
    push dx

    mov dx, [bp+4]      ; Extrae el puntero del string a imprimir
    mov ah, 09h         ; Función DOS para imprimir cadena hasta $
    int 21h
    
    pop dx
    pop ax
    pop bp
    ret 2
rugirSerpiente endp

rugirOveja proc near
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+4]      
    test ax, ax
    jns es_positivo     
    
    push ax             
    mov ah, 02h         
    mov dl, '-'
    int 21h
    pop ax
    neg ax              

es_positivo:
    mov cx, 0           
    mov bx, 10          
extraer_digitos:
    xor dx, dx          
    div bx              
    push dx             
    inc cx               
    test ax, ax         
    jnz extraer_digitos 
imprimir_digitos:
    pop dx              
    add dl, '0'         
    mov ah, 02h
    int 21h
    loop imprimir_digitos 

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2               
rugirOveja endp

ImprimirSalto proc near
    mov ah, 09h
    lea dx, msg_salto
    int 21h
    ret
ImprimirSalto endp

Principal proc far
    push ds
    xor ax, ax
    push ax
    mov ax, datos
    mov ds, ax

    mov ah, 09h
    lea dx, msg_inicio
    int 21h

    ; --- Tour 1: escamas ('PasCat') -> Debe imprimir 6 ---
    mov ah, 09h
    lea dx, msg_escamas
    int 21h
    
    lea ax, str_prueba1     ; Pasamos la DIRECCIÓN del string
    push ax
    call EscamasSerpiente
    
    push ax                 ; Imprimimos el resultado (número)
    call rugirOveja
    call ImprimirSalto

    ; --- Tour 2: acechar ('PasCat', 'C') -> Debe imprimir 3 ---
    mov ah, 09h
    lea dx, msg_acechar
    int 21h
    
    lea ax, str_prueba1     ; Dirección del string
    push ax
    mov ax, 'C'             ; Carácter a buscar
    push ax
    call AcecharSerpiente
    
    push ax                 ; Imprimimos el índice (3)
    call rugirOveja
    call ImprimirSalto

    ; --- Tour 3: enroscar ('PasCat', ' Compilador') -> 'PasCat Compilador' ---
    mov ah, 09h
    lea dx, msg_enrosc
    int 21h
    
    lea ax, buffer_dest     ; Puntero destino (donde guardar)
    push ax
    lea ax, str_prueba1     ; Puntero Str1
    push ax
    lea ax, str_prueba2     ; Puntero Str2
    push ax
    call EnroscarSerpiente

    lea ax, buffer_dest     ; Imprimimos el buffer resultante
    push ax
    call rugirSerpiente
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_fin
    int 21h

    mov ah, 4ch
    int 21h
Principal endp

codigo ends
end Principal
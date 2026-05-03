; =========================================================================
; Archivo: Huella.asm (Operaciones para Caracteres)
; Autores: 
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; Descripción: Bitácora de operaciones del tipo Huella (Char 8/16 bits). 
;              Demuestra funciones de validación (isDigit, isAlpha) y 
;              conversión de formato (toUpper, toLower).
; =========================================================================

pila segment stack 'stack'
    dw 256 dup(0)
pila ends

datos segment
    msg_inicio db "Iniciando Tour de Operaciones HUELLA...", 10, 13, 10, 13, "$"
    
    ; Mensajes del Tour
    msg_con1   db " -> Prueba conejo? ('7') | isDigit? = $"
    msg_con2   db " -> Prueba conejo? ('A') | isDigit? = $"
    msg_lob1   db " -> Prueba lobo? ('A')   | isAlpha? = $"
    msg_lob2   db " -> Prueba lobo? ('7')   | isAlpha? = $"
    msg_sal    db " -> Prueba salvaje ('b') | toUpper  = $"
    msg_doc    db " -> Prueba docil ('G')   | toLower  = $"
    
    ; Booleanos para imprimir
    str_vivo   db "vivo (1)$"
    str_muerto db "muerto (0)$"
    
    msg_salto  db 10, 13, "$"
    msg_fin    db 10, 13, "Tour finalizado con exito.", 10, 13, "$"
datos ends

codigo segment
    assume cs:codigo, ds:datos, ss:pila

; =========================================================================
; 1. OPERACIONES DE VALIDACIÓN (Retornan 1 si Verdadero, 0 si Falso)
; =========================================================================

; --- CONEJO? (isDigit?) ---
ConejoHuella proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]      ; Extrae el carácter de la pila
    
    cmp al, '0'         ; Compara con ASCII '0'
    jb no_es_conejo     ; Si es menor, no es dígito
    cmp al, '9'         ; Compara con ASCII '9'
    ja no_es_conejo     ; Si es mayor, no es dígito
    
    mov ax, 1           ; Es dígito (vivo)
    jmp fin_conejo
no_es_conejo:
    mov ax, 0           ; No es dígito (muerto)
fin_conejo:
    pop bp
    ret 2               ; Limpia 2 bytes
ConejoHuella endp

; --- LOBO? (isAlpha?) ---
LoboHuella proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    
    ; Revisar rango de mayúsculas (A-Z)
    cmp al, 'A'
    jb revisar_minusculas
    cmp al, 'Z'
    jbe es_lobo
    
revisar_minusculas:
    ; Revisar rango de minúsculas (a-z)
    cmp al, 'a'
    jb no_es_lobo
    cmp al, 'z'
    ja no_es_lobo

es_lobo:
    mov ax, 1           ; Es letra (vivo)
    jmp fin_lobo
no_es_lobo:
    mov ax, 0           ; No es letra (muerto)
fin_lobo:
    pop bp
    ret 2
LoboHuella endp

; =========================================================================
; 2. OPERACIONES DE CONVERSIÓN (Retornan el Carácter Modificado)
; =========================================================================

; --- SALVAJE (toUpper) ---
SalvajeHuella proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    
    ; Solo convertimos si está entre 'a' y 'z'
    cmp al, 'a'
    jb fin_salvaje
    cmp al, 'z'
    ja fin_salvaje
    
    sub al, 32          ; En ASCII, restar 32 pasa de minúscula a mayúscula
    
fin_salvaje:
    pop bp
    ret 2
SalvajeHuella endp

; --- DOCIL (toLower) ---
DocilHuella proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    
    ; Solo convertimos si está entre 'A' y 'Z'
    cmp al, 'A'
    jb fin_docil
    cmp al, 'Z'
    ja fin_docil
    
    add al, 32          ; En ASCII, sumar 32 pasa de mayúscula a minúscula
    
fin_docil:
    pop bp
    ret 2
DocilHuella endp

; =========================================================================
; 3. RUTINAS DE E/S Y UTILIDADES
; =========================================================================

; --- rugirHuella: Imprime el carácter guardado en AX ---
rugirHuella proc near
    push bp
    mov bp, sp
    push ax
    push dx

    mov ax, [bp+4]      ; Extrae carácter
    mov dl, al          ; Lo mueve a DL para la interrupción
    mov ah, 02h         ; Función DOS para imprimir un solo char
    int 21h
    
    pop dx
    pop ax
    pop bp
    ret 2
rugirHuella endp

; --- rugirBooleano: Imprime vivo o muerto basado en AX ---
rugirBooleano proc near
    push bp
    mov bp, sp
    push ax
    push dx

    mov ax, [bp+4]
    cmp ax, 1
    je imprimir_vivo

    mov ah, 09h
    lea dx, str_muerto
    int 21h
    jmp fin_rugirbool

imprimir_vivo:
    mov ah, 09h
    lea dx, str_vivo
    int 21h

fin_rugirbool:
    pop dx
    pop ax
    pop bp
    ret 2
rugirBooleano endp

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

    ; --- Tour 1: conejo? ('7') -> Debe dar VIVO ---
    mov ah, 09h
    lea dx, msg_con1
    int 21h
    mov ax, '7'
    push ax
    call ConejoHuella
    push ax
    call rugirBooleano
    call ImprimirSalto

    ; --- Tour 2: conejo? ('A') -> Debe dar MUERTO ---
    mov ah, 09h
    lea dx, msg_con2
    int 21h
    mov ax, 'A'
    push ax
    call ConejoHuella
    push ax
    call rugirBooleano
    call ImprimirSalto

    ; --- Tour 3: lobo? ('A') -> Debe dar VIVO ---
    mov ah, 09h
    lea dx, msg_lob1
    int 21h
    mov ax, 'A'
    push ax
    call LoboHuella
    push ax
    call rugirBooleano
    call ImprimirSalto

    ; --- Tour 4: lobo? ('7') -> Debe dar MUERTO ---
    mov ah, 09h
    lea dx, msg_lob2
    int 21h
    mov ax, '7'
    push ax
    call LoboHuella
    push ax
    call rugirBooleano
    call ImprimirSalto

    ; --- Tour 5: salvaje ('b') -> Debe imprimir 'B' ---
    mov ah, 09h
    lea dx, msg_sal
    int 21h
    mov ax, 'b'
    push ax
    call SalvajeHuella
    push ax
    call rugirHuella
    call ImprimirSalto

    ; --- Tour 6: docil ('G') -> Debe imprimir 'g' ---
    mov ah, 09h
    lea dx, msg_doc
    int 21h
    mov ax, 'G'
    push ax
    call DocilHuella
    push ax
    call rugirHuella
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_fin
    int 21h

    mov ah, 4ch
    int 21h
Principal endp

codigo ends
end Principal
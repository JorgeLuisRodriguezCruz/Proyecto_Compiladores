; =========================================================================
; Archivo: Gato.asm (Operaciones para Booleanos)
; Autores: 
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; Descripción: Definición de operaciones lógicas 
;              para el tipo Gato (Booleano: vivo=1, muerto=0). Demuestra 
;              AND (sim), OR (mut), XOR (com) y NOT (dep).
; =========================================================================

pila segment stack 'STACK'
    dw 256 dup(0)
pila ends

datos segment
    msg_inicio DB "Iniciando Tour de Operaciones GATO (Booleanos)...", 10, 13, 10, 13, "$"
    
    msg_sim    DB " -> Prueba AND (vivo sim muerto) = $"
    msg_mut    DB " -> Prueba OR  (vivo mut muerto) = $"
    msg_com    DB " -> Prueba XOR (vivo com vivo)   = $"
    msg_dep    DB " -> Prueba NOT (dep muerto)      = $"
    
    str_vivo   DB "vivo$"
    str_muerto DB "muerto$"
    
    msg_salto  DB 10, 13, "$"
    msg_fin    DB 10, 13, "Tour finalizado con exito.", 10, 13, "$"
datos ends

codigo segment
    assume cs:codigo, ds:datos, ss:pila

; =========================================================================
; LIBRERÍA DE OPERACIONES LÓGICAS (GATO)
; =========================================================================

; --- AND Lógico (Operador 'sim') ---
simgato proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      ; Parámetro Izquierdo
    mov bx, [bp+4]      ; Parámetro Derecho
    and ax, bx          ; AX = AX AND BX
    pop bp
    ret 4               ; Limpia 4 bytes (2 parámetros)
simgato endp

; --- OR Lógico (Operador 'mut') ---
mutgato proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    mov bx, [bp+4]      
    or ax, bx           ; AX = AX OR BX
    pop bp
    ret 4
mutgato endp

; --- XOR Lógico (Operador 'com') ---
comgato proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    mov bx, [bp+4]      
    xor ax, bx          ; AX = AX XOR BX
    pop bp
    ret 4
comgato endp

; --- NOT Lógico Unario (Operador 'dep') ---
depgato proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]      ; Extrae único parámetro
    xor ax, 1           ; XOR con 1 invierte el bit más bajo (1->0, 0->1)
    pop bp
    ret 2               ; Limpia 2 bytes (1 parámetro)
depgato endp

; =========================================================================
; RUTINA DE SALIDA: rugirGato (Imprimir 'vivo' o 'muerto')
; =========================================================================
rugirgato proc near
    push bp
    mov bp, sp
    push ax
    push dx

    mov ax, [bp+4]      ; Extraemos el valor booleano
    cmp ax, 1           ; ¿Es igual a 1 (vivo)?
    je imprimir_vivo

imprimir_muerto:
    mov ah, 09h
    lea dx, str_muerto
    int 21h
    jmp fin_rugir

imprimir_vivo:
    mov ah, 09h
    lea dx, str_vivo
    int 21h

fin_rugir:
    pop dx
    pop ax
    pop bp
    ret 2
rugirgato endp

; =========================================================================
; RUTINA UTILITARIA: Imprimir salto de línea
; =========================================================================
imprimirsalto proc near
    mov ah, 09h
    lea dx, msg_salto
    int 21h
    ret
imprimirsalto endp

principal proc far
    push ds
    xor ax, ax
    push ax
    mov ax, datos
    mov ds, ax

    mov ah, 09h
    lea dx, msg_inicio
    int 21h

    ; === 1. TOUR: AND (vivo sim muerto) -> 1 AND 0 = 0 (muerto) ===
    mov ah, 09h
    lea dx, msg_sim
    int 21h
    mov ax, 1           ; vivo
    push ax
    mov ax, 0           ; muerto
    push ax
    call simgato        
    push ax
    call rugirgato
    call imprimirsalto

    ; === 2. TOUR: OR (vivo mut muerto) -> 1 OR 0 = 1 (vivo) ===
    mov ah, 09h
    lea dx, msg_mut
    int 21h
    mov ax, 1           
    push ax
    mov ax, 0           
    push ax
    call mutgato        
    push ax
    call rugirgato
    call imprimirsalto

    ; === 3. TOUR: XOR (vivo com vivo) -> 1 XOR 1 = 0 (muerto) ===
    mov ah, 09h
    lea dx, msg_com
    int 21h
    mov ax, 1           
    push ax
    mov ax, 1           
    push ax
    call comgato        
    push ax
    call rugirgato
    call imprimirsalto

    ; === 4. TOUR: NOT (dep muerto) -> NOT 0 = 1 (vivo) ===
    mov ah, 09h
    lea dx, msg_dep
    int 21h
    mov ax, 0           
    push ax
    call depgato        
    push ax
    call rugirgato
    call imprimirsalto

    mov ah, 09h
    lea dx, msg_fin
    int 21h

    mov ah, 4ch
    int 21h
principal endp

codigo ends
end principal
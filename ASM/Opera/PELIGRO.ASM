; =========================================================================
; Archivo: PELIGRO.ASM (Operaciones Creativas - Tipo Peligro)
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; Descripción: Operaciones de respaldo para el tipo creativo Peligro.
; Escala: minimo(0), bajo(1), medio(2), alto(3), maximo(4)
; Operaciones: calmar, acechar, alfa, omega, amenaza.
; =========================================================================

pila segment stack 'stack'
    dw 256 dup(0)
pila ends

datos segment
    msg_inicio DB "Iniciando Tour de Operaciones PELIGRO...", 10, 13, 10, 13, "$"

    msg_calmar DB " -> Prueba CALMAR  (calmar medio(2))        = Nivel $"
    msg_acech  DB " -> Prueba ACECHAR (acechar medio(2))       = Nivel $"
    msg_alfa   DB " -> Prueba ALFA    (bajo(1) alfa alto(3))   = Nivel $"
    msg_omega  DB " -> Prueba OMEGA   (bajo(1) omega alto(3))  = Nivel $"
    msg_amen_f DB " -> Prueba AMENAZA (amenaza medio(2))       = Gato $"
    msg_amen_v DB " -> Prueba AMENAZA (amenaza maximo(4))      = Gato $"

    str_vivo   DB "vivo$"
    str_muerto DB "muerto$"

    msg_salto  DB 10, 13, "$"
    msg_fin    DB 10, 13, "Tour finalizado con exito.", 10, 13, "$"
datos ends

codigo segment
    assume cs:codigo, ds:datos, ss:pila

; =========================================================================
; LIBRERÍA DE OPERACIONES DE PELIGRO (0 al 4)
; =========================================================================

; --- CALMAR: Reduce el nivel de peligro (minimo = 0) ---
; Recibe: [BP+4] = Nivel actual
op_calmar proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    cmp ax, 0           ; Si ya es minimo(0), no baja mas
    je fin_calmar
    dec ax              ; Resta 1 nivel
fin_calmar:
    pop bp
    ret 2
op_calmar endp

; --- ACECHAR: Aumenta el nivel de peligro (maximo = 4) ---
; Recibe: [BP+4] = Nivel actual
op_acechar proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    cmp ax, 4           ; Si ya es maximo(4), no sube mas
    je fin_acechar
    inc ax              ; Sube 1 nivel
fin_acechar:
    pop bp
    ret 2
op_acechar endp

; --- ALFA: Retorna el peligro mayor ---
; Recibe: [BP+6] = Nivel A, [BP+4] = Nivel B
op_alfa proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]
    mov bx, [bp+4]
    cmp ax, bx
    jge fin_alfa        ; Si AX >= BX, AX ya tiene el mayor
    mov ax, bx          ; Si no, el mayor es BX
fin_alfa:
    pop bp
    ret 4
op_alfa endp

; --- OMEGA: Retorna el peligro menor ---
; Recibe: [BP+6] = Nivel A, [BP+4] = Nivel B
op_omega proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]
    mov bx, [bp+4]
    cmp ax, bx
    jle fin_omega       ; Si AX <= BX, AX ya tiene el menor
    mov ax, bx          ; Si no, el menor es BX
fin_omega:
    pop bp
    ret 4
op_omega endp

; --- AMENAZA: Retorna vivo(1) si es alto(3) o maximo(4) ---
; Recibe: [BP+4] = Nivel
op_amenaza proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    cmp ax, 3           ; Compara con alto(3)
    jge es_amenaza      ; Si es 3 o 4, hay amenaza
    
    mov ax, 0           ; Gato muerto
    jmp fin_amenaza
es_amenaza:
    mov ax, 1           ; Gato vivo
fin_amenaza:
    pop bp
    ret 2
op_amenaza endp

; =========================================================================
; RUTINAS UTILITARIAS: Impresión visual
; =========================================================================

imprimir_nivel proc near
    push bp
    mov bp, sp
    push ax
    push dx
    
    mov ax, [bp+4]
    add al, '0'         ; Convertir entero (0-4) a ASCII
    mov dl, al
    mov ah, 02h
    int 21h

    pop dx
    pop ax
    pop bp
    ret 2
imprimir_nivel endp

imprimir_gato proc near
    push bp
    mov bp, sp
    push ax
    push dx
    
    mov ax, [bp+4]
    cmp ax, 1
    je imp_vivo
    
    mov ah, 09h
    lea dx, str_muerto
    int 21h
    jmp fin_imp_gato
imp_vivo:
    mov ah, 09h
    lea dx, str_vivo
    int 21h
fin_imp_gato:
    pop dx
    pop ax
    pop bp
    ret 2
imprimir_gato endp

imprimir_salto proc near
    mov ah, 09h
    lea dx, msg_salto
    int 21h
    ret
imprimir_salto endp

; =========================================================================
; PROCEDIMIENTO PRINCIPAL (EL TOUR)
; =========================================================================
principal proc far
    push ds
    xor ax, ax
    push ax
    
    mov ax, datos
    mov ds, ax
    
    ; Inicio
    mov ah, 09h
    lea dx, msg_inicio
    int 21h

    ; 1. CALMAR (2 -> 1)
    mov ah, 09h
    lea dx, msg_calmar
    int 21h
    mov ax, 2
    push ax
    call op_calmar
    push ax
    call imprimir_nivel
    call imprimir_salto

    ; 2. ACECHAR (2 -> 3)
    mov ah, 09h
    lea dx, msg_acech
    int 21h
    mov ax, 2
    push ax
    call op_acechar
    push ax
    call imprimir_nivel
    call imprimir_salto

    ; 3. ALFA (1 y 3 -> 3)
    mov ah, 09h
    lea dx, msg_alfa
    int 21h
    mov ax, 1
    push ax
    mov ax, 3
    push ax
    call op_alfa
    push ax
    call imprimir_nivel
    call imprimir_salto

    ; 4. OMEGA (1 y 3 -> 1)
    mov ah, 09h
    lea dx, msg_omega
    int 21h
    mov ax, 1
    push ax
    mov ax, 3
    push ax
    call op_omega
    push ax
    call imprimir_nivel
    call imprimir_salto

    ; 5. AMENAZA (2 -> muerto)
    mov ah, 09h
    lea dx, msg_amen_f
    int 21h
    mov ax, 2
    push ax
    call op_amenaza
    push ax
    call imprimir_gato
    call imprimir_salto

    ; 6. AMENAZA (4 -> vivo)
    mov ah, 09h
    lea dx, msg_amen_v
    int 21h
    mov ax, 4
    push ax
    call op_amenaza
    push ax
    call imprimir_gato
    call imprimir_salto

    ; Fin
    mov ah, 09h
    lea dx, msg_fin
    int 21h

    ret
principal endp

codigo ends
end principal
; =========================================================================
; Archivo: Colmena.asm (Operaciones para Conjuntos)
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; Descripción: Operaciones de respaldo para tipo de dato Colmena (Conjuntos).
;              Demuestra abeja (insertar), aguijon (eliminar), enjambre (unión),
;              miel (intersección), familia (pertenencia) y desolado (vacío).
;              Incluye formato de salida visual { X Y }.
; =========================================================================

pila segment stack 'stack'
    dw 256 dup(0)
pila ends

datos segment
    msg_inicio DB "Iniciando Tour de Operaciones COLMENA (Conjuntos)...", 10, 13, 10, 13, "$"

    msg_abeja DB " -> Prueba ABEJA    (Insertar el 2 en colmena vacia) = $"
    msg_agui  DB " -> Prueba AGUIJON  (Eliminar el 2 del resultado)    = $"
    msg_enjam DB " -> Prueba ENJAMBRE (Union de {1} y {2})             = $"
    msg_miel  DB " -> Prueba MIEL     (Interseccion de {1,2} y {2,3})  = $"
    msg_fami  DB " -> Prueba FAMILIA  (Pertenece 2 a {1,2}?)           = $"
    msg_deso  DB " -> Prueba DESOLADO (Esta vacia la colmena 0?)       = $"

    str_vivo   DB "vivo$"
    str_muerto DB "muerto$"

    msg_salto DB 10, 13, "$"
    msg_fin   DB 10, 13, "Tour finalizado con exito.", 10, 13, "$"
datos ends

codigo segment
    assume cs:codigo, ds:datos, ss:pila

; =========================================================================
; LIBRERÍA DE OPERACIONES DE CONJUNTOS (COLMENA)
; =========================================================================

; --- ABEJA (Insertar elemento) ---
abejacolmena proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      ; Cargar la colmena
    mov cx, [bp+4]      ; Cargar el elemento a insertar (0-15)
    mov bx, 1
    shl bx, cl          ; Desplazar bit
    or ax, bx           ; Insertar bit con OR
    pop bp
    ret 4
abejacolmena endp

; --- AGUIJON (Eliminar elemento) ---
aguijoncolmena proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      ; Cargar colmena
    mov cx, [bp+4]      ; Cargar elemento a eliminar (0-15)
    mov bx, 1
    shl bx, cl          ; Desplazar bit
    not bx              ; Invertir (mascara de borrado)
    and ax, bx          ; Eliminar bit con AND
    pop bp
    ret 4
aguijoncolmena endp

; --- ENJAMBRE (Unión de conjuntos) ---
enjambrecolmena proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      ; Colmena A
    mov bx, [bp+4]      ; Colmena B
    or ax, bx           ; Unión con OR
    pop bp
    ret 4
enjambrecolmena endp

; --- MIEL (Intersección de conjuntos) ---
mielcolmena proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      ; Colmena A
    mov bx, [bp+4]      ; Colmena B
    and ax, bx          ; Intersección con AND
    pop bp
    ret 4
mielcolmena endp

; --- FAMILIA (Pertenencia -> Retorna Gato) ---
familiacolmena proc near
    push bp
    mov bp, sp
    mov cx, [bp+6]      ; Elemento buscado
    mov ax, [bp+4]      ; Colmena donde buscar
    mov bx, 1
    shl bx, cl
    and ax, bx          ; Aislar el bit
    jz no_pertenece
    mov ax, 1           ; Vivo
    jmp fin_fami
no_pertenece:
    mov ax, 0           ; Muerto
fin_fami:
    pop bp
    ret 4
familiacolmena endp

; --- DESOLADO? (Verificar si está vacío -> Retorna Gato) ---
desoladocolmena proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]      ; Colmena a verificar
    cmp ax, 0           ; 0 significa conjunto vacío
    je esta_vacia
    mov ax, 0           ; Muerto (tiene elementos)
    jmp fin_deso
esta_vacia:
    mov ax, 1           ; Vivo (está vacía)
fin_deso:
    pop bp
    ret 2
desoladocolmena endp

; =========================================================================
; RUTINAS UTILITARIAS: Impresión visual (Prints)
; =========================================================================

; --- Imprimir Colmena como Conjunto Matemático { X, Y } ---
imprimircolmena proc near
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push di             ; Guardamos DI porque lo usaremos como bandera IsFirst

    ; Imprimir llave de apertura "{ "
    mov ah, 02h
    mov dl, '{'
    int 21h
    mov dl, ' '
    int 21h

    mov bx, [bp+4]      ; Cargar el valor de la colmena (los bits) en BX
    mov cx, 0           ; Nuestro contador de abejas (indice 0 a 15)
    mov di, 1           ; DI sera nuestra bandera IsFirst (1 = Verdadero)

verificar_bit:
    mov ax, bx
    and ax, 1           ; Aislar el bit mas a la derecha
    jz no_imprimir      ; Si es 0, esa abeja no esta, saltamos

    cmp di, 1           ; ¿Es el primer elemento que vamos a imprimir?
    je imprimir_numero  ; Si es el primero, nos saltamos la coma
    
    ; Si NO es el primero, imprimimos la coma y el espacio ", "
    mov ah, 02h
    mov dl, ','
    int 21h
    mov dl, ' '
    int 21h

imprimir_numero:
    mov di, 0           ; Apagamos la bandera (IsFirst = Falso)

    ; Si hay abeja (es 1), imprimimos su numero guardado en CX
    cmp cx, 10
    jl es_digito_simple

    ; Si el numero es 10 o mayor, imprimimos un '1' primero
    mov ah, 02h
    mov dl, '1'
    int 21h
    
    ; Y luego calculamos el segundo digito (CX - 10)
    mov ax, cx
    sub al, 10
    add al, '0'         ; Convertir a ASCII
    mov dl, al
    mov ah, 02h
    int 21h
    jmp no_imprimir

es_digito_simple:
    ; Si es menor a 10, solo le sumamos '0' para ASCII
    mov ax, cx
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h

no_imprimir:
    shr bx, 1           ; Desplazar BX para evaluar la siguiente abeja
    inc cx              ; Aumentar contador
    cmp cx, 16          ; Ya revisamos los 16 posibles elementos (0-15)?
    jne verificar_bit

    ; Imprimir llave de cierre " }"
    mov ah, 02h
    mov dl, ' '
    int 21h
    mov dl, '}'
    int 21h

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2
imprimircolmena endp

; --- Imprimir Booleano (Gato) ---
imprimirgato proc near
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
imprimirgato endp

imprimirsalto proc near
    mov ah, 09h
    lea dx, msg_salto
    int 21h
    ret
imprimirsalto endp

; =========================================================================
; PROCEDIMIENTO PRINCIPAL (EL TOUR)
; =========================================================================
principal proc far
    push ds
    xor ax, ax
    push ax
    
    mov ax, datos
    mov ds, ax
    
    mov ah, 09h
    lea dx, msg_inicio
    int 21h

    ; === 1. Prueba ABEJA (Insertar 2 en conjunto 0) ===
    mov ah, 09h
    lea dx, msg_abeja
    int 21h
    
    mov ax, 0
    push ax         ; Colmena = 0
    mov ax, 2
    push ax         ; Elemento = 2
    call abejacolmena
    push ax         ; Resultado a la pila
    call imprimircolmena
    call imprimirsalto

    ; === 2. Prueba AGUIJON (Eliminar 2 del resultado anterior) ===
    mov ah, 09h
    lea dx, msg_agui
    int 21h
    
    ; El resultado anterior (4) ya está en AX
    mov ax, 4       ; Colmena {2}
    push ax
    mov ax, 2       ; Quitar elemento 2
    push ax
    call aguijoncolmena
    push ax
    call imprimircolmena
    call imprimirsalto

    ; === 3. Prueba ENJAMBRE (Union de {1} y {2} -> Result: {1 2} = 6) ===
    mov ah, 09h
    lea dx, msg_enjam
    int 21h
    
    mov ax, 2       ; Colmena A: bit 1 (valor 2)
    push ax
    mov ax, 4       ; Colmena B: bit 2 (valor 4)
    push ax
    call enjambrecolmena
    push ax
    call imprimircolmena
    call imprimirsalto

    ; === 4. Prueba MIEL (Interseccion de {1 2} y {2 3} -> Result: {2} = 4) ===
    mov ah, 09h
    lea dx, msg_miel
    int 21h
    
    mov ax, 6       ; Colmena A: {1 2}
    push ax
    mov ax, 12      ; Colmena B: {2 3}
    push ax
    call mielcolmena
    push ax
    call imprimircolmena
    call imprimirsalto

    ; === 5. Prueba FAMILIA (Pertenece 2 a {1 2}? -> vivo) ===
    mov ah, 09h
    lea dx, msg_fami
    int 21h
    
    mov ax, 2       ; Elemento a buscar
    push ax
    mov ax, 6       ; Colmena {1 2}
    push ax
    call familiacolmena
    push ax
    call imprimirgato
    call imprimirsalto

    ; === 6. Prueba DESOLADO (Vacio el 0? -> vivo) ===
    mov ah, 09h
    lea dx, msg_deso
    int 21h
    
    mov ax, 0       ; Colmena vacia
    push ax
    call desoladocolmena
    push ax
    call imprimirgato
    call imprimirsalto

    ; === FIN DEL TOUR ===
    mov ah, 09h
    lea dx, msg_fin
    int 21h

    ret
principal endp

codigo ends
end principal
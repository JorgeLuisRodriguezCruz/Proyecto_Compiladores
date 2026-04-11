; *************************************************************
; * Archivo: PELIGRO.ASM (MAESTRO DE CONVERSION)              *
; * Objetivo: Convertir todos los tipos de PasCat a Peligro   *
; * Autores: Jorge Luis Rodríguez / Franco Vinicio Rojas      *
; *************************************************************

datos segment
    Base        dw 10
    TmpPeligro  db 1               ; Resultado final (1 a 5)
    EsNegativo  db 0
    
    ; Mensajes de Interfaz
    MsgOVE      db 13, 10, "olerOveja (Entero -> Peligro): $"
    MsgHUE      db 13, 10, "olerHuella (Caracter -> Peligro): $"
    MsgGAT      db 13, 10, "olerGato (0/m o 1/v -> Peligro): $"
    MsgSER      db 13, 10, "olerSerpiente (Minimo, Bajo, Medio, Alto, Maximo): $"
    MsgCOL      db 13, 10, "olerColmena: Cantidad a agregar (1-9): $"
    MsgRes      db 13, 10, " -> rugirPeligro: Nivel $"
    MsgSep      db " - $"

    ; Mensajes de Error
    MsgErrOv    db 13, 10, "Error: Ingrese solo digitos (0-9) o signo menos: $"
    MsgErrG     db 13, 10, "Error: Use 'v'/1 para vivo o 'm'/0 para muerto: $"
    MsgErrS     db 13, 10, "Error: Nivel no reconocido. Intente de nuevo: $"
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgErrorC   db 13, 10, "Error: Ingrese un numero entre 1 y 9: $"

    ; Tabla de niveles (Exactamente 7 bytes cada uno para calculo facil)
    TxtPeli     db "Minimo$", "Bajo  $", "Medio $", "Alto  $", "Maximo$"

    ; Estructuras de datos
    BufferSer   db 50, ?, 50 dup('$') 
    BitsetCol   db 32 dup(0)
    Divisor     db 8
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- rugirPeligro: Imprime el numero (1-5) y su etiqueta ---
rugirPeligro proc near
    push ax bx dx
    
    mov dl, TmpPeligro
    add dl, '0'
    mov ah, 02h
    int 21h

    lea dx, MsgSep
    mov ah, 09h
    int 21h

    mov al, TmpPeligro
    dec al
    mov bl, 7
    mul bl
    lea dx, TxtPeli
    add dx, ax
    mov ah, 09h
    int 21h

    pop dx bx ax
    ret
rugirPeligro endP

inicio:
    mov ax, datos
    mov ds, ax
    mov es, ax              ; ES necesario para CMPSB

    ; ---------------------------------------------------------
    ; 1. OVEJA -> PELIGRO (Limitar matematicamente a 1-5)
    ; ---------------------------------------------------------
    lea dx, MsgOVE
    mov ah, 09h
    int 21h
    call oler_ove_aux
    
    cmp bx, 1
    jle set_peligro_1
    cmp bx, 5
    jge set_peligro_5
    mov TmpPeligro, bl
    jmp mostrar_peligro_oveja

set_peligro_1:
    mov TmpPeligro, 1
    jmp mostrar_peligro_oveja
set_peligro_5:
    mov TmpPeligro, 5

mostrar_peligro_oveja:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 2. HUELLA -> PELIGRO (Filtro numerico o maximo por precaucion)
    ; ---------------------------------------------------------
pedir_huella:
    lea dx, MsgHUE
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    
    cmp al, '1'
    jb default_peligro_max
    cmp al, '5'
    ja default_peligro_max
    
    sub al, '0'
    mov TmpPeligro, al
    jmp mostrar_peligro_huella
    
default_peligro_max:
    mov TmpPeligro, 5
mostrar_peligro_huella:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 3. GATO -> PELIGRO (Vivo = Entorno Seguro (1), Muerto = Entorno Letal (5))
    ; ---------------------------------------------------------
pedir_gato:
    lea dx, MsgGAT
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    
    or al, 20h              ; Tolerancia a mayusculas
    cmp al, '0'
    je entorno_letal_5
    cmp al, 'm'
    je entorno_letal_5
    cmp al, '1'
    je entorno_seguro_1
    cmp al, 'v'
    je entorno_seguro_1
    
    lea dx, MsgErrG
    mov ah, 09h
    int 21h
    jmp pedir_gato

entorno_seguro_1:
    mov TmpPeligro, 1
    jmp mostrar_peligro_gato
entorno_letal_5:
    mov TmpPeligro, 5
mostrar_peligro_gato:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 4. SERPIENTE -> PELIGRO (Comparacion de palabras exactas)
    ; ---------------------------------------------------------
pedir_serp_peli:
    lea dx, MsgSER
    mov ah, 09h
    int 21h
    lea dx, BufferSer
    mov ah, 0Ah
    int 21h
    
    ; Convertir entrada a formato compatible (Capitalize)
    ; Solo cambiamos la primera a mayuscula si es minuscula
    mov al, [BufferSer + 2]
    cmp al, 'a'
    jb check_resto
    cmp al, 'z'
    ja check_resto
    sub al, 20h             ; Minuscula a Mayuscula
    mov [BufferSer + 2], al

check_resto:
    ; Convertir el resto a minusculas
    mov cl, [BufferSer + 1] ; Longitud
    dec cl                  ; Omitir la primera letra
    cmp cl, 0
    jle comparar_tabla      ; Si solo habia 1 letra (ej 'a')
    lea si, BufferSer + 3
convertir_min_loop:
    mov al, [si]
    cmp al, 'A'
    jb sig_letra
    cmp al, 'Z'
    ja sig_letra
    add al, 20h             ; Mayuscula a Minuscula
    mov [si], al
sig_letra:
    inc si
    dec cl
    jnz convertir_min_loop

comparar_tabla:
    ; Ahora la entrada es Ej: "Minimo", "Bajo", etc.
    mov cx, 5               ; 5 niveles posibles
    lea si, TxtPeli
    mov TmpPeligro, 1       ; Iniciar asumiendo nivel 1

comparar_nivel_loop:
    push cx
    lea di, BufferSer + 2
    mov cl, [BufferSer + 1] ; Longitud ingresada
    xor ch, ch

    ; Buscar el '$' o espacio en la etiqueta actual para saber su longitud real
    push si
    mov ah, 0               ; Contador de longitud real etiqueta
calc_len:
    mov al, [si]
    cmp al, '$'
    je fin_len
    cmp al, ' '
    je fin_len
    inc ah
    inc si
    jmp calc_len
fin_len:
    pop si

    ; Comparar longitudes
    cmp cl, ah
    jne probar_siguiente_nivel

    ; Si las longitudes coinciden, comparar caracteres
    repe cmpsb
    je nivel_encontrado     ; Si Zero Flag = 1, son iguales

probar_siguiente_nivel:
    pop cx
    add si, 7               
    mov al, TmpPeligro
    dec al
    mov bl, 7
    mul bl
    lea si, TxtPeli
    add si, ax
    add si, 7               ; SI apunta al siguiente bloque

    inc TmpPeligro
    loop comparar_nivel_loop

    ; Si sale del loop y no encontro nada
    lea dx, MsgErrS
    mov ah, 09h
    int 21h
    jmp pedir_serp_peli

nivel_encontrado:
    pop cx                  ; Limpiar stack
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 5. COLMENA -> PELIGRO (Basado en cardinalidad / cantidad)
    ; ---------------------------------------------------------
    lea dx, MsgCOL
    mov ah, 09h
    int 21h

leer_cantidad:
    mov ah, 01h
    int 21h
    cmp al, '1'
    jb error_cant
    cmp al, '9'
    ja error_cant
    sub al, 30h
    xor ah, ah
    mov cx, ax
    jmp bucle_captura
error_cant:
    lea dx, MsgErrorC
    mov ah, 09h
    int 21h
    jmp leer_cantidad

bucle_captura:
    push cx
    lea dx, MsgInput
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    xor ah, ah
    div Divisor
    mov bx, offset BitsetCol
    add bl, al
    adc bh, 0
    mov cl, ah
    mov al, 1
    shl al, cl
    or [bx], al
    pop cx
    loop bucle_captura

    ; --- Contar elementos en la colmena (Cardinalidad) ---
    mov cx, 32
    lea si, BitsetCol
    xor dx, dx

contar_bytes:
    lodsb
    cmp al, 0
    je sig_byte_col
    push cx
    mov cx, 8
contar_bits:
    shr al, 1
    jnc saltar_inc
    inc dx
saltar_inc:
    loop contar_bits
    pop cx
sig_byte_col:
    loop contar_bytes

    ; Evaluar cantidad
    cmp dl, 1
    jle set_col_1
    cmp dl, 5
    jge set_col_5
    mov TmpPeligro, dl
    jmp mostrar_peligro_col

set_col_1:
    mov TmpPeligro, 1
    jmp mostrar_peligro_col
set_col_5:
    mov TmpPeligro, 5
mostrar_peligro_col:
    call mostrar_resultado

    mov ah, 4Ch
    int 21h

; =============================================================
; SUBRUTINAS AUXILIARES
; =============================================================

mostrar_resultado proc near
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    call rugirPeligro
    ret
mostrar_resultado endP

oler_ove_aux proc near
    xor bx, bx
    mov EsNegativo, 0
leer_char_ov:
    mov ah, 01h
    int 21h
    cmp al, 13
    je fin_oler_ov
    cmp al, '-'
    jne es_digito_ov
    cmp bx, 0
    jne leer_char_ov
    mov EsNegativo, 1
    jmp leer_char_ov
es_digito_ov:
    cmp al, '0'
    jb err_ov_entrada
    cmp al, '9'
    ja err_ov_entrada
    sub al, 30h
    xor ah, ah
    mov cx, ax
    mov ax, bx
    mul Base
    add ax, cx
    mov bx, ax
    jmp leer_char_ov
err_ov_entrada:
    lea dx, MsgErrOv
    mov ah, 09h
    int 21h
    xor bx, bx
    mov EsNegativo, 0
    jmp leer_char_ov
fin_oler_ov:
    cmp EsNegativo, 1
    jne return_ov_aux
    neg bx
return_ov_aux:
    ret
oler_ove_aux endP

codigo endS
end inicio
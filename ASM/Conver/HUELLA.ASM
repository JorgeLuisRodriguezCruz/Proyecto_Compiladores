; *************************************************************
; * Archivo: HUELLA.ASM (MAESTRO DE CONVERSION)               *
; * Objetivo: Convertir todos los tipos de PasCat a Huella    *
; * Autores: Jorge Luis Rodríguez / Franco Vinicio Rojas      *
; *************************************************************

datos segment
    Base        dw 10
    TmpHuella   db ?               ; Almacena el resultado del casting
    EsNegativo  db 0               ; Control para oler_oveja
    
    ; Mensajes de Interfaz
    MsgOVE      db 13, 10, "olerOveja (Ingrese un numero): $"
    MsgGAT      db 13, 10, "olerGato (1:vivo, 0:muerto): $"
    MsgPEL      db 13, 10, "olerPeligro (1:Min, 2:Low, 3:Med, 4:High, 5:Max): $"
    MsgSER      db 13, 10, "olerSerpiente (Ingrese una cadena): $"
    MsgCOL      db 13, 10, "olerColmena: Cuantas huellas desea agregar (1-9)? $"
    MsgRes      db 13, 10, " -> rugirHuella: $"
    
    ; Errores y Validaciones
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgErrorC   db 13, 10, "Error: Digito entre 1 y 9: $"
    MsgErrRango db 13, 10, "Error: Rango ASCII (0-255). Se asignara '?': $"
    MsgErrP     db 13, 10, "Error: Rango 1-5. Reintente: $"
    MsgErrG     db 13, 10, "Error: Use 0 o 1. Reintente: $"

    ; Estructuras
    BufferSer   db 50, ?, 50 dup('$') 
    BitsetCol   db 32 dup(0)
    Divisor     db 8
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- rugirHuella ---
rugirHuella proc near
    push ax dx
    mov dl, TmpHuella
    mov ah, 02h
    int 21h
    pop dx ax
    ret
rugirHuella endP

inicio:
    mov ax, datos
    mov ds, ax

    ; ---------------------------------------------------------
    ; 1. OVEJA -> HUELLA (Casting validado)
    ; ---------------------------------------------------------
    lea dx, MsgOVE
    mov ah, 09h
    int 21h
    call oler_oveja
    mov ax, bx

    cmp ax, 0
    jl fuera_de_rango_oveja
    cmp ax, 255
    jg fuera_de_rango_oveja
    jmp asignar_huella_oveja

fuera_de_rango_oveja:
    lea dx, MsgErrRango
    mov ah, 09h
    int 21h
    mov al, '?'             ; char de error

asignar_huella_oveja:
    mov TmpHuella, al
    call imprimir_resultado

    ; ---------------------------------------------------------
    ; 2. GATO -> HUELLA (muerto='M', vivo='V')
    ; ---------------------------------------------------------
pedir_gato:
    lea dx, MsgGAT
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    cmp al, '0'
    jb error_gato
    cmp al, '1'
    ja error_gato
    
    cmp al, '0'
    je es_muerto
    mov TmpHuella, 'V'
    jmp fin_gato
es_muerto:
    mov TmpHuella, 'M'
fin_gato:
    call imprimir_resultado
    jmp pedir_peligro

error_gato:
    lea dx, MsgErrG
    mov ah, 09h
    int 21h
    jmp pedir_gato

    ; ---------------------------------------------------------
    ; 3. PELIGRO -> HUELLA (Nivel como char)
    ; ---------------------------------------------------------
pedir_peligro:
    lea dx, MsgPEL
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    cmp al, '1'
    jb error_peli
    cmp al, '5'
    ja error_peli
    
    mov TmpHuella, al
    call imprimir_resultado
    jmp pedir_serpiente

error_peli:
    lea dx, MsgErrP
    mov ah, 09h
    int 21h
    jmp pedir_peligro

    ; ---------------------------------------------------------
    ; 4. SERPIENTE -> HUELLA (Primer caracter)
    ; ---------------------------------------------------------
pedir_serpiente:
    lea dx, MsgSER
    mov ah, 09h
    int 21h
    lea dx, BufferSer
    mov ah, 0Ah
    int 21h
    
    mov al, [BufferSer + 1]
    cmp al, 0
    je serpiente_vacia
    mov al, [BufferSer + 2]
    mov TmpHuella, al
    jmp mostrar_ser
serpiente_vacia:
    mov TmpHuella, ' '
mostrar_ser:
    call imprimir_resultado

    ; ---------------------------------------------------------
    ; 5. COLMENA -> HUELLA (Extraer primer char)
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
    
    ; --- BUSQUEDA DEL PRIMER CARACTER ---
    mov cx, 32
    lea si, BitsetCol
    xor ax, ax

buscar_byte:
    mov bl, [si]
    cmp bl, 0
    jne encontrar_bit
    inc si
    inc ax
    loop buscar_byte
    mov TmpHuella, '?'      ; Vacio
    jmp mostrar_col

encontrar_bit:
    mov dl, 0
probar_bit:
    shr bl, 1
    jc calcular_final
    inc dl
    jmp probar_bit

calcular_final:
    mov bh, 8
    mul bh
    add al, dl
    mov TmpHuella, al

mostrar_col:
    call imprimir_resultado

    mov ah, 4Ch
    int 21h

; --- Subrutinas Auxiliares ---
imprimir_resultado:
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    call rugirHuella
    ret

oler_oveja proc near
    xor bx, bx
    mov EsNegativo, 0
leer_char_loop:
    mov ah, 01h
    int 21h
    cmp al, 13
    je aplicar_signo
    cmp al, '-'
    jne validar_num
    cmp bx, 0
    jne leer_char_loop
    mov EsNegativo, 1
    jmp leer_char_loop
validar_num:
    cmp al, '0'
    jb leer_char_loop
    cmp al, '9'
    ja leer_char_loop
    sub al, 30h
    xor ah, ah
    mov cx, ax
    mov ax, bx
    mul Base
    add ax, cx
    mov bx, ax
    jmp leer_char_loop
aplicar_signo:
    cmp EsNegativo, 1
    jne retornar_oveja
    neg bx
retornar_oveja:
    ret
oler_oveja endP

codigo endS
end inicio
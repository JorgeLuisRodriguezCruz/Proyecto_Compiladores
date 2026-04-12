; *************************************************************
; * Archivo: GATO.ASM (MAESTRO DE CONVERSION)                 *
; * Objetivo: Convertir todos los tipos de PasCat a Gato      *
; * Autores: Jorge Luis Rodríguez / Franco Vinicio Rojas      *
; *************************************************************

datos segment
    Base        dw 10
    TmpGato     db 0               ; Resultado final: 1 (vivo) o 0 (muerto)
    EsNegativo  db 0
    TmpHuella   db 0
    Divisor     db 8
    
    ; Mensajes de Interfaz
    MsgOVE      db 13, 10, "olerOveja (Ingrese un numero): $"
    MsgHUE      db 13, 10, "olerHuella (Ingrese v/m): $"
    MsgSER      db 13, 10, "olerSerpiente (Ingrese v/m o vivo/muerto): $"
    MsgCOL      db 13, 10, "olerColmena: Cuantas huellas desea agregar (1-9)? $"
    MsgPEL      db 13, 10, "olerPeligro (1:Min, 2:Low, 3:Med, 4:High, 5:Max): $"
    MsgRes      db 13, 10, " -> rugirGato: $"

    ; Mensajes de Error (Agregados para evitar Undefined Symbol)
    MsgErrP     db 13, 10, "Error: Nivel debe ser 1-5. Reintente: $"
    MsgErrOv    db 13, 10, "Error: Ingrese solo digitos (0-9) o signo menos: $"
    MsgErrG     db 13, 10, "Error: Use 'v' para vivo o 'm' para muerto: $"
    MsgErrSG    db 13, 10, "Error: Ingrese 'v', 'm', 'vivo' o 'muerto': $"
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgErrorC   db 13, 10, "Error: Ingrese un numero entre 1 y 9: $"

    ; Etiquetas de estado
    TxtVivo     db "vivo$"
    TxtMuerto   db "muerto$"

    ; Estructuras de datos
    BufferSer   db 50, ?, 50 dup('$') 
    BitsetCol   db 32 dup(0)
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- rugirGato: Traduce el 1/0 a texto vivo/muerto ---
rugirGato proc near
    push ax dx
    cmp TmpGato, 1
    je imprimir_vivo
    lea dx, TxtMuerto
    jmp imprimir_fin
imprimir_vivo:
    lea dx, TxtVivo
imprimir_fin:
    mov ah, 09h
    int 21h
    pop dx ax
    ret
rugirGato endP

inicio:
    mov ax, datos
    mov ds, ax

    ; ---------------------------------------------------------
    ; 1. OVEJA -> GATO (Cero = Muerto, No Cero = Vivo)
    ; ---------------------------------------------------------
    lea dx, MsgOVE
    mov ah, 09h
    int 21h
    call oler_oveja_validada
    
    cmp bx, 0
    je oveja_muerta
    mov TmpGato, 1
    jmp mostrar_gato_oveja
oveja_muerta:
    mov TmpGato, 0
mostrar_gato_oveja:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 2. HUELLA -> GATO (Acepta v/V o m/M)
    ; ---------------------------------------------------------
pedir_gato:
    lea dx, MsgHUE
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    
    or al, 20h              ; Convertir a minuscula
    cmp al, 'm'
    je es_muerto
    cmp al, 'v'
    je es_vivo

    lea dx, MsgErrG
    mov ah, 09h
    int 21h
    jmp pedir_gato

es_muerto:
    mov TmpGato, 0
    jmp fin_gato
es_vivo:
    mov TmpGato, 1
fin_gato:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 3. SERPIENTE -> GATO (Acepta v, m, vivo, muerto)
    ; ---------------------------------------------------------
pedir_serpiente_gato:
    lea dx, MsgSER
    mov ah, 09h
    int 21h
    lea dx, BufferSer
    mov ah, 0Ah
    int 21h
    
    mov cl, [BufferSer + 1]
    cmp cl, 1
    je check_un_char
    cmp cl, 4
    je check_palabra_vivo
    cmp cl, 6
    je check_palabra_muerto
    jmp error_ser_gato

check_un_char:
    mov al, [BufferSer + 2]
    or al, 20h
    cmp al, 'v'
    je set_gato_vivo
    cmp al, 'm'
    je set_gato_muerto
    jmp error_ser_gato

check_palabra_vivo:
    lea si, BufferSer + 2
    mov al, [si]
    or al, 20h
    cmp al, 'v'
    jne error_ser_gato
    mov al, [si+1]
    or al, 20h
    cmp al, 'i'
    jne error_ser_gato
    mov al, [si+2]
    or al, 20h
    cmp al, 'v'
    jne error_ser_gato
    mov al, [si+3]
    or al, 20h
    cmp al, 'o'
    jne error_ser_gato
    jmp set_gato_vivo

check_palabra_muerto:
    lea si, BufferSer + 2
    mov al, [si]
    or al, 20h
    cmp al, 'm'
    jne error_ser_gato
    mov al, [si+1]
    or al, 20h
    cmp al, 'u'
    jne error_ser_gato
    mov al, [si+2]
    or al, 20h
    cmp al, 'e'
    jne error_ser_gato
    mov al, [si+3]
    or al, 20h
    cmp al, 'r'
    jne error_ser_gato
    mov al, [si+4]
    or al, 20h
    cmp al, 't'
    jne error_ser_gato
    mov al, [si+5]
    or al, 20h
    cmp al, 'o'
    jne error_ser_gato
    jmp set_gato_muerto

error_ser_gato:
    lea dx, MsgErrSG
    mov ah, 09h
    int 21h
    jmp pedir_serpiente_gato

set_gato_vivo:
    mov TmpGato, 1
    jmp mostrar_gato_serpiente
set_gato_muerto:
    mov TmpGato, 0
mostrar_gato_serpiente:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 4. COLMENA -> GATO (Vacia = Muerto, Con datos = Vivo)
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
    
    ; Verificar si la colmena quedó viva o muerta
    mov cx, 32
    lea si, BitsetCol
    mov TmpGato, 0          ; Asumimos muerta por defecto
verificar_colmena_loop:
    lodsb
    cmp al, 0
    jne colmena_a_viva
    loop verificar_colmena_loop
    jmp mostrar_gato_colmena
colmena_a_viva:
    mov TmpGato, 1
mostrar_gato_colmena:
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 5. PELIGRO -> GATO (Nivel 1-5 siempre es Vivo)
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
    
    cmp al, '5'
    je gato_muerto        ; Minimo es vivo
    jmp gato_vivo     ; Cualquier otro nivel es considerado peligroso (muerto)

error_peli:
    lea dx, MsgErrP
    mov ah, 09h
    int 21h
    jmp pedir_peligro

gato_muerto:
    mov TmpGato, 0
    call mostrar_resultado
    jmp fin_programa

gato_vivo:
    mov TmpGato, 1
    call mostrar_resultado
    jmp fin_programa

fin_programa:
    mov ah, 4Ch
    int 21h

; =============================================================
; SUBRUTINAS
; =============================================================

mostrar_resultado:
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    call rugirGato
    ret

oler_oveja_validada proc near
    xor bx, bx
    mov EsNegativo, 0
leer_caracter:
    mov ah, 01h
    int 21h
    cmp al, 13
    je fin_lectura
    cmp al, '-'
    jne validar_es_digito
    cmp bx, 0
    jne leer_caracter
    mov EsNegativo, 1
    jmp leer_caracter
validar_es_digito:
    cmp al, '0'
    jb leer_caracter
    cmp al, '9'
    ja leer_caracter
    sub al, 30h
    xor ah, ah
    mov cx, ax
    mov ax, bx
    mul Base
    add ax, cx
    mov bx, ax
    jmp leer_caracter
fin_lectura:
    cmp EsNegativo, 1
    jne retornar_oveja
    neg bx
retornar_oveja:
    ret
oler_oveja_validada endP

codigo endS
end inicio
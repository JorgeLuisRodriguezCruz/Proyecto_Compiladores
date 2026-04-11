; *************************************************************
; * Archivo: COLMENA.ASM (MAESTRO DE CONVERSION)              *
; * Objetivo: Convertir todos los tipos de PasCat a Colmena   *
; * Autores: Jorge Luis Rodríguez / Franco Vinicio Rojas      *
; *************************************************************

datos segment
    Base        dw 10
    EsNegativo  db 0
    EsPrimero   db 1               ; Control para comas en la impresion
    
    ; Mensajes de Interfaz
    MsgOVE      db 13, 10, "olerOveja (Ingrese un numero): $"
    MsgHUE      db 13, 10, "olerHuella (Ingrese un caracter): $"
    MsgGAT      db 13, 10, "olerGato (0/m:muerto, 1/v:vivo): $"
    MsgPEL      db 13, 10, "olerPeligro (1:Min, 2:Low, 3:Med, 4:High, 5:Max): $"
    MsgSER      db 13, 10, "olerSerpiente (Ingrese una cadena): $"
    MsgRes      db 13, 10, " -> rugirColmena: $"

    ; Mensajes de Error
    MsgErrOv    db 13, 10, "Error: Ingrese solo digitos o signo menos: $"
    MsgErrG     db 13, 10, "Error: Use 0/m para muerto o 1/v para vivo: $"
    MsgErrP     db 13, 10, "Error: Nivel debe ser 1-5. Reintente: $"

    ; Textos de apoyo para extraer caracteres
    TxtVivo     db "vivo$"
    TxtMuerto   db "muerto$"
    TxtPeli     db "Minimo$", "Bajo  $", "Medio $", "Alto  $", "Maximo$"

    ; Estructura central de la Colmena
    BitsetCol   db 32 dup(0)
    Divisor     db 8
    BufferSer   db 255, ?, 255 dup('$')
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- limpiar_colmena: Llena el bitset con ceros ---
limpiar_colmena proc near
    push ax cx di
    mov cx, 32
    lea di, BitsetCol
    mov al, 0
    rep stosb
    pop di cx ax
    ret
limpiar_colmena endP

; --- encender_bit: Recibe ASCII en BL y lo agrega al Set ---
encender_bit proc near
    push ax bx cx
    mov al, bl
    xor ah, ah
    div Divisor             ; AL = indice del byte, AH = indice del bit
    
    mov bx, offset BitsetCol
    add bl, al
    adc bh, 0               ; Manejar acarreo en la direccion
    
    mov cl, ah
    mov al, 1
    shl al, cl              ; Crear mascara
    or [bx], al             ; Encender bit
    
    pop cx bx ax
    ret
encender_bit endP

; --- rugirColmena: Imprime el bitset en formato { a, b, c } ---
rugirColmena proc near
    push ax bx cx dx
    mov dl, '{'
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    
    mov EsPrimero, 1
    mov dx, 0               ; DX sera el contador ASCII (0-255)

recorrer_set:
    mov ax, dx
    div Divisor
    mov bx, offset BitsetCol
    add bl, al
    adc bh, 0
    mov cl, ah
    mov al, 1
    shl al, cl
    test [bx], al           ; ¿Esta el bit encendido?
    jz saltar_impresion

    cmp EsPrimero, 1
    je imprimir_char
    
    ; Imprimir coma y espacio si no es el primero
    push dx
    mov dl, ','
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    pop dx

imprimir_char:
    push dx
    mov ah, 02h             ; Imprimir el caracter ASCII que representa el bit
    int 21h
    pop dx
    mov EsPrimero, 0

saltar_impresion:
    inc dx
    cmp dx, 256
    jne recorrer_set

    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, '}'
    int 21h

    pop dx cx bx ax
    ret
rugirColmena endP

inicio:
    mov ax, datos
    mov ds, ax
    mov es, ax

    ; ---------------------------------------------------------
    ; 1. OVEJA -> COLMENA (Caracteres del numero)
    ; ---------------------------------------------------------
    lea dx, MsgOVE
    mov ah, 09h
    int 21h
    call oler_ove_aux
    call limpiar_colmena
    
    mov ax, bx
    test ax, ax
    jge descomponer_oveja
    mov bl, '-'
    call encender_bit
    neg ax

descomponer_oveja:
    mov cx, 0
    mov bx, 10
dividir_ov:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz dividir_ov
extraer_ov:
    pop dx
    add dl, 30h
    mov bl, dl
    call encender_bit
    loop extraer_ov
    
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 2. HUELLA -> COLMENA (Caracter unico)
    ; ---------------------------------------------------------
    lea dx, MsgHUE
    mov ah, 09h
    int 21h
    call limpiar_colmena
    mov ah, 01h
    int 21h
    mov bl, al
    call encender_bit
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 3. GATO -> COLMENA (Caracteres de "vivo" o "muerto")
    ; ---------------------------------------------------------
pedir_gato:
    lea dx, MsgGAT
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    
    or al, 20h              ; Tolerancia a mayusculas
    cmp al, '0'
    je gato_muerto
    cmp al, 'm'
    je gato_muerto
    cmp al, '1'
    je gato_vivo
    cmp al, 'v'
    je gato_vivo
    
    lea dx, MsgErrG
    mov ah, 09h
    int 21h
    jmp pedir_gato

gato_muerto:
    lea si, TxtMuerto
    call procesar_palabra
    jmp pedir_peligro
gato_vivo:
    lea si, TxtVivo
    call procesar_palabra
    jmp pedir_peligro

    ; ---------------------------------------------------------
    ; 4. PELIGRO -> COLMENA (Caracteres del Nivel)
    ; ---------------------------------------------------------
pedir_peligro:
    lea dx, MsgPEL
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    
    cmp al, '1'
    jb err_peligro
    cmp al, '5'
    ja err_peligro
    
    sub al, '1'
    mov bl, 7               ; Cada etiqueta mide 7 bytes
    mul bl
    lea si, TxtPeli
    add si, ax
    call procesar_palabra
    jmp pedir_serpiente

err_peligro:
    lea dx, MsgErrP
    mov ah, 09h
    int 21h
    jmp pedir_peligro

    ; ---------------------------------------------------------
    ; 5. SERPIENTE -> COLMENA (Cada caracter de la cadena)
    ; ---------------------------------------------------------
pedir_serpiente:
    lea dx, MsgSER
    mov ah, 09h
    int 21h
    call limpiar_colmena
    lea dx, BufferSer
    mov ah, 0Ah
    int 21h
    
    mov cl, [BufferSer + 1]
    xor ch, ch
    test cx, cx
    jz fin_serpiente
    lea si, BufferSer + 2
bucle_serpiente:
    lodsb
    mov bl, al
    call encender_bit
    loop bucle_serpiente

fin_serpiente:
    call mostrar_resultado

    ; =============================================================
    ; FIN DEL PROGRAMA
    ; =============================================================
    mov ah, 4Ch
    int 21h

; =============================================================
; SUBRUTINAS AUXILIARES
; =============================================================

mostrar_resultado:
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    call rugirColmena
    ret

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

; --- Rutina compartida para Gato y Peligro ---
procesar_palabra proc near
    call limpiar_colmena
leer_letra:
    lodsb
    cmp al, '$'
    je fin_palabra
    cmp al, ' '             ; Ignorar espacios de relleno
    je fin_palabra
    mov bl, al
    call encender_bit
    jmp leer_letra
fin_palabra:
    call mostrar_resultado
    ret                     
procesar_palabra endP

codigo endS
end inicio
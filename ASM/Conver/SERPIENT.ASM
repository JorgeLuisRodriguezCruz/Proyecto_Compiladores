; *************************************************************
; * Archivo: SERPIENT.ASM (MAESTRO DE CONVERSION)             *
; * Objetivo: Convertir todos los tipos de PasCat a Serpiente *
; * Autores: Jorge Luis Rodríguez / Franco Vinicio Rojas      *
; *************************************************************

datos segment
    Base        dw 10
    EsNegativo  db 0
    EsPrimero   db 1               
    
    ; Mensajes de Interfaz
    MsgOVE      db 13, 10, "olerOveja (Ingrese un numero): $"
    MsgHUE      db 13, 10, "olerHuella (Ingrese un caracter): $"
    MsgGAT      db 13, 10, "olerGato (1:vivo, 0:muerto): $"
    MsgPEL      db 13, 10, "olerPeligro (1:Min, 2:Low, 3:Med, 4:High, 5:Max): $"
    MsgCOL      db 13, 10, "olerColmena: Cuantas huellas desea agregar (1-9)? $"
    MsgRes      db 13, 10, " -> rugirSerpiente: $"

    ; Mensajes de Error
    MsgErrOv    db 13, 10, "Error: Ingrese solo digitos o signo menos: $"
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgErrorC   db 13, 10, "Error: Digito entre 1 y 9: $"

    ; Buffer para la Serpiente final
    BufferRes   db 256 dup('$')
    
    ; Tablas para Gato y Peligro (7 bytes por etiqueta para facilitar calculo)
    TxtVivo     db "vivo  $"
    TxtMuerto   db "muerto$"
    TxtPeli     db "Minimo$", "Bajo  $", "Medio $", "Alto  $", "Maximo$"

    TmpPeligro  db 0               
    TmpGato     db 0               
    TmpHuella   db 0               

    ; Estructuras para Colmena
    BitsetCol   db 32 dup(0)
    Divisor     db 8
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- rugirSerpiente: Imprime el buffer final ---
rugirSerpiente proc near
    push ax dx
    lea dx, BufferRes
    mov ah, 09h
    int 21h
    pop dx ax
    ret
rugirSerpiente endP

; --- limpiar_buffer: Prepara BufferRes con '$' ---
limpiar_buffer proc near
    push ax cx di
    mov cx, 256
    lea di, BufferRes
    mov al, '$'
    rep stosb
    pop di cx ax
    ret
limpiar_buffer endP

inicio:
    mov ax, datos
    mov ds, ax
    mov es, ax

    ; ---------------------------------------------------------
    ; 1. OVEJA -> SERPIENTE
    ; ---------------------------------------------------------
    lea dx, MsgOVE
    mov ah, 09h
    int 21h
    call oler_ove_aux
    call limpiar_buffer
    mov ax, bx
    lea di, BufferRes
    call oveja_a_string
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 2. HUELLA -> SERPIENTE
    ; ---------------------------------------------------------
    lea dx, MsgHUE
    mov ah, 09h
    int 21h
    call oler_huella
    call limpiar_buffer
    mov al, TmpHuella
    mov [BufferRes], al
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 3. GATO -> SERPIENTE
    ; ---------------------------------------------------------
    lea dx, MsgGAT
    mov ah, 09h
    int 21h
    call oler_gato
    call limpiar_buffer
    
    mov al, TmpGato
    cmp al, 0
    je gato_muerto
    lea si, TxtVivo
    jmp copiar_gato_str
gato_muerto:
    lea si, TxtMuerto
copiar_gato_str:
    lea di, BufferRes
    call copiar_texto
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 4. PELIGRO -> SERPIENTE
    ; ---------------------------------------------------------
    lea dx, MsgPEL
    mov ah, 09h
    int 21h
    call oler_peligro
    call limpiar_buffer
    
    mov al, TmpPeligro
    dec al                  ; Ajustar 1-5 a 0-4
    mov bl, 7               ; Tamaño de cada etiqueta
    mul bl
    lea si, TxtPeli
    add si, ax
    lea di, BufferRes
    call copiar_texto
    call mostrar_resultado

    ; ---------------------------------------------------------
    ; 5. COLMENA -> SERPIENTE (Formato Conjunto { a, b })
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

    call limpiar_buffer
    lea di, BufferRes
    mov byte ptr [di], '{'
    inc di
    mov byte ptr [di], ' '
    inc di
    
    mov EsPrimero, 1
    mov dx, 0               ; Contador ASCII

bucle_busqueda_set:
    mov ax, dx
    div Divisor
    mov bx, offset BitsetCol
    add bl, al
    adc bh, 0
    mov cl, ah
    mov al, 1
    shl al, cl
    test [bx], al
    jz siguiente_huella

    cmp EsPrimero, 1
    je poner_elemento
    mov byte ptr [di], ','
    inc di
    mov byte ptr [di], ' '
    inc di
poner_elemento:
    mov [di], dl
    inc di
    mov EsPrimero, 0
siguiente_huella:
    inc dx
    cmp dx, 256
    jne bucle_busqueda_set

    mov byte ptr [di], ' '
    inc di
    mov byte ptr [di], '}'
    inc di
    call mostrar_resultado

    mov ah, 4Ch
    int 21h

; =============================================================
; SUBRUTINAS
; =============================================================

mostrar_resultado:
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    call rugirSerpiente
    ret

copiar_texto proc near      ; Para copiar cadenas terminadas en '$'
    ; SI = Origen, DI = Destino
sig_char:
    lodsb
    cmp al, '$'
    je fin_copiado
    cmp al, ' '              ; Omitir espacios de relleno si los hay
    je fin_copiado
    stosb
    jmp sig_char
fin_copiado:
    ret
copiar_texto endP

oveja_a_string:
    test ax, ax
    jge num_pos
    mov byte ptr [di], '-'
    inc di
    neg ax
num_pos:
    xor cx, cx
    mov bx, 10
div_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz div_loop
store_loop:
    pop ax
    add al, '0'
    stosb
    loop store_loop
    ret

oler_ove_aux:
    xor bx, bx
    mov EsNegativo, 0
leer_char:
    mov ah, 01h
    int 21h
    cmp al, 13
    je fin_oler
    cmp al, '-'
    jne es_num
    cmp bx, 0
    jne leer_char
    mov EsNegativo, 1
    jmp leer_char
es_num:
    cmp al, '0'
    jb err_ov
    cmp al, '9'
    ja err_ov
    sub al, 30h
    xor ah, ah
    mov cx, ax
    mov ax, bx
    mul Base
    add ax, cx
    mov bx, ax
    jmp leer_char
err_ov:
    lea dx, MsgErrOv
    mov ah, 09h
    int 21h
    jmp leer_char
fin_oler:
    cmp EsNegativo, 1
    jne return_ov
    neg bx
return_ov:
    ret

oler_huella proc near
    mov ah, 01h
    int 21h
    mov TmpHuella, al
    ret
oler_huella endP

oler_gato proc near
    mov ah, 01h
    int 21h
    sub al, '0'
    mov TmpGato, al          ; Cambio AX por AL (mismo tamaño)
    ret
oler_gato endP

oler_peligro proc near
    mov ah, 01h
    int 21h
    sub al, '0'
    mov TmpPeligro, al       ; Cambio AX por AL (mismo tamaño)
    ret
oler_peligro endP

codigo endS
end inicio
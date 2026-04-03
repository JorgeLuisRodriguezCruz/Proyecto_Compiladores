; *************************************************************
; * Archivo: OVEJA.ASM (MAESTRO DE CONVERSION)                *
; * Objetivo: Convertir todos los tipos de PasCat a Oveja     *
; * Autores: Jorge Luis Rodríguez / Franco Vinicio Rojas      *
; *************************************************************

datos segment
    Base        dw 10
    TmpOveja    dw 0               ; Almacena el resultado del casting
    EsNegativo  db 0               ; Control para olerOveja
    
    ; Mensajes de Interfaz
    MsgHUE      db 13, 10, "olerHuella: $"
    MsgGAT      db 13, 10, "olerGato (Gato -> Oveja): $"
    MsgPEL      db 13, 10, "olerPeligro (1-5 -> Oveja): $"
    MsgSER      db 13, 10, "olerSerpiente (String -> Oveja): $"
    MsgCOL      db 13, 10, "olerColmena: Cuantas huellas desea agregar (1-9)? $"
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgErrorC   db 13, 10, "Error: Debe ser un digito entre 1 y 9. Intente de nuevo: $"
    MsgRes      db 13, 10, " -> rugirOveja: $"
    MsgErrP     db 13, 10, "Error: Nivel debe ser 1-5. Reintente: $"
    MsgErrG     db 13, 10, "Error: Gato debe ser 0 (muerto) o 1 (vivo). Reintente: $"
    MsgErrSer   db 13, 10, "Error: La serpiente no es solo de numeros$"

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

; rugirOveja
rugirOveja proc near    
    push AX BX CX DX
    cmp ax, 0
    jge imprimir_p
    push ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    pop ax
    neg ax
imprimir_p:
    xor cx, cx
    mov bx, Base
ciclo1: 
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne ciclo1
    mov ah, 02h
ciclo2: 
    pop DX
    add dl, 30h
    int 21h
    loop ciclo2 
    pop DX CX BX AX
    ret
rugirOveja endP

inicio:
    mov ax, datos
    mov ds, ax

    ; ---------------------------------------------------------
    ; 1. Camaleon: HUELLA -> OVEJA (ASCII)
    ; ---------------------------------------------------------
    lea dx, MsgHUE
    mov ah, 09h
    int 21h
    mov ah, 01h             ; olerHuella
    int 21h
    xor ah, ah
    mov TmpOveja, ax
    call imprimir_resultado

    ; ---------------------------------------------------------
    ; 2. Camaleon: GATO -> OVEJA (vivo=1, muerto=0)
    ; ---------------------------------------------------------
pedir_gato:
    lea dx, MsgGAT
    mov ah, 09h
    int 21h
    mov ah, 01h             ; olerGato
    int 21h
    cmp al, '0'
    jb error_gato
    cmp al, '1'
    ja error_gato

    sub al, 30h             ; Convertir '1'/'0' a valor
    xor ah, ah
    mov TmpOveja, ax
    call imprimir_resultado
    jmp pedir_peligro

error_gato:
    lea dx, MsgErrG
    mov ah, 09h
    int 21h
    jmp pedir_gato

    ; ---------------------------------------------------------
    ; 3. Camaleon: PELIGRO -> OVEJA (Validación 1-5)
    ; ---------------------------------------------------------
pedir_peligro:
    lea dx, MsgPEL
    mov ah, 09h
    int 21h
    mov ah, 01h             ; olerPeligro
    int 21h
    cmp al, '1'
    jb error_peligro
    cmp al, '5'
    ja error_peligro
    
    sub al, 30h             ; Mantener valor literal 1-5 como Oveja
    xor ah, ah
    mov TmpOveja, ax
    call imprimir_resultado
    jmp proximo_tipo

error_peligro:
    lea dx, MsgErrP
    mov ah, 09h
    int 21h
    jmp pedir_peligro

proximo_tipo:
    ; ---------------------------------------------------------
    ; 4. Camaleon: SERPIENTE -> OVEJA (Con Validación de Dígitos)
    ; ---------------------------------------------------------
    lea dx, MsgSER
    mov ah, 09h
    int 21h
    lea dx, BufferSer       ; olerSerpiente
    mov ah, 0Ah
    int 21h
    
    xor bx, bx
    mov si, offset BufferSer + 2
    mov cl, [BufferSer + 1]
    xor ch, ch
    jcxz fin_serpiente      ; Si está vacía, terminar
    
    mov EsNegativo, 0
    mov al, [si]
    cmp al, '-'             ; ¿Empieza con signo?
    jne validar_contenido
    
    mov EsNegativo, 1
    inc si
    dec cx
    jcxz error_validacion    ; Si solo puso "-", es error

validar_contenido:
    ; --- Bucle de Validación ---
    push si                 ; Guardar posición inicial para el parseo posterior
    push cx                 ; Guardar longitud para el parseo posterior
verificar_loop:
    mov al, [si]
    cmp al, '0'
    jb error_validacion     ; No es un número
    cmp al, '9'
    ja error_validacion     ; No es un número
    inc si
    loop verificar_loop
    
    pop cx                  ; Restaurar registros para empezar la conversión
    pop si
    jmp empezar_parse       ; Todo bien, proceder al cálculo

error_validacion:
    pop cx
    pop si
    mov bx, 0               ; Valor por defecto en caso de error
    jmp fin_serpiente

empezar_parse:
    mov al, [si]
    sub al, 30h
    xor ah, ah
    push ax
    mov ax, bx
    mul Base
    pop dx
    add ax, dx
    mov bx, ax
    inc si
    loop empezar_parse

    cmp EsNegativo, 1
    jne fin_serpiente
    neg bx

fin_serpiente:
    mov TmpOveja, bx
    call imprimir_resultado

    ; ---------------------------------------------------------
    ; 5. Camaleon: COLMENA -> OVEJA (Cardinalidad)
    ; ---------------------------------------------------------
    lea dx, MsgCOL
    mov ah, 09h
    int 21h

leer_cantidad:
    mov ah, 01h
    int 21h
    
    ; --- VALIDACIÓN ---
    cmp al, '1'          ; ¿Es menor que '1'?
    jb error_cant
    cmp al, '9'          ; ¿Es mayor que '9'?
    ja error_cant
    
    sub al, 30h          ; Convertir a número si es válido
    xor ah, ah
    mov cx, ax
    jmp bucle_captura

error_cant:
    lea dx, MsgErrorC
    mov ah, 09h
    int 21h
    jmp leer_cantidad    ; Volver a pedir sin saltar de línea para no ensuciar

bucle_captura:
    push cx
    lea dx, MsgInput
    mov ah, 09h
    int 21h
    mov ah, 01h           ; Leer el caracter deseado
    int 21h             ; El codigo ASCII queda en AL (0-255)

    ; --- Logica para encender el bit correspondiente al ASCII ---
    ; Byte_Index = ASCII / 8
    ; Bit_Index  = ASCII % 8
    xor ah, ah                 ; AX = ASCII
    div Divisor                ; AL = Cociente (Byte), AH = Residuo (Bit)
    
    mov bx, offset BitsetCol
    add bl, al                 ; BX apunta al byte correcto dentro del Bitset
    adc bh, 0
    
    mov cl, ah                 ; Preparamos el desplazamiento con el residuo
    mov al, 1
    shl al, cl                 ; Creamos la mascara de bit
    or [bx], al                ; Encendemos el bit en la memoria (Bitwise OR)

    pop cx
    loop bucle_captura

    ; (Se asume que la colmena tiene elementos tras olerColmena)
    xor ax, ax              ; Acumulador de cardinalidad
    mov cx, 32
    mov si, offset BitsetCol

    ; Despliegue del conjunto { 'a', 'b', 'c' }
contar_bytes:
    push cx
    mov bl, [si]
    mov cx, 8
contar_bits:
    shr bl, 1
    jnc sig
    inc ax
sig:
    loop contar_bits
    inc si
    pop cx
    loop contar_bytes
    
    mov TmpOveja, ax
    call imprimir_resultado

    ; Fin del programa
    mov ah, 4Ch
    int 21h

; --- Subrutina de apoyo para visualización ---
imprimir_resultado:
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    mov ax, TmpOveja
    call rugirOveja
    ret

codigo endS
end inicio
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
    MsgHUE      db 13, 10, "olerHuella (Ingrese un caracter): $"
    MsgGAT      db 13, 10, "olerGato (0/m:muerto o 1/v:vivo -> Oveja): $"
    MsgPEL      db 13, 10, "olerPeligro (1-5 -> Oveja): $"
    MsgSER      db 13, 10, "olerSerpiente (String numerico -> Oveja): $"
    MsgCOL      db 13, 10, "olerColmena: Cuantas huellas desea agregar (1-9)? $"
    MsgRes      db 13, 10, " -> rugirOveja: $"
    
    ; Mensajes de Error
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgErrorC   db 13, 10, "Error: Debe ser un digito entre 1 y 9. Intente de nuevo: $"
    MsgErrP     db 13, 10, "Error: Nivel debe ser 1-5. Reintente: $"
    MsgErrG     db 13, 10, "Error: Use 'v'/1 para vivo o 'm'/0 para muerto. Reintente: $"
    MsgErrSer   db 13, 10, "Error: La serpiente debe contener solo numeros. Reintente: $"

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

; --- rugirOveja: Imprime el valor entero final ---
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
ciclo_div: 
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne ciclo_div
    mov ah, 02h
ciclo_print: 
    pop DX
    add dl, 30h
    int 21h
    loop ciclo_print 
    pop DX CX BX AX
    ret
rugirOveja endP

inicio:
    mov ax, datos
    mov ds, ax

    ; ---------------------------------------------------------
    ; 1. HUELLA -> OVEJA (Valor ASCII exacto)
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
    ; 2. GATO -> OVEJA (muerto=0, vivo=1)
    ; ---------------------------------------------------------
pedir_gato:
    lea dx, MsgGAT
    mov ah, 09h
    int 21h
    mov ah, 01h             ; olerGato
    int 21h
    
    or al, 20h              ; Tolerancia a mayusculas
    cmp al, '0'
    je gato_a_cero
    cmp al, 'm'
    je gato_a_cero
    cmp al, '1'
    je gato_a_uno
    cmp al, 'v'
    je gato_a_uno

    lea dx, MsgErrG
    mov ah, 09h
    int 21h
    jmp pedir_gato

gato_a_cero:
    mov TmpOveja, 0
    jmp fin_gato
gato_a_uno:
    mov TmpOveja, 1
fin_gato:
    call imprimir_resultado

    ; ---------------------------------------------------------
    ; 3. PELIGRO -> OVEJA (Nivel 1-5 como valor numerico)
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
    
    sub al, 30h             ; Convertir ASCII a entero
    xor ah, ah
    mov TmpOveja, ax
    call imprimir_resultado
    jmp pedir_serpiente

error_peligro:
    lea dx, MsgErrP
    mov ah, 09h
    int 21h
    jmp pedir_peligro

    ; ---------------------------------------------------------
    ; 4. SERPIENTE -> OVEJA (Conversión String -> Número con Error)
    ; ---------------------------------------------------------
pedir_serpiente:
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
    jcxz set_cero_serp      ; Si está vacía, devuelve 0
    
    mov EsNegativo, 0
    mov al, [si]
    cmp al, '-'             ; ¿Empieza con signo?
    jne validar_contenido
    
    mov EsNegativo, 1
    inc si
    dec cx
    jcxz error_validacion   ; Si solo puso "-", es error

validar_contenido:
    push si                 
    push cx                 
verificar_loop:
    mov al, [si]
    cmp al, '0'
    jb error_validacion     ; No es un número
    cmp al, '9'
    ja error_validacion     ; No es un número
    inc si
    loop verificar_loop
    
    pop cx                  ; Todo bien, restaurar e iniciar calculo
    pop si
    jmp empezar_parse       

error_validacion:
    pop cx
    pop si
    lea dx, MsgErrSer
    mov ah, 09h
    int 21h
    jmp pedir_serpiente     ; Volver a solicitar la serpiente

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
    jmp fin_serpiente

set_cero_serp:
    mov bx, 0
fin_serpiente:
    mov TmpOveja, bx
    call imprimir_resultado

    ; ---------------------------------------------------------
    ; 5. COLMENA -> OVEJA (Cardinalidad del conjunto)
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

    xor ax, ax              ; Acumulador de cardinalidad
    mov cx, 32
    mov si, offset BitsetCol

contar_bytes:
    push cx
    mov bl, [si]
    mov cx, 8
contar_bits:
    shr bl, 1
    jnc sig
    inc ax                  ; Sumar 1 a la cardinalidad por cada bit encendido
sig:
    loop contar_bits
    inc si
    pop cx
    loop contar_bytes
    
    mov TmpOveja, ax
    call imprimir_resultado

    ; =============================================================
    ; CIERRE DEL PROGRAMA
    ; =============================================================
    mov ah, 4Ch
    int 21h

; --- Subrutina Auxiliar ---
imprimir_resultado proc near
    lea dx, MsgRes
    mov ah, 09h
    int 21h
    mov ax, TmpOveja
    call rugirOveja
    ret
imprimir_resultado endP

codigo endS
end inicio
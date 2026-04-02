; *************************************************************
; Archivo: COLMENA.ASM
; Descripción: Programa en ensamblador que permite al usuario ingresar una cantidad de elementos (
; entre 1 y 9), luego ingresar esos elementos (números del 0 al 9) y finalmente muestra el conjunto resultante en formato { 1, 2, 3 }.
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************

datos segment
    Base        dw 10
    ; El bitset de 256 bits requiere 32 bytes (32 * 8 = 256)
    Bitset      db 32 dup(0)      
    IsFirst     db 1              ; Control para no poner coma al inicio
    Divisor     db 8              ; Usado para calcular posicion de bit
    
    MsgCount    db "olerColmena: Cuantas huellas desea agregar (1-9)? $"
    MsgInput    db 13, 10, "Ingrese huella: $"
    MsgOutput   db 13, 10, "rugirColmena: $"
    MsgError    db 13, 10, "Error: Debe ser un digito entre 1 y 9. Intente de nuevo: $"
    
    OpenB       db "{ $"
    CloseB      db " }$"
    Coma       db ", $"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

inicio:
    ; Inicializar segmento de datos
    mov ax, datos
    mov ds, ax

    pedir_cantidad:
    lea dx, MsgCount
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
    jmp continuar_proceso

error_cant:
    lea dx, MsgError
    mov ah, 09h
    int 21h
    jmp leer_cantidad    ; Volver a pedir sin saltar de línea para no ensuciar

continuar_proceso:
    jcxz mostrar_resultado

bucle_captura:
    push cx                    
    
    lea dx, MsgInput
    mov ah, 09h
    int 21h

    mov ah, 01h                ; Leer el caracter deseado
    int 21h                    ; El codigo ASCII queda en AL (0-255)
    
    ; --- Logica para encender el bit correspondiente al ASCII ---
    ; Byte_Index = ASCII / 8
    ; Bit_Index  = ASCII % 8
    xor ah, ah                 ; AX = ASCII
    div Divisor                ; AL = Cociente (Byte), AH = Residuo (Bit)
    
    mov bx, offset Bitset
    add bl, al                 ; BX apunta al byte correcto dentro del Bitset
    adc bh, 0
    
    mov cl, ah                 ; Preparamos el desplazamiento con el residuo
    mov al, 1
    shl al, cl                 ; Creamos la mascara de bit
    or [bx], al                ; Encendemos el bit en la memoria (Bitwise OR)

    pop cx
    loop bucle_captura

    ; Despliegue del conjunto { 'a', 'b', 'c' }
mostrar_resultado:
    lea dx, MsgOutput
    mov ah, 09h
    int 21h

    lea dx, OpenB              ; Imprimir "{"
    mov ah, 09h
    int 21h

    

    ; Recorremos los 256 posibles bits (0 a 255)
    mov cx, 0                  ; CX sera nuestro indice de caracter ASCII
recorrer_set:
    push cx                    ; Guardamos el indice actual
    
    ; Calcular posicion del bit actual
    mov ax, cx
    div Divisor                ; AL = Byte, AH = Bit
    
    mov bx, offset Bitset
    add bl, al
    adc bh, 0
    
    mov cl, ah
    mov al, 1
    shl al, cl
    test [bx], al              ; ¿El bit esta encendido?
    jz siguiente_char          ; Si es 0, no esta en el conjunto

    ; --- Logica de formato ---
    cmp IsFirst, 1
    je imprimir_char
    lea dx, Coma               ; Imprimir coma si no es el primero
    mov ah, 09h
    int 21h

imprimir_char:
    mov IsFirst, 0             ; Ya encontramos el primero
    pop cx
    push cx                    ; Recuperamos el valor ASCII
    mov dl, cl                 ; DL = caracter a imprimir
    mov ah, 02h                ; Funcion para imprimir un solo caracter
    int 21h
    jmp saltar_pop

siguiente_char:
    pop cx                     ; Recuperamos indice si no imprimimos nada

saltar_pop:
    inc cx
    cmp cx, 256                ; ¿Terminamos de revisar todos los ASCII?
    jne recorrer_set

    lea dx, CloseB             ; Imprimir "}"
    mov ah, 09h
    int 21h

    ; Finalizar programa
    mov ah, 4Ch
    int 21h
codigo endS
end inicio
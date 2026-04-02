; *************************************************************
; Programa: oveja.asm
; Descripción: Programa que solicita al usuario ingresar un número entero, lo almacena en una variable y luego lo muestra en pantalla.
; Autores: 
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************

datos segment
    Base     dw 10
    ValorInt dw 0
    MsgIn    db "olerOveja: $"
    MsgOut   db 13, 10, "rugirOveja: $"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

rugirOveja proc near    
    push AX BX CX DX   
    xor cx, cx
    mov bx, Base
ciclo1: xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne ciclo1
    mov ah, 02h
ciclo2: pop DX
    add dl, 30h
    cmp dl, 39h
    jbe prnPAX
    add dl, 7
prnPAX: int 21h
    loop ciclo2 
    pop DX CX BX AX
    ret
rugirOveja endP

inicio:
    mov ax, datos      ; Inicializar el segmento de datos
    mov ds, ax

    lea dx, MsgIn
    mov ah, 09h
    int 21h

    ; Lectura y conversion simple (ASCII a Binario)
    xor bx, bx
leer:
    mov ah, 01h     ; Función para leer un carácter de la entrada estándar
    int 21h         ; El carácter leído se almacena en AL
    cmp al, 13      ; Enter (carriage return) tiene el código ASCII 13
    je fin_leer     ; Si se presiona Enter, termina la lectura
    sub al, 30h     ; Convertir el carácter ASCII a su valor numérico (0-9)
    mov ah, 0       ; Limpiar AH para la multiplicación
    push ax         
    mov ax, bx      ; Multiplicar el número actual por la base (10)
    mul Base        ; AX = BX * Base
    pop dx          ; Recuperar el dígito leído
    add bx, ax      ; Sumar el dígito al número actual
    add ax, dx      ; Sumar el dígito al resultado de la multiplicación
    mov bx, ax      ; Guardar el resultado parcial en BX
    jmp leer        

fin_leer:
    mov ValorInt, bx    

    lea dx, MsgOut
    mov ah, 09h
    int 21h

    mov ax, ValorInt
    call rugirOveja

    mov ah, 4Ch
    int 21h
codigo endS
end inicio
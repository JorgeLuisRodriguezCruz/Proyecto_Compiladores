; *************************************************************
; Archivo: OVEJA.ASM
; Descripción: Programa que solicita al usuario ingresar un número entero, lo almacena en una variable y luego lo muestra en pantalla.
; con soporte de números negativos (-32768 a 32767).
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************

datos segment
    Base        dw 10
    ValorInt    dw 0
    EsNegativo  db 0               ; Bandera de signo: 0=Positivo, 1=Negativo
    MsgIn       db "olerOveja: $"
    MsgOut      db 13, 10, "rugirOveja: $"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- Rutina rugirOveja (Salida con Signo) ---
rugirOveja proc near    
    push AX BX CX DX
    
    ; 1. Verificar si el número es negativo
    cmp ax, 0
    jge preparar_impresion         ; Si es >= 0, saltar
    
    ; Si es negativo, imprimir el signo '-' y convertir a positivo
    push ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    pop ax
    neg ax                         ; AX = -AX (Complemento a dos)

preparar_impresion:
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

    lea dx, MsgIn
    mov ah, 09h
    int 21h

    ; --- Lectura validada con signo (olerOveja) ---
    xor bx, bx
    mov EsNegativo, 0              ; Resetear bandera de signo

leer:
    mov ah, 01h
    int 21h
    
    cmp al, 13                     ; ¿Es Enter?
    je fin_leer

    ; Validar si el primer carácter es un signo menos
    cmp al, '-'
    jne validar_digito
    cmp bx, 0                      ; Solo aceptar '-' si es el primer carácter
    jne leer
    mov EsNegativo, 1
    jmp leer

validar_digito:
    cmp al, '0'
    jb leer
    cmp al, '9'
    ja leer

    ; Conversión y Acumulación
    sub al, 30h
    xor ah, ah
    mov cx, ax
    
    mov ax, bx
    mul Base
    add ax, cx
    mov bx, ax
    jmp leer

fin_leer:
    ; Aplicar el signo si la bandera EsNegativo está activa
    cmp EsNegativo, 1
    jne guardar_valor
    neg bx                         ; Convertir el acumulado a negativo

guardar_valor:
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
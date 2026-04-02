; *************************************************************
; Programa: gato.asm
; Descripción: Programa que solicita al usuario ingresar un valor booleano (1 para verdadero, 0 para falso), lo almacena en una variable y luego muestra un mensaje indicando si el valor es verdadero o falso.
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************
datos segment
    ValorBool db ?
    MsgIn     db "olerGato (1:vivo, 0:muerto): $"
    MsgV      db 13, 10, "vivo$"
    MsgF      db 13, 10, "muerto$"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila
inicio:
    mov ax, datos       ; Cargar el segmento de datos en AX
    mov ds, ax          ; Establecer DS para apuntar al segmento de datos

    lea dx, MsgIn       ; Cargar la dirección del mensaje de entrada en DX
    mov ah, 09h         ; Función para imprimir cadena
    int 21h         ; Llamar a la interrupción para mostrar el mensaje

    mov ah, 01h     ; Función para leer un carácter de la entrada estándar
    int 21h         ; El carácter leído se almacena en AL
    sub al, 30h     ; Convertir el carácter ASCII a su valor numérico (0 o 1)
    mov ValorBool, al   

    cmp ValorBool, 0
    je es_f
    lea dx, MsgV
    jmp print
es_f:
    lea dx, MsgF
print:
    mov ah, 09h        ; Función para imprimir cadena
    int 21h            ; Llamar a la interrupción para mostrar el mensaje

    mov ah, 4Ch     ; Función para terminar el programa
    int 21h
codigo endS
end inicio
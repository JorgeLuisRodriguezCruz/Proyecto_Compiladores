; *************************************************************
; Programa: char.asm
; Descripción: Programa que solicita al usuario ingresar un caracter, lo almacena en una variable y luego lo muestra en pantalla.
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************
datos segment
    DatoChar db ?
    MsgIn    db "Ingrese un caracter: $"
    MsgOut   db 13, 10, "Caracter: $"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila
inicio:
    mov ax, datos   ; Inicializar el segmento de datos
    mov ds, ax      

    lea dx, MsgIn   ; Cargar la dirección del mensaje de entrada en DX
    mov ah, 09h     ; Función para imprimir cadena
    int 21h

    mov ah, 01h     ; Función para leer un carácter de la entrada estándar
    int 21h
    mov DatoChar, al    ; Almacenar el carácter leído en la variable DatoChar

    lea dx, MsgOut      
    mov ah, 09h
    int 21h

    mov dl, DatoChar    ; Imprimir el carácter almacenado
    mov ah, 02h
    int 21h

    mov ah, 4Ch
    int 21h
codigo endS
end inicio
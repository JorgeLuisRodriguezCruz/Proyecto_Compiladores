; *************************************************************
; Programa: serpient.asm
; Descripción: Programa que solicita al usuario ingresar una cadena de caracteres, la almacena en
; una variable y luego la muestra en pantalla.
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************
datos segment
    BufferStr db 50, ?, 50 dup('$')
    MsgIn     db "olerSerpiente: $"
    MsgOut    db 13, 10, "rugirSerpiente: $"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila
inicio:
    mov ax, datos
    mov ds, ax

    lea dx, MsgIn
    mov ah, 09h
    int 21h

    lea dx, BufferStr
    mov ah, 0Ah
    int 21h

    lea dx, MsgOut
    mov ah, 09h
    int 21h

    lea dx, BufferStr + 2
    mov ah, 09h
    int 21h

    mov ah, 4Ch
    int 21h
codigo endS
end inicio
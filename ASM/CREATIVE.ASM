; *************************************************************
; Programa: CREATIVE.ASM
; Descripción: Programa en ensamblador que permite al usuario seleccionar un nivel de peligro (1-5) y muestra el nivel de extinción correspondiente (Min, Low, Med, High, Max).
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************

datos segment
    ; Almacenamiento: 0=Min, 1=Low, 2=Med, 3=High, 4=Max
    LevelVar    db ?              
    
    ; Mensajes de interfaz
    MsgPrompt   db "Seleccione nivel de peligro (1:Min, 2:Low, 3:Med, 4:High, 5:Max): $"
    MsgOutput   db 13, 10, "Nivel de extincion: $"
    
    ; Literales para la salida
    TxtMin      db "Minimo$"
    TxtLow      db "Bajo$"
    TxtMed      db "Medio$"
    TxtHigh     db "Alto$"
    TxtMax      db "Maximo$"
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

    ; 1. ENTRADA (Olfatear)
    lea dx, MsgPrompt
    mov ah, 09h
    int 21h

    mov ah, 01h                ; Leer tecla
    int 21h
    sub al, 31h                ; Convertir '1'-'5' a 0-4
    mov LevelVar, al           ; ALMACENAMIENTO en el formato correcto (byte)

    ; 2. SALIDA (Rugir)
    lea dx, MsgOutput
    mov ah, 09h
    int 21h

    

    ; Lógica de selección para mostrar el literal
    mov al, LevelVar
    
    cmp al, 0
    je print_min
    cmp al, 1
    je print_low
    cmp al, 2
    je print_med
    cmp al, 3
    je print_high
    cmp al, 4
    je print_max
    jmp finalizar              ; Si es otra tecla, salir

print_min:
    lea dx, TxtMin
    jmp imprimir
print_low:
    lea dx, TxtLow
    jmp imprimir
print_med:
    lea dx, TxtMed
    jmp imprimir
print_high:
    lea dx, TxtHigh
    jmp imprimir
print_max:
    lea dx, TxtMax

imprimir:
    mov ah, 09h                ; Función para imprimir cadena ($)
    int 21h

finalizar:
    ; Finalizar programa (ah=4Ch)
    mov ah, 4Ch
    int 21h
codigo endS
end inicio
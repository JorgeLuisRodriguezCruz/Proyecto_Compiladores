; *************************************************************
; Archivo: SELECTED.ASM
; Descripción: Programa en ensamblador que permite al usuario ingresar una cantidad de elementos (
; entre 1 y 9), luego ingresar esos elementos (números del 0 al 9) y finalmente muestra el conjunto resultante en formato { 1, 2, 3 }.
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; *************************************************************

datos segment
    Base        dw 10             ; Base para la rutina printAX
    Bitset      dw 0              ; Variable de 16 bits para el conjunto
    IsFirst     db 1              ; Bandera para control de comas (1=Verdadero)
    
    ; Mensajes de la interfaz
    MsgCount    db "Cuantos elementos desea agregar (1-9)? $"
    MsgInput    db 13, 10, "Ingrese numero (0-9): $"
    MsgOutput   db 13, 10, "Resultado: $"
    
    ; Formato de conjunto
    OpenB       db "{ $"
    CloseB      db " }$"
    Coma       db ", $"
datos endS

pila segment stack 'stack'
    dw 256 dup(?)
pila endS

codigo segment
    Assume CS:codigo, DS:datos, SS:pila

; --- Subrutina printAX ---
printAX proc near    
    push AX
    push BX
    push CX                           
    push DX
    xor cx, cx
    mov bx, Base
ciclo1PAX: xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne ciclo1PAX
    mov ah, 02h
ciclo2PAX: pop DX
    add dl, 30h
    cmp dl, 39h
    jbe prnPAX
    add dl, 7
prnPAX: int 21h
    loop ciclo2PAX 
    pop DX
    pop CX
    pop BX
    pop AX
    ret
printAX endP

inicio:
    ; Inicialización del segmento de datos
    mov ax, datos
    mov ds, ax

    ; 1. ENTRADA: Preguntar cantidad de elementos
    lea dx, MsgCount
    mov ah, 09h
    int 21h

    mov ah, 01h                ; Leer cantidad
    int 21h
    sub al, 30h                ; Convertir ASCII a número
    xor ah, ah
    mov cx, ax                 ; Usar CX como contador del bucle
    
    jcxz mostrar_resultado     ; Si la cantidad es 0, saltar a la salida

    ; 2. ALMACENAMIENTO: Bucle para capturar y encender bits
bucle_captura:
    push cx                    ; Guardar contador del bucle
    
    lea dx, MsgInput
    mov ah, 09h
    int 21h

    mov ah, 01h                ; Leer el número (0-9)
    int 21h
    sub al, 30h                ; Convertir a valor numérico
    
    ; Lógica de Bitset (Encender el bit en la posición AL)
    mov cl, al                 ; CL indica el desplazamiento
    mov ax, 1                  ; Cargamos un bit base
    shl ax, cl                 ; Desplazamos el bit a la posición n
    or Bitset, ax              ; Aplicamos OR para agregar al conjunto

    pop cx                     ; Recuperar contador
    loop bucle_captura

    ; 3. SALIDA: Despliegue formateado { 1, 2, 3 }
mostrar_resultado:
    lea dx, MsgOutput
    mov ah, 09h
    int 21h

    lea dx, OpenB              ; Imprimir "{"
    mov ah, 09h
    int 21h

    

    mov cx, 0                  ; Contador para recorrer los 16 bits (0-15)
recorrer_bits:
    mov ax, 1
    push cx                    ; Guardar índice actual
    shl ax, cl                 ; Crear máscara para el bit actual
    test Bitset, ax            ; Verificar si el bit está activo (1)
    jz siguiente_bit           ; Si es 0, el elemento no existe

    ; --- Lógica de la coma ---
    cmp IsFirst, 1             ; ¿Es el primer elemento encontrado?
    je imprimir_dato           ; Si es el primero, no imprimimos coma
    
    lea dx, Coma               ; Si no es el primero, imprimir ", "
    mov ah, 09h
    int 21h

imprimir_dato:
    mov IsFirst, 0             ; Apagar bandera de "primero"
    mov ax, cx                 ; Preparar AX con el índice para printAX
    call printAX

siguiente_bit:
    pop cx                     ; Recuperar índice
    inc cx
    cmp cx, 16                 ; ¿Revisamos los 16 bits de la variable dw?
    jne recorrer_bits

    lea dx, CloseB             ; Imprimir "}"
    mov ah, 09h
    int 21h

    ; Finalizar programa (ah=4Ch)
    mov ah, 4Ch
    int 21h
codigo endS
end inicio
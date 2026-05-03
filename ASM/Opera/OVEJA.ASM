; =========================================================================
; Subject: Parser de PasCat
; Archivo: Oveja.asm (Operaciones para Enteros)
; Autores:
; Jorge Luis Rodríguez Cruz - 2020010773
; Franco Vinicio Rojas Lagos - 2022437823
; Descripción: Bitácora de operaciones del tipo Oveja (Entero 16 bits). 
;              Demuestra aritmética básica, incremento/decremento y 
;              comparaciones relacionales. Pila usada para parámetros.
; =========================================================================

pila segment stack 'stack'
    dw 256 dup(0)
pila ends

datos segment
    msg_inicio db "Iniciando Tour de Operaciones OVEJA (Enteros V1.3)...", 10, 13, 10, 13, "$"
    
    ; Mensajes de Aritmética
    msg_suma   db " -> Prueba Suma (boa) | 15 boa 10  = $"
    msg_resta  db " -> Prueba Resta (can)| 20 can 8   = $"
    msg_mult   db " -> Prueba Mult (emu) | 4 emu 5    = $"
    msg_div    db " -> Prueba Div (gnu)  | 50 gnu 5   = $"
    msg_mod    db " -> Prueba Mod (yak)  | 17 yak 5   = $"
    msg_neg    db " -> Prueba Negacion   | -(10)      = $"
    
    ; Mensajes de Incremento/Decremento
    msg_inc    db " -> Prueba Inc (acariciar 10)      = $"
    msg_dec    db " -> Prueba Dec (reprender 10)      = $"
    
    ; Mensajes Relacionales (Devuelven 1 o 0)
    msg_clon   db " -> Prueba Igual (15 clon 15)      = $"
    msg_dep    db " -> Prueba Mayor (20 depredador 8) = $"
    
    msg_salto  db 10, 13, "$"
    msg_fin    db 10, 13, "Tour finalizado con exito.", 10, 13, "$"
datos ends

codigo segment
    assume cs:codigo, ds:datos, ss:pila

; =========================================================================
; 1. ARITMÉTICA BÁSICA
; =========================================================================
SumaOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    add ax, [bp+4]      
    pop bp
    ret 4               
SumaOveja endp

RestaOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    sub ax, [bp+4]      
    pop bp
    ret 4
RestaOveja endp

MultOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    mov bx, [bp+4]      
    imul bx             
    pop bp
    ret 4
MultOveja endp

DivOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    cwd                 
    mov bx, [bp+4]      
    idiv bx             
    pop bp
    ret 4
DivOveja endp

ModOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+6]      
    cwd                 
    mov bx, [bp+4]      
    idiv bx             
    mov ax, dx          
    pop bp
    ret 4
ModOveja endp

NegOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]      
    neg ax              
    pop bp
    ret 2               
NegOveja endp

; =========================================================================
; 2. INCREMENTO Y DECREMENTO
; =========================================================================
AcariciarOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]      
    inc ax              
    pop bp
    ret 2               
AcariciarOveja endp

ReprenderOveja proc near
    push bp
    mov bp, sp
    mov ax, [bp+4]
    dec ax              
    pop bp
    ret 2
ReprenderOveja endp

; =========================================================================
; 3. OPERACIONES RELACIONALES (Retornan 1 si Verdadero, 0 si Falso)
; =========================================================================
ClonOveja proc near     ; Igual (==)
    push bp
    mov bp, sp
    mov ax, [bp+6]
    cmp ax, [bp+4]
    je es_clon
    mov ax, 0
    jmp fin_clon
es_clon:
    mov ax, 1
fin_clon:
    pop bp
    ret 4
ClonOveja endp

HibridoOveja proc near  ; Diferente (<>)
    push bp
    mov bp, sp
    mov ax, [bp+6]
    cmp ax, [bp+4]
    jne es_hibrido
    mov ax, 0
    jmp fin_hibrido
es_hibrido:
    mov ax, 1
fin_hibrido:
    pop bp
    ret 4
HibridoOveja endp

DepredadorOveja proc near ; Mayor que (>)
    push bp
    mov bp, sp
    mov ax, [bp+6]
    cmp ax, [bp+4]
    jg es_depredador
    mov ax, 0
    jmp fin_depredador
es_depredador:
    mov ax, 1
fin_depredador:
    pop bp
    ret 4
DepredadorOveja endp

PresaOveja proc near      ; Menor que (<)
    push bp
    mov bp, sp
    mov ax, [bp+6]
    cmp ax, [bp+4]
    jl es_presa
    mov ax, 0
    jmp fin_presa
es_presa:
    mov ax, 1
fin_presa:
    pop bp
    ret 4
PresaOveja endp

DepClonOveja proc near    ; Mayor o igual (>=)
    push bp
    mov bp, sp
    mov ax, [bp+6]
    cmp ax, [bp+4]
    jge es_depclon
    mov ax, 0
    jmp fin_depclon
es_depclon:
    mov ax, 1
fin_depclon:
    pop bp
    ret 4
DepClonOveja endp

PresaClonOveja proc near  ; Menor o igual (<=)
    push bp
    mov bp, sp
    mov ax, [bp+6]
    cmp ax, [bp+4]
    jle es_presaclon
    mov ax, 0
    jmp fin_presaclon
es_presaclon:
    mov ax, 1
fin_presaclon:
    pop bp
    ret 4
PresaClonOveja endp

; =========================================================================
; 4. RUTINAS DE E/S Y UTILIDADES
; =========================================================================
rugirOveja proc near
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+4]      
    test ax, ax
    jns es_positivo     
    
    push ax             
    mov ah, 02h         
    mov dl, '-'
    int 21h
    pop ax
    neg ax              

es_positivo:
    mov cx, 0           
    mov bx, 10          

extraer_digitos:
    xor dx, dx          
    div bx              
    push dx             
    inc cx               
    test ax, ax         
    jnz extraer_digitos 

imprimir_digitos:
    pop dx              
    add dl, '0'         
    mov ah, 02h
    int 21h
    loop imprimir_digitos 

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2               
rugirOveja endp

ImprimirSalto proc near
    mov ah, 09h
    lea dx, msg_salto
    int 21h
    ret
ImprimirSalto endp

Principal proc far
    push ds
    xor ax, ax
    push ax
    mov ax, datos
    mov ds, ax

    mov ah, 09h
    lea dx, msg_inicio
    int 21h

    ; --- Tour Matemáticas ---
    mov ah, 09h
    lea dx, msg_suma
    int 21h
    mov ax, 15          
    push ax             
    mov ax, 10          
    push ax             
    call SumaOveja      
    push ax             
    call rugirOveja
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_resta
    int 21h
    mov ax, 20          
    push ax
    mov ax, 8           
    push ax
    call RestaOveja     
    push ax
    call rugirOveja
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_mult
    int 21h
    mov ax, 4           
    push ax
    mov ax, 5           
    push ax
    call MultOveja      
    push ax
    call rugirOveja
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_div
    int 21h
    mov ax, 50          
    push ax
    mov ax, 5           
    push ax
    call DivOveja       
    push ax
    call rugirOveja
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_mod
    int 21h
    mov ax, 17          
    push ax
    mov ax, 5           
    push ax
    call ModOveja       
    push ax
    call rugirOveja
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_neg
    int 21h
    mov ax, 10          
    push ax
    call NegOveja       
    push ax
    call rugirOveja     
    call ImprimirSalto

    ; --- Tour Incremento/Decremento ---
    mov ah, 09h
    lea dx, msg_inc
    int 21h
    mov ax, 10          
    push ax
    call AcariciarOveja       
    push ax
    call rugirOveja     
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_dec
    int 21h
    mov ax, 10          
    push ax
    call ReprenderOveja       
    push ax
    call rugirOveja     
    call ImprimirSalto

    ; --- Tour Comparaciones Relacionales ---
    mov ah, 09h
    lea dx, msg_clon
    int 21h
    mov ax, 15          ; Izq
    push ax
    mov ax, 15          ; Der
    push ax
    call ClonOveja       
    push ax
    call rugirOveja     ; Imprime 1 (Verdadero)
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_dep
    int 21h
    mov ax, 20          ; Izq
    push ax
    mov ax, 8           ; Der
    push ax
    call DepredadorOveja       
    push ax
    call rugirOveja     ; Imprime 1 (Verdadero)
    call ImprimirSalto

    mov ah, 09h
    lea dx, msg_fin
    int 21h

    mov ah, 4ch
    int 21h
Principal endp

codigo ends
end Principal
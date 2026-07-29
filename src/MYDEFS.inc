; for windows functions

; Constants
WIDTH			equ 32
HEIGHT			equ 16
TILES			equ 512
START_INDEX 	equ 210
START_FOOD  	equ 110
KEY_U			equ 0x26
KEY_R			equ 0x27
KEY_D			equ 0x28
KEY_L			equ 0x25
KEY_ESC			equ 0x1B
DIR_U			equ 0
DIR_R			equ 1
DIR_D			equ 2
DIR_L			equ 3	

macro GETHANDLE op, ptr {
    invoke GetStdHandle, op
    mov [ptr], rax
}

macro GETRNGSEED seed_ptr {
    rdtsc
    shl rdx, 32
    or rax, rdx
    or rax, 1
    mov [seed_ptr], rax
}

; to zero the board array

macro ZEROB arr {
    mov rdi, arr
    mov al, 0
    mov rcx, 400
    rep stosb
}

; for xorshift, using Marsaglia Triple B offsets (as opposed to 12, 25, 27)

macro XOR64 sd {
    mov rax, [sd]
    mov rcx, rax
    shl rax, 13
    xor rax, rcx
    mov rcx, rax
    shr rax, 7
    xor rax, rcx
    mov rcx, rax
    shl rax, 17
    xor rax, rcx
    mov [sd], rax
}



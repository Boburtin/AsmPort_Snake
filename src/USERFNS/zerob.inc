
macro ZEROB arr
{
    mov rdi, arr
    mov al, 0
    mov rcx, 400
    rep stosb
}

macro XOR64 sd 
{
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
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

macro GETHANDLE op, ptr
{
    invoke GetStdHandle, op
    mov [ptr], rax
}

macro GETRNGSEED seed_ptr
{
    rdtsc
    shl rdx, 32
    or rax, rdx
    or rax, 1
    mov [seed_ptr], rax
}

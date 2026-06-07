format PE64 CONSOLE 6.0

entry _start

include './lib/win64a.inc'

; Constants
WIDTH			= 20
HEIGHT			= 20
TILES			= 400
START_INDEX 	= 210
START_FOOD  	= 110

; Direction enum
DIR_UP		 	= 0
DIR_RIGHT	 	= 1
DIR_DOWN	 	= 2
DIR_LEFT	 	= 3

section '.text' code readable executable

zerob:
	mov     rdi, board
	mov     al, 0
	mov     rcx, 400
	rep     stosb
	ret

xor64:
	mov     rax, [seed]
	mov     rcx, rax
	shl     rax, 13
	xor     rax, rcx
	mov     rcx, rax
	shr     rax, 7
	xor     rax, rcx
	mov     rcx, rax
	shl     rax, 17
	xor     rax, rcx
	mov     [seed], rax
	ret

food_fn:
.loopstrt:
	call    xor64
	xor     rdx, rdx							; zero rdx so it doesn't read it as an extension of rcx
	mov     rcx, 400
	div     rcx									; rdx holds the remainder (index % 400)
	cmp     byte 	[board + rdx], 0
	jne     .loopstrt
	mov     word	[food_idx], dx
	mov     byte	[board + rdx], 2
	ret

read_input:
	mov     rcx, [hStdin]
	lea     rdx, [pending_events]
	call    [GetNumberOfConsoleInputEvents]
	cmp     dword [pending_events], 0
	je      .no_input
	mov     rcx, [hStdin]
	lea     rdx, [input_record]
	mov     r8, 1
	lea     r9, [events_read]
	call    [ReadConsoleInputA]
	cmp     word [input_record], 1
	jne     .no_input
	cmp     dword [input_record + 4], 0
	je      .no_input
	movzx   eax, word [input_record + 10]
	cmp     eax, 0x26
	je      .up_input
	cmp     eax, 0x27
	je      .right_input
	cmp     eax, 0x28
	je      .down_input
	cmp     eax, 0x25
	je      .left_input
	cmp     eax, 0x1B
	je      quit
	ret
.up_input:
	mov     word [dir_buf], DIR_UP
	ret
.right_input:
	mov     word [dir_buf], DIR_RIGHT
	ret
.down_input:
	mov     word [dir_buf], DIR_DOWN
	ret
.left_input:
	mov     word [dir_buf], DIR_LEFT
	ret
.no_input:
	ret
update:
	movzx   eax, word [dir]
	movzx   ecx, word [dir_buf]
	mov     edx, ecx
	sub     ecx, eax
	and     ecx, 3
	cmp     ecx, 2
	cmovne  eax, edx
	mov     word [dir], ax
	movzx   rbx, word [snk_head]
	movzx   rbx, word [snake + rbx*2]
	movsx   rdx, word [dirtable + rax*2]
	add     rbx, rdx
.check_right:
	cmp     eax, DIR_RIGHT
	jne     .check_left
	push    rax
	mov     rax, rbx
	xor     rdx, rdx
	mov		rcx, WIDTH
	div     rcx
	test    rdx, rdx
	pop     rax
	jnz     .check_left
	sub     rbx, WIDTH
	jmp     .check_final
.check_left:
	cmp     eax, DIR_LEFT
	jne     .check_up
	push    rax
	lea     rax, [rbx+1]
	xor     rdx, rdx
	mov     rcx, WIDTH
	div     rcx									; next + 1 % columns -> result in rdx
	test    rdx, rdx
	pop     rax
	jnz     .check_up
	add     rbx, WIDTH
	jmp     .check_final
.check_up:
	cmp     eax, DIR_UP
	jne     .check_down
	push    rax
	mov     rax, rbx
	test    rax, rax
	pop     rax
	jge     .check_down
	add     rbx, 400
	jmp     .check_final
.check_down:
	push    rax
	mov     rax, rbx
	cmp     rax, 400
	pop     rax
	jl      .check_final
	sub     rbx, 400
.check_final:
	mov     word [next], bx
	movzx   rax, word [food_idx]
	cmp     rbx, rax
	je      .eat
	movzx   rax, byte [board + rbx]
	cmp     rax, 1
	je      .dead
	movzx   rax, word 					[snk_tail]
	movzx   rbx, word 					[snake + rax*2]
	mov     byte [board + rbx], 0
	inc     ax
	cmp     ax, 400
	jb      .ok_tl
	xor     ax, ax
.ok_tl:
	mov     word [snk_tail], ax
	movzx   rax, word [snk_head]
	inc     ax
	cmp     ax, 400
	jb      .ok_hd
	xor     ax, ax
.ok_hd:
	mov     word [snk_head], ax
	movzx   rbx, word [next]
	mov     word [snake + rax*2], bx
	mov     byte [board + rbx], 1
	ret
.eat:
	movzx   rax, word [snk_head]
	inc     ax
	cmp     ax, 400
	jb      .ok_eat
	xor     ax, ax
.ok_eat:
	mov     word [snk_head], ax
	movzx   rbx, word [next]
	mov     word [snake + rax*2], bx
	mov     byte [board + rbx], 1
	call    food_fn
	ret
.dead:
	jmp     init_game
init_game:
	call    zerob
	mov     word [snk_head], 0
	mov     word [snk_tail], 0
	mov     word [dir], 1
	mov     word [dir_buf], 1
	mov     word [snake], START_INDEX
	mov     byte [board + START_INDEX], 1
	call    food_fn
	ret
_start:
	push    rbp
	mov     rbp, rsp
	sub     rsp, 48
	rdtsc
	shl     rdx, 32								; to zero low bits
	or      rax, rdx							; 		and construct rdtsc from eax, edx 
	mov     [seed], rax							; randseed
	mov     rcx, -10							; stdout
	call    [GetStdHandle]
	mov     [hStdin], rax
	mov     rcx, -11							; stdin
	call    [GetStdHandle]
	mov     [hStdout], rax
	call    init_game
.game_loop:
	mov     rbx, 0
.render_loop:
	movzx   eax, byte [board + rbx]
	cmp     eax, 1
	je      .draw_snake
	cmp     eax, 2
	je      .draw_food
	lea     rdx, [spacechar]
	jmp     .rest
.draw_snake:
	lea     rdx, [snakechar]
	jmp     .rest
.draw_food:
	lea     rdx, [foodchar]
.rest:
	push    rdx
	mov     rax, rbx
	xor     rdx, rdx
	mov     rcx, WIDTH
	div     rcx
	shl     eax, 16
	or      eax, edx
	mov     r9d, eax
	pop     rdx
	mov     rcx, [hStdout]
	mov     r8, 1
	lea     rax, [events_read]
	mov     [rsp+32], rax
	call    [WriteConsoleOutputCharacterW]
	inc     rbx
	cmp     rbx, 400
	jne     .render_loop
	call    read_input
	call    update
	invoke  Sleep, 100
	jmp     .game_loop
quit:           								; restore stack and shut program down
	add     rsp, 48
	pop     rbp
	invoke  ExitProcess, 0
; end of instructions

section '.data' data readable writeable
dirtable        dw      -WIDTH, 1, WIDTH, -1	; delta array
foodchar        db      '*', 0
snakechar       db      'O', 0
spacechar       db      ' ', 0

section '.bss' readable writeable
board           rb      400
snake           rw      400
seed            rq      1
snk_head        rw      1
snk_tail        rw      1
food_idx        rw      1
input_record    rb      20
events_read     rd      1
pending_events  rd      1
hStdin          rq      1
dir             rw      1
dir_buf         rw      1
hStdout         rq      1
next            rw      1

section '.idata' import data readable writeable
library kernel32, 'kernel32.dll'
import	kernel32, \
GetStdHandle,'GetStdHandle',\
WriteConsoleOutputCharacterW,'WriteConsoleOutputCharacterW',\
SetConsoleCursorPosition,'SetConsoleCursorPosition',\
ReadConsoleInputA,'ReadConsoleInputA',\
GetNumberOfConsoleInputEvents,'GetNumberOfConsoleInputEvents',\
Sleep,	'Sleep',\
ExitProcess, 'ExitProcess'
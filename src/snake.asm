format PE64 CONSOLE 6.0
entry _start
include "win64a.inc"
include "MYDEFS.inc"

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

section '.text' code readable executable

food_fn:
	.loopstrt:
		XOR64 	seed
; rax holds the xorshifted seed value and tiles is a power of 2 so and > div
        and rax, TILES-1
; rdx = xorshift result % TILES = food index (if free)
		cmp     byte 	[board + rax], 0
; loop if the value of board[rdx] isn't 0 (empty)
		jne     .loopstrt
		mov     word	[food_idx], ax
		mov     byte	[board + rax], 2
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
	cmp     eax, KEY_U
	je      .up_input
	cmp     eax, KEY_R
	je      .right_input
	cmp     eax, KEY_D
	je      .down_input
	cmp     eax, KEY_L
	je      .left_input
	cmp     eax, KEY_ESC
	je      quit
	ret
	.up_input:
		mov     word [dir_buf], DIR_U
		ret
	.right_input:
		mov     word [dir_buf], DIR_R
		ret
	.down_input:
		mov     word [dir_buf], DIR_D
		ret
	.left_input:
		mov     word [dir_buf], DIR_L
		ret
	.no_input:
		ret
update:
; current direction [0, 1, 2, 3]
	movzx   eax, word [dir]
; next direction [0, 1, 2, 3]
	movzx   ecx, word [dir_buf]
	mov     edx, ecx; save dir_buf for the cmovne
	sub     ecx, eax; compute delta / dir_buf - dir
	and     ecx, 3  ; equivalent to mod 4
	cmp     ecx, 2  ; set ZF = 1 if true
	cmovne  eax, edx; fires if ZF = 0 only, otherwise still holds OG dir
	mov     word [dir], ax
	movzx   rbx, word [snk_head]
	movzx   rbx, word [snake + rbx*2]
	movsx   rdx, word [dirtable + rax*2]
	add     rbx, rdx
	.check_right:
		cmp     eax, DIR_R; cmp against either OG dir or new dir
		jne     .check_left
        test    rbx, WIDTH-1
        jnz     .check_final
        sub     rbx, WIDTH
		jmp     .check_final
	.check_left:
		cmp     eax, DIR_L
		jne     .check_up
		lea     rax, [rbx+1]
        and     rdx, WIDTH-1
        jnz     .check_final
        add     rbx, WIDTH
		jmp     .check_final
	.check_up:
		cmp     eax, DIR_U
		jne     .check_down
		test    rbx, rbx
		jge     .check_final
		add     rbx, TILES
		jmp     .check_final
	.check_down:
		cmp     rbx, TILES
		jl      .check_final
		sub     rbx, TILES
	.check_final:
		mov     word [next], bx
		movzx   rax, word [food_idx]
		cmp     rbx, rax
		je      .eat
		movzx   rax, byte [board + rbx]
		cmp     rax, 1
		je      .dead
		movzx   rax, word [snk_tail]
		movzx   rbx, word [snake + rax*2]
		mov     byte [board + rbx], 0
		inc     ax
		cmp     ax, TILES
		jb      .ok_tl
		xor     ax, ax
	.ok_tl:
		mov     word [snk_tail], ax
		movzx   rax, word [snk_head]
		inc     ax
		cmp     ax, TILES
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
		cmp     ax, TILES
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
	ZEROB	board
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
	GETRNGSEED seed
    GETHANDLE -10, hStdin
    GETHANDLE -11, hStdout
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
		mov     r9d, eax ; position coord, arg 4
		pop     rdx ; char ptr, arg 2
		mov     rcx, [hStdout] ; stdout, arg 1
		mov     r8, 1 ; len, arg 3
		lea     rax, [events_read]
		mov     [rsp+32], rax ; stack below shadow space, arg 5
		call    [WriteConsoleOutputCharacterW]
		inc     rbx
		cmp     rbx, TILES
		jne     .render_loop
		call    read_input
		call    update
		invoke  Sleep, 150
		jmp     .game_loop
quit:
	add     rsp, 40
	pop     rbp
    sub     rsp, 8
	invoke  ExitProcess, 0
; end of instructions

section '.data' data readable writeable
; direction deltas
	dirtable        dw      -WIDTH, 1, WIDTH, -1
; console output characters
	foodchar        db      '*', 0
	snakechar       db      'o', 0
    headchar        db      'O', 0
	spacechar       db      ' ', 0

section '.bss' readable writeable
	board           rb      TILES
	snake           rw      TILES
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
	library kernel32, "kernel32.dll"
	import	kernel32,\
		Sleep, 						  "Sleep", \
		GetStdHandle, 				  "GetStdHandle", \
		ExitProcess,  				  "ExitProcess", \ 
		WriteConsoleOutputCharacterW, "WriteConsoleOutputCharacterW", \		
		GetNumberOfConsoleInputEvents,"GetNumberOfConsoleInputEvents", \
		ReadConsoleInputA,			  "ReadConsoleInputA"

format PE64 CONSOLE 6.0

entry start

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

section '.code' code readable executable		; rcx, rdx, r8, r9, rax windows

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

checkfood:
.loopstrt:
	call    xor64
	xor     rdx, rdx							; zero rdx so it doesn't read it as an extension of rcx
	mov     rcx, 400							; div divisor
	div     rcx									; xor64 puts result in rax; / rcx in rax; % rcx in rdx
	cmp     byte 	[board + rdx], 0			; check if tile is free
	jne     .loopstrt							; jump back to loopstrt if it's not
	mov     word	[food_idx], rdx				; move rdx as a word sized int into food index if it is
	mov     byte	[board + rdx], 2
	ret

read_input:
	mov     rcx, [hStdin]						; move our handle
	lea     rdx, [pending_events]				;
	call    [GetNumberOfConsoleInputEvents]
	cmp     dword 	[pending_events], 0
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
	cmp     eax, 0x26							; up
	je      .up_input
	cmp     eax, 0x27							; right
	je      .right_input
	cmp     eax, 0x28							; down
	je      .down_input
	cmp     eax, 0x25							; left
	je      .left_input
	cmp     eax, 0x1B							; escape
	je      quit
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
	cmovne  eax, edx							; update dir if ecx is not 2 (not opposites)
	mov     word [dir], ax						; save new dir
	movzx   rbx, word [snk_head]				; load head
	movzx   rbx, word [snake + rbx*2]			; load snake[snk_head]
	movsx   rdx, word [dirtable + rax*2]		; load dir DELTA
	add     rbx, rdx							; get next tile
	mov     word [next], rbx
.check_right:
	cmp     eax, DIR_RIGHT
	jne     .check_left
	push    rax
	mov     rax, rbx							; copy NEXT into rax
	xor     rdx, rdx							; clear register
	mov     rcx, WIDTH							; prep for next % COLS
	div     rcx									; next % COLS
	test    rdx, rdx							; set ZF = 1 if rdx & rdx == 0
	pop     rax
	jnz     .check_left							; jumps if ZF != 0 -> rdx & rdx == 0
	sub     rbx, WIDTH
	jmp     .check_final
.check_left:
	cmp     eax, DIR_LEFT						; check left wrap
	jne     .check_up
	push    rax
	mov     rax, rbx							; next
	xor     rdx, rdx
	mov     rcx, WIDTH
	div     rcx
	cmp     rdx, 19
	pop     rax
	jne     .check_up
	add     rbx, WIDTH
	jmp     .check_final
.check_up:
	cmp     eax, DIR_UP
	jne     .check_down
	push    rax
	mov     rax, rbx							; next
	cmp     rax, 0
	pop     rax
	jg      .check_down
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
	mov     word [snake + rax*2], rbx
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
	mov     word [snake + rax*2], rbx
	mov     byte [board + rbx], 1
	call    checkfood
	ret

init_game:
	call    zerob
	mov     word [snk_head], 0
	mov     word [snk_tail], 0
	mov     word [dir], 1
	mov     word [dir_buf], 1
	mov     word [snake], START_INDEX
	mov     byte [board + START_INDEX], 1
	mov     word [food_idx], START_FOOD
	call    checkfood
	ret

start:
	push    rbp
	mov     rbp, rsp
	sub     rsp, 32
	rdtsc   									; rdtsc puts the 64bit result into edx:eax
	shl     rdx, 32								; shl moves the high half up (left)
	or      rax, rdx							; puts the timestamp back together
	mov     [seed], rax							; store the rng seed
	mov     rcx, -10							; -10 is stdin ; -11 is stdout ; -12 is stderr
	call    [GetStdHandle]						; negative values in rcx means that if
	mov     [hStdin], rax						; the call fails it will be invalid
	mov     rcx, -11
	call    [GetStdHandle]
	mov     [hStdout], rax
.game_loop:
	call    read_input
	call    update
	mov     rbx, 0
.render_loop:
	movzx   eax, byte [board + rbx]
	cmp     eax, 1
	je      .draw_snake
	cmp     eax, 2
	je      .draw_food
	lea     rdx, [spacechar]
	jmp     .rest
	.draw_snake
	lea     rdx, [snakechar]
	jmp     .rest
	.draw_food
	lea     rdx, [foodchar]
	.rest
	mov     rcx, [hStdout]
	inc     rbx
	cmp     rbx, 400
	jne     .render_loop
quit:
	add     rsp, 32
	pop     rbp
	invoke  ExitProcess, 0						; exit program

section '.data' data readable writeable
dirtable        dw      -WIDTH, 1, WIDTH, -1
foodchar        db      '*', 0
snakechar       db      'O', 0
wallchar        db      '/', 0
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
section .text
global minmax_sum_asm

minmax_sum_asm:
    push    rbp
    mov     rbp, rsp
    push    r12
    push    r13

    mov     r12, rdx
    mov     r13, rcx

    test    rsi, rsi
    jnz     .nonempty

    xor     eax, eax
    test    r12, r12
    jz      .skip_min0
    mov     dword [r12], 0
.skip_min0:
    test    r13, r13
    jz      .done_empty
    mov     dword [r13], 0
.done_empty:
    jmp     .epilogue

.nonempty:
    mov     eax, [rdi]
    mov     r8d, eax
    mov     r9d, eax

    mov     rcx, rsi
    dec     rcx
    jz      .after_scan

    add     rdi, 4

.scan_loop:
    mov     eax, [rdi]
    
    cmp     eax, r8d
    jge     .check_max
    mov     r8d, eax


.check_max:
    cmp     eax, r9d
    jle     .next_elem
    mov     r9d, eax
    
.next_elem:
    add     rdi, 4
    dec     rcx
    jnz     .scan_loop

.after_scan:
    test    r12, r12
    jz      .skip_min
    mov     dword [r12], r8d
.skip_min:
    test    r13, r13
    jz      .skip_max
    mov     dword [r13], r9d
.skip_max:
    movsxd  rax, r8d
    movsxd  rdx, r9d
    add     rax, rdx

.epilogue:
    pop     r13
    pop     r12
    pop     rbp
    ret

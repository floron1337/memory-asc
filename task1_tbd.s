EXEC_GET:
    movl $0, %ecx
    
    GET_LOOP:
    cmp $1000, %ecx
    je EXIT_GET_LOOP

    // %edx = MEMORY[i]
    movl (%edi, %ecx, 4), %edx
    cmp file_descriptor, %edx
    jne CONTINUE_GET_LOOP

    movl %ecx, file_start
    movl %ecx, file_end
    incl file_end

    GET_FILE_LOOP:
    // %edx = MEMORY[file_end + 1]
    movl file_end, %eax
    inc %eax
    movl (%edi, %eax, 4), %edx
    cmp %edx, file_descriptor
    jne EXIT_GET_FILE_LOOP

    incl file_end
    jmp GET_FILE_LOOP

    EXIT_GET_FILE_LOOP:
    // printf("(%d, %d)\n", file_start, file_end);
    pushl file_end
    pushl file_start
    pushl $printf_get_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    jmp EXIT_GET_LOOP

    CONTINUE_GET_LOOP:
    inc %ecx
    jmp GET_LOOP

    EXIT_GET_LOOP:
    ret

EXEC_DELETE:
    mov $0, %ecx

    DELETE_LOOP:
    cmp $1000, %ecx
    je EXIT_DELETE_LOOP

    // %edx = MEMORY[i]
    movl (%edi, %ecx, 4), %edx
    cmp file_descriptor, %edx
    jne CONTINUE_DELETE_LOOP

    movl %ecx, %eax

    DELETE_FILE_SCAN_LOOP:
    // with %eax starting from the first occurence
    // of the file_descriptor
    // if(MEMORY[%eax] != file_descriptor){
    //     goto EXIT_DELETE_MEMORY_SCAN_LOOP;
    // }
    movl (%edi, %eax, 4), %edx
    cmp file_descriptor, %edx
    jne EXIT_DELETE_LOOP

    movl $0, (%edi, %eax, 4)

    inc %eax
    jmp DELETE_FILE_SCAN_LOOP

    CONTINUE_DELETE_LOOP:
    inc %ecx
    jmp DELETE_LOOP

    EXIT_DELETE_LOOP:
    ret


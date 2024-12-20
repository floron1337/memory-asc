.data
scanf_fmt: .asciz "%d"
printf_descriptor_fmt: .asciz "%d: ((%d, %d), (%d, %d))\n"
printf_get_fmt: .asciz "((%d, %d), (%d, %d))\n"

i: .long 0
j: .long 0

i_copy: .long 0
j_copy: .long 0
file_start_copy: .long 0
file_end_copy: .long 0

query_count: .long 0
query_code: .long 0
file_count: .long 0

file_descriptor: .long 0
file_sector: .long 0
file_size: .long 0
file_start: .long 0
file_end: .long 0

current_chunk_start: .long 0
current_chunk_end: .long 0
current_chunk_size: .long 0

free_chunk_size: .long 0

malloc_j: .long 0

defrag_in_progress: .long 0

MEMORY: .space 4202500

.text
CLEAR_MEMORY:
    movl $0, i
    movl $0, j
    
    CLEAR_MEMORY_LOOP:
    movl j, %ecx
    cmp $1025, %ecx
    jne CLEAR_CHECK_LOOP_END

    inc i
    movl $0, j

    CLEAR_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1025, %ecx
    je EXIT_CLEAR_MEMORY

    // MEMORY[i][j] = 0
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl $0, (%edi, %eax, 4)

    inc j
    jmp CLEAR_MEMORY_LOOP

    EXIT_CLEAR_MEMORY:
    ret

PRINT_MEMORY:
    mov $0, i
    mov $0, j

    PRINT_LOOP:
    movl j, %ecx
    cmp $1024, %ecx
    jne PRINT_CHECK_LOOP_END
    
    inc i
    movl $0, j

    PRINT_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1024, %ecx
    je EXIT_PRINT

    // %edx = MEMORY[i][j]
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl (%edi, %eax, 4), %edx

    cmp $0, %edx
    je CONTINUE_PRINT_LOOP

    movl %edx, file_descriptor
    movl j, %eax
    movl %eax, file_start
    movl %eax, file_end
    movl i, %eax
    movl %eax, file_sector

    FILE_SCAN_LOOP:
    // %edx = MEMORY[i][file_end + 1]
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    movl file_end, %ebx
    incl %ebx
    addl %ebx, %eax
    movl (%edi, %eax, 4), %edx

    cmp %edx, file_descriptor
    jne FILE_SCAN_LOOP_EXIT

    incl file_end
    jmp FILE_SCAN_LOOP

    FILE_SCAN_LOOP_EXIT:
    pushl file_end
    pushl file_sector
    pushl file_start
    pushl file_sector
    pushl file_descriptor
    pushl $printf_descriptor_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl file_end, %eax
    movl %eax, j

    CONTINUE_PRINT_LOOP:
    inc j
    jmp PRINT_LOOP

    EXIT_PRINT:
    ret

EXEC_ADD:
    movl $0, i
    movl $0, j
    movl $0, current_chunk_start
    movl $0, current_chunk_size
    movl $0, current_chunk_end

    ADD_MEMORY_SCAN_LOOP:
    movl j, %ecx
    cmp $1024, %ecx
    jne ADD_MEMORY_SCAN_CHECK_LOOP_END
    
    inc i
    movl $0, j
    movl $0, current_chunk_start
    movl $0, current_chunk_size
    movl $0, current_chunk_end

    ADD_MEMORY_SCAN_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1024, %ecx
    je ADD_MEMORY_SCAN_FAIL

    // store MEMORY[i][j] into %edx
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl (%edi, %eax, 4), %edx

    // if MEMORY[i] == 0
    //      current_chunk_size++;

    cmp $0, %edx
    je ADD_MEMORY_SCAN_EMPTY_CHUNK
    jmp ADD_MEMORY_SCAN_FULL_CHUNK

    ADD_MEMORY_SCAN_EMPTY_CHUNK:
    incl current_chunk_size

    // if current_chunk_size == 1
    //      current_chunk_start = j;

    cmpl $1, current_chunk_size
    jne ADD_MEMORY_SCAN_EMPTY_CHUNK_MALLOC

    movl j, %ebx
    movl %ebx, current_chunk_start

    // check if current chunk is big enough
    // if(current_chunk_size == file_size (%eax))
    ADD_MEMORY_SCAN_EMPTY_CHUNK_MALLOC:
    movl current_chunk_size, %eax
    cmp file_size, %eax
    jne ADD_CONTINUE_MEMORY_SCAN

    // current_chunk_end = current_chunk_start + current_chunk_size
    movl current_chunk_start, %eax
    addl current_chunk_size, %eax
    movl %eax, current_chunk_end
    
    // malloc_j = current_chunk_start
    movl current_chunk_start, %eax
    movl %eax, malloc_j

    MALLOC_LOOP:
    movl malloc_j, %edx
    cmp %edx, current_chunk_end
    je ADD_MEMORY_SCAN_SUCCESS

    // MEMORY[i][malloc_j] = file_descriptor
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl malloc_j, %eax
    movl file_descriptor, %ebx
    movl %ebx, (%edi, %eax, 4)
    
    incl malloc_j
    jmp MALLOC_LOOP

    jmp ADD_CONTINUE_MEMORY_SCAN

    ADD_MEMORY_SCAN_FULL_CHUNK:
    movl $0, current_chunk_size
    jmp ADD_CONTINUE_MEMORY_SCAN

    ADD_CONTINUE_MEMORY_SCAN:
    incl j
    jmp ADD_MEMORY_SCAN_LOOP

    ADD_MEMORY_SCAN_FAIL:
    movl $0, file_sector
    movl $0, file_start
    movl $0, file_end
    jmp ADD_MEMORY_SCAN_EXIT

    ADD_MEMORY_SCAN_SUCCESS:
    movl i, %eax
    movl current_chunk_start, %ebx
    movl current_chunk_end, %ecx
    decl %ecx

    movl %eax, file_sector
    movl %ebx, file_start
    movl %ecx, file_end

    
    ADD_MEMORY_SCAN_EXIT:
    pushl file_end
    pushl file_sector
    pushl file_start
    pushl file_sector
    pushl file_descriptor
    pushl $printf_descriptor_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    ret

EXEC_GET:
    movl $0, i
    movl $0, j
    
    GET_LOOP:
    movl j, %ecx
    cmp $1024, %ecx
    jne GET_CHECK_LOOP_END

    inc i
    movl $0, j

    GET_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1024, %ecx
    je EXIT_GET_LOOP_NOT_FOUND

    // %edx = MEMORY[i][j]
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl (%edi, %eax, 4), %edx
    cmp file_descriptor, %edx
    jne CONTINUE_GET_LOOP

    movl j, %ecx
    movl %ecx, file_start
    movl %ecx, file_end
    incl file_end
    movl i, %ebx
    movl %ebx, file_sector

    GET_FILE_LOOP:
    // %edx = MEMORY[i][file_end + 1]
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    movl file_end, %ebx
    inc %ebx
    addl %ebx, %eax
    movl (%edi, %eax, 4), %edx
    cmp %edx, file_descriptor
    jne EXIT_GET_FILE_LOOP

    incl file_end
    jmp GET_FILE_LOOP

    EXIT_GET_FILE_LOOP:
    // printf("(%d, %d)\n", file_start, file_end);
    pushl file_end
    pushl file_sector
    pushl file_start
    pushl file_sector
    pushl $printf_get_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    jmp EXIT_GET_LOOP_SUCCESS

    CONTINUE_GET_LOOP:
    inc j
    jmp GET_LOOP

    EXIT_GET_LOOP_NOT_FOUND:
    // printf("(%d, %d)", 0, 0)
    movl $0, file_sector
    movl $0, file_start
    movl $0, file_end

    pushl file_end
    pushl file_sector
    pushl file_start
    pushl file_sector
    pushl $printf_get_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    EXIT_GET_LOOP_SUCCESS:
    ret

EXEC_DELETE:
    mov $0, i
    mov $0, j

    DELETE_LOOP:
    movl j, %ecx
    cmp $1024, %ecx
    jne DELETE_CHECK_LOOP_END

    inc i
    movl $0, j

    DELETE_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1024, %ecx
    je EXIT_DELETE_LOOP

    // %edx = MEMORY[i][j]
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl (%edi, %eax, 4), %edx
    cmp file_descriptor, %edx
    jne CONTINUE_DELETE_LOOP

    movl j, %eax
    movl %eax, file_end

    DELETE_FILE_SCAN_LOOP:
    // with file_end starting from the first occurence
    // of the file_descriptor
    // if(MEMORY[i][file_end] != file_descriptor){
    //     goto EXIT_DELETE_MEMORY_SCAN_LOOP;
    // }
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl file_end, %eax
    movl (%edi, %eax, 4), %edx
    cmp file_descriptor, %edx
    jne EXIT_DELETE_LOOP

    movl $0, (%edi, %eax, 4)

    inc file_end
    jmp DELETE_FILE_SCAN_LOOP

    CONTINUE_DELETE_LOOP:
    inc j
    jmp DELETE_LOOP

    EXIT_DELETE_LOOP:
    ret

// TODO: fix major flaw with defragmentation
// the files need to keep their order
// so in order to do that, you must modify EXEC_ADD
// to start the process from where the last allocation left off
// USE the defrag_in_progress flag

EXEC_DEFRAGMENTATION:
    movl $0, i
    movl $0, j
    movl $0, free_chunk_size

    DEFRAG_LOOP:
    movl j, %ecx
    cmp $1024, %ecx
    jne DEFRAG_CHECK_LOOP_END

    inc i
    movl $0, j
    movl $0, free_chunk_size

    DEFRAG_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1024, %ecx
    je EXIT_DEFRAG_LOOP

    // %edx = MEMORY[i][j]
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl (%edi, %eax, 4), %edx

    cmp $0, %edx
    jne DEFRAG_TRY_SHIFT

    incl free_chunk_size
    jmp CONTINUE_DEFRAG_LOOP

    DEFRAG_TRY_SHIFT:
    cmpl $0, free_chunk_size
    jl CONTINUE_DEFRAG_LOOP

    movl %edx, file_descriptor
    movl j, %ebx
    movl %ebx, file_start
    incl %ebx
    movl %ebx, file_end

    DEFRAG_FILE_SCAN_LOOP:
    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl file_end, %eax
    movl (%edi, %eax, 4), %edx
    cmp file_descriptor, %edx
    jne EXIT_DEFRAG_FILE_SCAN_LOOP

    incl file_end
    jmp DEFRAG_FILE_SCAN_LOOP

    EXIT_DEFRAG_FILE_SCAN_LOOP:
    movl i, %eax
    movl j, %ebx
    movl file_start, %ecx
    movl file_end, %edx

    movl %eax, i_copy
    movl %ebx, j_copy
    movl %ecx, file_start_copy
    movl %edx, file_end_copy

    call EXEC_DELETE

    movl i_copy, %eax
    movl j_copy, %ebx
    movl file_start_copy, %ecx
    movl file_end_copy, %edx

    movl %eax, i
    movl %ebx, j
    movl %ecx, file_start
    movl %edx, file_end

    movl file_end, %eax
    subl file_start, %eax
    movl %eax, file_size

    call EXEC_ADD

    movl i_copy, %eax
    movl j_copy, %ebx
    movl file_start_copy, %ecx
    movl file_end_copy, %edx

    movl %eax, i
    movl %ebx, j
    movl %ecx, file_start
    movl %edx, file_end

    movl file_end, %eax
    subl free_chunk_size, %eax
    decl %eax
    movl %eax, j
    movl $0, free_chunk_size

    CONTINUE_DEFRAG_LOOP:
    incl j
    jmp DEFRAG_LOOP

    EXIT_DEFRAG_LOOP:
    ret

.global main
main:
    lea MEMORY, %edi
    call CLEAR_MEMORY

    // scanf("%d", &query_count);
    pushl $query_count
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

    QUERY_LOOP:
    cmpl $0, query_count
    je END_PROGRAM 

    // scanf("%d", &query_code);
    pushl $query_code
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

    // QUERY INSTRUCTION CODES
    // 1 - ADD 
    // 2 - GET
    // 3 - DELETE
    // 4 - DEFRAGMENTATION

    cmpl $1, query_code
    je HANDLE_ADD

    cmpl $2, query_code
    je HANDLE_GET

    cmpl $3, query_code
    je HANDLE_DELETE

    cmpl $4, query_code
    je HANDLE_DEFRAGMENTATION

    HANDLE_ADD:
    // scanf("%d", &file_count);
    pushl $file_count
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

    ADD_LOOP:
        cmpl $0, file_count
        je EXIT_ADD_LOOP

        // scanf("%d", &file_descriptor);
        pushl $file_descriptor
        pushl $scanf_fmt
        call scanf
        popl %ebx
        popl %ebx

        // scanf("%d", &file_size);
        pushl $file_size
        pushl $scanf_fmt
        call scanf
        popl %ebx
        popl %ebx

        movl file_size, %eax
        addl $7, %eax
        movl $0, %edx
        movl $8, %ebx
        div %ebx

        movl %eax, file_size

        // EXEC_ADD(file_descriptor, file_size)
        call EXEC_ADD

        decl file_count
        jmp ADD_LOOP

    EXIT_ADD_LOOP:
    // call PRINT_MEMORY

    jmp CONTINUE_QUERY_LOOP

    HANDLE_GET:
    pushl $file_descriptor
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

    call EXEC_GET
    jmp CONTINUE_QUERY_LOOP

    HANDLE_DELETE:
    pushl $file_descriptor
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

    call EXEC_DELETE
    call PRINT_MEMORY

    jmp CONTINUE_QUERY_LOOP

    HANDLE_DEFRAGMENTATION:
    call EXEC_DEFRAGMENTATION
    // call PRINT_MEMORY
    jmp CONTINUE_QUERY_LOOP

    CONTINUE_QUERY_LOOP:
    decl query_count
    jmp QUERY_LOOP

    END_PROGRAM:
    pushl $0
    call fflush
    popl %ebx

    mov $1, %eax
    mov $0, %ebx
    int $0x80

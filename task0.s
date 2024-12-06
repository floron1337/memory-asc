.data
scanf_fmt: .asciz "%d"
printf_descriptor_fmt: .asciz "%d: (%d, %d)\n"
printf_get_fmt: .asciz "(%d, %d)\n"

query_count: .space 4
query_code: .space 4
file_count: .space 4

file_descriptor: .space 4
file_size: .space 4
file_start: .space 4
file_end: .space 4

current_chunk_start: .long 0
current_chunk_end: .long 0
current_chunk_size: .long 0

free_chunk_size: .long 0

malloc_i: .long 0

MEMORY: .space 4004

.text
CLEAR_MEMORY:
    mov $0, %ecx
    
    CLEAR_MEMORY_LOOP:
    cmp $1001, %ecx
    je EXIT_CLEAR_MEMORY

    movl $0, (%edi, %ecx, 4)

    inc %ecx
    jmp CLEAR_MEMORY_LOOP

    EXIT_CLEAR_MEMORY:
    ret

PRINT_MEMORY:
    mov $0, %ecx
    PRINT_LOOP:
    cmp $1000, %ecx
    je EXIT_PRINT

    // %edx = MEMORY[i]
    movl (%edi, %ecx, 4), %edx
    cmp $0, %edx
    je CONTINUE_PRINT_LOOP

    mov %edx, file_descriptor
    mov %ecx, file_start
    mov %ecx, file_end

    FILE_SCAN_LOOP:
    // %edx = MEMORY[file_end + 1]
    mov file_end, %eax
    inc %eax
    movl (%edi, %eax, 4), %edx
    cmp %edx, file_descriptor
    jne FILE_SCAN_LOOP_EXIT

    incl file_end
    jmp FILE_SCAN_LOOP

    FILE_SCAN_LOOP_EXIT:
    pushl file_end
    pushl file_start
    pushl file_descriptor
    pushl $printf_descriptor_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl file_end, %ecx

    CONTINUE_PRINT_LOOP:
    inc %ecx
    jmp PRINT_LOOP

    EXIT_PRINT:
    ret

EXEC_ADD:
    // Slice the file into chunks of 8kb
    // and calculate the number of required chunks
    // file_size = ceil(file_size / 8)

    movl file_size, %eax
    movl $0, %edx
    movl $8, %ebx
    div %ebx

    movl %eax, file_size

    cmp $0, %edx
    je ADD_INIT_MEMORY_SCAN

    incl file_size

    ADD_INIT_MEMORY_SCAN:
    movl $0, %ecx
    movl $0, current_chunk_start
    movl $0, current_chunk_size
    movl $0, current_chunk_end

    ADD_MEMORY_SCAN_LOOP:
    cmp $1000, %ecx
    je ADD_MEMORY_SCAN_EXIT

    // store MEMORY[i] into %edx
    movl (%edi, %ecx, 4), %edx

    // if MEMORY[i] == 0
    //      current_chunk_size++;

    cmp $0, %edx
    je ADD_MEMORY_SCAN_EMPTY_CHUNK
    jmp ADD_MEMORY_SCAN_FULL_CHUNK

    ADD_MEMORY_SCAN_EMPTY_CHUNK:
    incl current_chunk_size

    // if current_chunk_size == 1
    //      current_chunk_start = i;

    cmpl $1, current_chunk_size
    jne ADD_MEMORY_SCAN_EMPTY_CHUNK_MALLOC

    movl %ecx, current_chunk_start

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
    
    // malloc_i = current_chunk_start
    movl current_chunk_start, %eax
    movl %eax, malloc_i

    MALLOC_LOOP:
    movl malloc_i, %edx
    cmp %edx, current_chunk_end
    je ADD_MEMORY_SCAN_EXIT

    // MEMORY[malloc_i] = file_descriptor
    mov file_descriptor, %eax
    movl %eax, (%edi, %edx, 4)
    incl malloc_i
    jmp MALLOC_LOOP

    jmp ADD_CONTINUE_MEMORY_SCAN

    ADD_MEMORY_SCAN_FULL_CHUNK:
    movl $0, current_chunk_size
    jmp ADD_CONTINUE_MEMORY_SCAN

    ADD_CONTINUE_MEMORY_SCAN:
    incl %ecx
    jmp ADD_MEMORY_SCAN_LOOP

    ADD_MEMORY_SCAN_EXIT:
    ret

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

EXEC_DEFRAGMENTATION:
    movl $0, %ecx
    movl $0, free_chunk_size

    DEFRAG_LOOP:
    cmp $1000, %ecx
    je EXIT_DEFRAG_LOOP

    // %edx = MEMORY[i]
    movl (%edi, %ecx, 4), %edx

    cmp $0, %edx
    jne DEFRAG_TRY_SHIFT

    incl free_chunk_size
    jmp CONTINUE_DEFRAG_LOOP

    DEFRAG_TRY_SHIFT:
    cmpl $0, free_chunk_size
    jl CONTINUE_DEFRAG_LOOP

    movl %edx, file_descriptor
    movl %ecx, file_start
    movl %ecx, file_end

    DEFRAG_FILE_SCAN_LOOP:
    movl file_end, %eax
    movl (%edi, %eax, 4), %edx
    cmp file_descriptor, %edx
    jne EXIT_DEFRAG_FILE_SCAN_LOOP

    incl file_end
    jmp DEFRAG_FILE_SCAN_LOOP

    EXIT_DEFRAG_FILE_SCAN_LOOP:
    movl file_end, %eax
    subl file_start, %eax
    movl $0, %edx
    movl $8, %ebx
    mul %ebx

    movl %eax, file_size
    call EXEC_DELETE
    call EXEC_ADD

    movl file_end, %eax
    subl free_chunk_size, %eax
    movl %eax, %ecx
    movl $0, free_chunk_size

    CONTINUE_DEFRAG_LOOP:
    inc %ecx
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

        // EXEC_ADD(file_descriptor, file_size)
        call EXEC_ADD

        decl file_count
        jmp ADD_LOOP

    EXIT_ADD_LOOP:
    call PRINT_MEMORY
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
    call PRINT_MEMORY
    jmp CONTINUE_QUERY_LOOP

    CONTINUE_QUERY_LOOP:
    decl query_count
    jmp QUERY_LOOP

    END_PROGRAM:
    mov $1, %eax
    mov $0, %ebx
    int $0x80

.data
scanf_fmt: .asciz "%d"
scanf_string_fmt: .asciz "%s"

printf_descriptor_fmt: .asciz "%d: ((%d, %d), (%d, %d))\n"
printf_get_fmt: .asciz "((%d, %d), (%d, %d))\n"

i: .long 0
j: .long 0

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

last_i: .long 0
last_j: .long 0

MEMORY: .space 4202500

// CONCRETE VARIABLES
exists: .long 0
dir: .space 4
dir_path: .space 2048
entry: .space 4
d_name: .space 256
fds: .long 0
fileStat: .space 256
file_path: .space 2048
ignore1: .asciz "."
ignore2: .asciz ".."
slash: .asciz "/"

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

CHECK_EXISTENCE:
    movl $0, i
    movl $0, j
    movl $0, exists

    CHECK_EXISTENCE_LOOP:
    movl j, %ecx
    cmp $1024, %ecx
    jne CHECK_EXISTENCE_CHECK_LOOP_END

    inc i
    movl $0, j

    CHECK_EXISTENCE_CHECK_LOOP_END:
    movl i, %ecx
    cmp $1024, %ecx
    je EXIT_CHECK_EXISTENCE

    movl i, %eax
    movl $0, %edx
    movl $1024, %ebx
    mull %ebx
    addl j, %eax
    movl (%edi, %eax, 4), %edx

    cmp file_descriptor, %edx
    je EXIT_FILE_FOUND

    inc j
    jmp CHECK_EXISTENCE_LOOP

    EXIT_FILE_FOUND:
    movl $1, exists

    EXIT_CHECK_EXISTENCE:
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
    cmp $0, defrag_in_progress
    jne ADD_START
    movl $0, i
    movl $0, j

    ADD_START:
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


EXEC_DEFRAGMENTATION:
    movl $1, defrag_in_progress

    movl $0, last_i
    movl $0, last_j
    
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

    movl file_end, %eax
    subl file_start, %eax
    movl %eax, file_size

    call EXEC_DELETE

    movl last_i, %eax
    movl last_j, %ebx

    movl %eax, i
    movl %ebx, j

    call EXEC_ADD

    movl file_sector, %eax
    movl file_end, %ebx

    movl %eax, i
    movl %ebx, j
    
    movl %eax, last_i
    movl %ebx, last_j

    movl $0, free_chunk_size

    CONTINUE_DEFRAG_LOOP:
    incl j
    jmp DEFRAG_LOOP

    EXIT_DEFRAG_LOOP:
    movl $0, defrag_in_progress
    ret

EXEC_CONCRETE:
    //DIR* dir = opendir(folderPath);
    pushl $dir_path
    call opendir
    popl %ebx
    movl %eax, dir

    // while ((entry = readdir(dir)) != NULL)
    CONCRETE_LOOP:
    pushl dir
    call readdir
    popl %ebx
    movl %eax, entry

    cmp $0, entry
    je EXIT_CONCRETE_LOOP

    movl entry, %eax       
    addl $11, %eax        
    movl %eax, d_name       

    pushl $ignore1
    pushl d_name
    call strcmp
    addl $8, %esp

    cmp $0, %eax
    je CONCRETE_LOOP

    pushl $ignore2
    pushl d_name
    call strcmp
    addl $8, %esp

    cmp $0, %eax
    je CONCRETE_LOOP

    // strcpy(filePath, folderPath);
    // strcat(filePath, "/");
    // strcat(filePath, entry->d_name);

    pushl $dir_path
    pushl $file_path
    call strcpy
    addl $8, %esp

    pushl $slash
    pushl $file_path
    call strcat
    addl $8, %esp

    pushl d_name
    pushl $file_path
    call strcat
    addl $8, %esp

    pushl $fileStat
    pushl $file_path
    call stat
    addl $8, %esp

    lea fileStat, %eax      
    movl 12(%eax), %eax      
    movl %eax, fds

    movl fds, %eax                
    movl $255, %ecx                    
    movl $0, %edx                    
    divl %ecx                          
    addl $1, %edx                     

    movl %edx, file_descriptor

    lea fileStat, %eax     
    movl 44(%eax), %eax  
    //addl $8, %eax   
    movl $0, %edx
    movl $1024, %ecx
    divl %ecx
    movl %eax, file_size

    movl file_size, %eax
    addl $8, %eax
    movl $0, %edx
    movl $8, %ebx
    div %ebx

    movl %eax, file_size

    call CHECK_EXISTENCE
    cmp $1, exists
    je CONCRETE_ALREADY_EXISTS

    call EXEC_ADD
    jmp CONCRETE_LOOP

    CONCRETE_ALREADY_EXISTS:
    pushl $0
    pushl $0
    pushl $0
    pushl $0
    pushl file_descriptor
    pushl $printf_descriptor_fmt
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    jmp CONCRETE_LOOP

    EXIT_CONCRETE_LOOP:
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

    cmpl $5, query_code
    je HANDLE_CONCRETE

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

    HANDLE_CONCRETE:
    pushl $dir_path
    pushl $scanf_string_fmt
    call scanf
    popl %ebx
    popl %ebx

    call EXEC_CONCRETE
    
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

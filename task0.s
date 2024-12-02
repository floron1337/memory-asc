.data
scanf_fmt: .asciz "%d"
query_count: .space 4
query_code: .space 4
file_count: .space 4

file_descriptor: .space 4
file_size: .space 4
file_start: .space 4
file_end: .space 4

MEMORY: .space 1001

.text
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

    inc file_size

ADD_INIT_MEMORY_SCAN:

    ret

EXEC_GET:
    ret

EXEC_DELETE:
    ret

EXEC_DEFRAGMENTATION:
    ret

.global main
main:
    lea MEMORY, %edi

    // scanf("%d", &query_count);
    pushl $query_count
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

QUERY_LOOP:
    cmp $0, query_count
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

    cmp $1, query_code
    je HANDLE_ADD

    cmp $2, query_code
    je HANDLE_GET

    cmp $3, query_code
    je HANDLE_DELETE

    cmp $4, query_code
    je HANDLE_DEFRAGMENTATION

HANDLE_ADD:
    // scanf("%d", &file_count);
    pushl $file_count
    pushl $scanf_fmt
    call scanf
    popl %ebx
    popl %ebx

    ADD_LOOP:
        cmp $0, file_count
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

        dec file_count
        jmp ADD_LOOP
    EXIT_ADD_LOOP:
    jmp CONTINUE_QUERY_LOOP

HANDLE_GET:

    jmp CONTINUE_QUERY_LOOP

HANDLE_DELETE:

    jmp CONTINUE_QUERY_LOOP

HANDLE_DEFRAGMENTATION:

    jmp CONTINUE_QUERY_LOOP

CONTINUE_QUERY_LOOP:
    dec query_count
    jmp QUERY_LOOP

END_PROGRAM:
    mov $1, %eax
    mov $0, %ebx
    int $0x80

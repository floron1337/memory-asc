.data
    dir_path: .asciz "/home/floron/Desktop/fmi/asc/tema/qDPVlwMVpb"   # Path to the directory
    file_path: .space 2048
    fmt: .asciz "%d\n"         # Format string for printf
    debug: .space 256
    dir: .space 4
    entry: .space 4
    d_name: .space 256
    ignore1: .asciz "."
    ignore2: .asciz ".."
    slash: .asciz "/"
    fds: .long 0
    fileStat: .space 256

    file_size: .long 0
    file_descriptor: .long 0

.text

.global main

main:
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
    je EXIT

    movl entry, %eax       # Load entry (struct dirent*) into EAX
    addl $11, %eax         # Offset for d_name (assuming it’s at offset 11)
    movl %eax, d_name       # Save pointer to d_name in debug

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
    movl $0, %edx
    movl $1024, %ecx
    divl %ecx
    movl %eax, file_size

    pushl file_size
    pushl $fmt
    call printf
    addl $8, %esp

    jmp CONCRETE_LOOP

    EXIT:
    # Exit the program
    movl $1, %eax              # syscall number for exit
    xorl %ebx, %ebx            # Exit status 0
    int $0x80

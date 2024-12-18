#include <stdio.h>

#define MEMORY_SIZE 1025

int query_count = 0;
int MEMORY[MEMORY_SIZE];

void CLEAR_MEMORY(){
    int i = 0;
    CLEAR_MEMORY_LOOP:
    if(i == MEMORY_SIZE){
        goto CLEAR_MEMORY_EXIT;
    }
    MEMORY[i] = 0;
    i++;
    goto CLEAR_MEMORY_LOOP;
    CLEAR_MEMORY_EXIT:
}

void PRINT_MEMORY(){
    int i = 0;
    PRINT_LOOP:
    if(i == 1000){
        goto EXIT_PRINT_LOOP;
    }

    if(MEMORY[i] != 0){
        int file_descriptor = MEMORY[i];
        int file_start = i;
        int file_end = i;

        FILE_SCAN_LOOP:
        if(MEMORY[file_end + 1] != file_descriptor){
            goto FILE_SCAN_LOOP_EXIT;
        }

        file_end++;
        goto FILE_SCAN_LOOP;

        FILE_SCAN_LOOP_EXIT:
        printf("%d: (%d, %d)\n", file_descriptor, file_start, file_end);
        i = file_end;
    }

    i++;
    goto PRINT_LOOP;

    EXIT_PRINT_LOOP:

}

void EXEC_ADD(int file_descriptor, int file_size){

    file_size = (file_size + 7) / 8;

    int i = 0;
    int current_chunk_start = 0;
    int current_chunk_size = 0;
    int current_chunk_end = 0;
    
    ADD_MEMORY_SCAN_LOOP:
    if(i == MEMORY_SIZE){
        goto ADD_MEMORY_SCAN_EXIT;
    }

    if(MEMORY[i] == 0){
        current_chunk_size++;

        if(current_chunk_size == 1){
            current_chunk_start = i;
        }

        if(current_chunk_size == file_size){
            current_chunk_end = current_chunk_start + current_chunk_size - 1;
            int malloc_i = current_chunk_start;

            MALLOC_LOOP:
            if(malloc_i == current_chunk_end + 1){
                goto ADD_MEMORY_SCAN_EXIT;
            }
            
            MEMORY[malloc_i] = file_descriptor;
            malloc_i++;
            goto MALLOC_LOOP;
        }
    }
    else{
        current_chunk_size = 0;
    }
    i++;
    goto ADD_MEMORY_SCAN_LOOP;

    ADD_MEMORY_SCAN_EXIT:
}

void EXEC_GET(int file_descriptor){
    int i = 0;
    GET_MEMORY_SCAN_LOOP:
    if(i == 1000){
        goto EXIT_GET_MEMORY_SCAN_LOOP;
    }

    if(MEMORY[i] == file_descriptor){
        int file_start = i;
        int file_end = i + 1;

        GET_FILE_SCAN_LOOP:
        if(MEMORY[file_end + 1] != file_descriptor){
            goto GET_FILE_SCAN_LOOP_EXIT;
        }

        file_end++;
        goto GET_FILE_SCAN_LOOP;

        GET_FILE_SCAN_LOOP_EXIT:
        printf("(%d, %d)\n", file_start, file_end);
        goto EXIT_GET_MEMORY_SCAN_LOOP;
    }

    i++;
    goto GET_MEMORY_SCAN_LOOP;

    EXIT_GET_MEMORY_SCAN_LOOP:
}

void EXEC_DELETE(int file_descriptor){
    int i = 0;

    DELETE_MEMORY_SCAN_LOOP:
    if(i == 1000){
        goto EXIT_DELETE_MEMORY_SCAN_LOOP;
    }

    if(MEMORY[i] == file_descriptor){
        int file_it = i;

        DELETE_FILE_SCAN_LOOP:
        if(MEMORY[file_it] != file_descriptor){
            goto EXIT_DELETE_MEMORY_SCAN_LOOP;
        }
        MEMORY[file_it] = 0;

        file_it++;
        goto DELETE_FILE_SCAN_LOOP;
    }

    i++;
    goto DELETE_MEMORY_SCAN_LOOP;

    EXIT_DELETE_MEMORY_SCAN_LOOP:
}

void EXEC_DEFRAGMENTATION(){
    int i = 0;
    int free_chunk_size = 0;

    DEFRAG_MEMORY_SCAN_LOOP:
    if(i == 1024){
        goto EXIT_DEFRAG_MEMORY_SCAN_LOOP;
    }

    if(MEMORY[i] == 0){
        free_chunk_size++;
    }

    if(MEMORY[i] != 0 && free_chunk_size > 0){
        int file_descriptor = MEMORY[i];
        int file_start = i;
        int file_end = i + 1;

        DEFRAG_FILE_SCAN_LOOP:
        if(MEMORY[file_end] != file_descriptor){
            goto DEFRAG_FILE_SCAN_LOOP_EXIT;
        }

        file_end++;
        goto DEFRAG_FILE_SCAN_LOOP;

        DEFRAG_FILE_SCAN_LOOP_EXIT:
        int file_size = (file_end - file_start) * 8;

        EXEC_DELETE(file_descriptor);
        EXEC_ADD(file_descriptor, file_size);

        i = file_end - free_chunk_size;
        free_chunk_size = 0;
    }

    i++;
    goto DEFRAG_MEMORY_SCAN_LOOP;

    EXIT_DEFRAG_MEMORY_SCAN_LOOP:
}

int main(){
    scanf("%d", &query_count);

    QUERY_LOOP:
    if(query_count == 0){
        goto END_PROGRAM;
    }
    /* 
    QUERY INSTRUCTION CODES
    1 - ADD 
    2 - GET
    3 - DELETE
    4 - DEFRAGMENTATION
    */

    int query_code = 0;
    scanf("%d", &query_code);

    if(query_code == 1){
        int file_count = 0;
        scanf("%d", &file_count);

        ADD_LOOP:
        if(file_count == 0){
            goto EXIT_ADD_LOOP;
        }
        int file_descriptor = 0;
        scanf("%d", &file_descriptor);

        int file_size = 0;
        scanf("%d", &file_size);
        
        EXEC_ADD(file_descriptor, file_size);

        file_count--;
        goto ADD_LOOP;

        EXIT_ADD_LOOP:
        PRINT_MEMORY();
    }
    else if(query_code == 2){
        int file_descriptor = 0;
        scanf("%d", &file_descriptor);
        EXEC_GET(file_descriptor);
    }
    else if(query_code == 3){
        int file_descriptor = 0;
        scanf("%d", &file_descriptor);
        EXEC_DELETE(file_descriptor);
        PRINT_MEMORY();
    }
    else if(query_code == 4){
        EXEC_DEFRAGMENTATION();
        PRINT_MEMORY();
    }

    query_count--;
    goto QUERY_LOOP;

    END_PROGRAM:
    return 0;
}
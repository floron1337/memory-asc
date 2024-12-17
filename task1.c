#include <stdio.h>

#define MEMORY_SIZE 1025

int query_count = 0;
int MEMORY[MEMORY_SIZE][MEMORY_SIZE];

void CLEAR_MEMORY(){
    int i = 0;
    int j = 0;
    CLEAR_MEMORY_LOOP:
    if(j == MEMORY_SIZE){
        i++;
        j = 0;
    }
    if(i == MEMORY_SIZE){
        goto EXIT_CLEAR_MEMORY;
    }

    MEMORY[i][j] = 0;
    j++;
    goto CLEAR_MEMORY_LOOP;
    EXIT_CLEAR_MEMORY:
}

void PRINT_MEMORY(){
    int i = 0;
    int j = 0;
    PRINT_LOOP:
    if(j == MEMORY_SIZE){
        i++;
        j = 0;
    }

    if(i == MEMORY_SIZE){
        goto EXIT_PRINT_LOOP;
    }

    if(MEMORY[i][j] != 0){
        int file_descriptor = MEMORY[i][j];
        int file_sector = i;
        int file_start = j;
        int file_end = j;

        FILE_SCAN_LOOP:
        if(MEMORY[i][file_end + 1] != file_descriptor){
            goto FILE_SCAN_LOOP_EXIT;
        }

        file_end++;
        goto FILE_SCAN_LOOP;

        FILE_SCAN_LOOP_EXIT:
        printf("%d: ((%d, %d) (%d, %d))\n", file_descriptor, file_sector, file_start, file_sector, file_end);
        j = file_end;
    }

    j++;
    goto PRINT_LOOP;

    EXIT_PRINT_LOOP:

}

void EXEC_ADD(int file_descriptor, int file_size){
    if(file_size % 8 == 0){
        file_size = file_size / 8;
    }
    else{
        file_size = file_size / 8 + 1;
    }

    int i = 0;
    int j = 0;
    int current_chunk_start = 0;
    int current_chunk_size = 0;
    int current_chunk_end = 0;
    
    ADD_MEMORY_SCAN_LOOP:
    if(j == MEMORY_SIZE){
        i++;
        j = 0;
        current_chunk_start = 0;
        current_chunk_size = 0;
        current_chunk_end = 0;
    }

    if(i == MEMORY_SIZE){
        goto ADD_MEMORY_SCAN_EXIT;
    }

    if(MEMORY[i][j] == 0){
        current_chunk_size++;

        if(current_chunk_size == 1){
            current_chunk_start = j;
        }

        if(current_chunk_size == file_size){
            current_chunk_end = current_chunk_start + current_chunk_size - 1;
            int malloc_j = current_chunk_start;

            MALLOC_LOOP:
            if(malloc_j == current_chunk_end + 1){
                goto ADD_MEMORY_SCAN_EXIT;
            }
            
            MEMORY[i][malloc_j] = file_descriptor;
            malloc_j++;
            goto MALLOC_LOOP;
        }
    }
    else{
        current_chunk_size = 0;
    }
    j++;
    goto ADD_MEMORY_SCAN_LOOP;

    ADD_MEMORY_SCAN_EXIT:
}

void EXEC_GET(int file_descriptor){
    int i = 0;
    int j = 0;
    GET_LOOP:
    if(j == 1000){
        i++;
        j = 0;
    }

    if(i == 1000){
        goto EXIT_GET_LOOP;
    }

    if(MEMORY[i][j] == file_descriptor){
        int file_sector = i;
        int file_start = j;
        int file_end = j + 1;

        GET_FILE_SCAN_LOOP:
        if(MEMORY[i][file_end + 1] != file_descriptor){
            goto GET_FILE_SCAN_LOOP_EXIT;
        }

        file_end++;
        goto GET_FILE_SCAN_LOOP;

        GET_FILE_SCAN_LOOP_EXIT:
        printf("((%d, %d), (%d, %d))\n", file_sector, file_start, file_sector, file_end);
        goto EXIT_GET_LOOP;
    }

    j++;
    goto GET_LOOP;

    EXIT_GET_LOOP:
}

void EXEC_DELETE(int file_descriptor){
    int i = 0;
    int j = 0;

    DELETE_LOOP:
    if(j == 1000){
        i++;
        j = 0;
    }

    if(i == 1000){
        goto EXIT_DELETE_LOOP;
    }

    if(MEMORY[i][j] == file_descriptor){
        int file_it = j;

        DELETE_FILE_SCAN_LOOP:
        if(MEMORY[i][file_it] != file_descriptor){
            goto EXIT_DELETE_LOOP;
        }
        MEMORY[i][file_it] = 0;

        file_it++;
        goto DELETE_FILE_SCAN_LOOP;
    }

    j++;
    goto DELETE_LOOP;

    EXIT_DELETE_LOOP:
}

void EXEC_DEFRAGMENTATION(){
    int i = 0;
    int j = 0;
    int free_chunk_size = 0;

    DEFRAG_MEMORY_SCAN_LOOP:
    if(j == 1000){ 
        i++;
        j = 0;
        //free_chunk_size = 0;
    }

    if(i == 1000){
        goto EXIT_DEFRAG_MEMORY_SCAN_LOOP;
    }

    if(MEMORY[i][j] == 0){
        free_chunk_size++;
    }

    if(MEMORY[i][j] != 0 && free_chunk_size > 0){
        int file_descriptor = MEMORY[i][j];
        int file_start = j;
        int file_end = j + 1;

        DEFRAG_FILE_SCAN_LOOP:
        if(MEMORY[i][file_end] != file_descriptor){
            goto DEFRAG_FILE_SCAN_LOOP_EXIT;
        }

        file_end++;
        goto DEFRAG_FILE_SCAN_LOOP;

        DEFRAG_FILE_SCAN_LOOP_EXIT:
        int file_size = (file_end - file_start) * 8;

        EXEC_DELETE(file_descriptor);
        EXEC_ADD(file_descriptor, file_size);

        j = file_end - free_chunk_size;
        free_chunk_size = 0;
    }

    j++;
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
        printf("BEGIN DEFRAG\n");
        EXEC_DEFRAGMENTATION();
        PRINT_MEMORY();
    }

    query_count--;
    goto QUERY_LOOP;

    END_PROGRAM:
    return 0;
}
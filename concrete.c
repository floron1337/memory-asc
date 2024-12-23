#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

int main() {
    const char *folderPath = "/home/floron/Desktop/fmi/asc/tema/qDPVlwMVpb"; // Path to the folder
    
    struct dirent *entry;
    DIR *dir;
    // Open the directory
    dir = opendir(folderPath);
    if (dir == NULL) {
        perror("opendir");
        return 1;
    }

    // Iterate through directory entries
    while ((entry = readdir(dir)) != NULL) {
        // Skip "." and ".." entries
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // Build full path for the current file
        char filePath[1024];
        strcpy(filePath, folderPath);
        strcat(filePath, "/");
        strcat(filePath, entry->d_name);

        //int fds = open(filePath, 0);
        struct stat fileStat;
        stat(filePath, &fileStat);

        int fd = (fileStat.st_ino) % 255 + 1;
        int size = fileStat.st_size / 1024;

        printf("%d\n", size);
        //close(fds);
        
    }

    // Close the directory
    closedir(dir);
    return 0;
}

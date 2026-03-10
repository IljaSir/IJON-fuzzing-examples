#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef IJON_SET
  #define IJON_SET(x)
#endif

int main(int argc, char **argv) {
    char buf[128] = {0};
    if (read(STDIN_FILENO, buf, 127) <= 0) return 0;

    // A 10x10 Maze. 'S' is Start (0,0), 'E' is End (9,9)
    // The path requires ~30 highly specific, alternating moves.
    const char *maze[10] = {
        "S.########",
        "#........#",
        "########.#",
        "########.#",
        "#........#",
        "#.########",
        "#.########",
        "#........#",
        "########.#",
        "########.E"
    };

    int x = 0, y = 0;

    for (int i = 0; i < strlen(buf); i++) {
        int next_x = x, next_y = y;

        // Parse direction
        if (buf[i] == 'U') next_y--;
        else if (buf[i] == 'D') next_y++;
        else if (buf[i] == 'R') next_x++;
        else if (buf[i] == 'L') next_x--;
        else continue;

        // Break if we go out of bounds or hit a wall '#'
        if (next_x < 0 || next_x > 9 || next_y < 0 || next_y > 9) break;
        if (maze[next_y][next_x] == '#') break;

        // Move is valid, update coordinates
        x = next_x;
        y = next_y;

        // THE IJON FIX: 
        // Combine X and Y into a single integer. 
        // IJON_SET tells the fuzzer: "This specific coordinate is a new state, save the input!"
        IJON_SET((x << 8) | y);
        
        if (maze[y][x] == 'E') {
            printf("Escaped the maze!\n");
            abort(); 
        }
    }
    return 0;
}
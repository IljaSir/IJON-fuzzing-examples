#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#ifndef IJON_MAX
  #define IJON_MAX(slot, val)
#endif

int main() {
    char buf[16] = {0};
    
    // Strict size to prevent AFL++ from using length variations as coverage
    if (read(STDIN_FILENO, buf, 16) != 16) return 0;

    int score = 0;
    const char *secret = "PROTOCOL_PARSING";

    for (int i = 0; i < 16; i++) {
        // Branchless comparison. 
        score += (buf[i] == secret[i]);
    }

    // THE IJON FIX:
    // IJON_MAX runs a hill climbing optimization for score variable.
    IJON_MAX(1, score);

    if (score == 16) {
        printf("CRASH: IJON_MAX climbed the gradient!\n");
        abort();
    }

    return 0;
}
# AFL++ IJON: The 2D Maze Proof of Concept

This repository contains a minimal, self-contained Proof of Concept (PoC) demonstrating the power of the **IJON annotation framework** in [AFL++](https://github.com/AFLplusplus/AFLplusplus). 

It illustrates a classic fuzzing roadblock—**state space traversal without code branching**—and shows how `IJON_SET` can solve a strict 30+ step sequence in seconds, whereas standard AFL++ would take millions of years to guess it blindly.

## The Problem: State Collapse
Standard AFL++ is guided by **edge coverage** (which lines of code are executed). 
In this PoC, the program parses directional moves (`U`, `D`, `L`, `R`) to navigate a 10x10 maze. 

Once standard AFL++ executes a valid move and hits a wall, it has achieved 100% code coverage of the parser loop. Moving from tile `(1,1)` to `(2,1)` executes the exact same C code as moving from `(2,1)` to `(3,1)`. Because no *new code* is executed, standard AFL++ stops saving inputs and goes completely blind, treating the entire path as a single sequence it has to guess via brute force.

## The Solution: `IJON_SET`
By adding a single annotation to the source code:
```c
IJON_SET((x << 8) | y);
```
We tell AFL++ to log the distinct `(x, y)` coordinates into a custom coverage map. Even if the code path is identical, the fuzzer gets a "reward" every time it discovers a new tile, turning an impossible exponential guessing game into a trivial linear sequence.

## Portability
This PoC includes safe macro fallbacks. It will compile cleanly on standard `gcc`, standard `afl-clang-fast`, and IJON-enabled compilers without throwing undefined reference or redefinition errors.

---

## 🚀 How to Run the Experiment

You will need AFL++ installed on your system. This repository already includes an `in` directory with a valid starting seed.

### 1. The Control (Standard AFL++)
Compile and run the target *without* IJON instrumentation.
```bash
afl-clang-fast maze.c -o maze_standard
afl-fuzz -i in -o out_standard ./maze_standard
```

**Observation:** Standard AFL++ will likely never navigate the maze, as it sees no "new" coverage after the first few moves.

### 2. The Solution (AFL++ with IJON)
Compile and run the target by enabling the IJON LLVM pass:

```bash
AFL_LLVM_IJON=1 afl-clang-fast maze.c -o maze_ijon
afl-fuzz -i in -o out_ijon ./maze_ijon
```

**Observation:** The fuzzer will track coordinates and find the 'E' tile (triggering the crash) within seconds.
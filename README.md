# AFL++ IJON: The Proof of Concept Examples

This repository contains a minimal, self-contained Proof of Concept (PoC) demonstrating the power of the **IJON annotation framework** in [AFL++](https://github.com/AFLplusplus/AFLplusplus). 

**Acknowledgments:** This project contains a couple of simple examples of IJON use, *[IJON: Exploring Deep State Spaces via Fuzzing](https://ieeexplore.ieee.org/document/9152719/)* (Aschermann et al., IEEE S&P 2020). You can find the original source code, extended documentation, and further examples at the official [RUB-SysSec/ijon GitHub repository](https://github.com/RUB-SysSec/ijon).

## Repository Structure

The repository is organized to separate the source code from the compiled binaries and fuzzing artifacts. 

Before building, your directory should look like this:

```text
.
├── src/
│   ├── ijon_max_example/
│   │   └── example.c        # The branchless gradient climbing PoC
│   └── ijon_set_example/
│       └── example.c        # The 2D Maze state collapse PoC
├── build.sh                 # The master build and scaffolding script
└── fuzz_template.sh         # Template used to generate fuzzer run scripts
```

## The Examples
* **IJON_SET (Maze):** Standard fuzzers get stuck in mazes because moving doesn't always trigger new code paths. `IJON_SET` exposes the player's X/Y coordinates directly to the fuzzer, turning navigation into a simple step-by-step mapping process.
* **IJON_MAX (Branchless String):** Standard fuzzers fail on branchless loops because partial matches don't create new coverage. `IJON_MAX` solves this by introducing a hill-climbing optimization, rewarding the fuzzer for maximizing a "score" variable.

## Building and Running
1. **Compile:** Run `./build.sh` to compile the default targets. To build a specific target, use `./build.sh custom_example`. This creates both a plain AFL++ binary and an IJON-instrumented binary.
2. **Fuzz:** The build script generates run scripts in the `helper_scripts/` directory.
   * Run `./helper_scripts/run_<target>_plain_afl_fuzzing.sh` to see standard AFL++ fuzzing.
   * Run `./helper_scripts/run_<target>_ijon_afl_fuzzing.sh` to see IJON instrumented fuzzing.
# IJON_SET Proof of Concept: Maze Navigation via State Exposure

This repository contains a Proof of Concept (PoC) demonstrating how to use the `IJON_SET` annotation to guide a fuzzer through a state space when standard code coverage provides insufficient feedback.

## The Problem: State Space vs. Code Coverage
Standard AFL-style fuzzers rely heavily on edge coverage to identify new and interesting regions of a target application. However, current fuzzers are not able to properly explore the state space of a program beyond code coverage. 

In this maze example, parsing a 'Right' command and successfully moving right executes the exact same C branches regardless of where the player is actually located on the grid. This creates a severe limitation for standard fuzzers:
* Program executions that result in the same code coverage, but different values in the state, cannot be explored appropriately by current fuzzers.
* There is no feedback that rewards exploring combinations of different updates leading to new states, if all individual updates have been observed previously.
* Without recognizing the player's unique position, standard AFL++ goes blind. It views navigating the maze as a single, massive guessing game, making it impossible to blindly stumble upon the ~30-step winning sequence.

## The Solution: IJON_SET
To overcome this, a human analyst can identify the known relevant state values and directly expose the state to the fuzzer. In the context of a labyrinth, it is essential to understand that the `x` and `y` coordinates are relevant states that need to be explored.

By packing the `x` and `y` coordinates together into a single integer and passing it to `IJON_SET((x << 8) | y);`, we fundamentally alter how the fuzzer evaluates its progress:
* The `IJON_SET` annotation sets the least significant bit of the bitmap value directly. 
* This effectively allows new values in the state to be considered as equal to new code coverage.
* We successfully instruct the fuzzer to consider any new pair as new coverage. 
* Because any newly visited position in the game is treated like new coverage, the fuzzer receives an incremental reward for every single new tile it steps on. 

This transforms an exponential brute-force guessing game into a trivial, step-by-step mapping of the game board, allowing the fuzzer to easily string together the correct sequence and trigger the crash.
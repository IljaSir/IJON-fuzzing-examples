# IJON_MAX Proof of Concept: Branchless Gradient Climbing

This repository contains a minimal Proof of Concept (PoC) demonstrating how to use the `IJON_MAX` annotation to solve complex, branchless constraints where standard coverage-guided fuzzers fail.

## The Problem: Branchless Execution
Standard AFL++ relies on edge coverage to determine if an input is "interesting" and worth saving. It does this by tracking which lines of code are executed and how many times loops iterate. 

In this example, the program checks a 16-byte input against the string `"PROTOCOL_PARSING"` using a **branchless loop**:
`score += (buf[i] == secret[i]);`

Because there are no `if` statements inside the loop, getting 1 byte correct triggers the exact same control-flow edges as getting 15 bytes correct. Standard AFL++ receives absolutely zero feedback for incremental progress. It discards partial successes and goes completely blind, requiring it to randomly guess all 16 bytes at once—a mathematically impossible $256^{16}$ search space.

## The Solution: IJON_MAX
To solve this, we use the `IJON_MAX` annotation, which introduces a hill-climbing optimization primitive to the fuzzer. 

By adding `IJON_MAX(1, score);`, we alter the fuzzer's behavior in the following ways:
* **The Target:** We instruct the fuzzer to maximize the `score` variable. We place this in slot `1` because the IJON scheduler specifically looks for non-zero slots when picking inputs to fuzz from its maximization queue.
* **The Max-Map:** IJON maintains a separate shared memory "max-map" alongside standard code coverage to track the largest observed values.
* **The Reward:** When a random mutation successfully guesses a correct character, `score` increments. IJON compares this against the global max-map, sees that it is a new high score, and saves the input to a dedicated maximization queue.
* **The Climb:** By scheduling inputs from this max-map queue based on the `IJON_SCHEDULE_MAXMAP` environment variable, the fuzzer iteratively mutates its best attempts. 

This completely changes the rules of the game. Instead of blind brute-forcing, the fuzzer plays a game of "Hot or Cold," walking straight up the gradient from a score of 0 to 16 to trigger the crash in seconds.
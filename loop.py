#!/usr/bin/env python3
import sys
from agent import agent_loop

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ai <your task>")
        sys.exit(1)
    task = " ".join(sys.argv[1:])
    agent_loop(task)
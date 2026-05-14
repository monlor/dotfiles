# ECC Tool Prompt: run-tests

Run the repository test suite with package-manager autodetection and concise reporting.

## Instructions
1. Detect package manager from lock files in this order: `pnpm-lock.yaml`, `bun.lockb`, `yarn.lock`, `package-lock.json`.
2. Detect available scripts or test commands for this repo.
3. Execute tests with the best project-native command.
4. If tests fail, report failing files/tests first, then the smallest likely fix list.
5. Do not change code unless explicitly asked.

## Output Format
```
RUN TESTS: [PASS/FAIL]
Command used: <command>
Summary: <x passed / y failed>
Top failures:
- ...
Suggested next step:
- ...
```

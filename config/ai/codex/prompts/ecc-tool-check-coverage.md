# ECC Tool Prompt: check-coverage

Analyze coverage and compare it to an 80% threshold (or a threshold I specify).

## Instructions
1. Find existing coverage artifacts first (`coverage/coverage-summary.json`, `coverage/coverage-final.json`, `.nyc_output/coverage.json`).
2. If missing, run the project's coverage command using the detected package manager.
3. Report total coverage and top under-covered files.
4. Fail the report if coverage is below threshold.

## Output Format
```
COVERAGE: [PASS/FAIL]
Threshold: <n>%
Total lines: <n>%
Total branches: <n>% (if available)
Worst files:
- path: xx%
Recommended focus:
- ...
```

# ECC Tool Prompt: security-audit

Run a practical security audit: dependency vulnerabilities + secret scan + high-risk code patterns.

## Instructions
1. Run dependency audit command for this repo/package manager.
2. Scan source and staged changes for high-signal secrets (OpenAI keys, GitHub tokens, AWS keys, private keys).
3. Scan for risky patterns (`eval(`, `dangerouslySetInnerHTML`, unsanitized `innerHTML`, obvious SQL string interpolation).
4. Prioritize findings by severity: CRITICAL, HIGH, MEDIUM, LOW.
5. Do not auto-fix unless I explicitly ask.

## Output Format
```
SECURITY AUDIT: [PASS/FAIL]
Dependency vulnerabilities: <summary>
Secrets findings: <count>
Code risk findings: <count>
Critical issues:
- ...
Remediation plan:
1. ...
2. ...
```

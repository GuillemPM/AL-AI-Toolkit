# Security Policy

## Supported versions

This project is pre-1.0. Security fixes are applied on `main` for the latest `0.1.x` line.

## Reporting a vulnerability

Do **not** open a public GitHub issue for security-sensitive reports.

Email the maintainer via the address on the GitHub profile for [GuillemPM](https://github.com/GuillemPM), with subject `AI Open SDK for Business Central security`, and include:

- Affected app(s) and version
- Description and impact
- Reproduction steps or proof of concept (if available)

You should receive an acknowledgement within 7 days.

## Scope notes

- Never commit API keys, tokens, or tenant identifiers.
- Prefer `SecretText` for credentials in AL.
- Provider apps perform outbound HTTPS to configured base URLs; treat BaseUrl overrides as trusted configuration.
- Outbound provider HTTP is gated by Business Central privacy notices (`AIOS-OPENAI`, `AIOS-ANTHROPIC`, `AIOS-OPENAI-COMPAT`, `AIOS-OPENCODE-ZEN`). Approve on **Privacy Notices Status** (admin Agree for everyone); send paths check approval state and do not prompt end users.

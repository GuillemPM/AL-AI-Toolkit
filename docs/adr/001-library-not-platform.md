# ADR-001: Library, not platform

- Status: Accepted
- Date: 2026-08

## Decision

AL AI Toolkit ships exclusively as AL code consumed via extension dependency. No hosted backend, no SaaS component, no telemetry collection point owned by the project.

## Alternatives considered

A companion hosted service for cross-tenant analytics, prompt management, or provider routing — the kind of thing that would let the project generate revenue and create a moat.

## Why rejected

The moment this project owns a hosted service handling customer prompts and API keys across tenants, it becomes a vendor with security, compliance, and uptime obligations — a much larger undertaking than a library. It also undermines the trust argument that makes a library adoptable in regulated BC deployments: “your data never leaves your own boundary except to the provider you configured” is a strong, simple guarantee a hosted component would complicate. A platform's incentive is to create dependency; a library's incentive is to stay genuinely useful for free.

## Cost of this decision

No natural monetization path for the maintainer beyond sponsorship/consulting — a genuine sustainability risk (see [ADR-008](008-bdfl-with-succession.md) and [GOVERNANCE.md](../../GOVERNANCE.md)).

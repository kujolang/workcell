# ADR 004: Versioned JSON Definitions

## Context

Definitions must parse deterministically without executing untrusted configuration code.

## Decision

Use JSON with explicit `version: 1`, safe defaults, strict unknown-field rejection, and semantic validation.

## Alternatives

A Kujo-native executable definition was rejected for the input format because reading configuration should not execute arbitrary code. TOML remains a possible future format if a consistent safe parser/schema path is established.

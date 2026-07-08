---
name: access-gate
description: Integrate and use the access_gate Flutter package in application code. Use when adding widget or page-level access control with AccessScope, AccessController, AccessContext, AccessPolicy, AccessGate, AccessGuard, typed enum keys, policy composition, structured denied states, JSON/server-driven policies, tests, or examples in a Flutter app that consumes access_gate.
---

# Access Gate

## Workflow

1. Inspect the target app's current auth, account, feature flag, remote config,
   claims, or backend policy source before writing gates.
2. Add or verify the `access_gate` dependency.
3. Create one `AccessContext` from existing app state; do not invent a separate
   authorization source.
4. Put `AccessScope` above the UI that needs shared access facts.
5. Choose the smallest UI primitive:
   - Use `AccessGate` for one widget or section.
   - Use `AccessGuard` for a page, route body, or tab.
   - Use `AccessBuilder` for fully custom branching.
6. Use typed enum keys in app code when the app has a stable access vocabulary.
7. Add widget tests for allowed and denied states.

## Integration Rules

- Keep server-side authorization, database rules, and API checks in place.
  `access_gate` only controls client-side visibility.
- Keep provider-facing keys stable strings. Typed enums should map to those
  strings through `accessKey`.
- Prefer `AccessPolicy.allOf`, `AccessPolicy.anyOf`, and `AccessPolicy.not`
  for readable complex policies.
- Use `decision.denialReasons` for structured fallback UI; use
  `decision.reasons` for simple messages.
- Use JSON helpers only for JSON-compatible contexts and policies. Do not try to
  serialize custom predicates.

## Reference

Read `references/integration-patterns.md` for concrete snippets covering
controller setup, typed keys, widget gates, page guards, composed policies,
structured denial reasons, JSON helpers, and tests.

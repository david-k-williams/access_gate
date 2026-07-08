## 0.0.3

* Changed `AccessHidden` to render as a zero-size widget so denied gates remain safe inside multi-child layouts.
* Added render-order regression coverage for denied gates in multi-child layouts and for the example app.
* Added consumer-oriented usage documentation and Agent Skills-compatible Codex and Claude Code guidance.

## 0.0.2

* Added policy composition with `AccessPolicy.allOf`, `AccessPolicy.anyOf`, and `AccessPolicy.not`.
* Added structured denial reasons on `AccessDecision`.
* Added `AccessGuard` for page-level and route-body access decisions.
* Added JSON helpers for `AccessContext` and serializable `AccessPolicy` values.
* Expanded docs and the example app.

## 0.0.1

* Initial release with feature flag, RBAC, permission, and ABAC widget gates.
* Added `AccessScope`, `AccessController`, `AccessPolicy`, and `AccessContext`.
* Added typed key helpers for enum-backed features, roles, permissions, and attributes.
* Added `AccessHidden`, a fallback for denied gates.

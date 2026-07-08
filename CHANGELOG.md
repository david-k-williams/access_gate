## 0.0.4

* Added `AccessContext.merge` and `AccessContext.combine` for building one context from multiple app state sources.
* Added convenience policy and gate constructors for any-of features, roles, permissions, exact feature values, and exact attributes, including typed-key variants.
* Added optional policy labels, labeled denial reasons, and lightweight diagnostics through value equality, `hashCode`, and `toString` support.
* Rebuilt the example app as an interactive controller-driven demo with denied states, disabled UI, and JSON previews.
* Expanded consumer docs, provider recipes, loading guidance, testing guidance, and Agent Skills-compatible references.

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

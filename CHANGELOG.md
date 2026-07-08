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
* Added `AccessHidden`, a zero-render-object fallback for denied gates.

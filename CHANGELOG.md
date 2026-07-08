## Unreleased

* Added policy composition with `AccessPolicy.allOf`, `AccessPolicy.anyOf`, and `AccessPolicy.not`.

## 0.0.1

* Initial release with feature flag, RBAC, permission, and ABAC widget gates.
* Added `AccessScope`, `AccessController`, `AccessPolicy`, and `AccessContext`.
* Added typed key helpers for enum-backed features, roles, permissions, and attributes.
* Added `AccessHidden`, a zero-render-object fallback for denied gates.

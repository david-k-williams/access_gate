# access_gate Claude Guide

This repository contains `access_gate`, a provider-agnostic Flutter package for
widget and page-level access control.

## Start Here

- Read `lib/access_gate.dart` to confirm the public exports.
- Read `doc/using-access-gate.md` to understand consumer integration patterns.
- Use the project skill at `.claude/skills/access-gate/` for consumer-facing
  integration work.
- Keep the core package dependency-free except for Flutter.
- Preserve compatibility for `AccessDecision.reasons`; structured denial reasons
  are additive via `AccessDecision.denialReasons`.

## Architecture

- `AccessContext` stores current access facts: features, feature values, roles,
  permissions, attributes, and optional `userId`.
- `AccessPolicy` evaluates access rules, including composition with `allOf`,
  `anyOf`, and `not`.
- `AccessController` is the mutable `ChangeNotifier` state holder.
- `AccessScope` provides a controller through the widget tree.
- `AccessGate`, `AccessBuilder`, and `AccessGuard` render access-aware UI.

## Implementation Rules

- Keep public APIs provider-agnostic. Do not add Firebase, LaunchDarkly,
  Supabase, router, or state-management package dependencies.
- Store access keys as strings internally. Add typed-key helpers only at API
  edges.
- Defensively copy collections in public model constructors.
- Keep denied decisions structured and message-compatible.
- Do not serialize predicates; functions are runtime-only.
- Add tests for every public API behavior change.

## Validation

Run these from the repository root:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
dart pub publish --dry-run
```

When changing the full example app, also run:

```bash
cd example
flutter pub get
flutter analyze
flutter test
```

## Release Notes

- Update `pubspec.yaml` for release version bumps.
- Update `CHANGELOG.md` with user-visible package changes.
- Run `dart pub publish --dry-run` from a clean git tree before publishing.

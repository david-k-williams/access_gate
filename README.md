# access_gate

Hide Flutter widgets behind feature flags, roles, permissions, and
attribute-based access policies.

`access_gate` is intentionally provider-agnostic. Bring your own source of
truth, such as Firebase Remote Config, LaunchDarkly, Supabase claims, local app
state, or a backend policy response, then expose those facts through
`AccessContext`.

## Features

- Feature flag gates with enabled flags and exact feature values.
- RBAC gates with required roles or any-of role checks.
- Permission gates for fine-grained access checks.
- ABAC gates with exact attributes and custom predicates.
- Policy composition with all-of, any-of, and not rules.
- Context composition for combining auth, flag, account, and local facts.
- Convenience constructors for any-of and exact value checks.
- Optional policy labels for structured denial diagnostics.
- Structured denial reasons for custom fallback UI.
- `AccessGuard` for page-level access decisions.
- JSON helpers for access contexts and serializable policies.
- `AccessScope` and `AccessController` for inherited access state.
- `AccessHidden`, a zero-size fallback for denied gates.

## Getting started

Add the package, then create an `AccessController` from your app's current
feature flag and authorization state.

```dart
final accessController = AccessController(
  AccessContext(
    enabledFeatures: {'advanced_reports'},
    roles: {'admin'},
    permissions: {'reports.view'},
    attributes: {'plan': 'pro', 'region': 'us'},
  ),
);
```

Place `AccessScope` above the widgets that should use the shared access state.

```dart
AccessScope(
  controller: accessController,
  child: const MyApp(),
);
```

When access facts come from multiple places, combine them into one context:

```dart
final context = AccessContext.combine([
  AccessContext(enabledFeatures: {'advanced_reports'}),
  AccessContext(permissions: {'reports.view'}),
  AccessContext(attributes: {'plan': 'pro'}),
]);

accessController.update(context);
```

## Basic usage

Require one feature flag:

```dart
AccessGate.feature(
  feature: 'advanced_reports',
  child: const AdvancedReportsButton(),
);
```

Require a role:

```dart
AccessGate.role(
  role: 'admin',
  fallback: const Text('Admin access required'),
  child: const AdminPanel(),
);
```

Require a permission:

```dart
AccessGate.permission(
  permission: 'reports.view',
  child: const ReportList(),
);
```

Require one of several roles:

```dart
AccessGate.anyRole(
  roles: {'admin', 'analyst'},
  child: const AnalystDashboard(),
);
```

Require an exact feature value or attribute:

```dart
AccessGate.featureValue(
  feature: 'checkout_variant',
  value: 'variant_b',
  child: const VariantCheckout(),
);

AccessGate.attribute(
  attribute: 'plan',
  value: 'pro',
  child: const ProReports(),
);
```

Combine feature flags, roles, permissions, and ABAC attributes:

```dart
AccessGate.when(
  allFeatures: {'advanced_reports'},
  anyRoles: {'admin', 'analyst'},
  allPermissions: {'reports.view'},
  attributes: {'plan': 'pro'},
  child: const AdvancedReportsPage(),
);
```

Use a custom predicate when exact attribute matching is not enough:

```dart
AccessGate.when(
  predicate: (context) {
    return context.attribute('teamId') == selectedTeamId &&
        context.attribute('plan') == 'enterprise';
  },
  predicateReason: 'Requires access to this team.',
  child: const TeamSettings(),
);
```

## Policy composition

Compose policies when access can be granted through multiple paths, or when an
allow rule needs an explicit exclusion.

```dart
final policy = AccessPolicy.allOf(
  [
    AccessPolicy.anyOf([
      AccessPolicy.role('admin', label: 'Admin role'),
      AccessPolicy(
        allPermissions: {'reports.view'},
        attributes: {'plan': 'pro'},
        label: 'Pro reports permission',
      ),
    ]),
    AccessPolicy.not(
      AccessPolicy.role('suspended'),
      reason: 'Suspended users cannot access reports.',
      label: 'Suspension exclusion',
    ),
  ],
  label: 'Advanced reports policy',
);

AccessGate(
  policy: policy,
  child: const AdvancedReportsPage(),
);
```

## Page guards

Use `AccessGuard` when the whole page or route body should branch on an access
decision.

```dart
AccessGuard(
  policy: AccessPolicy.permission('reports.view'),
  builder: (context, decision) {
    return const ReportsPage();
  },
  deniedBuilder: (context, decision) {
    return Text(decision.reasons.first);
  },
);
```

## Typed keys

The core API stores provider-facing strings, but apps can define typed keys with
enums by implementing the category marker interfaces.

```dart
enum AppFeature implements AccessFeature {
  advancedReports('advanced_reports');

  const AppFeature(this.accessKey);

  @override
  final String accessKey;
}

enum AppRole implements AccessRole {
  admin('admin');

  const AppRole(this.accessKey);

  @override
  final String accessKey;
}
```

Use `fromKeys` and `*Key` constructors when you want compile-time key names in
app code:

```dart
final context = AccessContext.fromKeys(
  enabledFeatures: {AppFeature.advancedReports},
  roles: {AppRole.admin},
);

AccessGate.featureKey(
  feature: AppFeature.advancedReports,
  child: const AdvancedReportsButton(),
);
```

If an enum's case name already matches the provider key, the `AccessEnumKey`
extension exposes `myEnumValue.accessKey` as a convenience.

## Denied access

By default, denied gates render `accessHidden`, a zero-size widget that is safe
inside layout widgets like `Column`, `Row`, and `Stack`. This is useful when a
widget should simply disappear.

```dart
AccessGate.feature(
  feature: 'new_checkout',
  child: const CheckoutButton(),
);
```

Use `fallback` or `fallbackBuilder` when denied users should see something.

```dart
AccessGate.permission(
  permission: 'billing.manage',
  fallbackBuilder: (context, decision) {
    final reason = decision.denialReasons.first;
    return Text('${reason.key}: ${reason.message}');
  },
  child: const BillingSettings(),
);
```

`decision.reasons` remains available as a simple list of messages.

Use `AccessBuilder` when denied UI should remain visible but disabled:

```dart
AccessBuilder(
  policy: AccessPolicy.permission(
    'billing.manage',
    label: 'Billing permission',
  ),
  builder: (context, decision) {
    return FilledButton(
      onPressed: decision.allowed ? openBilling : null,
      child: Text(
        decision.allowed ? 'Manage billing' : decision.reasons.first,
      ),
    );
  },
);
```

## JSON helpers

`AccessContext` can round-trip through JSON-compatible maps. Policies without
custom predicates can also be serialized, including composed policies.

```dart
final context = AccessContext.fromJson(savedContextJson);
final policy = AccessPolicy.fromJson(savedPolicyJson);

final contextJson = context.toJson();
final policyJson = policy.toJson();
```

Policy labels are included in JSON when present. Custom predicate functions are
runtime-only and cannot be serialized.

## Loading and bootstrap

An empty context denies protected UI by design. During auth, claims, remote
config, or backend bootstrap, show your app's loading shell until the first
real `AccessContext` is ready, then mount gated UI or call
`accessController.update(context)`.

## Agent-friendly usage

Coding agents integrating this package into Flutter apps should read
`doc/using-access-gate.md`.

The shared Agent Skills-compatible skill lives at `skills/access-gate/`. Codex
can use it from that location. Claude Code users can copy that folder to
`~/.claude/skills/access-gate/`, or use the project wrapper at
`.claude/skills/access-gate/` when working from this repository.

Repository-maintenance guidance is available in `AGENTS.md` for Codex and
`CLAUDE.md` for Claude Code.

## Important security note

`access_gate` controls client-side visibility. It is not a replacement for
server-side authorization, database security rules, API checks, or audit
controls. Use it to keep Flutter UI honest and ergonomic; enforce real access
at your data and service boundaries too.

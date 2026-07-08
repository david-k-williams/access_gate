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
- `AccessScope` and `AccessController` for inherited access state.
- `AccessHidden`, a zero-render-object fallback inspired by `nil`.

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
final policy = AccessPolicy.allOf([
  AccessPolicy.anyOf([
    AccessPolicy.role('admin'),
    AccessPolicy(
      allPermissions: {'reports.view'},
      attributes: {'plan': 'pro'},
    ),
  ]),
  AccessPolicy.not(
    AccessPolicy.role('suspended'),
    reason: 'Suspended users cannot access reports.',
  ),
]);

AccessGate(
  policy: policy,
  child: const AdvancedReportsPage(),
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

By default, denied gates render `accessHidden`, which creates only an element and
does not create a render object. This is useful when a widget should simply
disappear.

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
    return Text(decision.reasons.first);
  },
  child: const BillingSettings(),
);
```

## Important security note

`access_gate` controls client-side visibility. It is not a replacement for
server-side authorization, database security rules, API checks, or audit
controls. Use it to keep Flutter UI honest and ergonomic; enforce real access
at your data and service boundaries too.

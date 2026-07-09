# Using access_gate

This guide is for developers and coding agents adding `access_gate` to a
Flutter app. It focuses on integration patterns, not package maintenance.

## Choose Access Facts

Build one `AccessContext` from the app's current source of truth. That source
can be Firebase Remote Config, LaunchDarkly, Supabase claims, account state, a
backend policy response, local config, or a combination of those.

```dart
final controller = AccessController(
  AccessContext(
    enabledFeatures: {'advanced_reports'},
    roles: {'admin'},
    permissions: {'reports.view'},
    attributes: {'plan': 'pro', 'region': 'us'},
  ),
);
```

Put `AccessScope` above the UI that should share those facts:

```dart
AccessScope(
  controller: controller,
  child: const MyApp(),
);
```

Create the controller once in an application-owned lifecycle, such as a
`State` object or dependency container. `AccessScope` listens to the controller
but does not dispose it. The owner must call `controller.dispose()` when the
controller is no longer needed. Do not create a new controller inside a widget's
`build` method.

When the source of truth changes, update the controller:

```dart
controller.update(nextAccessContext);
```

If facts come from multiple sources, compose them before updating:

```dart
final context = AccessContext.combine([
  AccessContext(enabledFeatures: remoteConfigFeatures),
  AccessContext(roles: claimRoles, permissions: claimPermissions),
  AccessContext(attributes: {'plan': accountPlan, 'region': region}),
  AccessContext(featureValues: localOverrides),
]);
```

Later contexts override duplicate feature values and attributes. Feature, role,
and permission sets are unioned.

## Handle Bootstrap Loading

`AccessContext.empty()` denies protected UI by design. Avoid mounting gated UI
with an empty context while auth, claims, flags, or account data are still
loading. Show the app's normal loading shell first, then create or update the
controller once facts are ready.

```dart
if (!accessFactsReady) {
  return const AppLoadingShell();
}

return AccessScope(
  controller: controller,
  child: const MyApp(),
);
```

## Prefer Typed Keys In App Code

Raw strings are useful at provider boundaries. Inside app code, enums make
policies easier to refactor safely.

```dart
enum AppFeature implements AccessFeature {
  advancedReports('advanced_reports');

  const AppFeature(this.accessKey);

  @override
  final String accessKey;
}

final context = AccessContext.fromKeys(
  enabledFeatures: {AppFeature.advancedReports},
);
```

Keep the string values stable because those are the provider-facing contract.

## Gate Widgets

Use `AccessGate` when a specific widget should appear or disappear.

```dart
AccessGate.permission(
  permission: 'reports.view',
  fallback: const Text('Reports are not available.'),
  child: const ReportsButton(),
);
```

Use `AccessGate.when` or `AccessGate.whenKeys` for combined feature, role,
permission, and attribute requirements.

Use convenience constructors for common checks:

```dart
AccessGate.anyPermission(
  permissions: {'reports.view', 'reports.manage'},
  child: const ReportsButton(),
);

AccessGate.featureValue(
  feature: 'reports_variant',
  value: 'variant_b',
  child: const VariantReports(),
);
```

## Guard Pages

Use `AccessGuard` when a full page, tab, or route body should branch.

```dart
AccessGuard(
  policy: AccessPolicy.permission('reports.view'),
  builder: (context, decision) => const ReportsPage(),
  deniedBuilder: (context, decision) {
    return Text(decision.reasons.first);
  },
);
```

`AccessGuard` is router-agnostic. Use it inside whichever router or navigation
system the app already has.

For route bodies, wrap the page widget:

```dart
AccessGuard(
  policy: AccessPolicy.permission('reports.view'),
  builder: (context, decision) => const ReportsPage(),
  deniedBuilder: (context, decision) => const UpgradePage(),
);
```

For tabs or navigation branches, guard the tab body and keep navigation state in
the app's existing router or shell.

## Compose Policies

Use composition when access has multiple paths or explicit exclusions.

```dart
final policy = AccessPolicy.allOf([
  AccessPolicy.anyOf([
    AccessPolicy.role('admin', label: 'Admin role'),
    AccessPolicy.permission(
      'reports.manage',
      label: 'Reports manage permission',
    ),
  ]),
  AccessPolicy.not(
    AccessPolicy.role('suspended'),
    reason: 'Suspended users cannot access reports.',
    label: 'Suspension exclusion',
  ),
], label: 'Reports access');
```

## Build Better Denied UI

`decision.reasons` is the simple message list. Use `decision.denialReasons`
when the app needs structured fallback UI, localization keys, analytics, or
debugging.

```dart
fallbackBuilder: (context, decision) {
  final reason = decision.denialReasons.first;
  return Text('${reason.policyLabel ?? reason.key}: ${reason.message}');
}
```

Use `AccessBuilder` when a denied action should stay visible but disabled:

```dart
AccessBuilder(
  policy: AccessPolicy.permission('billing.manage'),
  builder: (context, decision) {
    return FilledButton(
      onPressed: decision.allowed ? manageBilling : null,
      child: Text(decision.allowed ? 'Manage billing' : decision.reasons.first),
    );
  },
);
```

## Use JSON For Server-Driven Inputs

`AccessContext` can round-trip through JSON-compatible maps. `AccessPolicy` can
also round-trip when it does not contain a custom predicate.

```dart
final context = AccessContext.fromJson(contextJson);
final policy = AccessPolicy.fromJson(policyJson);
```

Custom predicates are Dart functions and cannot be serialized.

Example serializable policy shape:

```json
{
  "type": "allOf",
  "label": "Reports access",
  "policies": [
    {
      "type": "leaf",
      "allPermissions": ["reports.view"],
      "label": "Reports permission"
    }
  ]
}
```

## Provider Recipes

Firebase Remote Config: put enabled booleans in `enabledFeatures` or true
boolean `featureValues`; put variants and numeric/string config in
`featureValues`.

LaunchDarkly or similar flag providers: map flag keys to `featureValues`, and
also add keys with boolean `true` to `enabledFeatures` when the flag should be
treated as a simple on/off feature.

Supabase or backend claims: map role claims to `roles`, permission claims to
`permissions`, and account metadata such as plan, team, or region to
`attributes`.

Backend policy responses: use `AccessContext.fromJson` for facts and
`AccessPolicy.fromJson` only for policies that do not contain predicates.

Local config or debug overrides: merge them last with `AccessContext.combine`
when they should override provider values.

## Test Integration

Widget-test the visible behavior that matters to the app:

```dart
await tester.pumpWidget(
  AccessScope(
    controller: AccessController(
      AccessContext(permissions: {'reports.view'}),
    ),
    child: const ReportsButtonHost(),
  ),
);

expect(find.text('Reports'), findsOneWidget);
```

Also test denied states when the fallback text, route branch, or recovery action
matters to users.

Add focused tests for controller updates:

```dart
controller.update(AccessContext(permissions: {'reports.view'}));
await tester.pump();
expect(find.text('Reports'), findsOneWidget);
```

For route guards, test the allowed branch, denied branch, and any recovery
action. For visible-but-disabled UI, assert the button is disabled and the
reason text is visible.

## Agent Integration

The repo includes an Agent Skills-compatible integration skill at
`skills/access-gate/`. Use it from Codex directly, or copy it into
`~/.claude/skills/access-gate/` for Claude Code.

When working from this repository in Claude Code, the project wrapper at
`.claude/skills/access-gate/` points Claude to the same shared skill. Keep the
shared skill as the canonical source when updating examples or workflow rules.

## Security Boundary

`access_gate` controls client-side visibility. It is not a replacement for
server-side authorization, database security rules, API checks, or audit logs.
Treat every client-side decision as advisory. Enforce access again at service
and data boundaries, avoid shipping sensitive data solely because a widget is
hidden, and keep audit/security decisions on the server.

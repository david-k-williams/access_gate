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

When the source of truth changes, update the controller:

```dart
controller.update(nextAccessContext);
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

## Compose Policies

Use composition when access has multiple paths or explicit exclusions.

```dart
final policy = AccessPolicy.allOf([
  AccessPolicy.anyOf([
    AccessPolicy.role('admin'),
    AccessPolicy.permission('reports.manage'),
  ]),
  AccessPolicy.not(
    AccessPolicy.role('suspended'),
    reason: 'Suspended users cannot access reports.',
  ),
]);
```

## Build Better Denied UI

`decision.reasons` is the simple message list. Use `decision.denialReasons`
when the app needs structured fallback UI, localization keys, analytics, or
debugging.

```dart
fallbackBuilder: (context, decision) {
  final reason = decision.denialReasons.first;
  return Text('${reason.key}: ${reason.message}');
}
```

## Use JSON For Server-Driven Inputs

`AccessContext` can round-trip through JSON-compatible maps. `AccessPolicy` can
also round-trip when it does not contain a custom predicate.

```dart
final context = AccessContext.fromJson(contextJson);
final policy = AccessPolicy.fromJson(policyJson);
```

Custom predicates are Dart functions and cannot be serialized.

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

## Security Boundary

`access_gate` controls client-side visibility. It is not a replacement for
server-side authorization, database security rules, API checks, or audit logs.

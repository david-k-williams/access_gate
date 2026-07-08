# access_gate Integration Patterns

## Add The Dependency

```yaml
dependencies:
  access_gate: ^0.0.4
```

For local package development:

```yaml
dependencies:
  access_gate:
    path: ../access_gate
```

## Build Context From App State

```dart
final accessController = AccessController(
  AccessContext(
    enabledFeatures: {'advanced_reports'},
    roles: {'admin'},
    permissions: {'reports.view'},
    attributes: {'plan': 'pro'},
  ),
);
```

Wrap the app or feature subtree:

```dart
AccessScope(
  controller: accessController,
  child: const MyApp(),
);
```

Update after auth, claims, remote config, account, or backend policy changes:

```dart
accessController.update(nextContext);
```

Combine multiple fact sources in order:

```dart
final context = AccessContext.combine([
  AccessContext(enabledFeatures: remoteFeatures),
  AccessContext(permissions: claimPermissions),
  AccessContext(attributes: {'plan': accountPlan}),
  AccessContext(featureValues: localOverrides),
]);
```

Show the app's loading shell until initial access facts are ready; an empty
context denies protected UI by design.

## Typed Keys

```dart
enum AppFeature implements AccessFeature {
  advancedReports('advanced_reports');

  const AppFeature(this.accessKey);

  @override
  final String accessKey;
}

enum AppPermission implements AccessPermission {
  reportsView('reports.view');

  const AppPermission(this.accessKey);

  @override
  final String accessKey;
}
```

```dart
final context = AccessContext.fromKeys(
  enabledFeatures: {AppFeature.advancedReports},
  permissions: {AppPermission.reportsView},
);
```

## Widget Gates

```dart
AccessGate.feature(
  feature: 'advanced_reports',
  child: const AdvancedReportsButton(),
);
```

```dart
AccessGate.whenKeys(
  allFeatures: {AppFeature.advancedReports},
  allPermissions: {AppPermission.reportsView},
  fallback: const Text('Reports are not available.'),
  child: const AdvancedReportsPanel(),
);
```

```dart
AccessGate.anyPermission(
  permissions: {'reports.view', 'reports.manage'},
  child: const ReportsButton(),
);
```

```dart
AccessGate.featureValue(
  feature: 'reports_variant',
  value: 'variant_b',
  child: const VariantReportsPanel(),
);
```

## Page Guards

```dart
AccessGuard(
  policy: AccessPolicy.permission('reports.view'),
  builder: (context, decision) => const ReportsPage(),
  deniedBuilder: (context, decision) {
    return Text(decision.reasons.first);
  },
);
```

## Composed Policies

```dart
final policy = AccessPolicy.allOf([
  AccessPolicy.anyOf([
    AccessPolicy.role('admin', label: 'Admin role'),
    AccessPolicy.permission('reports.manage', label: 'Reports manager'),
  ]),
  AccessPolicy.not(
    AccessPolicy.role('suspended'),
    reason: 'Suspended users cannot access reports.',
    label: 'Suspension exclusion',
  ),
], label: 'Reports access');
```

## Structured Denied UI

```dart
fallbackBuilder: (context, decision) {
  final reason = decision.denialReasons.first;
  return Text('${reason.policyLabel ?? reason.key}: ${reason.message}');
}
```

## JSON Helpers

```dart
final context = AccessContext.fromJson(contextJson);
final policy = AccessPolicy.fromJson(policyJson);
```

Use `policy.toJson()` only for policies without custom predicates.

## Widget Test Shape

```dart
await tester.pumpWidget(
  AccessScope(
    controller: AccessController(
      AccessContext(permissions: {'reports.view'}),
    ),
    child: const TestHost(),
  ),
);

expect(find.text('Reports'), findsOneWidget);
```

import 'package:access_gate/access_gate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessContext', () {
    test('reads enabled features and feature values', () {
      final context = AccessContext(
        enabledFeatures: <String>{'dashboard'},
        featureValues: <String, Object?>{'checkout': true, 'nav': 'variant_b'},
      );

      expect(context.hasFeature('dashboard'), isTrue);
      expect(context.hasFeature('checkout'), isTrue);
      expect(context.hasFeature('nav'), isFalse);
      expect(context.featureValue('dashboard'), isTrue);
      expect(context.featureValue('nav'), 'variant_b');
    });

    test('copyWith can clear the user id', () {
      final context = AccessContext(userId: 'user-1');

      expect(context.copyWith(userId: null).userId, isNull);
    });

    test('hashCode matches equality for reordered maps', () {
      final first = AccessContext(
        featureValues: <String, Object?>{'checkout': true, 'nav': 'variant_b'},
        attributes: <String, Object?>{'plan': 'pro', 'region': 'us'},
      );
      final second = AccessContext(
        featureValues: <String, Object?>{'nav': 'variant_b', 'checkout': true},
        attributes: <String, Object?>{'region': 'us', 'plan': 'pro'},
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('creates context from typed keys', () {
      final context = AccessContext.fromKeys(
        enabledFeatures: <TestFeature>{TestFeature.advancedReports},
        featureValues: <TestFeature, Object?>{
          TestFeature.checkoutVariant: 'variant_b',
        },
        roles: <TestRole>{TestRole.admin},
        permissions: <TestPermission>{TestPermission.reportsView},
        attributes: <TestAttribute, Object?>{TestAttribute.plan: 'pro'},
      );

      expect(context.hasFeature('advanced_reports'), isTrue);
      expect(context.hasFeatureKey(TestFeature.advancedReports), isTrue);
      expect(context.featureValueKey(TestFeature.checkoutVariant), 'variant_b');
      expect(context.hasRoleKey(TestRole.admin), isTrue);
      expect(context.hasPermissionKey(TestPermission.reportsView), isTrue);
      expect(context.attributeKey(TestAttribute.plan), 'pro');
    });

    test('round-trips through JSON-compatible data', () {
      final context = AccessContext(
        userId: 'user-1',
        enabledFeatures: <String>{'advanced_reports'},
        featureValues: <String, Object?>{'checkout': true},
        roles: <String>{'admin'},
        permissions: <String>{'reports.view'},
        attributes: <String, Object?>{'plan': 'pro'},
      );

      expect(AccessContext.fromJson(context.toJson()), context);
    });
  });

  group('AccessPolicy', () {
    test('allows access when all requirements pass', () {
      final context = AccessContext(
        enabledFeatures: <String>{'advanced_reports'},
        featureValues: <String, Object?>{'chart_color': 'blue'},
        roles: <String>{'admin'},
        permissions: <String>{'reports.view'},
        attributes: <String, Object?>{'plan': 'pro', 'teamId': 'team-1'},
      );

      final decision = AccessPolicy(
        allFeatures: <String>{'advanced_reports'},
        featureValues: <String, Object?>{'chart_color': 'blue'},
        allRoles: <String>{'admin'},
        allPermissions: <String>{'reports.view'},
        attributes: <String, Object?>{'plan': 'pro'},
        predicate: (context) => context.attribute('teamId') == 'team-1',
      ).evaluate(context);

      expect(decision.allowed, isTrue);
      expect(decision.reasons, isEmpty);
    });

    test('denies access with reasons for missing requirements', () {
      final decision = AccessPolicy(
        allFeatures: <String>{'advanced_reports'},
        allRoles: <String>{'admin'},
        allPermissions: <String>{'reports.view'},
        attributes: <String, Object?>{'plan': 'pro'},
      ).evaluate(AccessContext(attributes: <String, Object?>{'plan': 'free'}));

      expect(decision.denied, isTrue);
      expect(
        decision.reasons,
        contains('Missing feature flag: advanced_reports.'),
      );
      expect(decision.reasons, contains('Missing role: admin.'));
      expect(decision.reasons, contains('Missing permission: reports.view.'));
      expect(decision.reasons, contains('Attribute plan must equal pro.'));
      expect(
        decision.denialReasons.map((reason) => reason.type),
        containsAll(<AccessDenialReasonType>[
          AccessDenialReasonType.missingFeature,
          AccessDenialReasonType.missingRole,
          AccessDenialReasonType.missingPermission,
          AccessDenialReasonType.attributeMismatch,
        ]),
      );
    });

    test('supports any-of role, permission, and feature requirements', () {
      final context = AccessContext(
        enabledFeatures: <String>{'billing_v2'},
        roles: <String>{'owner'},
        permissions: <String>{'invoices.read'},
      );

      final decision = AccessPolicy(
        anyFeatures: <String>{'billing_v1', 'billing_v2'},
        anyRoles: <String>{'admin', 'owner'},
        anyPermissions: <String>{'invoices.write', 'invoices.read'},
      ).evaluate(context);

      expect(decision.allowed, isTrue);
    });

    test('defensively copies and exposes immutable requirements', () {
      final allFeatures = <String>{'advanced_reports'};
      final attributes = <String, Object?>{'plan': 'pro'};
      final policy = AccessPolicy(
        allFeatures: allFeatures,
        attributes: attributes,
      );

      allFeatures.clear();
      attributes['plan'] = 'free';

      final decision = policy.evaluate(
        AccessContext(
          enabledFeatures: <String>{'advanced_reports'},
          attributes: <String, Object?>{'plan': 'pro'},
        ),
      );

      expect(decision.allowed, isTrue);
      expect(() => policy.allFeatures.add('billing'), throwsUnsupportedError);
      expect(() => policy.attributes['region'] = 'us', throwsUnsupportedError);
    });

    test('evaluates policies built from typed keys', () {
      final context = AccessContext.fromKeys(
        enabledFeatures: <TestFeature>{TestFeature.advancedReports},
        roles: <TestRole>{TestRole.admin},
        permissions: <TestPermission>{TestPermission.reportsView},
        attributes: <TestAttribute, Object?>{TestAttribute.plan: 'pro'},
      );

      final decision = AccessPolicy.fromKeys(
        allFeatures: <TestFeature>{TestFeature.advancedReports},
        allRoles: <TestRole>{TestRole.admin},
        allPermissions: <TestPermission>{TestPermission.reportsView},
        attributes: <TestAttribute, Object?>{TestAttribute.plan: 'pro'},
      ).evaluate(context);

      expect(decision.allowed, isTrue);
      expect(
        AccessPolicy.featureKey(
          TestFeature.advancedReports,
        ).evaluate(context).allowed,
        isTrue,
      );
      expect(
        AccessPolicy.roleKey(TestRole.admin).evaluate(context).allowed,
        isTrue,
      );
      expect(
        AccessPolicy.permissionKey(
          TestPermission.reportsView,
        ).evaluate(context).allowed,
        isTrue,
      );
    });

    test('supports a custom ABAC predicate', () {
      final policy = AccessPolicy(
        predicate: (context) {
          return context.attribute('department') == 'finance' &&
              context.attribute('spendLimit') == 5000;
        },
        predicateReason: 'Requires finance approval authority.',
      );

      final decision = policy.evaluate(
        AccessContext(
          attributes: <String, Object?>{
            'department': 'finance',
            'spendLimit': 1000,
          },
        ),
      );

      expect(decision.denied, isTrue);
      expect(
        decision.reasons,
        contains('Requires finance approval authority.'),
      );
    });

    test('allOf allows only when every composed policy allows access', () {
      final context = AccessContext(
        roles: <String>{'admin'},
        permissions: <String>{'reports.view'},
      );

      final allowed = AccessPolicy.allOf(<AccessPolicy>[
        AccessPolicy.role('admin'),
        AccessPolicy.permission('reports.view'),
      ]).evaluate(context);
      final denied = AccessPolicy.allOf(<AccessPolicy>[
        AccessPolicy.role('admin'),
        AccessPolicy.permission('reports.manage'),
      ]).evaluate(context);

      expect(allowed.allowed, isTrue);
      expect(denied.denied, isTrue);
      expect(denied.reasons, contains('Missing permission: reports.manage.'));
    });

    test('anyOf allows when one composed policy allows access', () {
      final context = AccessContext(roles: <String>{'analyst'});

      final decision = AccessPolicy.anyOf(<AccessPolicy>[
        AccessPolicy.role('admin'),
        AccessPolicy.role('analyst'),
      ]).evaluate(context);

      expect(decision.allowed, isTrue);
    });

    test('anyOf denies with child reasons when no composed policy allows', () {
      final decision = AccessPolicy.anyOf(<AccessPolicy>[
        AccessPolicy.role('admin'),
        AccessPolicy.permission('reports.view'),
      ]).evaluate(AccessContext());

      expect(decision.denied, isTrue);
      expect(decision.reasons, contains('Missing role: admin.'));
      expect(decision.reasons, contains('Missing permission: reports.view.'));
    });

    test('empty composition follows explicit all and any semantics', () {
      expect(
        AccessPolicy.allOf(<AccessPolicy>[]).evaluate(AccessContext()).allowed,
        isTrue,
      );

      final decision = AccessPolicy.anyOf(
        <AccessPolicy>[],
      ).evaluate(AccessContext());

      expect(decision.denied, isTrue);
      expect(
        decision.reasons,
        contains('Requires at least one policy to allow access.'),
      );
    });

    test('not inverts a composed policy decision', () {
      final policy = AccessPolicy.not(
        AccessPolicy.role('suspended'),
        reason: 'Suspended users cannot access this.',
      );

      final allowed = policy.evaluate(AccessContext());
      final denied = policy.evaluate(
        AccessContext(roles: <String>{'suspended'}),
      );

      expect(allowed.allowed, isTrue);
      expect(denied.denied, isTrue);
      expect(denied.reasons, <String>['Suspended users cannot access this.']);
      expect(
        denied.denialReasons.single.type,
        AccessDenialReasonType.notPolicyMatched,
      );
    });

    test('round-trips leaf policies through JSON-compatible data', () {
      final policy = AccessPolicy(
        allFeatures: <String>{'advanced_reports'},
        anyRoles: <String>{'admin', 'analyst'},
        allPermissions: <String>{'reports.view'},
        attributes: <String, Object?>{'plan': 'pro'},
      );
      final roundTripped = AccessPolicy.fromJson(policy.toJson());

      final context = AccessContext(
        enabledFeatures: <String>{'advanced_reports'},
        roles: <String>{'analyst'},
        permissions: <String>{'reports.view'},
        attributes: <String, Object?>{'plan': 'pro'},
      );

      expect(roundTripped.evaluate(context).allowed, isTrue);
      expect(roundTripped.toJson(), policy.toJson());
    });

    test('round-trips composed policies through JSON-compatible data', () {
      final policy = AccessPolicy.allOf(<AccessPolicy>[
        AccessPolicy.anyOf(<AccessPolicy>[
          AccessPolicy.role('admin'),
          AccessPolicy.permission('reports.manage'),
        ]),
        AccessPolicy.not(
          AccessPolicy.role('suspended'),
          reason: 'Suspended users cannot access this.',
        ),
      ]);
      final roundTripped = AccessPolicy.fromJson(policy.toJson());

      final context = AccessContext(roles: <String>{'admin'});

      expect(roundTripped.evaluate(context).allowed, isTrue);
      expect(roundTripped.toJson(), policy.toJson());
    });

    test('does not serialize predicate policies', () {
      final policy = AccessPolicy(predicate: (context) => true);

      expect(policy.toJson, throwsUnsupportedError);
    });
  });

  group('AccessGate', () {
    testWidgets('shows the child when access is allowed', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGate.feature(
            feature: 'dashboard',
            accessContext: AccessContext(
              enabledFeatures: <String>{'dashboard'},
            ),
            child: const Text('Dashboard'),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('renders nothing when access is denied', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGate.feature(
            feature: 'dashboard',
            accessContext: AccessContext(),
            child: const Text('Dashboard'),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsNothing);
      expect(find.byType(AccessHidden), findsOneWidget);
    });

    testWidgets('shows a fallback when access is denied', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGate.permission(
            permission: 'reports.view',
            accessContext: AccessContext(),
            fallbackBuilder: (context, decision) {
              return Text(decision.reasons.first);
            },
            child: const Text('Report'),
          ),
        ),
      );

      expect(find.text('Report'), findsNothing);
      expect(find.text('Missing permission: reports.view.'), findsOneWidget);
    });

    testWidgets('updates when the scoped controller changes', (tester) async {
      final controller = AccessController(AccessContext());

      await tester.pumpWidget(
        AccessScope(
          controller: controller,
          child: _TestHost(
            child: AccessGate.role(
              role: 'admin',
              child: const Text('Admin tools'),
            ),
          ),
        ),
      );

      expect(find.text('Admin tools'), findsNothing);

      controller.update(AccessContext(roles: <String>{'admin'}));
      await tester.pump();

      expect(find.text('Admin tools'), findsOneWidget);
    });

    testWidgets('updates when an explicit controller changes', (tester) async {
      final controller = AccessController(AccessContext());

      await tester.pumpWidget(
        _TestHost(
          child: AccessGate.role(
            role: 'admin',
            controller: controller,
            child: const Text('Admin tools'),
          ),
        ),
      );

      expect(find.text('Admin tools'), findsNothing);

      controller.update(AccessContext(roles: <String>{'admin'}));
      await tester.pump();

      expect(find.text('Admin tools'), findsOneWidget);
    });

    testWidgets('supports typed key constructors', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGate.whenKeys(
            accessContext: AccessContext.fromKeys(
              enabledFeatures: <TestFeature>{TestFeature.advancedReports},
              roles: <TestRole>{TestRole.admin},
              permissions: <TestPermission>{TestPermission.reportsView},
              attributes: <TestAttribute, Object?>{TestAttribute.plan: 'pro'},
            ),
            allFeatures: <TestFeature>{TestFeature.advancedReports},
            allRoles: <TestRole>{TestRole.admin},
            allPermissions: <TestPermission>{TestPermission.reportsView},
            attributes: <TestAttribute, Object?>{TestAttribute.plan: 'pro'},
            child: const Text('Advanced reports'),
          ),
        ),
      );

      expect(find.text('Advanced reports'), findsOneWidget);
    });

    testWidgets('supports composed policies', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGate(
            accessContext: AccessContext(roles: <String>{'admin'}),
            policy: AccessPolicy.anyOf(<AccessPolicy>[
              AccessPolicy.role('admin'),
              AccessPolicy.permission('reports.view'),
            ]),
            child: const Text('Composed access'),
          ),
        ),
      );

      expect(find.text('Composed access'), findsOneWidget);
    });

    testWidgets('preserves render order with mixed gates and guards', (
      tester,
    ) async {
      final controller = AccessController(
        AccessContext(
          enabledFeatures: <String>{'advanced_reports'},
          roles: <String>{'admin'},
          permissions: <String>{'reports.view'},
          attributes: <String, Object?>{'plan': 'pro'},
        ),
      );
      final jsonContext = AccessContext.fromJson(controller.context.toJson());
      final jsonPolicy = AccessPolicy.fromJson(
        AccessPolicy.permission('reports.view').toJson(),
      );

      await tester.pumpWidget(
        AccessScope(
          controller: controller,
          child: _TestHost(
            child: Column(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                AccessGate.when(
                  allFeatures: <String>{'advanced_reports'},
                  child: const Text('Typed key gate'),
                ),
                AccessGate.when(
                  allPermissions: <String>{'reports.view'},
                  child: const Text('String gate'),
                ),
                AccessGate(
                  policy: AccessPolicy.allOf(<AccessPolicy>[
                    AccessPolicy.role('admin'),
                    AccessPolicy.not(AccessPolicy.role('suspended')),
                  ]),
                  child: const Text('Composed policy gate'),
                ),
                AccessGuard(
                  accessContext: jsonContext,
                  policy: jsonPolicy,
                  builder: (context, decision) {
                    return const Text('Guard with JSON policy');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      final typedTop = tester.getTopLeft(find.text('Typed key gate')).dy;
      final stringTop = tester.getTopLeft(find.text('String gate')).dy;
      final composedTop = tester
          .getTopLeft(find.text('Composed policy gate'))
          .dy;
      final guardTop = tester
          .getTopLeft(find.text('Guard with JSON policy'))
          .dy;

      expect(typedTop, lessThan(stringTop));
      expect(stringTop, lessThan(composedTop));
      expect(composedTop, lessThan(guardTop));
    });

    testWidgets('preserves render order around a default denied gate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHost(
          child: Column(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              const Text('Before denied gate'),
              AccessGate.permission(
                permission: 'reports.view',
                accessContext: AccessContext(),
                child: const Text('Hidden reports'),
              ),
              const Text('After denied gate'),
              AccessGuard(
                accessContext: AccessContext(
                  permissions: <String>{'reports.view'},
                ),
                policy: AccessPolicy.permission('reports.view'),
                builder: (context, decision) {
                  return const Text('Guard after denied gate');
                },
              ),
            ],
          ),
        ),
      );

      expect(find.text('Hidden reports'), findsNothing);

      final beforeTop = tester.getTopLeft(find.text('Before denied gate')).dy;
      final afterTop = tester.getTopLeft(find.text('After denied gate')).dy;
      final guardTop = tester
          .getTopLeft(find.text('Guard after denied gate'))
          .dy;

      expect(beforeTop, lessThan(afterTop));
      expect(afterTop, lessThan(guardTop));
    });
  });

  group('AccessBuilder', () {
    testWidgets('passes the evaluated decision to the builder', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessBuilder(
            accessContext: AccessContext(),
            policy: AccessPolicy.permission('reports.view'),
            builder: (context, decision) {
              return Text(
                decision.allowed ? 'Allowed' : decision.reasons.first,
              );
            },
          ),
        ),
      );

      expect(find.text('Missing permission: reports.view.'), findsOneWidget);
    });

    testWidgets('updates when an explicit controller changes', (tester) async {
      final controller = AccessController(AccessContext());

      await tester.pumpWidget(
        _TestHost(
          child: AccessBuilder(
            controller: controller,
            policy: AccessPolicy.permission('reports.view'),
            builder: (context, decision) {
              return Text(decision.allowed ? 'Allowed' : 'Denied');
            },
          ),
        ),
      );

      expect(find.text('Denied'), findsOneWidget);
      expect(find.text('Allowed'), findsNothing);

      controller.update(AccessContext(permissions: <String>{'reports.view'}));
      await tester.pump();

      expect(find.text('Allowed'), findsOneWidget);
      expect(find.text('Denied'), findsNothing);
    });
  });

  group('AccessGuard', () {
    testWidgets('builds the allowed branch', (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGuard(
            accessContext: AccessContext(roles: <String>{'admin'}),
            policy: AccessPolicy.role('admin'),
            builder: (context, decision) {
              return const Text('Admin page');
            },
            denied: const Text('Denied page'),
          ),
        ),
      );

      expect(find.text('Admin page'), findsOneWidget);
      expect(find.text('Denied page'), findsNothing);
    });

    testWidgets('builds the denied branch with structured reasons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHost(
          child: AccessGuard(
            accessContext: AccessContext(),
            policy: AccessPolicy.permission('reports.view'),
            builder: (context, decision) {
              return const Text('Reports page');
            },
            deniedBuilder: (context, decision) {
              return Text(decision.denialReasons.single.key!);
            },
          ),
        ),
      );

      expect(find.text('Reports page'), findsNothing);
      expect(find.text('reports.view'), findsOneWidget);
    });
  });

  group('AccessDecision', () {
    test('defensively copies and exposes immutable reasons', () {
      final reasons = <String>['Missing permission: reports.view.'];
      final decision = AccessDecision(allowed: false, reasons: reasons);

      reasons.add('Missing role: admin.');

      expect(decision.reasons, <String>['Missing permission: reports.view.']);
      expect(decision.denialReasons.single.message, decision.reasons.single);
      expect(() => decision.reasons.add('Other'), throwsUnsupportedError);
      expect(
        () => decision.denialReasons.add(AccessDenialReason.custom('Other')),
        throwsUnsupportedError,
      );
    });

    test('defensively copies structured denial reasons', () {
      final denialReasons = <AccessDenialReason>[
        AccessDenialReason(
          type: AccessDenialReasonType.missingPermission,
          key: 'reports.view',
          message: 'Missing permission: reports.view.',
        ),
      ];
      final decision = AccessDecision.denyWithReasons(denialReasons);

      denialReasons.clear();

      expect(decision.reasons, <String>['Missing permission: reports.view.']);
      expect(
        decision.denialReasons.single.type,
        AccessDenialReasonType.missingPermission,
      );
    });
  });

  testWidgets('AccessHidden creates a zero-size render object', (tester) async {
    await tester.pumpWidget(
      const _TestHost(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[AccessHidden(key: Key('hidden'))],
          ),
        ),
      ),
    );

    final element = tester.element(find.byKey(const Key('hidden')));
    expect(element, isA<Element>());
    expect(element, isA<RenderObjectElement>());
    expect(tester.getSize(find.byKey(const Key('hidden'))), Size.zero);
  });

  test('AccessEnumKey exposes the enum name as a convenience key', () {
    expect(TestDefaultNamedFeature.dashboard.accessKey, 'dashboard');
  });
}

class _TestHost extends StatelessWidget {
  const _TestHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }
}

enum TestFeature implements AccessFeature {
  advancedReports('advanced_reports'),
  checkoutVariant('checkout_variant');

  const TestFeature(this.accessKey);

  @override
  final String accessKey;
}

enum TestRole implements AccessRole {
  admin('admin');

  const TestRole(this.accessKey);

  @override
  final String accessKey;
}

enum TestPermission implements AccessPermission {
  reportsView('reports.view');

  const TestPermission(this.accessKey);

  @override
  final String accessKey;
}

enum TestAttribute implements AccessAttribute {
  plan('plan');

  const TestAttribute(this.accessKey);

  @override
  final String accessKey;
}

enum TestDefaultNamedFeature { dashboard }

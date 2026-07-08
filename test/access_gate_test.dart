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

  group('AccessDecision', () {
    test('defensively copies and exposes immutable reasons', () {
      final reasons = <String>['Missing permission: reports.view.'];
      final decision = AccessDecision(allowed: false, reasons: reasons);

      reasons.add('Missing role: admin.');

      expect(decision.reasons, <String>['Missing permission: reports.view.']);
      expect(() => decision.reasons.add('Other'), throwsUnsupportedError);
    });
  });

  testWidgets('AccessHidden creates no render object', (tester) async {
    await tester.pumpWidget(
      const _TestHost(child: AccessHidden(key: Key('hidden'))),
    );

    final element = tester.element(find.byKey(const Key('hidden')));
    expect(element, isA<Element>());
    expect(element, isNot(isA<RenderObjectElement>()));
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

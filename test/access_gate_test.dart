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
      final decision = const AccessPolicy(
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

      final decision = const AccessPolicy(
        anyFeatures: <String>{'billing_v1', 'billing_v2'},
        anyRoles: <String>{'admin', 'owner'},
        anyPermissions: <String>{'invoices.write', 'invoices.read'},
      ).evaluate(context);

      expect(decision.allowed, isTrue);
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
  });

  testWidgets('AccessHidden creates no render object', (tester) async {
    await tester.pumpWidget(
      const _TestHost(child: AccessHidden(key: Key('hidden'))),
    );

    final element = tester.element(find.byKey(const Key('hidden')));
    expect(element, isA<Element>());
    expect(element, isNot(isA<RenderObjectElement>()));
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

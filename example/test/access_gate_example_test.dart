import 'package:access_gate/access_gate.dart';
import 'package:access_gate_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('updates gates and JSON preview when access facts change', (
    tester,
  ) async {
    final accessController = AccessController();

    await tester.pumpWidget(ExampleApp(accessController: accessController));

    expect(find.text('Advanced reports are visible'), findsOneWidget);
    expect(find.text('Variant B experience is visible'), findsOneWidget);
    expect(find.text('Reports page guard allowed'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('export-button')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('reports-permission-switch')));
    await tester.pump();

    expect(find.text('Advanced reports denied'), findsOneWidget);
    expect(
      find.textContaining(
        'Advanced reports policy: Missing permission: reports.view.',
      ),
      findsWidgets,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('export-button')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('variant-switch')));
    await tester.pump();

    expect(find.text('Variant gate denied'), findsOneWidget);
    expect(
      find.textContaining(
        'Variant B reports policy: Feature reports_variant must equal variant_b.',
      ),
      findsOneWidget,
    );

    final contextJson = await _jsonText(tester, const Key('json-context'));
    expect(contextJson, contains('"permissions": []'));
    expect(contextJson, contains('"reports_variant": "variant_a"'));
  });

  testWidgets('shows structured denial reason for suspended users', (
    tester,
  ) async {
    final accessController = AccessController();

    await tester.pumpWidget(ExampleApp(accessController: accessController));

    await tester.tap(find.byKey(const Key('suspended-role-switch')));
    await tester.pump();

    expect(find.text('Reports page guard denied'), findsOneWidget);
    expect(
      find.textContaining(
        'Suspension exclusion: Suspended users cannot access reports.',
      ),
      findsOneWidget,
    );
    expect(
      await _jsonText(tester, const Key('json-policy')),
      contains('"label": "Reports access policy"'),
    );
  });
}

Future<String> _jsonText(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(find.byKey(key), 500);
  await tester.pumpAndSettle();
  return tester.widget<SelectableText>(find.byKey(key)).data!;
}

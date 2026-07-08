import 'package:access_gate/access_gate.dart';
import 'package:access_gate_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the example gates in source order', (tester) async {
    final accessController = AccessController(
      AccessContext.fromKeys(
        enabledFeatures: <AppFeature>{AppFeature.advancedReports},
        roles: <AppRole>{AppRole.admin},
        permissions: <AppPermission>{AppPermission.reportsView},
        attributes: <AppAttribute, Object?>{
          AppAttribute.plan: 'pro',
          AppAttribute.region: 'us',
        },
      ),
    );

    await tester.pumpWidget(ExampleApp(accessController: accessController));

    final typedTop = tester
        .getTopLeft(find.text('Typed key gate: advanced reports'))
        .dy;
    final stringTop = tester
        .getTopLeft(find.text('String gate: advanced reports'))
        .dy;
    final composedTop = tester
        .getTopLeft(find.text('Composed policy gate: reports access'))
        .dy;
    final guardTop = tester
        .getTopLeft(find.text('Guard with JSON policy: reports page'))
        .dy;

    expect(typedTop, lessThan(stringTop));
    expect(stringTop, lessThan(composedTop));
    expect(composedTop, lessThan(guardTop));
  });
}

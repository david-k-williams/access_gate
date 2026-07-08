import 'package:access_gate/access_gate.dart';
import 'package:flutter/material.dart';

void main() {
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

  runApp(ExampleApp(accessController: accessController));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.accessController});

  final AccessController accessController;

  @override
  Widget build(BuildContext context) {
    return AccessScope(
      controller: accessController,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('AccessGate example')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AccessGate.whenKeys(
                  allFeatures: <AppFeature>{AppFeature.advancedReports},
                  anyRoles: <AppRole>{AppRole.admin, AppRole.analyst},
                  allPermissions: <AppPermission>{AppPermission.reportsView},
                  attributes: <AppAttribute, Object?>{AppAttribute.plan: 'pro'},
                  fallback: const Text('Typed reports are not available.'),
                  child: const Text('Typed key gate: advanced reports'),
                ),
                const SizedBox(height: 12),
                AccessGate.when(
                  allFeatures: <String>{'advanced_reports'},
                  anyRoles: <String>{'admin', 'analyst'},
                  allPermissions: <String>{'reports.view'},
                  attributes: <String, Object?>{'plan': 'pro'},
                  fallback: const Text('String reports are not available.'),
                  child: const Text('String gate: advanced reports'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AppFeature implements AccessFeature {
  advancedReports('advanced_reports');

  const AppFeature(this.accessKey);

  @override
  final String accessKey;
}

enum AppRole implements AccessRole {
  admin('admin'),
  analyst('analyst');

  const AppRole(this.accessKey);

  @override
  final String accessKey;
}

enum AppPermission implements AccessPermission {
  reportsView('reports.view');

  const AppPermission(this.accessKey);

  @override
  final String accessKey;
}

enum AppAttribute implements AccessAttribute {
  plan('plan'),
  region('region');

  const AppAttribute(this.accessKey);

  @override
  final String accessKey;
}

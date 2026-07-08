import 'package:access_gate/access_gate.dart';
import 'package:flutter/material.dart';

void main() {
  final accessController = AccessController(
    AccessContext(
      enabledFeatures: <String>{'advanced_reports'},
      roles: <String>{'admin'},
      permissions: <String>{'reports.view'},
      attributes: <String, Object?>{'plan': 'pro', 'region': 'us'},
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
            child: AccessGate.when(
              allFeatures: const <String>{'advanced_reports'},
              anyRoles: const <String>{'admin', 'analyst'},
              allPermissions: const <String>{'reports.view'},
              attributes: const <String, Object?>{'plan': 'pro'},
              fallback: const Text('Reports are not available.'),
              child: const Text('Advanced reports'),
            ),
          ),
        ),
      ),
    );
  }
}

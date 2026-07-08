import 'dart:convert';

import 'package:access_gate/access_gate.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(ExampleApp(accessController: AccessController()));
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, required this.accessController});

  final AccessController accessController;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  static const _encoder = JsonEncoder.withIndent('  ');

  bool _advancedReportsEnabled = true;
  bool _adminRoleEnabled = true;
  bool _reportsViewEnabled = true;
  bool _proPlanEnabled = true;
  bool _usRegionEnabled = true;
  bool _suspendedRoleEnabled = false;
  bool _variantBEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.accessController.update(_buildContext());
  }

  AccessContext _buildContext() {
    return AccessContext.combine(<AccessContext>[
      AccessContext.fromKeys(
        enabledFeatures: <AppFeature>{
          if (_advancedReportsEnabled) AppFeature.advancedReports,
        },
        featureValues: <AppFeature, Object?>{
          AppFeature.reportsVariant: _variantBEnabled
              ? 'variant_b'
              : 'variant_a',
        },
      ),
      AccessContext.fromKeys(
        roles: <AppRole>{
          if (_adminRoleEnabled) AppRole.admin,
          if (_suspendedRoleEnabled) AppRole.suspended,
        },
        permissions: <AppPermission>{
          if (_reportsViewEnabled) AppPermission.reportsView,
        },
      ),
      AccessContext.fromKeys(
        userId: 'demo-user',
        attributes: <AppAttribute, Object?>{
          AppAttribute.plan: _proPlanEnabled ? 'pro' : 'free',
          AppAttribute.region: _usRegionEnabled ? 'us' : 'eu',
        },
      ),
    ]);
  }

  AccessPolicy get _advancedReportsPolicy {
    return AccessPolicy.fromKeys(
      allFeatures: <AppFeature>{AppFeature.advancedReports},
      anyRoles: <AppRole>{AppRole.admin, AppRole.analyst},
      allPermissions: <AppPermission>{AppPermission.reportsView},
      attributes: <AppAttribute, Object?>{AppAttribute.plan: 'pro'},
      label: 'Advanced reports policy',
    );
  }

  AccessPolicy get _reportsAccessPolicy {
    return AccessPolicy.allOf(<AccessPolicy>[
      AccessPolicy.anyRoleKey(<AppRole>{
        AppRole.admin,
        AppRole.analyst,
      }, label: 'Staff role path'),
      AccessPolicy.permissionKey(
        AppPermission.reportsView,
        label: 'Reports permission',
      ),
      AccessPolicy.not(
        AccessPolicy.roleKey(AppRole.suspended),
        reason: 'Suspended users cannot access reports.',
        label: 'Suspension exclusion',
      ),
    ], label: 'Reports access policy');
  }

  AccessPolicy get _variantPolicy {
    return AccessPolicy.featureValueKey(
      AppFeature.reportsVariant,
      'variant_b',
      label: 'Variant B reports policy',
    );
  }

  void _update(VoidCallback change) {
    setState(() {
      change();
      widget.accessController.update(_buildContext());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AccessScope(
      controller: widget.accessController,
      child: MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: Scaffold(
          appBar: AppBar(title: const Text('access_gate example')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _Section(
                title: 'Access facts',
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      key: const Key('advanced-feature-switch'),
                      title: const Text('Advanced reports feature'),
                      value: _advancedReportsEnabled,
                      onChanged: (value) {
                        _update(() => _advancedReportsEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('admin-role-switch'),
                      title: const Text('Admin role'),
                      value: _adminRoleEnabled,
                      onChanged: (value) {
                        _update(() => _adminRoleEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('reports-permission-switch'),
                      title: const Text('reports.view permission'),
                      value: _reportsViewEnabled,
                      onChanged: (value) {
                        _update(() => _reportsViewEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('pro-plan-switch'),
                      title: const Text('Pro plan attribute'),
                      value: _proPlanEnabled,
                      onChanged: (value) {
                        _update(() => _proPlanEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('us-region-switch'),
                      title: const Text('US region attribute'),
                      value: _usRegionEnabled,
                      onChanged: (value) {
                        _update(() => _usRegionEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('suspended-role-switch'),
                      title: const Text('Suspended role'),
                      value: _suspendedRoleEnabled,
                      onChanged: (value) {
                        _update(() => _suspendedRoleEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('variant-switch'),
                      title: const Text('Reports variant B'),
                      value: _variantBEnabled,
                      onChanged: (value) {
                        _update(() => _variantBEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Gates',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AccessGate(
                      policy: _advancedReportsPolicy,
                      fallbackBuilder: (context, decision) {
                        return _DeniedPanel(
                          title: 'Advanced reports denied',
                          decision: decision,
                        );
                      },
                      child: const _AllowedPanel(
                        title: 'Advanced reports are visible',
                        body: 'Feature, role, permission, and plan all match.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    AccessGate(
                      policy: _variantPolicy,
                      fallbackBuilder: (context, decision) {
                        return _DeniedPanel(
                          title: 'Variant gate denied',
                          decision: decision,
                        );
                      },
                      child: const _AllowedPanel(
                        title: 'Variant B experience is visible',
                        body: 'Feature values can drive exact-match variants.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    AccessGuard(
                      policy: _reportsAccessPolicy,
                      builder: (context, decision) {
                        return const _AllowedPanel(
                          title: 'Reports page guard allowed',
                          body: 'The page body can render normally.',
                        );
                      },
                      deniedBuilder: (context, decision) {
                        return _DeniedPanel(
                          title: 'Reports page guard denied',
                          decision: decision,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AccessBuilder(
                      policy: AccessPolicy.permissionKey(
                        AppPermission.reportsView,
                        label: 'Export button permission',
                      ),
                      builder: (context, decision) {
                        return FilledButton(
                          key: const Key('export-button'),
                          onPressed: decision.allowed ? () {} : null,
                          child: Text(
                            decision.allowed
                                ? 'Export report'
                                : decision.reasons.first,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Denied reasons',
                child: AccessBuilder(
                  policy: _advancedReportsPolicy,
                  builder: (context, decision) {
                    if (decision.allowed) {
                      return const Text(
                        'Advanced reports policy is currently allowed.',
                        key: Key('denied-reasons'),
                      );
                    }
                    return Column(
                      key: const Key('denied-reasons'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final reason in decision.denialReasons)
                          Text(
                            '${reason.policyLabel ?? 'Policy'}: '
                            '${reason.message}',
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'JSON preview',
                child: ListenableBuilder(
                  listenable: widget.accessController,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Context'),
                        SelectableText(
                          key: const Key('json-context'),
                          _encoder.convert(
                            widget.accessController.context.toJson(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Policy'),
                        SelectableText(
                          key: const Key('json-policy'),
                          _encoder.convert(_reportsAccessPolicy.toJson()),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AllowedPanel extends StatelessWidget {
  const _AllowedPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _DeniedPanel extends StatelessWidget {
  const _DeniedPanel({required this.title, required this.decision});

  final String title;
  final AccessDecision decision;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: colorScheme.error),
            ),
            const SizedBox(height: 4),
            for (final reason in decision.denialReasons)
              Text('${reason.policyLabel ?? 'Policy'}: ${reason.message}'),
          ],
        ),
      ),
    );
  }
}

enum AppFeature implements AccessFeature {
  advancedReports('advanced_reports'),
  reportsVariant('reports_variant');

  const AppFeature(this.accessKey);

  @override
  final String accessKey;
}

enum AppRole implements AccessRole {
  admin('admin'),
  analyst('analyst'),
  suspended('suspended');

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

// Progress sync settings (KOReader "Progress sync" menu).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import 'kosync_client.dart';
import 'kosync_service.dart';
import 'kosync_settings.dart';

class KoSyncSettingsScreen extends StatefulWidget {
  const KoSyncSettingsScreen({super.key});

  @override
  State<KoSyncSettingsScreen> createState() => _KoSyncSettingsScreenState();
}

class _KoSyncSettingsScreenState extends State<KoSyncSettingsScreen> {
  int? _queued;

  KoSyncService get _service => ServicesScope.of(context).kosync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshQueue();
  }

  Future<void> _refreshQueue() async {
    final n = await _service.queue.count();
    if (mounted) setState(() => _queued = n);
  }

  void _show(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<String?> _editText(String title, String value, {String? hint, TextInputType? keyboard}) {
    final controller = TextEditingController(text: value);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _sendQueue() async {
    try {
      final sent = await _service.drainQueue();
      _show('Sent $sent queued update(s).');
    } on KoSyncException catch (e) {
      _show(e.toString());
    }
    await _refreshQueue();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KoSyncSettings>(
      valueListenable: _service.settings,
      builder: (context, s, _) {
        final text = Theme.of(context).textTheme;
        Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(t, style: text.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Progress sync')),
          body: ListView(
            children: [
              header('Account'),
              if (s.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text('Logged in as ${s.username}'),
                  subtitle: Text(s.serverUrl),
                  trailing: TextButton(
                    onPressed: () async {
                      await _service.logout();
                      await _refreshQueue();
                    },
                    child: const Text('Logout'),
                  ),
                )
              else
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Register / Login'),
                  subtitle: Text(
                    s.hasServer
                        ? 'Use the same account as KOReader on your other devices'
                        : 'Set the sync server address first',
                  ),
                  enabled: s.hasServer,
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => _LoginDialog(service: _service, initialUser: s.username ?? ''),
                    );
                    if (ok == true) _show('Logged in to the sync server.');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.dns),
                title: const Text('Sync server'),
                subtitle: Text(s.hasServer ? s.serverUrl : 'Not set'),
                onTap: () async {
                  final v = await _editText(
                    'Sync server address',
                    s.hasServer ? s.serverUrl : 'http://',
                    hint: 'http://server:17200',
                    keyboard: TextInputType.url,
                  );
                  if (v == null) return;
                  var url = v.trim();
                  if (url == 'http://' || url == 'https://') url = '';
                  if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme != true) {
                    _show('The address must start with http:// or https://');
                    return;
                  }
                  await _service.updateSettings(s.copyWith(serverUrl: url));
                },
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Use the public KOReader server'),
                enabled: s.serverUrl != kOfficialSyncServer,
                onTap: () => _service.updateSettings(s.copyWith(serverUrl: kOfficialSyncServer)),
              ),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Device name'),
                subtitle: Text(_service.deviceName),
                onTap: () async {
                  final v = await _editText(
                    'Device name for sync',
                    s.deviceName ?? '',
                    hint: 'Leave empty to use ${_service.deviceModel}',
                  );
                  if (v == null) return;
                  await _service.updateSettings(s.copyWith(deviceName: () => v.trim().isEmpty ? null : v.trim()));
                },
              ),
              header('Automatic sync'),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.sync),
                title: const Text('Automatically keep documents in sync'),
                subtitle: const Text(
                  'Pull when a book opens or the app returns. Push when a book closes or the app '
                  'goes to the background.',
                ),
                value: s.autoSync,
                onChanged: (v) => _service.updateSettings(s.copyWith(autoSync: v)),
              ),
              ListTile(
                leading: const Icon(Icons.repeat),
                enabled: s.autoSync,
                title: const Text('Also push every # pages'),
                subtitle: Text(s.pagesBeforeUpdate > 0 ? '${s.pagesBeforeUpdate} pages' : 'Never'),
                onTap: () async {
                  final v = await _editText(
                    'Number of pages before update',
                    '${s.pagesBeforeUpdate}',
                    hint: '0 turns this off',
                    keyboard: TextInputType.number,
                  );
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 0 || n > 999) return;
                  await _service.updateSettings(s.copyWith(pagesBeforeUpdate: n));
                },
              ),
              header('Sync behavior'),
              _StrategyTile(
                title: 'Sync to a newer position',
                value: s.syncForward,
                onChanged: (v) => _service.updateSettings(s.copyWith(syncForward: v)),
              ),
              _StrategyTile(
                title: 'Sync to an older position',
                value: s.syncBackward,
                onChanged: (v) => _service.updateSettings(s.copyWith(syncBackward: v)),
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Document matching'),
                subtitle: const Text('Must be the same on all devices'),
                trailing: DropdownButton<ChecksumMethod>(
                  value: s.checksumMethod,
                  items: [for (final m in ChecksumMethod.values) DropdownMenuItem(value: m, child: Text(m.label))],
                  onChanged: (m) {
                    if (m != null) _service.updateSettings(s.copyWith(checksumMethod: m));
                  },
                ),
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.info_outline),
                title: const Text('Send book title and file name'),
                subtitle: const Text('The official server ignores this. Custom servers may use it.'),
                value: s.sendMetadata,
                onChanged: (v) => _service.updateSettings(s.copyWith(sendMetadata: v)),
              ),
              header('Offline queue'),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(_queued == null ? 'Queued updates' : 'Queued updates: $_queued'),
                subtitle: const Text('Positions that could not be sent. They are sent when a sync next succeeds.'),
                trailing: TextButton(
                  onPressed: s.isLoggedIn && (_queued ?? 0) > 0 ? _sendQueue : null,
                  child: const Text('Send now'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Device ID'),
                subtitle: Text(_service.deviceId, style: const TextStyle(fontFamily: 'monospace')),
                onLongPress: () => Clipboard.setData(ClipboardData(text: _service.deviceId)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _StrategyTile extends StatelessWidget {
  const _StrategyTile({required this.title, required this.value, required this.onChanged});

  final String title;
  final SyncStrategy value;
  final ValueChanged<SyncStrategy> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.swap_vert),
      title: Text(title),
      trailing: DropdownButton<SyncStrategy>(
        value: value,
        items: [for (final v in SyncStrategy.values) DropdownMenuItem(value: v, child: Text(v.label))],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog({required this.service, required this.initialUser});

  final KoSyncService service;
  final String initialUser;

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  late final _user = TextEditingController(text: widget.initialUser);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  /// KOReader validateUser(): both fields must have a non-space character.
  String? _validate() {
    final u = _user.text.trim().isNotEmpty;
    final p = _password.text.trim().isNotEmpty;
    if (!u && !p) return 'Invalid username and password';
    if (!u) return 'Invalid username';
    if (!p) return 'Invalid password';
    return null;
  }

  Future<void> _run(Future<void> Function(String, String) action) async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(_user.text, _password.text);
      if (mounted) Navigator.pop(context, true);
    } on KoSyncException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Progress sync account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _user,
            enabled: !_busy,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: _busy ? null : () => _run(widget.service.register), child: const Text('Register')),
        FilledButton(onPressed: _busy ? null : () => _run(widget.service.login), child: const Text('Login')),
      ],
    );
  }
}

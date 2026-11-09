// Library folders: the folders that the library scans, the download
// folder, and the Android "All files access" permission.
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_services.dart';
import 'library_settings.dart';

/// Android 11 (API 30) brought "All files access". Before it, the storage
/// permission gives path access.
Future<Permission> _storagePermission() async {
  final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  return sdk >= 30 ? Permission.manageExternalStorage : Permission.storage;
}

/// True when the app may read shared storage by path.
Future<bool> hasStorageAccess() async {
  if (!Platform.isAndroid) return true;
  return (await _storagePermission()).isGranted;
}

/// Asks for storage access (Android 11 and later open a settings page).
Future<bool> requestStorageAccess() async {
  if (!Platform.isAndroid) return true;
  return (await (await _storagePermission()).request()).isGranted;
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> with WidgetsBindingObserver {
  bool? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The user returns from the system settings page.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final a = await hasStorageAccess();
    if (mounted) setState(() => _access = a);
  }

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return ValueListenableBuilder<LibrarySettings>(
      valueListenable: services.library,
      builder: (context, s, _) {
        Future<void> save(LibrarySettings n) async {
          await services.updateLibrary(n);
          services.scanner.scan(n.folders).ignore();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Library folders')),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Add folder'),
            onPressed: _access == true
                ? () async {
                    final dir = await pickFolder(context);
                    if (dir != null && !s.folders.contains(dir)) await save(s.copyWith(folders: [...s.folders, dir]));
                  }
                : null,
          ),
          body: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
            if (_access == false)
              MaterialBanner(
                leading: const Icon(Icons.folder_off_outlined),
                content: const Text('To find book files in your folders, allow this app to access all files. '
                    'Books open in place; the app does not copy them.'),
                actions: [
                  FilledButton(
                    onPressed: () async {
                      await requestStorageAccess();
                      await _check();
                    },
                    child: const Text('Allow'),
                  ),
                ],
              ),
            const ListTile(
              title: Text('Scanned folders'),
              subtitle: Text('EPUB and FB2 files in these folders and their subfolders show in the library.'),
            ),
            for (final f in s.folders)
              ListTile(
                leading: Icon(Directory(f).existsSync() ? Icons.folder : Icons.folder_off),
                title: Text(f),
                subtitle: Directory(f).existsSync() ? null : const Text('Folder not found'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove',
                  onPressed: () => save(s.copyWith(folders: [...s.folders]..remove(f))),
                ),
              ),
            if (s.folders.isEmpty) const ListTile(title: Text('No folders.')),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download folder'),
              subtitle: Text(s.effectiveDownloadFolder ?? 'Not set'),
              onTap: _access == true
                  ? () async {
                      final dir = await pickFolder(context);
                      if (dir != null) await services.updateLibrary(s.copyWith(downloadFolder: () => dir));
                    }
                  : null,
            ),
          ]),
        );
      },
    );
  }
}

/// A simple folder browser for shared storage. Returns the chosen path.
Future<String?> pickFolder(BuildContext context, {String start = LibrarySettings.storageRoot}) {
  return Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => _FolderPicker(start: start)));
}

class _FolderPicker extends StatefulWidget {
  const _FolderPicker({required this.start});

  final String start;

  @override
  State<_FolderPicker> createState() => _FolderPickerState();
}

class _FolderPickerState extends State<_FolderPicker> {
  late String _dir = widget.start;

  List<Directory> _children() {
    try {
      final list = Directory(_dir)
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where((d) => !d.path.split('/').last.startsWith('.'))
          .toList()
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      return list;
    } on FileSystemException {
      return const [];
    }
  }

  /// Storage volumes: internal storage and SD cards under /storage.
  List<String> _volumes() {
    final v = <String>[LibrarySettings.storageRoot];
    try {
      for (final d in Directory('/storage').listSync().whereType<Directory>()) {
        final name = d.path.split('/').last;
        if (name != 'emulated' && name != 'self') v.add(d.path);
      }
    } on FileSystemException {
      // /storage is not listable on some devices.
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final children = _children();
    final volumes = _volumes();
    final parent = Directory(_dir).parent.path;
    final atRoot = volumes.contains(_dir);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a folder'),
        actions: [
          if (volumes.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sd_storage),
              tooltip: 'Storage',
              onSelected: (v) => setState(() => _dir = v),
              itemBuilder: (_) => [for (final v in volumes) PopupMenuItem(value: v, child: Text(v))],
            ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New folder',
            onPressed: () async {
              final c = TextEditingController();
              final name = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('New folder'),
                  content: TextField(controller: c, autofocus: true),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Create')),
                  ],
                ),
              );
              if (name == null || name.trim().isEmpty) return;
              try {
                await Directory('$_dir/${name.trim()}').create();
                setState(() => _dir = '$_dir/${name.trim()}');
              } on FileSystemException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(_dir, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(children: [
            if (!atRoot)
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('..'),
                onTap: () => setState(() => _dir = parent),
              ),
            for (final d in children)
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(d.path.split('/').last),
                onTap: () => setState(() => _dir = d.path),
              ),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _dir),
            child: const Text('Use this folder'),
          ),
        ),
      ),
    );
  }
}

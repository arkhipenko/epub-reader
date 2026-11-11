import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'licenses.dart';

/// The About dialog: the copyright, the license and warranty statement, the
/// source code address, and the license page (GNU AGPL "Appropriate Legal
/// Notices").
void showAppAbout(BuildContext context, String version) {
  showAboutDialog(
    context: context,
    applicationName: kAppName,
    applicationVersion: 'Version $version',
    applicationIcon: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('images/icon.png', width: 48, height: 48),
    ),
    applicationLegalese: kCopyright,
    children: const [
      SizedBox(height: 16),
      Text(
        'This program is free software under the GNU Affero General Public '
        'License, version 3 or later. You can give it to others and change it '
        'under the terms of that license. It comes with ABSOLUTELY NO WARRANTY.\n\n'
        'It includes crengine, parts of KOReader, fonts and libraries from other '
        'projects. "View licenses" shows the license texts and their authors.',
      ),
      SizedBox(height: 16),
      _SourceLink(),
    ],
  );
}

class _SourceLink extends StatefulWidget {
  const _SourceLink();

  @override
  State<_SourceLink> createState() => _SourceLinkState();
}

class _SourceLinkState extends State<_SourceLink> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SelectableText('Source code:\n$kSourceUrl')),
        IconButton(
          icon: Icon(_copied ? Icons.check : Icons.copy),
          tooltip: 'Copy the address',
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: kSourceUrl));
            if (mounted) setState(() => _copied = true);
          },
        ),
      ],
    );
  }
}

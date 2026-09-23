import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/native/vita_shell.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:routerino/routerino.dart';

class CannotOpenFileDialog extends StatelessWidget {
  final String path;

  const CannotOpenFileDialog({required this.path, super.key});

  static Future<void> open(BuildContext context, String path, void Function()? onDeleteTap) async {
    if (checkPlatformIsDesktop()) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(t.dialogs.cannotOpenFile.title),
          content: Text(t.dialogs.cannotOpenFile.content(file: path)),
          actions: [
            _OpenInVitaShellButton(path: path),
            if (onDeleteTap != null)
              TextButton(
                onPressed: () {
                  onDeleteTap();
                  context.pop();
                },
                child: Text(t.receiveHistoryPage.entryActions.deleteFromHistory),
              ),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(t.general.close),
            )
          ],
        ),
      );
    } else {
      await context.pushBottomSheet(() => CannotOpenFileDialog(path: path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: t.dialogs.cannotOpenFile.title,
      description: t.dialogs.cannotOpenFile.content(file: path),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OpenInVitaShellButton(path: path),
            ElevatedButton(
              onPressed: () => context.popUntilRoot(),
              child: Text(t.general.close),
            ),
          ],
        ),
      ),
    );
  }
}


/// "Open in VitaShell", shown only on a console that has it.
///
/// The label says what happens because what happens is drastic: the Vita runs
/// one application at a time, so this closes LocalSend. A button that quits the
/// app without warning is not a button, it is a trap.
///
/// The string is not translated. Every other string here comes from slang, and
/// adding one means regenerating the whole catalogue for a control that exists
/// on exactly one platform; a literal is the smaller lie. See
/// patches/corpus/localsend-0002.
class _OpenInVitaShellButton extends StatelessWidget {
  const _OpenInVitaShellButton({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    // Asked every time the dialog opens rather than cached, which costs one
    // platform-channel round trip on a dialog that is already waiting for a
    // human. VitaShell can be installed while the app is running.
    return FutureBuilder<bool>(
      future: VitaShell.available(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return TextButton(
          // Not awaited: when it succeeds this process is gone before the
          // future completes.
          onPressed: () => VitaShell.openFolderOf(path),
          child: const Text('Open in VitaShell (closes app)'),
        );
      },
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flubar/app/constants.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/ui/dialogs/get_dialog/providers.dart';
import 'package:flubar/ui/view/settings_view/view.dart';
import 'package:flubar/ui/widgets/media_drag_widget/providers.dart';
import 'package:flubar/ui/widgets/player_widget/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'constants.dart';
import 'menu_entry.dart';
import 'providers.dart';

class MenuBarWidget extends ConsumerStatefulWidget {
  const MenuBarWidget({super.key});

  @override
  ConsumerState<MenuBarWidget> createState() => _MenuBarWidgetState();
}

class _MenuBarWidgetState extends ConsumerState<MenuBarWidget> {
  ShortcutRegistryEntry? _shortcutsEntry;

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MenuBar(children: MenuEntry.build(_getEntries()));

  List<MenuEntry> _getEntries() {
    final entries = [
      MenuEntry(
        label: '文件',
        menuChildren: [
          MenuEntry(
            label: '添加',
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true, allowedExtensions: kAudioExtensions);
              if (result != null) {
                ref
                    .read(mediaDragStateProvider.notifier)
                    .addFiles(result.xFiles.map((e) => e.path));
              }
            },
          ),
          const MenuEntry(divider: true),
          MenuEntry(
            label: '设置',
            onPressed: () async => await ref
                .read(getDialogProvider.notifier)
                .to(const SettingsView()),
          ),
        ],
      ),
      MenuEntry(
        label: '播放器',
        menuChildren: [
          MenuEntry(
            label: '播放选中',
            enabled: hasSelectionProvider,
            onPressed: () async =>
                await ref.read(playerProvider.notifier).play(),
            shortcut: const SingleActivator(LogicalKeyboardKey.f8),
          ),
          MenuEntry(
            label: '上一首',
            streamEnabled: playerHasPreviousProvider,
            onPressed: () async =>
                await ref.read(playerProvider.notifier).previous(),
            shortcut: const SingleActivator(LogicalKeyboardKey.f7),
          ),
          MenuEntry(
            label: '下一首',
            streamEnabled: playerHasNextProvider,
            onPressed: () async =>
                await ref.read(playerProvider.notifier).next(),
            shortcut: const SingleActivator(LogicalKeyboardKey.f9),
          ),
        ],
      ),
      MenuEntry(
        label: '帮助',
        menuChildren: [
          MenuEntry(
            label: 'Talker',
            menuChildren: [
              MenuEntry(
                label: 'Global',
                onPressed: () async => await ref
                    .read(getDialogProvider.notifier)
                    .to(TalkerScreen(talker: globalTalker)),
              ),
              MenuEntry(
                label: 'Rename',
                onPressed: () async => await ref
                    .read(getDialogProvider.notifier)
                    .to(TalkerScreen(talker: renameTalker)),
              ),
              MenuEntry(
                label: 'Transcode',
                onPressed: () async => await ref
                    .read(getDialogProvider.notifier)
                    .to(TalkerScreen(talker: transcodeTalker)),
              ),
            ],
          ),
          MenuEntry(
            label: '关于',
            onPressed: () => showAboutDialog(
                context: context,
                applicationName: kAppName,
                applicationVersion: kAppVersion),
          ),
        ],
      ),
    ];
    _shortcutsEntry?.dispose();
    _shortcutsEntry =
        ShortcutRegistry.of(context).addAll(MenuEntry.shortcuts(entries));
    return entries;
  }
}

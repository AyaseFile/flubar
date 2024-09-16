import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/view/playlist_view/view.dart';
import 'package:flubar/ui/view/tracklist_view/view.dart';
import 'package:flubar/ui/widgets/media_drag_widget/view.dart';
import 'package:flubar/ui/widgets/menu_bar_widget/view.dart';
import 'package:flubar/ui/widgets/talker_wrapper/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:window_manager/window_manager.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    ref.read(settingsProvider.notifier).saveSettings();
    super.onWindowClose();
  }

  @override
  Widget build(BuildContext context) {
    final multiSplitViewTheme = MultiSplitViewThemeData(
      dividerThickness: kDividerThickness,
      dividerPainter: DividerPainters.grooved1(
        color: Theme.of(context).colorScheme.primary,
        highlightedColor: Theme.of(context).colorScheme.primary,
      ),
    );
    return Scaffold(
      body: TalkerWrapper(
        talker: globalTalker,
        child: Column(
          children: [
            const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Expanded(child: MenuBarWidget())]),
            Expanded(
              child: MultiSplitViewTheme(
                data: multiSplitViewTheme,
                child: MultiSplitView(
                  pushDividers: true,
                  initialAreas: [
                    Area(
                        flex: 1,
                        builder: (context, area) => const PlaylistView()),
                    Area(
                      flex: 5,
                      builder: (context, area) => const Stack(
                          children: [TrackTableView(), MediaDragWidget()]),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
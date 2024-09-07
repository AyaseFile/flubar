import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuEntry {
  final String? label;
  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;
  final Provider<bool>? enabled;
  final StreamProvider<bool>? streamEnabled;
  final bool divider;

  const MenuEntry({
    this.label,
    this.shortcut,
    this.onPressed,
    this.menuChildren,
    this.enabled,
    this.streamEnabled,
    this.divider = false,
  })  : assert(menuChildren == null || onPressed == null),
        assert(label == null || divider == false);

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.divider) {
        return const MenuDivider();
      }
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label!),
        );
      }
      if (selection.enabled != null) {
        return Consumer(
          builder: (context, ref, _) {
            final enabled = ref.watch(selection.enabled!);
            return MenuItemButton(
              shortcut: selection.shortcut,
              onPressed: enabled ? selection.onPressed : null,
              child: Text(selection.label!),
            );
          },
        );
      }
      if (selection.streamEnabled != null) {
        return Consumer(
          builder: (context, ref, _) {
            final enabled = ref.watch(selection.streamEnabled!);
            return MenuItemButton(
              shortcut: selection.shortcut,
              onPressed: enabled.when(
                data: (value) => value ? selection.onPressed : null,
                loading: () => null,
                error: (e, st) => null,
              ),
              child: Text(selection.label!),
            );
          },
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label!),
      );
    }

    return selections.map(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(
      List<MenuEntry> selections) {
    final result = <MenuSerializableShortcut, Intent>{};
    for (final selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
      } else {
        if (selection.shortcut != null && selection.onPressed != null) {
          result[selection.shortcut!] =
              VoidCallbackIntent(selection.onPressed!);
        }
      }
    }
    return result;
  }
}

class MenuDivider extends StatelessWidget {
  const MenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
        height: 8.0,
        child: Divider(thickness: 1.0, indent: 8.0, endIndent: 8.0));
  }
}

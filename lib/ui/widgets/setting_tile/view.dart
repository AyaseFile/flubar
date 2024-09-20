import 'package:flubar/app/settings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart' as settings_ui;

class SettingsTile<N extends Notifier<T>, T, V>
    extends settings_ui.AbstractSettingsTile {
  final String title;
  final String? description;
  final Widget? leading;
  final NotifierProvider<N, T> provider;
  final V Function(T) selector;
  final void Function(BuildContext)? onPressed;

  const SettingsTile({
    super.key,
    required this.title,
    this.description,
    this.leading,
    required this.provider,
    required this.selector,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final value = ref.watch(provider.select(selector));
      return settings_ui.SettingsTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        description: description != null
            ? Text(description!, style: const TextStyle(fontSize: 12))
            : null,
        leading: leading,
        trailing: Text(value is String ? value : value.toString(),
            style: const TextStyle(fontSize: 14)),
        onPressed: onPressed,
      );
    });
  }
}

class ExampleSettingsTile extends settings_ui.AbstractSettingsTile {
  final String title;
  final String? description;
  final Widget? leading;
  final String Function(String)? processValue;

  const ExampleSettingsTile({
    super.key,
    required this.title,
    this.description,
    this.leading,
    this.processValue,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final value = () {
        final value = ref.watch(
            metadataSettingsProvider.select((state) => state.fileNameTpl));
        return processValue != null ? processValue!(value) : value;
      }();
      return settings_ui.SettingsTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        description: description != null
            ? Text(description!, style: const TextStyle(fontSize: 12))
            : null,
        leading: leading,
        trailing: Text(value,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        enabled: false,
      );
    });
  }
}

class SwitchSettingsTile<N extends Notifier<T>, T>
    extends settings_ui.AbstractSettingsTile {
  final String title;
  final Widget? leading;
  final NotifierProvider<N, T> provider;
  final bool Function(T) selector;
  final void Function(bool)? onToggle;

  const SwitchSettingsTile({
    super.key,
    required this.title,
    this.leading,
    required this.provider,
    required this.selector,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final value = ref.watch(provider.select(selector));
      return settings_ui.SettingsTile.switchTile(
        initialValue: value,
        onToggle: onToggle,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        leading: leading,
      );
    });
  }
}

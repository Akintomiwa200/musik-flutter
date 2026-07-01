import 'package:flutter/material.dart';

import '../data/sample_albums.dart';
import '../models/album.dart';
import '../screens/account_settings_screen.dart';
import '../screens/album_screen.dart';
import '../screens/code_scanner_screen.dart';
import '../screens/now_playing_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/queue_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/share_screen.dart';
import '../screens/storage_settings_screen.dart';
import '../screens/usb_screen.dart';

/// Central navigation helpers so every screen links consistently.
class AppRoutes {
  AppRoutes._();

  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  static Future<int?> settings(BuildContext context, {int currentTab = 0}) {
    return push<int>(context, SettingsScreen(currentTab: currentTab));
  }

  static void profile(BuildContext context) => push(context, const ProfileScreen());
  static void album(BuildContext context, {required Album album}) =>
      push(context, AlbumScreen(album: album));
  static void scanner(BuildContext context) => push(context, const CodeScannerScreen());
  static void usb(BuildContext context) => push(context, const UsbScreen());
  static void storage(BuildContext context) => push(context, const StorageSettingsScreen());
  static void account(BuildContext context) => push(context, const AccountSettingsScreen());
  static void queue(BuildContext context, {required String source}) =>
      push(context, QueueScreen(sourceLabel: source));
  static void share(BuildContext context, {required String title, required String artist}) =>
      push(context, ShareScreen(title: title, artist: artist));
  static void nowPlaying(BuildContext context, {Album? album}) =>
      push(context, NowPlayingScreen(album: album));
}

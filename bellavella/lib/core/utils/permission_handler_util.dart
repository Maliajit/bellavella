import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHandlerUtil {
  static Future<void> requestAllPermissions(BuildContext context) async {
    if (kIsWeb) return; // Permissions managed by browser
    
    // 1. Basic Permissions (Location, Camera, Mic, Notifications)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.storage,
    ].request();

    // 2. Background Location (Requires separate request on Android 10+)
    if (await Permission.location.isGranted) {
      if (await Permission.locationAlways.isDenied) {
        // Shown on next initialization or triggered manually
        await Permission.locationAlways.request();
      }
    }

    // 3. System Alert Window (Display over other apps)
    // This is critical for the full-screen "Incoming Call" style UI
    if (await Permission.systemAlertWindow.isDenied) {
      if (context.mounted) {
        bool? userApproved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overlay Permission Required'),
            content: const Text(
              'To receive incoming service requests like a phone call, please enable "Display over other apps" in the next screen.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (userApproved == true) {
          await Permission.systemAlertWindow.request();
        }
      }
    }
  }

  static Future<bool> checkOverlayPermission() async {
    return await Permission.systemAlertWindow.isGranted;
  }
}

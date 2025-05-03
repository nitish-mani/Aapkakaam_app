import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker extends StatefulWidget {
  final Widget child;
  const VersionChecker({Key? key, required this.child}) : super(key: key);

  @override
  State<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends State<VersionChecker> {
  String _currentVersion = '';
  String _latestVersion = '1.0.1'; // Example (normally fetched from API)

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = info.version;
      print("Current Version: $_currentVersion");
      print("Latest Version: $_latestVersion");
    });

    if (_currentVersion != _latestVersion) {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false, // Block system back button
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.system_update,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Update Available',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              content: const Text(
                'A newer version of the app is available.\nPlease update to continue.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    // TODO: Redirect user to Play Store / App Store link
                    // Example: launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.example.app"));
                  },
                  child: const Text(
                    'Update Now',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

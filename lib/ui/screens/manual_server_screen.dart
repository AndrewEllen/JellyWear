import 'package:flutter/material.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../data/jellyfin/server_discovery.dart';
import '../../navigation/app_router.dart';

/// Screen for manually entering a server URL.
class ManualServerScreen extends StatefulWidget {
  const ManualServerScreen({super.key});

  @override
  State<ManualServerScreen> createState() => _ManualServerScreenState();
}

class _ManualServerScreenState extends State<ManualServerScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Dismiss keyboard first
    _focusNode.unfocus();

    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Enter a URL');
      return;
    }

    // Add http:// if no protocol specified
    String normalizedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      normalizedUrl = 'http://$url';
    }

    // Remove trailing slash
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    // Validate server connection
    final serverInfo = await ServerDiscovery.validateServer(normalizedUrl);

    if (!mounted) return;

    setState(() => _isValidating = false);

    if (serverInfo == null) {
      setState(() => _errorMessage = 'Could not connect to $normalizedUrl');
      return;
    }

    // Navigate to login with validated server info
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginScreenArgs(
        serverUrl: serverInfo.address,
        serverName: serverInfo.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Server URL',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _submit(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '192.168.1.100:8096',
                    errorText: _errorMessage,
                    errorMaxLines: 2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _submit,
                    child: _isValidating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Connect'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

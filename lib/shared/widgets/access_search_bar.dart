import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccessSearchBar extends StatefulWidget {
  const AccessSearchBar({super.key});

  @override
  State<AccessSearchBar> createState() => _AccessSearchBarState();
}

class _AccessSearchBarState extends State<AccessSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_controller.text != state.searchQuery) {
      _controller.text = state.searchQuery;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: context.read<AppState>().search,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search accessible places...',
          hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 28),
          suffixIcon: IconButton(
            tooltip: 'Voice search',
            onPressed: () async {
              final appState = context.read<AppState>();
              final message = await appState.startVoiceSearch();
              if (message != null && context.mounted) {
                appState.ttsService.speak(message);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            icon: Icon(
              state.isListening ? Icons.mic : Icons.mic_none,
              color: state.isListening ? AppColors.error : AppColors.primary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

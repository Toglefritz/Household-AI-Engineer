import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/insets.dart';

/// Search section component for the dashboard sidebar.
///
/// Provides a search input field for filtering applications. Only displayed when the sidebar is expanded to provide
/// sufficient space for text input.
class SidebarSearchSection extends StatelessWidget {
  /// Creates a sidebar search section widget.
  const SidebarSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchApplicationsHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Insets.small,
                vertical: Insets.xSmall,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Padding(
            padding: EdgeInsets.only(top: Insets.medium),
          ),
        ],
      ),
    );
  }
}

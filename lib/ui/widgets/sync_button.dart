import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/ui/bloc/sync/sync_bloc.dart';
import 'package:ligne/ui/widgets/loading/loading_indicator.dart';

class SyncButton extends StatelessWidget {
  final VoidCallback? onSyncSuccess;
  final bool showLoading;
  
  const SyncButton({
    super.key,
    this.onSyncSuccess,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state is SyncFailure) {
          // Close any open loading dialogs first
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${state.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  if (!state.isSyncing) {
                    context.read<SyncBloc>().add(const SyncData());
                  }
                },
              ),
            ),
          );
        } else if (state is SyncSuccess) {
          // Close loading dialog if shown
          if (showLoading && Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          
          // Notify parent about successful sync
          if (onSyncSuccess != null) {
            // Use a post-frame callback to ensure the dialog is dismissed first
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onSyncSuccess!();
            });
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sync completed successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is SyncInProgress) {
          // Show loading dialog when sync starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!Navigator.canPop(context)) {
              showDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black45,
                builder: (BuildContext context) {
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const LoadingIndicator(
                              size: LoadingIndicatorSize.large,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Syncing Data...',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please wait while we sync your data',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          });
        }
      },
      builder: (context, state) {
        // Show loading dialog if showLoading is true and syncing
        if (showLoading && state.isSyncing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => WillPopScope(
                onWillPop: () async => false,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingIndicator(
                          size: LoadingIndicatorSize.large,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Syncing Data...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we sync your data',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          });
        }
        
        return IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              // Base icon
              const Icon(Icons.sync),
              // Loading indicator
              if (state.isSyncing)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    padding: const EdgeInsets.all(2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: state.isSyncing
              ? null
              : () => context.read<SyncBloc>().add(const SyncData()),
          tooltip: 'Sync with cloud',
        );
      },
    );
  }
}

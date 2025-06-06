import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/ui/bloc/sync/sync_bloc.dart';

class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state is SyncFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${state.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is SyncSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        // Show loading overlay if syncing
        if (state.isSyncing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          });
        } else {
          // Close the dialog if it's open when sync is done
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }

        return IconButton(
          icon: const Icon(Icons.sync),
          onPressed: state.isSyncing
              ? null
              : () => context.read<SyncBloc>().add(const SyncData()),
          tooltip: 'Sync with cloud',
        );
      },
    );
  }
}

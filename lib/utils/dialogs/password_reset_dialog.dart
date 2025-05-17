import 'package:flutter/material.dart';
import 'package:ligne/utils/dialogs/generic_dialog.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

Future<void> showPasswordResetDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context, 
    title: context.loc.password_reset, 
    content: context.loc.password_reset_dialog_prompt, 
    optionsBuilder: () => {
      context.loc.ok: null,
    },
  );
}

import 'package:flutter/material.dart';
import 'package:ligne/utils/dialogs/generic_dialog.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

Future<void> showErrorDialog(BuildContext context, String text) {
  return showGenericDialog(
    context: context, 
    title: context.loc.generic_error_prompt, 
    content: text, 
    optionsBuilder: () => {
      context.loc.ok: null,
    },
  );
}

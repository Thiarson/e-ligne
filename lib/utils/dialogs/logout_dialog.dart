import 'package:flutter/material.dart';
import 'package:ligne/utils/dialogs/generic_dialog.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

Future<bool> showLogoutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context, 
    title: context.loc.logout_button, 
    content: context.loc.logout_dialog_prompt, 
    optionsBuilder: () => {
      context.loc.yes: true,
      context.loc.cancel: false,
    },
  ).then((value) => value ?? false);
}

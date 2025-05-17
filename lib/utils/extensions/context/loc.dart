import 'package:flutter/material.dart' show BuildContext;
import 'package:ligne/l10n/gen/app_localizations.dart'
  show AppLocalizations;

extension Localization on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

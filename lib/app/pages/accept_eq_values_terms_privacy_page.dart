import 'dart:io';

import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

class AcceptEqualitieValuesTermsPrivacyPage extends StatefulWidget {
  const AcceptEqualitieValuesTermsPrivacyPage({
    required this.settings,
  });

  final Settings settings;

  @override
  State<AcceptEqualitieValuesTermsPrivacyPage> createState() =>
      _AcceptEqualitieValuesTermsPrivacyPageState();
}

class _AcceptEqualitieValuesTermsPrivacyPageState
    extends State<AcceptEqualitieValuesTermsPrivacyPage> {
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          body: ContentWithStickyFooterState(
            content: _buildContent(context),
            footer: Fields.dialogActions(
              context,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              buttons: _buildActions(context),
            ),
          ),
        ),
      );

  Column _buildContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headerImages(),
        const SizedBox(height: 60.0),
        _introTextSpan(),
        const SizedBox(height: 20.0),
        EqValues(),
        EqTermsAndPrivacy(),
      ],
    );
  }

  Widget _headerImages() => Column(children: [
        const SizedBox(height: 18.0),
        Image.asset(Constants.ouisyncLogoFull,
            width: MediaQuery.of(context).size.width * 0.6),
        Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(S.current.messageBy,
                style: context.theme.appTextStyle.bodyMicro
                    .copyWith(color: Colors.black54))),
        Image.asset(Constants.eQLogo,
            width: MediaQuery.of(context).size.width * 0.2)
      ]);

  Widget _introTextSpan() => RichText(
      textAlign: TextAlign.start,
      text: TextSpan(style: context.theme.appTextStyle.bodyMedium, children: [
        Fields.boldTextSpan(S.current.titleAppTitle),
        TextSpan(text: ' ${S.current.messageEqualitieValues}')
      ]));

  List<Widget> _buildActions(BuildContext context) => [
        OutlinedButton(
            onPressed: () => exit(0),
            child: Text(S.current.actionIDontAgree.toUpperCase())),
        ElevatedButton(
            onPressed: () async {
              await widget.settings.setEqualitieValues(true);
              Navigator.of(context).pop(null);
            },
            autofocus: true,
            child: Text(S.current.actionIAgree.toUpperCase()))
      ];
}

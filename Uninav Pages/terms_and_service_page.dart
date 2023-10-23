import 'package:flutter/material.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/back_button.dart';

class TermsAndServicePage extends StatefulWidget {
  const TermsAndServicePage({Key? key}) : super(key: key);

  static const String routeName = "TermsAndService";

  @override
  State<TermsAndServicePage> createState() => _TermsAndServicePageState();
}

class _TermsAndServicePageState extends State<TermsAndServicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(MarginConstants.sideMargin, MediaQuery.of(context).padding.top, MarginConstants.sideMargin, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MyBackButton(),
              Text(
                "Terms and Service",
                style:
                    AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "I've Got Nothin",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

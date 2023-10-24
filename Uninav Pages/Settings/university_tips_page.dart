import 'package:flutter/material.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/back_button.dart';

class UniversityTipsPage extends StatefulWidget {
  const UniversityTipsPage({Key? key}) : super(key: key);

  static const String routeName = "UniversityTips";

  @override
  State<UniversityTipsPage> createState() => _UniversityTipsPageState();
}

class _UniversityTipsPageState extends State<UniversityTipsPage> {
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
                "Univeristy Tips",
                style:
                    AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "No tips",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

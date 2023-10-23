import 'package:flutter/material.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/back_button.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  static const String routeName = "AboutUs";

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
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
                "About Us",
                style:
                    AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "I'm at your mom's house",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

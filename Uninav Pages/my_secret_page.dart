import 'package:flutter/material.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/back_button.dart';

class MySecretPage extends StatefulWidget {
  const MySecretPage({Key? key}) : super(key: key);

  static const String routeName = "MySecret";

  @override
  State<MySecretPage> createState() => _MySecretPageState();
}

class _MySecretPageState extends State<MySecretPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              MarginConstants.sideMargin,
              MediaQuery.of(context).padding.top,
              MarginConstants.sideMargin,
              0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MyBackButton(),
              Text(
                "My Secret",
                style:
                    AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "I'm Sad",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/alert_dialog.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  static const String routeName = "FeedbackPage";

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const String _feedbackText =
      "Feel free to send us feedback on the app and any new information we should add to the app.";

  final TextEditingController _feedBackTextController =
      TextEditingController(text: "");

  @override
  void dispose() {
    _feedBackTextController.dispose();
    super.dispose();
  }

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
                AppLocalizations.of(context)!.feedback,
                style: AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                _feedbackText,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              SizedBox(
                height: 200,
                child: TextField(
                  controller: _feedBackTextController,
                  maxLines: null, // Set this
                  expands: true, // and this
                  cursorColor: Colors.black,
                  textAlign: TextAlign.start,
                  textAlignVertical: TextAlignVertical.top,

                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Theme.of(context).disabledColor, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Theme.of(context).disabledColor, width: 1)),
                  ),
                  onSubmitted: (value) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  keyboardType: TextInputType.name,
                ),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: ElevatedButton(
                    onPressed: () {
                      if (_feedBackTextController.text.isEmpty) {
                        return;
                      }
                      final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'walidsheykho@gmail.com',
                          queryParameters: {
                            'subject': 'Uninav Feedback',
                            'body': _feedBackTextController.text
                          });
                      canLaunchUrl(emailLaunchUri).then((value) {
                        if (value) {
                          launchUrl(emailLaunchUri);
                          _feedBackTextController.clear();
                        } else {
                          String dialogTitle = "Message Failed";
                          String dialogMessage =
                              "Unfortunately the email message failed to send. Please try again.";
                          var dialog = CustomAlertDialog(
                              title: dialogTitle,
                              message: Text(dialogMessage,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              onPostivePressed: () {},
                              onNegativePressed: null,
                              positiveBtnText: "",
                              negativeBtnText: "Okay");

                          showDialog(
                              context: context,
                              builder: (BuildContext context) => dialog);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize:
                            const Size(double.infinity, double.infinity),
                        backgroundColor: const Color.fromARGB(255, 0, 85, 222)),
                    child: Text(
                      "Open Email",
                      style: AppTextStyle.ptSansBold(size: 18),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}

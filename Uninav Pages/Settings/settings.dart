import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Settings/about_us_page.dart';
import 'package:uninav/Screens/Settings/account.dart';
import 'package:uninav/Screens/Settings/feedback_page.dart';
import 'package:uninav/Screens/Settings/my_data.dart';
import 'package:uninav/Screens/Settings/my_secret_page.dart';
import 'package:uninav/Screens/Settings/preferences.dart';
import 'package:uninav/Screens/Settings/terms_and_service_page.dart';
import 'package:uninav/Screens/Settings/university_tips_page.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/Settings/settings_option_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static const String routeName = "SettingsPage";

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Map<String, String> places1 = {
    "Account": AccountPage.routeName,
    "Preferences": PreferencesPage.routeName,
    "My Data": MyDataPage.routeName,
  };

  static const Map<String, String> places2 = {
    "Feedback and Support": FeedbackPage.routeName,
    "Univeristy Tips": UniversityTipsPage.routeName,
    "My Secret": MySecretPage.routeName,
  };

  static const Map<String, String> places3 = {
    "Terms and Service": TermsAndServicePage.routeName,
    "About Us": AboutUsPage.routeName,
  };

  void _pushPage1(String page) {
    context.pushNamed(places1[page]!);
  }

  void _pushPage2(String page) {
    context.pushNamed(places2[page]!);
  }

  void _pushPage3(String page) {
    context.pushNamed(places3[page]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
        child: SingleChildScrollView(
            child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + MarginConstants.sideMargin,
            ),
            Row(
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      image: DecorationImage(
                          image: Provider.of<UserProvider>(context, listen: false)
                            .getUserProfileUrl != null ? Image.network(
                        Provider.of<UserProvider>(context, listen: false)
                            .getUserProfileUrl!,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(Provider.of<UserProvider>(context, listen: false).getDefaultUserProfilePath);
                        },
                      ).image : Image.asset(Provider.of<UserProvider>(context, listen: false).getDefaultUserProfilePath).image)),
                  clipBehavior: Clip.hardEdge,
                ),
                const SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Provider.of<UserProvider>(context, listen: false)
                              .getUserData
                              ?.name ??
                          "",
                      style: AppTextStyle.ptSansBold(
                          color: Colors.black, size: 22),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      Provider.of<UserProvider>(context, listen: false)
                          .getUserEmail,
                      style: AppTextStyle.ptSansRegular(
                          color: Theme.of(context).hintColor, size: 18),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: MarginConstants.formHeightBetweenSection,
            ),
            SettingsOptions(
              operations: places1.keys.toList(),
              call: _pushPage1,
            ),
            const SizedBox(
              height: MarginConstants.formHeightBetweenSection,
            ),
            SettingsOptions(
              operations: places2.keys.toList(),
              call: _pushPage2,
            ),
            const SizedBox(
              height: MarginConstants.formHeightBetweenSection,
            ),
            SettingsOptions(
              operations: places3.keys.toList(),
              call: _pushPage3,
            )
          ],
        )),
      ),
    );
  }
}

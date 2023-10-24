import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/app_themes.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:uninav/Widgets/Settings/theme_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ThemeSelectionPage extends StatefulWidget {
  const ThemeSelectionPage({Key? key}) : super(key: key);

  static const String routeName = "ThemeSelectionPage";

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  final List<ColorScheme> themes = AppThemes.appThemeList;

  @override
  Widget build(BuildContext context) {
    int selectedIndex =
        Provider.of<UserProvider>(context, listen: false).getUserData?.theme ??
            0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(MarginConstants.sideMargin,
            MediaQuery.of(context).padding.top, MarginConstants.sideMargin, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MyBackButton(),
            Text(
              AppLocalizations.of(context)!.theme,
              style: AppTextStyle.ptSansBold(color: Colors.black, size: 30),
            ),
            const SizedBox(
              height: MarginConstants.formHeightBetweenTitleSection,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        0,
                        MarginConstants.formHeightBetweenSection,
                        0,
                        MarginConstants.formHeightBetweenSection),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            Provider.of<UserProvider>(context, listen: false)
                                .updateUserTheme(index);
                          });
                        },
                        child: ThemeCard(
                            key: Key(index.toString()),
                            selected: index == selectedIndex,
                            colors: [
                              themes[index].primary,
                              themes[index].secondary,
                              themes[index].tertiary
                            ]),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                        height: MarginConstants.formHeightBetweenSubsection,
                      );
                    },
                    itemCount: themes.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

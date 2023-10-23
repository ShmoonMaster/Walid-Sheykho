import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Settings/theme_selection.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/language_helper.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({Key? key}) : super(key: key);

  static const String routeName = "PreferencesPage";

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late bool _international;
  late String _language;

  @override
  void initState() {
    super.initState();
    _international = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.international ??
        false;
    _language = LanguageHelper.fullLanguageStringFromShort(
        Provider.of<UserProvider>(context, listen: false)
                .getUserData
                ?.getSetLanguage ??
            "");
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
                AppLocalizations.of(context)!.preferences,
                style: AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "Theme",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleText,
              ),
              GestureDetector(
                onTap: () {
                  context.pushNamed(ThemeSelectionPage.routeName);
                },
                child: Container(
                  height: SizeConstants.textBoxHeight,
                  padding: const EdgeInsets.fromLTRB(
                      MarginConstants.extraSideMargin,
                      0,
                      MarginConstants.extraSideMargin,
                      0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Row(children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          shape: BoxShape.circle),
                    ),
                    Expanded(
                        child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 20, color: Theme.of(context).highlightColor),
                    ))
                  ]),
                ),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              Text(
                "Language",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleText,
              ),
              PopupMenuButton(
                  elevation: 0,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, -60),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                          onTap: () {
                            setState(() {
                              Provider.of<UserProvider>(context, listen: false)
                                  .setLanguage(Language.en.name);
                              _language =
                                  LanguageHelper.fullLanguageStringFromShort(
                                      Language.en.name);
                            });
                          },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text(
                              LanguageHelper.fullLanguageStringFromShort(
                                  Language.en.name),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )),
                      PopupMenuItem(
                          onTap: () {
                            setState(() {
                              Provider.of<UserProvider>(context, listen: false)
                                  .setLanguage(Language.ja.name);
                              _language =
                                  LanguageHelper.fullLanguageStringFromShort(
                                      Language.ja.name);
                            });
                          },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text(
                              LanguageHelper.fullLanguageStringFromShort(
                                  Language.ja.name),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )),
                    ];
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 80.0),
                    child: Container(
                      height: SizeConstants.textBoxHeight,
                      padding: const EdgeInsets.fromLTRB(
                          MarginConstants.bigChipMargin,
                          0,
                          MarginConstants.bigChipMargin,
                          0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_language,
                              style: Theme.of(context).textTheme.bodyMedium),
                          Icon(Icons.unfold_more_rounded,
                              size: 20,
                              color: Theme.of(context).highlightColor),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              Text(
                "International Time",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleText),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_international) {
                            return;
                          }
                          setState(() {
                            _international = true;
                            Provider.of<UserProvider>(context, listen: false)
                                .setInternationalTime(_international);
                          });
                        },
                        child: Container(
                          height: SizeConstants.textBoxHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: (_international)
                                  ? Theme.of(context).cardColor
                                  : Colors.white,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15)),
                              border: Border.all(
                                  width: 1,
                                  color: (_international)
                                      ? Theme.of(context).highlightColor
                                      : Theme.of(context).dividerColor)),
                          child: Text(
                            "17:00",
                            style: (_international)
                                ? AppTextStyle.ptSansBold(
                                    color: Theme.of(context).highlightColor,
                                    size: 18)
                                : Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_international) {
                            return;
                          }
                          setState(() {
                            _international = false;
                            Provider.of<UserProvider>(context, listen: false)
                                .setInternationalTime(_international);
                          });
                        },
                        child: Container(
                          height: SizeConstants.textBoxHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: (!_international)
                                  ? Theme.of(context).cardColor
                                  : Colors.white,
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15)),
                              border: Border.all(
                                  width: 1,
                                  color: (!_international)
                                      ? Theme.of(context).highlightColor
                                      : Theme.of(context).dividerColor)),
                          child: Text(
                            "5:00 pm",
                            style: (!_international)
                                ? AppTextStyle.ptSansBold(
                                    color: Theme.of(context).highlightColor,
                                    size: 18)
                                : Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

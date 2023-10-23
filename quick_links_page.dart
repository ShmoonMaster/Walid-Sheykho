import 'package:flutter/material.dart';
import 'package:uninav/Databases/college_data.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/Home/quick_link_page_card.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class QuickLinksPage extends StatefulWidget {
  const QuickLinksPage({super.key});

  static const String routeName = "QuickLinksPage";

  @override
  State<QuickLinksPage> createState() => _QuickLinksPageState();
}

class _QuickLinksPageState extends State<QuickLinksPage> {
  // This function takes a url, and launches a browser of the given
  // page from the parameter.
  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> quickLinks = CollegeData.quickLinks.keys.toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const MyBackButton(),
              Text(
                AppLocalizations.of(context)!.quickLinks,
                style: AppTextStyle.ptSansBold(
                    color: const Color.fromARGB(255, 0, 0, 0), size: 30),
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(MarginConstants.extraSideMargin, 0, MarginConstants.extraSideMargin, 0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    scrollDirection: Axis.vertical,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 20,
                    children: List.generate(
                        quickLinks.length,
                        (index) => GestureDetector(
                              onTap: () {
                                _launchUrl(Uri.parse(CollegeData
                                    .quickLinks[quickLinks[index]]![1]));
                              },
                              child: QuickLinkPageCard(
                                name: quickLinks[index],
                                imageName: CollegeData
                                    .quickLinks[quickLinks[index]]![0],
                                primary: CollegeData
                                    .quickLinks[quickLinks[index]]![2],
                                card: CollegeData
                                    .quickLinks[quickLinks[index]]![3],
                                link: CollegeData
                                    .quickLinks[quickLinks[index]]![1],
                              ),
                            )),
                  ),
                ),
              )
            ])),
      ),
    );
  }
}

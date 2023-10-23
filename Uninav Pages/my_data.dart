import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Provider/additions_provider.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/alert_dialog.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyDataPage extends StatefulWidget {
  const MyDataPage({Key? key}) : super(key: key);

  static const String routeName = "MyDataPage";

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  void _clearAllUserData() {
    _clearEventsAndTasks();
    Provider.of<UserProvider>(context, listen: false).deleteUser();
  }

  void _clearEventsAndTasks() {
    Provider.of<EventsProvider>(context, listen: false).clearAllEvents();
    Provider.of<AdditionsProvider>(context, listen: false).clearAllAdditions();
  }

  void _clearTasks() {
    Provider.of<AdditionsProvider>(context, listen: false).clearAllAdditions();
  }

  void _clearFavorites() {
    Provider.of<UserProvider>(context, listen: false).clearFavorites();
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
                AppLocalizations.of(context)!.mydata,
                style: AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "Schedule Data",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleText,
              ),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: ElevatedButton(
                    onPressed: () {
                      var dialog = CustomAlertDialog(
                          title: "Clear Events and Tasks",
                          message: Text(
                              "Do you wish to delete all of your events and tasks from your local data?",
                              style: Theme.of(context).textTheme.bodyMedium),
                          onPostivePressed: () {
                            _clearEventsAndTasks();
                          },
                          onNegativePressed: null,
                          positiveBtnText: "Delete",
                          negativeBtnText: "Keep");
              
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => dialog);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, SizeConstants.textBoxHeight),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Theme.of(context).cardColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Clear Events and Tasks",
                          style: AppTextStyle.ptSansMedium(
                              size: 18, color: Theme.of(context).highlightColor),
                        ),
                        Icon(Icons.delete_rounded,
                            size: 25, color: Theme.of(context).colorScheme.error)
                      ],
                    )),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSubsection,
              ),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: ElevatedButton(
                    onPressed: () {
                      var dialog = CustomAlertDialog(
                          title: "Clear Tasks",
                          message: Text(
                              "Do you wish to delete all of your tasks?",
                              style: Theme.of(context).textTheme.bodyMedium),
                          onPostivePressed: () {
                            _clearTasks();
                          },
                          onNegativePressed: null,
                          positiveBtnText: "Delete",
                          negativeBtnText: "Keep");
              
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => dialog);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, SizeConstants.textBoxHeight),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Theme.of(context).cardColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Clear Tasks",
                          style: AppTextStyle.ptSansMedium(
                              size: 18, color: Theme.of(context).highlightColor),
                        ),
                        Icon(Icons.delete_rounded,
                            size: 25, color: Theme.of(context).colorScheme.error)
                      ],
                    )),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              Text(
                "Map Data",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleText,
              ),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: ElevatedButton(
                    onPressed: () {
                      var dialog = CustomAlertDialog(
                          title: "Clear Favorite Locations",
                          message: Text(
                              "Do you wish to delete all of your favorite locations?",
                              style: Theme.of(context).textTheme.bodyMedium),
                          onPostivePressed: () {
                            _clearFavorites();
                          },
                          onNegativePressed: null,
                          positiveBtnText: "Delete",
                          negativeBtnText: "Keep");
              
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => dialog);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, SizeConstants.textBoxHeight),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Theme.of(context).cardColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Clear Favorite Locations",
                          style: AppTextStyle.ptSansMedium(
                              size: 18, color: Theme.of(context).highlightColor),
                        ),
                        Icon(Icons.delete_rounded,
                            size: 25, color: Theme.of(context).colorScheme.error)
                      ],
                    )),
              ),
              const SizedBox(
                height: 45,
              ),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: ElevatedButton(
                    onPressed: () {
                      var dialog = CustomAlertDialog(
                          title: "Delete User",
                          message: Text("Do you wish to delete all of your data?",
                              style: Theme.of(context).textTheme.bodyMedium),
                          onPostivePressed: () {
                            _clearAllUserData();
                          },
                          onNegativePressed: null,
                          positiveBtnText: "Delete",
                          negativeBtnText: "Keep");
              
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => dialog);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, SizeConstants.textBoxHeight),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer),
                    child: Text(
                      "Clear All Data and Sign Out",
                      style: AppTextStyle.ptSansBold(
                          size: 18, color: Theme.of(context).colorScheme.error),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

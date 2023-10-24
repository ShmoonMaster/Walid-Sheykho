import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/Event/select_date_container.dart';
import 'package:uninav/Widgets/Settings/settings_option_widget.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  static const String routeName = "AccountPage";

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static final DateTime _now = DateTime.now();

  final inputDateFormat = DateFormat('MM/dd/yyyy');
  final FirebaseAuth auth = FirebaseAuth.instance;

  String _curName = "";
  DateTime _startDate = DateTime(_now.year, _now.month, _now.day);
  DateTime _endDate = DateTime(_now.year, _now.month, _now.day);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _curName =
        Provider.of<UserProvider>(context, listen: false).getUserData?.name ??
            "";
    _startDate = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.startDate ??
        _startDate;
    _endDate = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.endDate ??
        _endDate;
  }

  // This function takes a bool for isStart and show the time selection subview
  // and it can either be for the start time or end time based on the given parameter.
  void _startSelectDate(BuildContext context, bool isStartDate) async {
    DateTime temp = (isStartDate) ? _startDate : _endDate;
    dtp.DatePicker.showDatePicker(context,
        showTitleActions: true, currentTime: temp, onConfirm: (newDate) {
      setState(() {
        newDate = DateTime(newDate.year, newDate.month, newDate.day);
        DateTime first = _startDate;
        DateTime second = _endDate;
        if (isStartDate) {
          first = newDate;
        } else {
          second = newDate;
        }

        _startDate = first;
        _endDate = second;
        Provider.of<UserProvider>(context, listen: false)
            .setStudyDates(_startDate, _endDate);
      });
    },
        theme: dtp.DatePickerTheme(
          backgroundColor: Colors.white,
          headerColor: Colors.white,
          cancelStyle:
              AppTextStyle.ptSansRegular(color: Colors.black54, size: 18.0),
          doneStyle: AppTextStyle.ptSansBold(
              color: Theme.of(context).colorScheme.primary, size: 18.0),
          itemStyle: AppTextStyle.ptSansRegular(color: Colors.grey, size: 18.0),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                AppLocalizations.of(context)!.account,
                style: AppTextStyle.ptSansBold(color: Colors.black, size: 30),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Text(
                "Name",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              Container(
                padding: const EdgeInsets.all(MarginConstants.sideMargin),
                height: SizeConstants.textBoxHeight,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1),
                    borderRadius: BorderRadius.circular(15)),
                child: TextFormField(
                  initialValue:
                      Provider.of<UserProvider>(context).getUserData?.name,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    isCollapsed: true,
                    hintText: "Shmoon Master",
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).hintColor),
                    errorStyle: const TextStyle(
                        color: Colors.transparent, fontSize: 0, height: 0),
                    errorMaxLines: 1,
                    errorText: null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  onFieldSubmitted: ((value) {
                    _curName = value;
                    if (_curName !=
                        Provider.of<UserProvider>(context, listen: false)
                            .getUserData
                            ?.name) {
                      Provider.of<UserProvider>(context, listen: false)
                          .updateUserName(_curName);
                    }
                  }),
                ),
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              Text(
                "University",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleText,
              ),
              Container(
                  padding: const EdgeInsets.all(15),
                  height: SizeConstants.textBoxHeight,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text(
                        Provider.of<UserProvider>(context, listen: false)
                            .getUserEmail,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.green, size: 25)
                    ],
                  )),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSubsection,
              ),
              SettingsOptions(
                operations: [
                  Provider.of<UserProvider>(context, listen: false)
                          .getUserData
                          ?.university ??
                      "",
                ],
                call: (page) {
                  //TODO: make a university update option
                },
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Start-End Dates",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    TimeHelper.formattedTimeBetweenTwoDates(
                        _startDate, _endDate),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
              ),
              SelectDateContainer(
                  selectDate: (isStartDate) {
                    _startSelectDate(context, isStartDate);
                  },
                  startDate: _startDate,
                  endDate: _endDate,
                  endDateIsActive: true),
              const SizedBox(
                height: MarginConstants.formHeightBetweenSection,
              ),
              SizedBox(
                height: SizeConstants.textBoxHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<UserProvider>(context, listen: false).signOut();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    splashFactory: NoSplash.splashFactory,
                    backgroundColor: Theme.of(context).highlightColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(double.infinity, double.infinity),
                  ),
                  child: Text("Log Out",
                      style: AppTextStyle.ptSansBold(size: 18, color: null)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

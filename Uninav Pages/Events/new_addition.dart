import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uninav/Databases/college_data.dart';
import 'package:uninav/Models/event_addition_model.dart';
import 'package:uninav/Provider/additions_provider.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/Event/repeat_chip.dart';
import 'package:uninav/Widgets/Event/select_date_container.dart';
import 'package:uninav/Widgets/Event/type_chip.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'package:uninav/Widgets/alert_dialog.dart';

class AdditionFormPageArguments {
  final int? eventId;
  final EventAddition? addition;
  const AdditionFormPageArguments({this.eventId, this.addition});
}

// This is the addition creation form where the user can create new additions.
class AdditionForm extends StatefulWidget {
  final AdditionFormPageArguments? data;
  const AdditionForm({Key? key, required this.data}) : super(key: key);

  static const String routeName = "AdditionFormPage";

  @override
  State<AdditionForm> createState() => _AdditionFormState();
}

class _AdditionFormState extends State<AdditionForm>
    with SingleTickerProviderStateMixin {
  static const double _typeChipHeight = 40;

  late final AdditionFormPageArguments _data;

  final _inputDateFormat = DateFormat('MM/dd/yyyy');
  final ScrollController _scrollController = ScrollController();

  late EventAddition _currentAddition;
  late DateTime _currentEndDate;

  bool _isInit = true;
  List<Event> _activeEvents = [];
  RepeatTypeEnum _repeatType = RepeatTypeEnum.once;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      _data = widget.data!;
    }

    if (_data.addition != null) {
      _currentAddition = EventAddition(
          id: _data.addition!.id,
          eventID: _data.addition!.eventID,
          name: _data.addition!.name,
          type: _data.addition!.type,
          date: _data.addition!.date,
          priorityTags: [],
          locationTags: [],
          finished: _data.addition!.finished);
    } else {
      _currentAddition = EventAddition(
          id: -1,
          eventID: -1,
          name: "",
          type: EventAdditionType.assignment,
          date: DateTime.now(),
          priorityTags: [],
          locationTags: [],
          finished: false);
    }

    if (_data.eventId != null) {
      _currentAddition.eventID = _data.eventId!;
    }

    _currentEndDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _activeEvents = Provider.of<EventsProvider>(context, listen: false)
          .getAllEvents
          .where((event) => _data.eventId == null || event.id == _data.eventId)
          .toList();
      _activeEvents.sort();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  // This function sends the addition to the database and closes the page
  void _addOneAddition() {
    if (_data.addition != null) {
      Provider.of<AdditionsProvider>(context, listen: false)
          .editAddition(_currentAddition);
    } else {
      Provider.of<AdditionsProvider>(context, listen: false)
          .addAddition(_currentAddition);
    }
    context.pop();
  }

  // This function adds multiple additions at a time based on the
  // repeat type of the addition.
  void _addMultipleAdditions() {
    int interval = (_repeatType == RepeatTypeEnum.weekly) ? 7 : 14;
    DateTime startDate = DateTime(_currentAddition.date.year,
        _currentAddition.date.month, _currentAddition.date.day);
    while (!startDate.isAfter(_currentEndDate)) {
      EventAddition nextAddition = EventAddition(
          id: -1,
          eventID: _currentAddition.eventID,
          name: _currentAddition.name,
          type: _currentAddition.type,
          date: DateTime(startDate.year, startDate.month, startDate.day,
              _currentAddition.date.hour, _currentAddition.date.minute),
          priorityTags: _currentAddition.priorityTags.toList(),
          locationTags: _currentAddition.locationTags.toList(),
          finished: _currentAddition.finished);

      Provider.of<AdditionsProvider>(context, listen: false)
          .addAddition(nextAddition);

      startDate =
          DateTime(startDate.year, startDate.month, startDate.day + interval);
    }
    context.pop();
  }

  // This function shows the select time subview for the user to choose a time for the addition.
  void _startSelectTime(bool international) async {
    DateTime tempTime = _currentAddition.date;
    dtp.DatePickerTheme theme = dtp.DatePickerTheme(
      backgroundColor: Colors.white,
      headerColor: Colors.white,
      cancelStyle:
          AppTextStyle.ptSansRegular(color: Colors.black54, size: 18.0),
      doneStyle: AppTextStyle.ptSansBold(
          color: Theme.of(context).colorScheme.secondary, size: 18.0),
      itemStyle: AppTextStyle.ptSansRegular(color: Colors.grey, size: 18.0),
    );
    if (international) {
      dtp.DatePicker.showTimePicker(
        context,
        currentTime: tempTime,
        showTitleActions: true,
        theme: theme,
        onConfirm: (newTime) {
          setState(() {
            _currentAddition.date = newTime;
          });
        },
      );
    } else {
      dtp.DatePicker.showTime12hPicker(
        context,
        currentTime: tempTime,
        showTitleActions: true,
        theme: theme,
        onConfirm: (newTime) {
          setState(() {
            _currentAddition.date = newTime;
          });
        },
      );
    }
  }

  // This function shows the select date subview for the user to choose a date for the addition.
  void _startSelectDate(bool isStart) async {
    DateTime temp = isStart ? _currentAddition.date : _currentEndDate;
    dtp.DatePicker.showDatePicker(context,
        showTitleActions: true, currentTime: temp, onConfirm: (newDate) {
      setState(() {
        if (isStart) {
          _currentAddition.date = DateTime(
              newDate.year, newDate.month, newDate.day, temp.hour, temp.minute);
        } else {
          _currentEndDate = DateTime(
              newDate.year, newDate.month, newDate.day, temp.hour, temp.minute);
        }
      });
    },
        theme: dtp.DatePickerTheme(
          backgroundColor: Colors.white,
          headerColor: Colors.white,
          cancelStyle:
              AppTextStyle.ptSansRegular(color: Colors.black54, size: 18.0),
          doneStyle: AppTextStyle.ptSansBold(
              color: Theme.of(context).colorScheme.secondary, size: 18.0),
          itemStyle: AppTextStyle.ptSansRegular(color: Colors.grey, size: 18.0),
        ));
  }

  // This function takes an event addition type and updates the view based on that update.
  void _updateType(EventAdditionType type) {
    setState(() {
      _currentAddition.type = type;
    });
  }

  // This function takes a RepeatTypeEnum and updates the repeat type of the event
  void _updateRepeat(RepeatTypeEnum type) {
    if (_repeatType.name == type.name) {
      return;
    }
    setState(() {
      _repeatType = type;
    });
  }

  // This function shows a dialog with the given error text
  void _warnDialog(String title, String error) async {
    var dialog = CustomAlertDialog(
        title: title,
        message: Text(error, style: Theme.of(context).textTheme.bodyMedium),
        onPostivePressed: () {},
        onNegativePressed: null,
        positiveBtnText: "Alright",
        negativeBtnText: null);
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  // This funtion verifies that all of the data is correct before it can be saved.
  void verify() async {
    if (_currentAddition.name.isEmpty) {
      _warnDialog("My Name!", "Please input a name for this task.");
      return;
    }

    if (_currentAddition.eventID < 0) {
      _warnDialog("My Event!", "Please select an event for this task.");
      return;
    }

    if (_repeatType != RepeatTypeEnum.once &&
        DateTime(_currentAddition.date.day).isAfter(_currentEndDate)) {
      _warnDialog(
          "Bad Dates!", "Please select a start date before the end date.");
      return;
    }

    if (_repeatType == RepeatTypeEnum.once) {
      _addOneAddition();
    } else {
      _addMultipleAdditions();
    }
  }

  // This function builds the string for the text based on the number of additions
  // that will be saved and the window of dates for the additions.
  String _buildAdditionInfoString() {
    String weekday = DateFormat('EEEE').format(_currentAddition.date);
    if (_repeatType == RepeatTypeEnum.once) {
      return "Task: 1 ${_currentAddition.type.name} on $weekday";
    }

    DateTime checkStartDate = DateTime(_currentAddition.date.year,
        _currentAddition.date.month, _currentAddition.date.day);

    if (checkStartDate.isAfter(_currentEndDate)) {
      return "Invalid Date Range";
    }

    int count = 0;
    int interval = (_repeatType == RepeatTypeEnum.weekly) ? 7 : 14;
    while (!checkStartDate.isAfter(_currentEndDate)) {
      count += 1;
      checkStartDate = DateTime(checkStartDate.year, checkStartDate.month,
          checkStartDate.day + interval);
    }

    if (count < 2) {
      return "Task: $count ${_currentAddition.type.name} on $weekday";
    }

    return "Task: $count ${_currentAddition.type.name}s on $weekday";
  }

  // This function builds a column where all the events for the addition
  // can be saved to.
  Column get _buildTypeWraps {
    List<Event> topTypes = [];
    int topLength = 0;
    List<Event> bottomTypes = [];
    int bottomLength = 0;

    DateTime now =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    _activeEvents =
        _activeEvents.sorted((a, b) => b.dates.end.compareTo(a.dates.end));

    for (Event x in _activeEvents) {
      if (bottomLength >= topLength) {
        topTypes.add(x);
        topLength += x.name.length;
      } else {
        bottomTypes.add(x);
        bottomLength += x.name.length;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: _typeChipHeight,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List<Widget>.generate(topTypes.length, (index) {
              bool isSelected = topTypes[index].id == _currentAddition.eventID;
              bool isActive = topTypes[index].dates.start.isBefore(now) &&
                  topTypes[index].dates.end.isAfter(now);
              TextStyle textStyle = (isSelected)
                  ? AppTextStyle.ptSansBold(
                      color: Theme.of(context).colorScheme.secondary,
                      size: 18.0)
                  : AppTextStyle.ptSansRegular(
                      color: Theme.of(context).hintColor, size: 18.0);

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _currentAddition.eventID = topTypes[index].id;
                      });
                    }
                  },
                  child: Chip(
                    avatar: (isActive)
                        ? Icon(Icons.trip_origin_rounded,
                            color: (isSelected)
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).hintColor,
                            size: 20)
                        : null,
                    backgroundColor: (isSelected)
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).dividerColor.withOpacity(.4),
                    labelStyle: textStyle,
                    labelPadding: EdgeInsets.zero,
                    padding: EdgeInsets.fromLTRB(
                        (isActive) ? 0 : MarginConstants.chipHInternalPadding,
                        0,
                        MarginConstants.chipHInternalPadding,
                        0),
                    label: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topTypes[index].name),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(
          height: (_activeEvents.length > 1) ? _typeChipHeight : 0,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: List<Widget>.generate(bottomTypes.length, (index) {
              bool isSelected =
                  bottomTypes[index].id == _currentAddition.eventID;
              bool isActive = bottomTypes[index].dates.start.isBefore(now) &&
                  bottomTypes[index].dates.end.isAfter(now);
              TextStyle textStyle = (isSelected)
                  ? AppTextStyle.ptSansBold(
                      color: Theme.of(context).colorScheme.secondary,
                      size: 18.0)
                  : AppTextStyle.ptSansRegular(
                      color: Theme.of(context).hintColor, size: 18.0);

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _currentAddition.eventID = bottomTypes[index].id;
                      });
                    }
                  },
                  child: Chip(
                    avatar: (isActive)
                        ? Icon(Icons.trip_origin_rounded,
                            color: (isSelected)
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).hintColor,
                            size: 20)
                        : null,
                    backgroundColor: (isSelected)
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).dividerColor.withOpacity(.4),
                    labelStyle: textStyle,
                    labelPadding: EdgeInsets.zero,
                    padding: EdgeInsets.fromLTRB(
                        (isActive) ? 0 : MarginConstants.chipHInternalPadding,
                        5,
                        MarginConstants.chipHInternalPadding,
                        5),
                    label: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bottomTypes[index].name),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        )
      ],
    );
  }

  // This function builds the types for the addition and returns a
  // listview for the user to select from.
  ListView _buildTypes() {
    List<EventAdditionType> additionTypes = EventAdditionType.values;
    List<TypeChip> types = List.generate(
        additionTypes.length,
        (i) => TypeChip(
            active: _currentAddition.type == additionTypes[i],
            event: false,
            icon: CollegeData.additionTypeIcons[i],
            name: CollegeData.additionTypes[i],
            type: additionTypes[i],
            update: _updateType));

    return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
        itemCount: types.length,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
              width: MarginConstants.bigChipMargin,
            ),
        itemBuilder: (context, index) {
          return types[index];
        });
  }

  // This function builds the repeat for the event and
  // returns a listview for the user to select from.
  ListView _buildRepeatTypes() {
    bool isEditing = _data.addition != null;
    List<RepeatTypeEnum> repeatTypes = RepeatTypeEnum.values;
    List<RepeatChip> types = List.generate(
        (isEditing) ? 1 : repeatTypes.length,
        (i) => RepeatChip(
            active: _repeatType == repeatTypes[i],
            event: false,
            name: CollegeData.repeatTypes[i],
            type: repeatTypes[i],
            update: _updateRepeat));

    return ListView.separated(
        itemCount: types.length,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
              width: MarginConstants.littleChipMargin,
            ),
        itemBuilder: (context, index) {
          return types[index];
        });
  }

  // This function builds the form for event addition where the user can input data. It only
  // requires the build context.
  SingleChildScrollView _buildForm(BuildContext context) {
    bool international = Provider.of<UserProvider>(context, listen: false)
        .getInternationTimingPreference;
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: MarginConstants.sideMargin),
            child: Text(
              "Task Type",
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(
            height: MarginConstants.formHeightBetweenTitleSection,
          ),
          SizedBox(
            height: 50,
            child: _buildTypes(),
          ),
          const SizedBox(
            height: MarginConstants.formHeightBetweenSubsection,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            child: Text(
              "Event",
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).hintColor, fontSize: 17),
            ),
          ),
          const SizedBox(
            height: MarginConstants.formHeightBetweenTitleSection,
          ),
          SizedBox(
            height: MarginConstants.formHeightBetweenTitleSection +
                ((_activeEvents.length > 1)
                    ? _typeChipHeight * 2
                    : _typeChipHeight),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTypeWraps,
            ),
          ),
          const SizedBox(height: MarginConstants.formHeightBetweenSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Name", style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleText,
                ),
                Container(
                  height: SizeConstants.textBoxHeight,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).dividerColor, width: 1),
                      borderRadius: BorderRadius.circular(15)),
                  child: TextFormField(
                    initialValue: _currentAddition.name,
                    cursorColor: Colors.black,
                    maxLength: 30,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      counterText: "",
                      isCollapsed: false,
                      hintText: "Ex. Chem 142",
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
                    onChanged: (value) {
                      _currentAddition.name = value;
                    },
                  ),
                ),
                const SizedBox(
                    height: MarginConstants.formHeightBetweenSection),
                Text("Date and Time",
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleSection,
                ),
                SizedBox(
                  height: _typeChipHeight,
                  child: _buildRepeatTypes(),
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleSection,
                ),
                SelectDateContainer(
                    selectDate: _startSelectDate,
                    startDate: _currentAddition.date,
                    endDate: (_repeatType != RepeatTypeEnum.once)
                        ? _currentEndDate
                        : _currentAddition.date,
                    endDateIsActive: _repeatType != RepeatTypeEnum.once),
                    const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleSection,
                ),
                GestureDetector(
                  onTap: () {
                    _startSelectTime(international);
                  },
                  child: Container(
                    height: SizeConstants.textBoxHeight,
                    padding: const EdgeInsets.fromLTRB(
                        MarginConstants.sideMargin,
                        0,
                        MarginConstants.sideMargin,
                        0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: Theme.of(context).dividerColor, width: 1),
                        borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Theme.of(context).highlightColor,
                          size: 25,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          TimeHelper.timeToString(
                              TimeOfDay(
                                  hour: _currentAddition.date.hour,
                                  minute: _currentAddition.date.minute),
                              international),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    _buildAdditionInfoString(),
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(
                    height: MarginConstants.formHeightBetweenSection),
                SizedBox(
                  height: SizeConstants.textBoxHeight,
                  child: ElevatedButton(
                    onPressed: () async {
                      verify();
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize:
                            const Size(double.infinity, double.infinity)),
                    child: Text(
                      "${(_data.addition == null) ? 'Create' : 'Edit'} Task",
                      style: AppTextStyle.ptSansBold(
                          color: Colors.white, size: 18.0),
                    ),
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        MarginConstants.formHeightBetweenSection),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                MarginConstants.sideMargin,
                MediaQuery.of(context).padding.top + MarginConstants.sideMargin,
                MarginConstants.sideMargin,
                MarginConstants.sideMargin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {
                      context.pop();
                    },
                    splashColor: Colors.white,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 30,
                      color: Colors.grey[400],
                    )),
                RichText(
                    text: TextSpan(children: <TextSpan>[
                  TextSpan(
                      text: (_data.addition == null) ? "Create " : "Edit ",
                      style: AppTextStyle.ptSansBold(
                          size: 30.0, color: Colors.black)),
                  TextSpan(
                      text: "Task",
                      style: AppTextStyle.ptSansRegular(
                          size: 30.0, color: Colors.black)),
                ])),
                const SizedBox(
                  width: MarginConstants.formHeightBetweenSection,
                )
              ],
            ),
          ),
          Flexible(child: Form(child: _buildForm(context))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uninav/Databases/college_data.dart';
import 'package:uninav/Models/event_theme_info.dart';
import 'package:uninav/Provider/additions_provider.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Event/select_location.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/app_themes.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/schedule_timing_helper.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/Event/event_overlap_container.dart';
import 'package:uninav/Widgets/Event/repeat_chip.dart';
import 'package:uninav/Widgets/Event/select_date_container.dart';
import 'package:uninav/Widgets/Event/type_chip.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'package:uninav/Widgets/alert_dialog.dart';
import 'package:uninav/Widgets/Event/color_selection_widget.dart';
import 'package:uninav/Widgets/transitions.dart';

class EventFormPageArguments {
  final Event? initialCourse;
  const EventFormPageArguments({this.initialCourse});
}

// This class is the form to edit or create new events for the user to save and display.
class EventFormPage extends StatefulWidget {
  final EventFormPageArguments? data;
  const EventFormPage({Key? key, required this.data}) : super(key: key);

  static const String routeName = "EventFormPage";

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage>
    with SingleTickerProviderStateMixin {
  static const double _typeChipHeight = 40;

  late final EventFormPageArguments _data;
  late final ScrollController _scrollController;
  late final Event _currentEvent;
  late final List<EventThemeInfo> _colors;

  final DateFormat _inputDateFormat = DateFormat('MM/dd/yyyy');

  late bool _international;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      _data = widget.data!;
    }

    if (_data.initialCourse != null) {
      _currentEvent = _data.initialCourse!.copy();
    } else {
      DateTimeRange preferedRange = DateTimeRange(
          start: Provider.of<UserProvider>(context, listen: false)
                  .getUserData
                  ?.startDate ??
              TimeHelper.getNow(),
          end: Provider.of<UserProvider>(context, listen: false)
                  .getUserData
                  ?.endDate ??
              TimeHelper.getNow());
      _currentEvent = Event.empty(dates: preferedRange);
    }

    _international = Provider.of<UserProvider>(context, listen: false)
        .getInternationTimingPreference;
    _colors = AppThemes.eventColors.values.toList().sublist(0, 23);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // This function takes a string of the locaiton name and a LatLng object as the
  // location coordinates and saves them to the current course. If the given location
  // is empty, then it will not save.
  void setLocation(String location, LatLng coordinates) {
    if (location.isNotEmpty) {
      _currentEvent.location = location;
      _currentEvent.locationCoordinate = coordinates;
    }
  }

  // This function saves the event to the database and the cache and pops this
  // page from the stack.
  void _addEvent() {
    if (_currentEvent.repeatType == RepeatTypeEnum.once) {
      _currentEvent.dates = DateTimeRange(
          start: _currentEvent.dates.start,
          end: _currentEvent.dates.start.endOfDay);
    }
    if (_data.initialCourse != null) {
      Provider.of<EventsProvider>(context, listen: false)
          .editEvent(_currentEvent);
    } else {
      Provider.of<EventsProvider>(context, listen: false)
          .addEvent(_currentEvent);
    }
    context.pop();
  }

  // This function takes a bool for isStart and show the time selection subview
  // and it can either be for the start time or end time based on the given parameter.
  void _startSelectTime(bool isStart) async {
    TimeOfDay temp =
        (isStart) ? _currentEvent.startTime : _currentEvent.endTime;
    DateTime now = TimeHelper.getNow();
    DateTime tempTime =
        DateTime(now.year, now.month, now.day, temp.hour, temp.minute);

    onConfirm(newTime) {
      setState(() {
        temp = TimeOfDay(hour: newTime.hour, minute: newTime.minute);
        (isStart)
            ? _currentEvent.startTime = temp
            : _currentEvent.endTime = temp;
      });
    }

    dtp.DatePickerTheme theme = dtp.DatePickerTheme(
      backgroundColor: Colors.white,
      headerColor: Colors.white,
      cancelStyle:
          AppTextStyle.ptSansRegular(color: Colors.black54, size: 18.0),
      doneStyle: AppTextStyle.ptSansBold(
          color: Theme.of(context).colorScheme.primary, size: 18.0),
      itemStyle: AppTextStyle.ptSansRegular(color: Colors.grey, size: 18.0),
    );
    if (_international) {
      dtp.DatePicker.showTimePicker(context,
          currentTime: tempTime,
          showTitleActions: true,
          theme: theme,
          onConfirm: onConfirm);
    } else {
      dtp.DatePicker.showTime12hPicker(context,
          currentTime: tempTime,
          showTitleActions: true,
          theme: theme,
          onConfirm: onConfirm);
    }
  }

  // This function takes a bool for isStartDate and show the date selection subview
  // and it can either be for the start date or end date based on the given parameter.
  void _startSelectDate(bool isStartDate) async {
    DateTime temp =
        (isStartDate) ? _currentEvent.dates.start : _currentEvent.dates.end;
    dtp.DatePicker.showDatePicker(context,
        showTitleActions: true, currentTime: temp, onConfirm: (newDate) {
      setState(() {
        newDate = DateTime(newDate.year, newDate.month, newDate.day);
        DateTime first = _currentEvent.dates.start;
        DateTime second = _currentEvent.dates.end;
        if (isStartDate) {
          first = newDate;
        } else {
          second = newDate;
        }

        if (first.isAfter(second)) {
          if (isStartDate) {
            second = first;
          } else {
            first = second;
          }
        }
        _currentEvent.dates = DateTimeRange(start: first, end: second.endOfDay);
        if (_currentEvent.repeatType == RepeatTypeEnum.once) {
          _currentEvent.days = [newDate.weekday - 1];
        }
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

  // Shows an error dialog with the given errors. If it passes in an event,
  // then it given an option for event to be deleted.
  void _warnDialog(String title, String error, Event? event) async {
    final CustomAlertDialog deleteDialog = CustomAlertDialog(
        title: "Delete Other Event",
        message: Text("Are you sure you want to delete ${event?.name}?",
            style: Theme.of(context).textTheme.bodyMedium),
        onPostivePressed: () {
          if (event != null) {
            Provider.of<EventsProvider>(context, listen: false)
                .deleteEvent(event.id);
            Provider.of<AdditionsProvider>(context, listen: false)
                .deleteAdditionsForEvent(event.id);
          }
        },
        onNegativePressed: null,
        positiveBtnText: "Yes",
        negativeBtnText: "No");
    final CustomAlertDialog dialog = CustomAlertDialog(
        title: title,
        message: (event == null)
            ? Text(error, style: Theme.of(context).textTheme.bodyMedium)
            : EventOverlapErrorContainer(
                oldEvent: event,
                currentEvent: _currentEvent,
              ),
        onPostivePressed: () {},
        onNegativePressed: () {
          if (event != null) {
            showDialog(
                context: context,
                builder: (BuildContext context) => deleteDialog);
          }
        },
        positiveBtnText: "Alright",
        negativeBtnText: (event != null) ? "Delete Other Event" : null);
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  // This function takes a FormalTypeEnum and updates the formal type of the event
  void _updateType(FormalTypeEnum type) {
    if (_currentEvent.formalType.name == type.name) {
      return;
    }
    setState(() {
      _currentEvent.formalType = type;
      _currentEvent.type = "";
    });
  }

  // This function takes a RepeatTypeEnum and updates the repeat type of the event
  void _updateRepeat(RepeatTypeEnum type) {
    if (_currentEvent.repeatType.name == type.name) {
      return;
    }
    setState(() {
      _currentEvent.repeatType = type;
      if (type == RepeatTypeEnum.once) {
        _currentEvent.days = [_currentEvent.dates.start.weekday - 1];
      }
    });
  }

  // This function verifies the data is valid before sending it to the database;
  void verify() async {
    if (_currentEvent.type.isEmpty) {
      _warnDialog("Type", "Please select a type for the event.", null);
      return;
    }

    if (_currentEvent.name.isEmpty) {
      _warnDialog("Name", "Please input a name for this event.", null);
      return;
    }

    if (_currentEvent.location.isEmpty ||
        (_currentEvent.locationCoordinate == null &&
            _currentEvent.eventLink == null)) {
      _warnDialog("Where", "Please pick a location for this event.", null);
      return;
    }

    if (_currentEvent.dates.end.isBefore(_currentEvent.dates.start)) {
      _warnDialog(
          "Dates", "Your start date must be after your end date.", null);
      return;
    }

    int numMin = (_currentEvent.endTime.hour * 60 +
            _currentEvent.endTime.minute) -
        (_currentEvent.startTime.hour * 60 + _currentEvent.startTime.minute);

    if (numMin <= 0) {
      _warnDialog("Times",
          "Start time must be at least 1 minute before end time.", null);
      return;
    }

    if (numMin < 15) {
      _warnDialog(
          "Too Short", "Your event must be at least 15 minutes long.", null);
      return;
    }

    if (_currentEvent.days.isEmpty) {
      _warnDialog(
          "Days!", "Please pick the days of the week for your event.", null);
      return;
    }

    List overlap = ScheduleTimingHelper.checkEventOverlap(
        _currentEvent.startTime,
        _currentEvent.endTime,
        DateTimeRange(
            start: _currentEvent.dates.start,
            end: (_currentEvent.repeatType == RepeatTypeEnum.once)
                ? _currentEvent.dates.start
                : _currentEvent.dates.end),
        _currentEvent.repeatType,
        _currentEvent.days,
        _currentEvent.id,
        Provider.of<EventsProvider>(context, listen: false).getAllEvents);

    if (overlap[0]) {
      _warnDialog("Uh Oh!", "", overlap[1]);
      return;
    }

    _addEvent();
  }

  // This function builds the types for the event and returns a
  // listview for the user to select from.
  ListView _buildTypes() {
    List<FormalTypeEnum> typeEnums = FormalTypeEnum.values;

    List<TypeChip> types = List.generate(
        typeEnums.length,
        (i) => TypeChip(
            active: _currentEvent.formalType == typeEnums[i],
            event: true,
            icon: CollegeData.eventTypeIcons[i],
            name: CollegeData.eventTypes[i],
            type: typeEnums[i],
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

  // This function builds the repeat for the event and returns a
  // listview for the user to select from.
  ListView _buildRepeatTypes() {
    List<RepeatTypeEnum> repeatTypes = RepeatTypeEnum.values;
    List<RepeatChip> types = List.generate(
        repeatTypes.length,
        (i) => RepeatChip(
            active: _currentEvent.repeatType == repeatTypes[i],
            event: true,
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

  // This function builds a column where all of the types for the event
  // can be selected from.
  Column _buildTypeWraps() {
    List<String> types = [];
    switch (_currentEvent.formalType) {
      case FormalTypeEnum.course:
        types = CollegeData.courseTypes;
        break;
      case FormalTypeEnum.activity:
        types = CollegeData.activityTypes;
        break;
      case FormalTypeEnum.job:
        types = CollegeData.jobTypes;
        break;
      default:
    }

    List<String> topTypes = [];
    int topLength = 0;
    List<String> bottomTypes = [];
    int bottomLength = 0;

    for (String x in types) {
      if (bottomLength >= topLength) {
        topTypes.add(x);
        topLength += x.length;
      } else {
        bottomTypes.add(x);
        bottomLength += x.length;
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
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _currentEvent.type = topTypes[index];
                      });
                    }
                  },
                  child: Chip(
                    backgroundColor: (topTypes[index] == _currentEvent.type)
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).dividerColor.withOpacity(.4),
                    labelStyle: (topTypes[index] == _currentEvent.type)
                        ? AppTextStyle.ptSansBold(
                            color: Theme.of(context).colorScheme.primary,
                            size: 18.0)
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                    padding: const EdgeInsets.fromLTRB(
                        MarginConstants.chipHInternalPadding,
                        0,
                        MarginConstants.chipHInternalPadding,
                        0),
                    label: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topTypes[index]),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(
          height: _typeChipHeight,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: List<Widget>.generate(bottomTypes.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _currentEvent.type = bottomTypes[index];
                      });
                    }
                  },
                  child: Chip(
                    backgroundColor: (bottomTypes[index] == _currentEvent.type)
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).dividerColor.withOpacity(.4),
                    labelStyle: (bottomTypes[index] == _currentEvent.type)
                        ? AppTextStyle.ptSansBold(
                            color: Theme.of(context).colorScheme.primary,
                            size: 18.0)
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                    padding: const EdgeInsets.fromLTRB(
                        MarginConstants.chipHInternalPadding,
                        0,
                        MarginConstants.chipHInternalPadding,
                        0),
                    label: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(bottomTypes[index]),
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

  // This function takes a string as a day and an index for the day,
  // and builds a gesture detector for the user to select that day.
  GestureDetector _buildDayCard(String day, int index) {
    return GestureDetector(
      onTap: () {
        if (_currentEvent.repeatType != RepeatTypeEnum.once) {
          setState(() {
            if (_currentEvent.days.contains(index)) {
              _currentEvent.days.remove(index);
            } else {
              _currentEvent.days.add(index);
            }
          });
        }
      },
      child: Container(
        height: 50,
        width: 40,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: !(_currentEvent.days.contains(index))
                ? (_currentEvent.repeatType != RepeatTypeEnum.once)
                    ? Colors.transparent
                    : Theme.of(context).dividerColor
                : Theme.of(context).colorScheme.primaryContainer,
            border: Border.all(
                color: (_currentEvent.days.contains(index) ||
                        _currentEvent.repeatType == RepeatTypeEnum.once)
                    ? Colors.transparent
                    : Theme.of(context).dividerColor,
                width: 1)),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            day,
            softWrap: false,
            style: !(_currentEvent.days.contains(index))
                ? AppTextStyle.ptSansRegular(
                    color: Theme.of(context).hintColor,
                    size: 16.0,
                  )
                : AppTextStyle.ptSansBold(
                    color: Theme.of(context).colorScheme.primary,
                    size: 17.0,
                  ),
          ),
        ),
      ),
    );
  }

  // This function builds the form for event where the user can input data. It only
  // requires the build context.
  SingleChildScrollView _buildForm(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              "Event Type",
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
              "Type",
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
                2 * _typeChipHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTypeWraps(),
            ),
          ),
          const SizedBox(
            height: MarginConstants.formHeightBetweenSubsection,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            child: Text(
              "Theme",
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).hintColor, fontSize: 17),
            ),
          ),
          const SizedBox(
            height: MarginConstants.formHeightBetweenTitleSection,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: ((context, index) => GestureDetector(
                        onTap: () => setState(() {
                          if (_currentEvent.themeIndex == index) {
                            _currentEvent.themeIndex = null;
                          } else {
                            _currentEvent.themeIndex = index;
                          }
                        }),
                        child: ColorSelectionWidget(
                            color: _colors[index].primary,
                            active: _currentEvent.themeIndex != null &&
                                _currentEvent.themeIndex == index),
                      )),
                  separatorBuilder: ((context, index) => const SizedBox(
                        width: 10,
                      )),
                  itemCount: _colors.length),
            ),
          ),
          const SizedBox(
            height: MarginConstants.formHeightBetweenSection,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 9,
                      child: Text(
                        "Name",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        "Room",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleText,
                ),
                Container(
                  padding: const EdgeInsets.only(left: 5),
                  height: SizeConstants.textBoxHeight,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).dividerColor, width: 1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 9,
                        child: TextFormField(
                          initialValue: _currentEvent.name,
                          cursorColor: Colors.black,
                          maxLength: 30,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            isCollapsed: false,
                            counterText: "",
                            hintText: "CHEM 142",
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).hintColor),
                            errorStyle: const TextStyle(
                                color: Colors.transparent,
                                fontSize: 0,
                                height: 0),
                            errorMaxLines: 1,
                            errorText: null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          onChanged: (value) {
                            _currentEvent.name = value;
                          },
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: VerticalDivider(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                          thickness: 1,
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          initialValue: _currentEvent.room,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            isDense: false,
                            filled: false,
                            isCollapsed: false,
                            hintText: "BAG 142",
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                          onChanged: (value) {
                            _currentEvent.room = value;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                    height: MarginConstants.formHeightBetweenSection),
                Text("Location", style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleText,
                ),
                GestureDetector(
                  onTap: () {
                    if (!mounted) {
                      return;
                    }
                    Navigator.push(
                        context,
                        Transitions.createRightSlideRoute(SelectLocation(
                          key: const Key("SelectLocation"),
                          data: SelectLocationArguments(
                              isOnline: (_currentEvent.location.isEmpty)
                                  ? null
                                  : _currentEvent.isOnline,
                              previousLocationName: _currentEvent.location,
                              previousCoordinate:
                                  _currentEvent.locationCoordinate,
                              previousLink: _currentEvent.eventLink),
                        ))).then((selectLocationData) => setState(() {
                          selectLocationData =
                              selectLocationData as List<dynamic>?;
                          if (selectLocationData == null) {
                            return;
                          }
                          _currentEvent.location =
                              selectLocationData[1] as String;
                          if (selectLocationData[0] as bool) {
                            _currentEvent.locationCoordinate =
                                selectLocationData[2] as LatLng;
                            _currentEvent.eventLink = null;
                          } else {
                            _currentEvent.eventLink =
                                selectLocationData[2] as String;
                            _currentEvent.locationCoordinate = null;
                          }
                        }));
                  },
                  child: Container(
                      padding: const EdgeInsets.all(
                          MarginConstants.standardInternalMargin),
                      height: SizeConstants.textBoxHeight,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor, width: 1),
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              (_currentEvent.isOnline)
                                  ? Icons.cloud_rounded
                                  : Icons.pin_drop,
                              color: (_currentEvent.location.isEmpty)
                                  ? Theme.of(context).hintColor
                                  : Theme.of(context).highlightColor,
                              size: 22,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: (_currentEvent.location.isNotEmpty)
                                  ? Text(
                                      _currentEvent.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    )
                                  : Text("BAG - Bagley Hall",
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color:
                                                  Theme.of(context).hintColor)),
                            ),
                            Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).disabledColor,
                              size: 30,
                            )
                          ])),
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenSection,
                ),
                Text(
                  "Times and Days",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleSection,
                ),
                SizedBox(
                  height: _typeChipHeight,
                  child: _buildRepeatTypes(),
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenSubsection,
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        "First Day",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    Expanded(
                        flex: 5,
                        child: Text("Last Day",
                            style: Theme.of(context).textTheme.labelSmall))
                  ],
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleText,
                ),
                SelectDateContainer(
                    selectDate: _startSelectDate,
                    startDate: _currentEvent.dates.start,
                    endDate: _currentEvent.dates.end,
                    endDateIsActive: true),const SizedBox(
                  height: MarginConstants.formHeightBetweenSubsection,
                ),
                Row(
                  children: [
                    Expanded(
                        flex: 5,
                        child: Text("From",
                            style: Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 5,
                        child: Text("To",
                            style: Theme.of(context).textTheme.labelSmall))
                  ],
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleText,
                ),
                Container(
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).dividerColor, width: 1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: GestureDetector(
                          onTap: () {
                            _startSelectTime(true);
                          },
                          child: Container(
                            height: SizeConstants.textBoxHeight,
                            padding: const EdgeInsets.only(
                                left: MarginConstants.sideMargin),
                            decoration: BoxDecoration(
                                color: Colors.white,
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
                                      _currentEvent.startTime, _international),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: VerticalDivider(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                          thickness: 2,
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: GestureDetector(
                          onTap: () {
                            _startSelectTime(false);
                          },
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: MarginConstants.sideMargin),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15)),
                            height: SizeConstants.textBoxHeight,
                            child: Row(children: [
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
                                    _currentEvent.endTime, _international),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleSection,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildDayCard('M', 0),
                    _buildDayCard('T', 1),
                    _buildDayCard('W', 2),
                    _buildDayCard('Th', 3),
                    _buildDayCard('F', 4),
                    _buildDayCard('Sa', 5),
                    _buildDayCard('Su', 6),
                  ],
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize:
                            const Size(double.infinity, double.infinity)),
                    child: Text(
                      (_data.initialCourse != null)
                          ? 'Edit Event'
                          : 'Create Event',
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 30,
                    color: Colors.grey[400],
                  ),
                ),
                RichText(
                    text: TextSpan(children: <TextSpan>[
                  TextSpan(
                      text: (_data.initialCourse != null) ? "Edit " : "Create ",
                      style: AppTextStyle.ptSansBold(
                          size: 30.0, color: Colors.black)),
                  TextSpan(
                      text: "Event",
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

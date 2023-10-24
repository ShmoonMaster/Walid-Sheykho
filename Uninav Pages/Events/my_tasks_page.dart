import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Models/chip_data_model.dart';
import 'package:uninav/Models/event_addition_model.dart';
import 'package:uninav/Provider/additions_provider.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Event/new_addition.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/Event/event_addition_container.dart';
import 'dart:math' as math;
import 'package:uninav/Widgets/Home/task_productivity_curves_widget.dart';
import 'package:uninav/Widgets/Home/tasks_persistent_header_delegate.dart';
import 'package:uninav/Widgets/alert_dialog.dart';
import 'package:uninav/Widgets/avator_chip.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:uninav/Widgets/circle.dart';
import 'package:uninav/Widgets/transitions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({Key? key}) : super(key: key);

  static const routeName = 'MyTasksPage';

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  late final List<ChipData> _additionStatusChips;
  late final TextEditingController _fieldController;

  final Map<int, String> _events = {};
  final Set<int> _chosenDeletingTasks = {};

  bool _internationalTime = false;
  bool _isDeleting = false;
  int _chosenSortIndex = 0;
  RangeValues _chosenTimesValues = const RangeValues(0.0, 1440.0);

  @override
  void initState() {
    super.initState();
    _internationalTime = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.international ??
        false;

    _additionStatusChips = [
      ChipData(text: "Late", icon: Icons.alarm_outlined),
      ChipData(text: "To Do", icon: Icons.pending_actions_rounded),
      ChipData(text: "Done", icon: Icons.done),
    ];

    _fieldController = TextEditingController(text: "");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<EventsProvider>(context, listen: false)
        .getAllEvents
        .forEach((element) {
      _events[element.id] = element.name;
    });
  }

  @override
  void dispose() {
    _fieldController.dispose();
    super.dispose();
  }

  // Show error dialog if there are no events to add tasks to
  void _showNoEventsErrorDialog() {
    var dialog = CustomAlertDialog(
        title: "No Events",
        message: Text("You have no events. Please make an event to add tasks.",
            style: Theme.of(context).textTheme.bodyMedium),
        onPostivePressed: () {},
        onNegativePressed: null,
        positiveBtnText: "Alright",
        negativeBtnText: null);
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  // Call this function to update the is deleting property for the page
  // with the given parameter. If the parameter is the same as the current
  // state then it does nothing.
  void _toggleIsDeleting(bool isDeleting) {
    if (isDeleting == _isDeleting) {
      return;
    }
    setState(() {
      _chosenDeletingTasks.clear();
      _isDeleting = isDeleting;
    });
  }

  // This filters the event additions based on the current filters and
  // search paramters.
  List<EventAddition> _getRelevantAdditions(List<EventAddition> additions) {
    if (additions.isEmpty && _events.isEmpty) {
      return additions;
    }

    additions.sort(((a, b) {
      switch (_chosenSortIndex) {
        case 0:
          return a.date.compareTo(b.date);
        case 1:
          return b.date.compareTo(a.date);
        case 2:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        default:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    }));

    DateTime now = TimeHelper.getNow();

    return additions.where((element) {
      bool correctStatus = element.finished && _additionStatusChips[2].active ||
          !element.finished &&
              (element.date.isBefore(now) && _additionStatusChips[0].active ||
                  !element.date.isBefore(now) &&
                      _additionStatusChips[1].active);
      bool correctTime = (element.date.hour * 60 + element.date.minute) >=
              _chosenTimesValues.start &&
          (element.date.hour * 60 + element.date.minute) <=
              _chosenTimesValues.end;
      bool correctName = _fieldController.text.isEmpty ||
          element.name
              .toLowerCase()
              .contains(_fieldController.text.toLowerCase());
      return correctStatus && correctTime && correctName;
    }).toList();
  }

  // This function gets the string pertaining to the
  // type filters for this page. This function assumes
  // that chosenTypes is not empty. If it is, then it will
  // treat it as if it has three items.
  String get _getAdditionTypeString {
    List<String> types;

    types = _additionStatusChips
        .where((element) => element.active)
        .map((e) => e.text)
        .toList();

    if (types.isEmpty || types.length == _additionStatusChips.length) {
      return "All";
    }

    return types.join(" • ");
  }

  // This function takes a list of tasks and calucates the visual
  // metadata based on the trends of previous months.
  Map _calculateVisualData(List<EventAddition> tasks) {
    DateTime now = TimeHelper.getNow();
    Map data = {};

    data["months"] = <String>[];
    for (int i = 0; i > -6; i--) {
      data["months"].insert(
          0, DateFormat.MMM().format(DateTime(now.year, now.month + i)));
    }
    tasks = tasks
        .where((element) =>
            element.finished &&
            element.date.isBefore(DateTime(now.year, now.month + 1, 1)))
        .toList();
    if (tasks.isEmpty) {
      data["interval"] = 1;
      List<int> points = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      data[EventAdditionType.exam.name] = points;
      data[EventAdditionType.assignment.name] = points;
      data[EventAdditionType.meeting.name] = points;
      return data;
    }

    data[EventAdditionType.exam.name] = [
      tasks
          .where((element) =>
              element.date.month == now.month && element.type.name == "exam")
          .length
    ];
    data[EventAdditionType.assignment.name] = [
      tasks
          .where((element) =>
              element.date.month == now.month &&
              element.type.name == "assignment")
          .length
    ];
    data[EventAdditionType.meeting.name] = [
      tasks
          .where((element) =>
              element.date.month == now.month && element.type.name == "meeting")
          .length
    ];

    int maxVal = math.max(
        data[EventAdditionType.exam.name].first,
        math.max(data[EventAdditionType.assignment.name].first,
            data[EventAdditionType.meeting.name].first));
    for (int i = -2; i > -12; i--) {
      DateTime middle = DateTime(now.year, now.month + i ~/ 2, 15);
      List<EventAddition> thisMonthTasks = tasks
          .where(((element) =>
              element.date.month == middle.month &&
              ((i % 2 == 0 && element.date.isAfter(middle)) ||
                  (i % 2 == 1 && element.date.isBefore(middle)))))
          .toList();
      int examVal =
          thisMonthTasks.where((element) => element.type.name == "exam").length;
      int assVal = thisMonthTasks
          .where((element) => element.type.name == "assignment")
          .length;
      int meeVal = thisMonthTasks
          .where((element) => element.type.name == "meeting")
          .length;
      data[EventAdditionType.exam.name].insert(0, examVal);
      data[EventAdditionType.assignment.name].insert(0, assVal);
      data[EventAdditionType.meeting.name].insert(0, meeVal);
      maxVal = math.max(maxVal, math.max(examVal, math.max(assVal, meeVal)));
    }
    data["interval"] = (maxVal - (maxVal % 5) + 5) ~/ 5;

    return data;
  }

  // This builds the bottom sheet for the filters of the events
  StatefulBuilder get _buildSheet {
    return StatefulBuilder(builder: (context, setModalState) {
      return SizedBox(
        height: MediaQuery.of(context).padding.bottom + 350,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MarginConstants.sideMargin, 10, MarginConstants.sideMargin, 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text("Filters",
                style: AppTextStyle.ptSansRegular(
                    color: Theme.of(context).hintColor, size: 20)),
            const SizedBox(height: 15),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: (() {
                        setModalState(() {
                          _chosenSortIndex = (_chosenSortIndex + 1) % 4;
                        });
                      }),
                      child: Container(
                          padding: const EdgeInsets.all(15),
                          height: 60,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 1),
                              borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              Transform.rotate(
                                  angle:
                                      (_chosenSortIndex % 2 == 0) ? 0 : math.pi,
                                  child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 25,
                                      color: Color.fromRGBO(100, 100, 100, 1))),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                (_chosenSortIndex < 2) ? "Date" : "Name",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Expanded(
                                child: SizedBox(),
                              ),
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: GridView(
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 5,
                                            crossAxisSpacing: 5),
                                    children: List.generate(
                                        4,
                                        (index) => Circle(
                                              size: 2,
                                              color: (_chosenSortIndex == index)
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                  : Theme.of(context)
                                                      .disabledColor,
                                            ))),
                              )
                            ],
                          )),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List<Widget>.generate(3, (index) {
                        return GestureDetector(
                            onTap: () {
                              if (mounted &&
                                  (_additionStatusChips
                                              .where(
                                                  (element) => element.active)
                                              .length >
                                          1 ||
                                      !_additionStatusChips[index].active)) {
                                setModalState(() {
                                  _additionStatusChips[index].active =
                                      !_additionStatusChips[index].active;
                                });
                              }
                            },
                            child: AvatarChip(
                                active: _additionStatusChips[index].active,
                                colorMain:
                                    Theme.of(context).colorScheme.secondary,
                                colorSec: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                text: _additionStatusChips[index].text,
                                icon: _additionStatusChips[index].icon));
                      }),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    RangeSlider(
                      values: _chosenTimesValues,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      inactiveColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      max: 1440,
                      onChanged: (RangeValues values) {
                        setModalState(() {
                          _chosenTimesValues = values;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                              text: TextSpan(children: [
                            TextSpan(
                              text: "After ",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextSpan(
                                text: TimeHelper.timeToString(
                                    TimeOfDay(
                                        hour: _chosenTimesValues.start ~/ 60,
                                        minute:
                                            _chosenTimesValues.start ~/ 1 % 60),
                                    _internationalTime),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ])),
                          RichText(
                              text: TextSpan(children: [
                            TextSpan(
                              text: "Before ",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextSpan(
                                text: TimeHelper.timeToString(
                                    TimeOfDay(
                                        hour: _chosenTimesValues.end ~/ 60,
                                        minute:
                                            _chosenTimesValues.end ~/ 1 % 60),
                                    _internationalTime),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ]))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(MarginConstants.sideMargin,
            MediaQuery.of(context).padding.top, MarginConstants.sideMargin, 0),
        child: Consumer<AdditionsProvider>(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.myTasks,
                      style: AppTextStyle.ptSansBold(
                          color: Theme.of(context).colorScheme.secondary,
                          size: 30),
                    ),
                    GestureDetector(
                      onTap: () {
                        Transitions.showMyModalBottomSheet(
                            context, _buildSheet, Colors.white, null, () {
                          setState(() {});
                        });
                      },
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(5),
                        child: Row(children: [
                          Transform.rotate(
                              angle: (_chosenSortIndex % 2 == 0) ? 0 : math.pi,
                              child: const Icon(Icons.arrow_downward_rounded,
                                  size: 22,
                                  color: Color.fromRGBO(100, 100, 100, 1))),
                          const SizedBox(
                            width: 2,
                          ),
                          Text(
                            (_chosenSortIndex < 2) ? "Date" : "Name",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons.filter_list_rounded,
                            size: 30,
                            color: Theme.of(context).colorScheme.secondary,
                          )
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: SizeConstants.searchBoxHeight,
                  child: TextFormField(
                      controller: _fieldController,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.streetAddress,
                      cursorColor: Colors.black,
                      onChanged: (value) {
                        setState(() {});
                      },
                      style: AppTextStyle.ptSansRegular(
                          color: Colors.black, size: 18),
                      maxLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        isCollapsed: true,
                        prefixIcon: Padding(
                          padding:
                              const EdgeInsets.only(left: 12.0, right: 8.0),
                          child: Icon(Icons.search_rounded,
                              color: Theme.of(context).hintColor, size: 30),
                        ),
                        suffixIcon: (_fieldController.text.isNotEmpty)
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 0.0),
                                child: IconButton(
                                  icon: Icon(Icons.cancel,
                                      color: Theme.of(context).hintColor,
                                      size: 25),
                                  onPressed: () => {
                                    setState(() {
                                      _fieldController.clear();
                                    })
                                  },
                                ),
                              )
                            : null,
                        contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            MarginConstants.standardInternalMargin,
                            0,
                            MarginConstants.standardInternalMargin),
                        fillColor: Theme.of(context).cardColor,
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(15)),
                      )),
                ),
              ],
            ),
            builder: (context, provider, child) {
              List<EventAddition> data = provider.getAllAdditions;
              List<EventAddition> relevantData = _getRelevantAdditions(data);
              Map graphData = _calculateVisualData(relevantData);

              bool isActive =
                  Provider.of<EventsProvider>(context, listen: false)
                      .getAllEvents
                      .isNotEmpty;

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const MyBackButton(),
                        AnimatedSwitcher(
                            key: const Key("delete transitions"),
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: ((child, animation) {
                              const begin = Offset(1.0, 0);
                              const end = Offset.zero;
                              const curve = Curves.ease;
                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            }),
                            child: (!_isDeleting)
                                ? Container(
                                    alignment: Alignment.centerRight,
                                    key: const Key("first"),
                                    width: 200,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                            onTap: () {
                                              _toggleIsDeleting(true);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.delete_rounded,
                                                color: Theme.of(context)
                                                    .highlightColor,
                                                size: 27,
                                              ),
                                            )),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        GestureDetector(
                                            onTap: () async {
                                              if (isActive) {
                                                showCupertinoModalPopup(
                                                    context: context,
                                                    builder: (BuildContext
                                                            context) =>
                                                        const AdditionForm(
                                                            data:
                                                                AdditionFormPageArguments()));
                                              } else {
                                                _showNoEventsErrorDialog();
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(2.5),
                                              child: Icon(
                                                Icons.add_rounded,
                                                color: (isActive)
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .secondary
                                                    : Theme.of(context)
                                                        .disabledColor,
                                                size: 35,
                                              ),
                                            ))
                                      ],
                                    ),
                                  )
                                : Container(
                                    alignment: Alignment.centerRight,
                                    width: 200,
                                    key: const Key("second"),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.vibrate();
                                            for (int id
                                                in _chosenDeletingTasks) {
                                              provider.deleteAdditionWithId(id);
                                            }
                                            setState(() {
                                              _chosenDeletingTasks.clear();
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                MarginConstants.standardInternalMargin, 8, MarginConstants.standardInternalMargin, 8),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                    width: 1),
                                                color: (_chosenDeletingTasks
                                                        .isEmpty)
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                            child: Row(
                                              children: [
                                                Text(
                                                    "Delete ${_chosenDeletingTasks.length}",
                                                    style:
                                                        AppTextStyle.ptSansBold(
                                                      color:
                                                          (_chosenDeletingTasks
                                                                  .isEmpty)
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .error
                                                              : Colors.white,
                                                      size: 18,
                                                    )),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Icon(
                                                  Icons.delete,
                                                  color: (_chosenDeletingTasks
                                                          .isEmpty)
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .error
                                                      : Colors.white,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        GestureDetector(
                                            onTap: () {
                                              _toggleIsDeleting(false);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Icon(
                                                Icons.cancel_rounded,
                                                color: Theme.of(context)
                                                    .highlightColor,
                                                size: 30,
                                              ),
                                            )),
                                      ],
                                    ),
                                  ))
                      ],
                    ),
                    child ?? const SizedBox(),
                    const SizedBox(
                      height: 15,
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverPersistentHeader(
                              pinned: true,
                              delegate: TasksPersistentHeaderDelegate(
                                  title: 'Productivity', meta: "6 Mos")),
                          SliverList(
                              delegate: SliverChildListDelegate([
                            CustomPaint(
                              painter: TaskProductivityCurves(
                                  dates: graphData["months"] as List<String>,
                                  interval: graphData["interval"] as int,
                                  examPoints:
                                      graphData[EventAdditionType.exam.name]
                                          as List<int>,
                                  assignmentPoints: graphData[EventAdditionType
                                      .assignment.name] as List<int>,
                                  meetingPoints:
                                      graphData[EventAdditionType.meeting.name]
                                          as List<int>),
                              child: SizedBox(
                                  height: 170,
                                  width:
                                      MediaQuery.of(context).size.width - 30),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                          ])),
                          SliverPersistentHeader(
                              pinned: true,
                              delegate: TasksPersistentHeaderDelegate(
                                  title: "${relevantData.length} Tasks",
                                  meta: _getAdditionTypeString)),
                          SliverFixedExtentList(
                            delegate:
                                SliverChildBuilderDelegate((context, index) {
                              if (index == relevantData.length) {
                                return const SizedBox(
                                  height: 15,
                                );
                              }
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.heavyImpact();
                                  if (_isDeleting) {
                                    setState(() {
                                      int id = relevantData[index].id;
                                      if (_chosenDeletingTasks.contains(id)) {
                                        _chosenDeletingTasks.remove(id);
                                      } else {
                                        _chosenDeletingTasks.add(id);
                                      }
                                    });
                                  } else {
                                    provider.toggleFinishedWithAdditionId(
                                        relevantData[index].id);
                                  }
                                },
                                onLongPress: () {
                                  showCupertinoModalPopup(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AdditionForm(
                                            data: AdditionFormPageArguments(
                                                addition: relevantData[index]),
                                          ));
                                },
                                child: EventAdditionContainer(
                                  addition: relevantData[index],
                                  isDeleting: _isDeleting,
                                  selectedToDelete: _chosenDeletingTasks
                                      .contains(relevantData[index].id),
                                  event: _events[relevantData[index].eventID] ??
                                      "NA",
                                ),
                              );
                            }, childCount: relevantData.length + 1),
                            itemExtent: 110,
                          )
                        ],
                      ),
                    ),
                  ]);
            }),
      ),
    );
  }
}

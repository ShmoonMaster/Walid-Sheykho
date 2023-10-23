import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Models/chip_data_model.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Screens/Event/event_info.dart';
import 'package:uninav/Screens/Event/new_event.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/Event/event_container.dart';
import 'package:uninav/Widgets/Home/tasks_persistent_header_delegate.dart';
import 'package:uninav/Widgets/avator_chip.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:uninav/Widgets/circle.dart';
import 'package:uninav/Widgets/transitions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  static const routeName = 'myEventsPage';

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  late final List<ChipData> _eventStatusChips;
  late final TextEditingController _fieldController;

  int _chosenSortIndex = 0;

  @override
  void initState() {
    super.initState();

    _eventStatusChips = [
      ChipData(
        text: "Past",
        icon: Icons.arrow_back_rounded,
      ),
      ChipData(
        text: "Current",
        icon: Icons.trip_origin_rounded,
      ),
      ChipData(
        text: "Future",
        icon: Icons.arrow_forward_rounded,
      )
    ];

    _fieldController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _fieldController.dispose();
    super.dispose();
  }

  // Get string description of the current event based off of
  // what types are active or not, if all are active,
  // then it returns all, if not, it separates them by '•'
  String get _getEventTypeString {
    List<String> types;

    types = _eventStatusChips
        .where((element) => element.active)
        .map((e) => e.text)
        .toList();

    if (types.isEmpty || types.length == _eventStatusChips.length) {
      return "All";
    }

    return types.join(" • ");
  }

  // Gets the list of events based off of the current filters
  // and returns a new list from the total given
  List<Event> _getRelevantEvents(List<Event> totalEvents) {
    if (totalEvents.isEmpty) {
      return totalEvents;
    }

    totalEvents.sort(((a, b) {
      switch (_chosenSortIndex) {
        case 0:
          return a.dates.start.compareTo(b.dates.start);
        case 1:
          return b.dates.start.compareTo(a.dates.start);
        case 2:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        default:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    }));

    DateTime now = TimeHelper.getNow();
    return totalEvents.where((element) {
      bool correctStatus = (element.dates.end.isBefore(now) &&
              _eventStatusChips[0].active) ||
          (element.dates.start.isAfter(now) && _eventStatusChips[2].active) ||
          (!element.dates.end.isBefore(now) &&
              !element.dates.start.isAfter(now) &&
              _eventStatusChips[1].active);
      bool correctName = _fieldController.text.isEmpty ||
          element.name
              .toLowerCase()
              .contains(_fieldController.text.toLowerCase());
      return correctStatus && correctName;
    }).toList();
  }

  // Builds bottom filter sheet to be displayed
  StatefulBuilder get _buildSheet {
    return StatefulBuilder(builder: (context, setModalState) {
      return SizedBox(
        height: MediaQuery.of(context).padding.bottom + 250,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              MarginConstants.sideMargin, 10, MarginConstants.sideMargin, 30),
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
                                                      .primary
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
                                  (_eventStatusChips
                                              .where(
                                                  (element) => element.active)
                                              .length >
                                          1 ||
                                      !_eventStatusChips[index].active)) {
                                setModalState(() {
                                  _eventStatusChips[index].active =
                                      !_eventStatusChips[index].active;
                                });
                              }
                            },
                            child: AvatarChip(
                                active: _eventStatusChips[index].active,
                                colorMain:
                                    Theme.of(context).colorScheme.primary,
                                colorSec: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                text: _eventStatusChips[index].text,
                                icon: _eventStatusChips[index].icon));
                      }),
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
    final mainColor = Theme.of(context).colorScheme.primary;
    final darkColor = HSLColor.fromColor(mainColor).withLightness(.4).toColor();
    final lightColor =
        HSLColor.fromColor(mainColor).withLightness(.8).toColor();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(MarginConstants.sideMargin,
            MediaQuery.of(context).padding.top, MarginConstants.sideMargin, 0),
        child: Consumer<EventsProvider>(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MyBackButton(),
                  GestureDetector(
                      onTap: () {
                        showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) =>
                                const EventFormPage(
                                  data: EventFormPageArguments(),
                                ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: Icon(
                          Icons.add_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 35,
                        ),
                      ))
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.myEvents,
                    style: AppTextStyle.ptSansBold(
                        color: Theme.of(context).colorScheme.primary, size: 30),
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
                      padding: const EdgeInsets.all(5.0),
                      child: Row(children: [
                        Transform.rotate(
                            angle: (_chosenSortIndex % 2 == 0) ? 0 : math.pi,
                            child: const Icon(Icons.arrow_downward_rounded,
                                size: 25,
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: MarginConstants.formHeightBetweenTitleSection,
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
                        padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                        child: Icon(Icons.search_rounded,
                            color: Theme.of(context).hintColor, size: 30),
                      ),
                      suffixIcon: (_fieldController.text.isNotEmpty)
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 0.0),
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
                      contentPadding: const EdgeInsets.fromLTRB(12, 15, 0, 15),
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
            ]),
            builder: (context, provider, child) {
              List<Event> data = _getRelevantEvents(provider.getAllEvents);
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    child ?? const SizedBox(),
                    const SizedBox(
                      height: 12,
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverPersistentHeader(
                              pinned: true,
                              delegate: TasksPersistentHeaderDelegate(
                                  title: "${data.length} Events",
                                  meta: _getEventTypeString)),
                          SliverFixedExtentList(
                            delegate:
                                SliverChildBuilderDelegate((context, index) {
                              if (index == data.length) {
                                return Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(25.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Circle(size: 10, color: lightColor),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Circle(size: 10, color: mainColor),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Circle(size: 10, color: darkColor)
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () {
                                  context.pushNamed(EventInfoPage.routeName,
                                      extra: EventInfoPageArguments(
                                          eventId: data[index].id));
                                },
                                child: EventContainer(event: data[index]),
                              );
                            }, childCount: data.length + 1),
                            itemExtent: 125,
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

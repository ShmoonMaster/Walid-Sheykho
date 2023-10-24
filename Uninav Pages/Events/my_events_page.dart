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
  const MyEventsPage({Key? key}) : super(key: key);

  static const routeName = 'myEventsPage';

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  static const double _standardBottomSheetHeight = 250;
  // State variables
  late final List<ChipData> _eventStatusChips;
  late final TextEditingController _fieldController;
  int _chosenSortIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize state variables
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
      ),
    ];
    _fieldController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _fieldController.dispose();
    super.dispose();
  }

  // Get string description of the current event based on active chips
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

  // Get the list of events based on filters
  List<Event> _getRelevantEvents(List<Event> totalEvents) {
    if (totalEvents.isEmpty) {
      return totalEvents;
    }
    totalEvents.sort((a, b) {
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
    });

    DateTime now = TimeHelper.getNow();
    return totalEvents.where((element) {
      bool correctStatus = (element.dates.end.isBefore(now) && _eventStatusChips[0].active) ||
          (element.dates.start.isAfter(now) && _eventStatusChips[2].active) ||
          (!element.dates.end.isBefore(now) &&
              !element.dates.start.isAfter(now) &&
              _eventStatusChips[1].active);
      bool correctName = _fieldController.text.isEmpty ||
          element.name.toLowerCase().contains(_fieldController.text.toLowerCase());
      return correctStatus && correctName;
    }).toList();
  }

  // Build the filter sheet to be displayed
  StatefulBuilder get _buildSheet {
    return StatefulBuilder(builder: (context, setModalState) {
      return SizedBox(
        height: MediaQuery.of(context).padding.bottom + _standardBottomSheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              MarginConstants.sideMargin, 10, MarginConstants.sideMargin, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Filters",
              style: AppTextStyle.ptSansRegular(
                color: Theme.of(context).hintColor,
                size: 20,
              ),
            ),
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
                      onTap: () {
                        setModalState(() {
                          _chosenSortIndex = (_chosenSortIndex + 1) % 4;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        height: 60,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: (_chosenSortIndex % 2 == 0) ? 0 : math.pi,
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 25,
                                color: Color.fromRGBO(100, 100, 100, 1),
                              ),
                            ),
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
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                ),
                                children: List.generate(4, (index) => Circle(
                                  size: 2,
                                  color: (_chosenSortIndex == index)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).disabledColor,
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                                (_eventStatusChips.where((element) => element.active).length > 1 ||
                                    !_eventStatusChips[index].active)) {
                              setModalState(() {
                                _eventStatusChips[index].active = !_eventStatusChips[index].active;
                              });
                            }
                          },
                          child: AvatarChip(
                            active: _eventStatusChips[index].active,
                            colorMain: Theme.of(context).colorScheme.primary,
                            colorSec: Theme.of(context).colorScheme.primaryContainer,
                            text: _eventStatusChips[index].text,
                            icon: _eventStatusChips[index].icon,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      );
    });
  }

  // Function to build the header section with title and filter button
  Widget _buildHeaderSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MyBackButton(),
        GestureDetector(
          onTap: _onAddEventButtonPressed,
          child: Padding(
            padding: const EdgeInsets.all(2.5),
            child: Icon(
              Icons.add_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 35,
            ),
          ),
        ),
      ],
    );
  }

  // Function to build the search input field
  Widget _buildSearchField() {
    return SizedBox(
      height: SizeConstants.searchBoxHeight,
      child: TextFormField(
        controller: _fieldController,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.streetAddress,
        cursorColor: Colors.black,
        onChanged: _onSearchFieldChanged,
        style: AppTextStyle.ptSansRegular(
          color: Colors.black,
          size: 18,
        ),
        maxLines: 1,
        decoration: _buildSearchInputDecoration(),
      ),
    );
  }

  // Function to build the main event list
  Widget _buildEventList(List<Event> data) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _buildPersistentHeaderDelegate(data.length),
        ),
        SliverFixedExtentList(
          delegate: _buildEventListDelegate(data),
          itemExtent: 125,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = Theme.of(context).colorScheme.primary;
    final darkColor = HSLColor.fromColor(mainColor).withLightness(.4).toColor();
    final lightColor = HSLColor.fromColor(mainColor).withLightness(.8).toColor();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          MarginConstants.sideMargin,
          MediaQuery.of(context).padding.top,
          MarginConstants.sideMargin,
          0,
        ),
        child: Consumer<EventsProvider>(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeaderSection(),
            _buildTitleSection(),
            const SizedBox(height: MarginConstants.formHeightBetweenTitleSection),
            _buildSearchField(),
          ]),
          builder: (context, provider, child) {
            List<Event> data = _getRelevantEvents(provider.getAllEvents);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child ?? const SizedBox(),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildEventList(data),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Event/event_info.dart';
import 'package:uninav/Screens/Event/my_events_page.dart';
import 'package:uninav/Screens/Event/my_tasks_page.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/circle.dart';
import 'package:uninav/Widgets/Event/event_schedule_container.dart';
import 'package:uninav/Widgets/Event/events_background_tile.dart';
import 'package:uninav/Widgets/Event/event_time_marker.dart';

class EventPage extends StatefulWidget {
  const EventPage({Key? key}) : super(key: key);

  static const String routeName = "EventPage";

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>
    with SingleTickerProviderStateMixin {
  // Constants
  static const double _standardTopHeightSmall = 180;
  static const double _standartTopHeightLarge = 380;
  static const double _standardHourSectorHeight = 170;
  static const double _standardTopContentHeight = 160;

  static final DateFormat _format = DateFormat.MMMd();

  // Stream controller for the top height
  final StreamController<double> _topHeight = StreamController();

  // Value notifier for the updated date range
  final ValueNotifier<String> _updatedRange = ValueNotifier("");

  // Scroll controller
  late final ScrollController _scrollController;

  // Flags and variables
  bool _isWeekMode = true;
  double _topPadding = 0;
  double _currentTimePosition = 0;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late bool _internationalTime;

  @override
  void initState() {
    super.initState();

    _internationalTime = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.international ??
        false;

    _focusedDay = TimeHelper.getNow();
    _selectedDay = TimeHelper.getNow();

    _initializeScrollController();
  }

  @override
  void dispose() {
    _topHeight.close();
    _updatedRange.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Initialize the scroll controller
  void _initializeScrollController() {
    _scrollController =
        ScrollController(initialScrollOffset: _currentTimePosition - 80);
  }

  // Get the date period name based on the current day
  String _getDatePeriodName() {
    final temp = _selectedDay.difference(TimeHelper.getNow()).inDays;

    if (isSameDay(_selectedDay, TimeHelper.getNow())) {
      return "Today";
    } else if (temp == -1) {
      return "Yesterday";
    } else if (temp < 0) {
      return "${temp.abs()} Days Ago";
    } else if (temp == 1) {
      return "Tomorrow";
    } else {
      return "$temp Days Away";
    }
  }

  // Push the event information page onto the stack
  void _pushEventInfo(Event event) {
    context.pushNamed(EventInfoPage.routeName,
        extra: EventInfoPageArguments(
          eventId: event.id,
        ));
  }

  // Get the list of selected events based on the chosen date
  List<Event> _getSelectedEvents(List<Event> oldList) {
    final events = Provider.of<EventsProvider>(context, listen: false)
        .getEventsOnDate(_selectedDay, oldList);
    events.sort((a, b) => a.compareTo(b));
    return events;
  }

  // Build an event card
  Widget _buildEventCard(Event event) {
    final topPixels =
        (event.startTime.hour * 60 + event.startTime.minute) / 60 *
                _standardHourSectorHeight +
            _standardHourSectorHeight / 2;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(top: topPixels),
        child: EventScheduleContainer(
          internationalTime: _internationalTime,
          event: event,
          infoRoute: _pushEventInfo,
          isToday: true,
          hourHeight: _standardHourSectorHeight,
        ),
      ),
    );
  }

  // Get the date range based on whether it's a week or month view
  DateTimeRange _getDateRange(DateTime date) {
    if (_isWeekMode) {
      return DateTimeRange(
          start: DateTime(date.year, date.month, date.day - date.weekday + 1),
          end: DateTime(date.year, date.month, date.day - date.weekday + 8));
    }
    return DateTimeRange(
        start: DateTime(date.year, date.month, 1),
        end: DateTime(date.year, date.month + 1, 0));
  }

  // Build the top navigation view
  Widget _buildDayNavigation(double topHeight) {
    return AnimatedContainer(
      clipBehavior: Clip.hardEdge,
      duration: const Duration(milliseconds: 10),
      curve: Curves.bounceInOut,
      padding: EdgeInsets.fromLTRB(
        MarginConstants.sideMargin,
        _topPadding,
        MarginConstants.sideMargin,
        0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      alignment: Alignment.topCenter,
      height: topHeight + _topPadding,
      child: _buildTopContent(),
    );
  }

  // Build the content within the top navigation view
  Widget _buildTopContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(),
        const SizedBox(height: 5),
        _buildPeriodInfo(),
        const SizedBox(height: 10),
        _buildCalendar(),
        const SizedBox(height: 100),
      ],
    );
  }

  // Build the top row in the top navigation view
  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            DateFormat.yMMMMd("en_US").format(_selectedDay),
            style: AppTextStyle.ptSansBold(
              color: Colors.white,
              size: 25.0,
            ),
          ),
        ),
        _buildUndoButton(),
      ],
    );
  }

  // Build the "Undo" button
  Widget _buildUndoButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedDay = TimeHelper.getNow();
        });
      },
      style: ButtonStyle(
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.all(5),
        ),
        backgroundColor: MaterialStateProperty.all(
          Colors.white.withOpacity(.3),
        ),
        shadowColor: MaterialStateProperty.all(
          Colors.transparent,
        ),
      ),
      child: const Icon(
        Icons.undo,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  // Build the period info section
  Widget _buildPeriodInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getDatePeriodName(),
          style: AppTextStyle.ptSansRegular(
            color: Colors.white,
            size: 16.0,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _updatedRange,
          builder: (context, val, child) {
            return Text(
              val as String,
              style: AppTextStyle.ptSansRegular(
                size: 14.0,
                color: Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }

  // Build the calendar
  Widget _buildCalendar() {
    return TableCalendar(
      key: const Key("calendar"),
      headerVisible: false,
      focusedDay: _selectedDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
          _focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
        });
      },
      calendarFormat: (_isWeekMode) ? CalendarFormat.week : CalendarFormat.month,
      onPageChanged: (focusedDay) {
        _focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
        DateTimeRange range = _getDateRange(focusedDay);
        _updatedRange.value = (_isWeekMode)
            ? "${_format.format(range.start)} - ${_format.format(range.end)}"
            : DateFormat.yMMM().format(range.start);
      },
      daysOfWeekHeight: 20,
      rowHeight: 50,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTextStyle.ptSansBold(
          color: null,
          size: 13.0,
        ),
        weekendStyle: AppTextStyle.ptSansBold(
          color: null,
          size: 13.0,
        ),
      ),
      calendarStyle: _buildCalendarStyle(),
    );
  }

  // Build the calendar style
  CalendarStyle _buildCalendarStyle() {
    TextStyle whiteTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white);

    return CalendarStyle(
      cellMargin: const EdgeInsets.all(3),
      defaultTextStyle: whiteTextStyle,
      weekendTextStyle: whiteTextStyle,
      holidayTextStyle: whiteTextStyle,
      todayTextStyle: whiteTextStyle,
      outsideTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white.withOpacity(.5)),
      disabledTextStyle: whiteTextStyle,
      rangeEndTextStyle: whiteTextStyle,
      rangeStartTextStyle: whiteTextStyle,
      withinRangeTextStyle: whiteTextStyle,
      defaultDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
      ),
      disabledDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
      ),
      weekendDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
      ),
      holidayDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
      ),
      outsideDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
      ),
      rowDecoration: const BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      markerDecoration: const BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      rangeEndDecoration: const BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      rangeStartDecoration: const BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      withinRangeDecoration: const BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      selectedDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      selectedTextStyle: AppTextStyle.ptSansBold(
        color: Theme.of(context).colorScheme.primary,
        size: 18.0,
      ),
      todayDecoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(.2),
      ),
    );
  }

  // Build the content of the page
  Widget _buildPageContent() {
    _topPadding = MediaQuery.of(context).padding.top;
    TimeOfDay now = TimeOfDay.now();

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Padding(
            padding: EdgeInsets.fromLTRB(0, _standardTopContentHeight + _topPadding, 0, 0),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: _standardHourSectorHeight * 26,
                child: Consumer<EventsProvider>(
                  child: _buildTimeMarkers(),
                  builder: (context, snapshot, child) {
                    final events = _getSelectedEvents(
                        snapshot.getEventsInRange(_getDateRange(_selectedDay)));
                    _currentTimePosition = ((now.hour * 60 + now.minute) /
                                60) *
                            _standardHourSectorHeight +
                        _standardHourSectorHeight / 2;

                    return Stack(
                      children: [
                        child ?? const SizedBox(),
                        _buildCurrentTimeDivider(),
                        ...events.map((event) {
                          return _buildEventCard(event);
                        }).toList(),
                        _buildCurrentTimeCircle(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          _buildTopNavigation(),
          _buildTopBackground(),
          _buildTopActions(),
        ],
      ),
    );
  }

  // Build the time markers
  Widget _buildTimeMarkers() {
    TimeOfDay now = TimeOfDay.now();
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: (now.hour * 60 + now.minute) /
                  60 *
                  _standardHourSectorHeight +
              _standardHourSectorHeight / 2,
        ),
        child: Column(
          children: List.generate(25, (index) {
            final hour = (index + 1 + 6) % 24;
            return EventTimeMarker(
              hour: hour,
              height: _standardHourSectorHeight,
            );
          }),
        ),
      ),
    );
  }

  // Build the divider for the current time
  Widget _buildCurrentTimeDivider() {
    return Padding(
      padding: EdgeInsets.fromLTRB(90, _currentTimePosition, MarginConstants.sideMargin, 0),
      child: Divider(
        color: (_selectedDay.sameDayAs(TimeHelper.getNow()))
            ? Theme.of(context).colorScheme.primary
            : const Color.fromARGB(0, 255, 255, 255),
        thickness: 1,
        height: 1,
      ),
    );
  }

  // Build the circle for the current time
  Widget _buildCurrentTimeCircle() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(55, _currentTimePosition - 10, 0, 0),
        child: Circle(
          color: (_selectedDay.sameDayAs(TimeHelper.getNow()))
              ? Theme.of(context).colorScheme.primary
              : const Color.fromARGB(0, 255, 255, 255),
          size: 20,
        ),
      ),
    );
  }

  // Build the top navigation
  Widget _buildTopNavigation() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: StreamBuilder<Object>(
          stream: _topHeight.stream,
          initialData: _standardTopHeightSmall,
          builder: (context, AsyncSnapshot snapshot) {
            return _buildDayNavigation(snapshot.data as double);
          },
        ),
      ),
    );
  }

  // Build the top background
  Widget _buildTopBackground() {
    return Container(
      color: Colors.white,
    );
  }

  // Build the top actions
  Widget _buildTopActions() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MarginConstants.sideMargin, MarginConstants.sideMargin,
              MarginConstants.sideMargin, 70 + MarginConstants.sideMargin),
          child: _buildTasksButton(),
        ),
      ),
    );
  }

  // Build the "Tasks" button
  Widget _buildTasksButton() {
    return FloatingActionButton(
      heroTag: null,
      onPressed: () {
        context.pushNamed(MyTasksPage.routeName);
      },
      backgroundColor: Theme.of(context).colorScheme.secondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.format_list_bulleted_rounded,
        size: 30,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPageContent();
  }
}

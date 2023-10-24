import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Event/event_info.dart';
import 'package:uninav/Screens/Event/my_events_page.dart';
import 'package:uninav/Screens/Event/my_tasks_page.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/circle.dart';
import 'package:uninav/Widgets/Event/event_schedule_container.dart';
import 'package:uninav/Widgets/Event/events_background_tile.dart';

// This class will manage the current scheduled events for the week
// it displays the events under a calendar.
class EventPage extends StatefulWidget {
  const EventPage({Key? key}) : super(key: key);

  static const String routeName = "EventPage";

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>
    with SingleTickerProviderStateMixin {
  static const double _standardTopHeightSmall = 180;
  static const double _standartTopHeightLarge = 380;
  static const double _standardHourSectorHeight = 170;

  static final DateFormat _format = DateFormat.MMMd();
  final StreamController<double> _topHeight = StreamController();
  final ValueNotifier<String> _updatedRange = ValueNotifier("");

  late final ScrollController _scrollController;

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

    DateTimeRange range = _getDateRange(TimeHelper.getNow());
    _updatedRange.value =
        "${_format.format(range.start)} - ${_format.format(range.end)}";
    _currentTimePosition =
        ((TimeOfDay.now().hour * 60 + TimeOfDay.now().minute) / 60) *
                _standardHourSectorHeight +
            _standardHourSectorHeight / 2;
    _scrollController =
        ScrollController(initialScrollOffset: _currentTimePosition - 80);
  }

  @override
  void dispose() {
    _topHeight.close();
    _updatedRange.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // This function returns the string of the date period based on
  // the current day ie. Today, Tomorrow ...
  String _getDatePeriodName() {
    int temp = _selectedDay.difference(TimeHelper.getNow()).inDays;

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

  // This function takes an event model and pushes the event information
  // page on the stack.
  void _pushCourseInfo(Event event) {
    context.pushNamed(EventInfoPage.routeName,
        extra: EventInfoPageArguments(
          eventId: event.id,
        ));
  }

  // This function takes all of the events in the chosen range, and picks
  // the events that are on the selected date
  // rType: list of event models
  List<Event> _selectedEventsList(List<Event> oldList) {
    List<Event> events = Provider.of<EventsProvider>(context, listen: false)
        .getEventsOnDate(_selectedDay, oldList);
    oldList.sort((a, b) => a.compareTo(b));
    return events;
  }

  // This function takes an event model and creates a event card to be displayed
  // and aligns it in the page based on the time of day that it starts.
  // rType: Align (eventCard)
  Align _buildEventCard(Event event) {
    double topPixels = (event.startTime.hour * 60 + event.startTime.minute) /
            60 *
            _standardHourSectorHeight +
        _standardHourSectorHeight / 2;
    return Align(
        alignment: Alignment.topLeft,
        child: Padding(
            padding: EdgeInsets.only(top: topPixels),
            child: EventScheduleContainer(
              internationalTime: _internationalTime,
              event: event,
              infoRoute: _pushCourseInfo,
              isToday: true,
              hourHeight: _standardHourSectorHeight,
            )));
  }

  // This function gets that date range based on the _isWeekMode bool.
  // If it is true, then it gets the given week, if not, it returns a month
  // long date range.
  // rType: DateTimeRange
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

  // This function takes a height and builds the top navigation view
  // holding the calendar and selected time views. Its height can be changed
  // and that change is made by the given parameter.
  // rType: Animated Container
  AnimatedContainer _buildDayNavigation(double topHeight) {
    TextStyle whiteTextStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white);

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
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                            DateFormat.yMMMMd("en_US").format(_selectedDay),
                            style: AppTextStyle.ptSansBold(
                                color: Colors.white, size: 25.0)),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDay = TimeHelper.getNow();
                            });
                          },
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15))),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(5)),
                            backgroundColor: MaterialStateProperty.all(
                                Colors.white.withOpacity(.3)),
                            shadowColor: MaterialStateProperty.all(
                                Colors.transparent), // <-- Button color
                          ),
                          child: const Icon(Icons.undo,
                              color: Colors.white, size: 20)),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getDatePeriodName(),
                        style: AppTextStyle.ptSansRegular(
                            color: Colors.white, size: 16.0),
                      ),
                      ValueListenableBuilder(
                          valueListenable: _updatedRange,
                          builder: (context, val, child) {
                            return Text(
                              val as String,
                              style: AppTextStyle.ptSansRegular(
                                  size: 14.0, color: Colors.white),
                            );
                          }),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TableCalendar(
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
                        _selectedDay = DateTime(selectedDay.year,
                            selectedDay.month, selectedDay.day);
                        _focusedDay = DateTime(
                            focusedDay.year,
                            focusedDay.month,
                            focusedDay
                                .day); // update `_focusedDay` here as well
                      });
                    },
                    calendarFormat: (_isWeekMode)
                        ? CalendarFormat.week
                        : CalendarFormat.month,
                    onPageChanged: (focusedDay) {
                      _focusedDay = DateTime(
                          focusedDay.year, focusedDay.month, focusedDay.day);
                      DateTimeRange range = _getDateRange(focusedDay);
                      _updatedRange.value = (_isWeekMode)
                          ? "${_format.format(range.start)} - ${_format.format(range.end)}"
                          : DateFormat.yMMM().format(range.start);
                    },
                    daysOfWeekHeight: 20,
                    rowHeight: 50,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle:
                          AppTextStyle.ptSansBold(color: null, size: 13.0),
                      weekendStyle:
                          AppTextStyle.ptSansBold(color: null, size: 13.0),
                    ),
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(3),
                      defaultTextStyle: whiteTextStyle,
                      weekendTextStyle: whiteTextStyle,
                      holidayTextStyle: whiteTextStyle,
                      todayTextStyle: whiteTextStyle,
                      outsideTextStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Colors.white.withOpacity(.5)),
                      disabledTextStyle: whiteTextStyle,
                      rangeEndTextStyle: whiteTextStyle,
                      rangeStartTextStyle: whiteTextStyle,
                      withinRangeTextStyle: whiteTextStyle,
                      defaultDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(15)),
                      disabledDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(15)),
                      weekendDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(15)),
                      holidayDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(15)),
                      outsideDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(15)),
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
                          color: Colors.white),
                      selectedTextStyle: AppTextStyle.ptSansBold(
                          color: Theme.of(context).colorScheme.primary,
                          size: 18.0),
                      todayDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withOpacity(.2)),
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                  )
                ],
              ),
            ),
            GestureDetector(
              onVerticalDragEnd: ((details) {
                double tempVal = topHeight;
                if (details.velocity.pixelsPerSecond.dy > 500) {
                  tempVal = _standartTopHeightLarge;
                } else if (details.velocity.pixelsPerSecond.dy < -500) {
                  tempVal = _standardTopHeightSmall;
                } else {
                  tempVal =
                      ((tempVal - _standardTopHeightSmall) / 200).round() *
                              200 +
                          _standardTopHeightSmall;
                }

                _isWeekMode = tempVal == _standardTopHeightSmall;
                _topHeight.add(tempVal);
                DateTimeRange range = _getDateRange(_focusedDay);
                _updatedRange.value = (_isWeekMode)
                    ? "${_format.format(range.start)} - ${_format.format(range.end)}"
                    : DateFormat.yMMM().format(range.start);
              }),
              onTap: () {
                if (_isWeekMode) {
                  _isWeekMode = false;
                  _topHeight.add(_standartTopHeightLarge);
                } else {
                  _isWeekMode = true;
                  _topHeight.add(_standardTopHeightSmall);
                }
              },
              onVerticalDragUpdate: ((details) {
                double tempVal = details.globalPosition.dy - 25;
                tempVal = min(_standartTopHeightLarge, tempVal);
                tempVal = max(_standardTopHeightSmall, tempVal);
                _isWeekMode = tempVal == _standardTopHeightSmall;
                _topHeight.add(tempVal);
              }),
              child: Container(
                height: 30,
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.only(bottom: 10),
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5)),
                ),
              ),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    _topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      key: widget.key,
      body: Stack(
        children: [
          Container(
            color: Colors.white,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 160 + _topPadding, 0, 0),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: _standardHourSectorHeight * 26,
                child: Consumer<EventsProvider>(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: 26,
                    itemBuilder: (context, index) {
                      return EventsBackgroundTile(
                        index: index,
                        internationalTime: _internationalTime,
                        height: _standardHourSectorHeight,
                      );
                    },
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                  builder: (context, snapshot, child) {
                    List<Event> events = _selectedEventsList(
                        snapshot.getEventsInRange(_getDateRange(_selectedDay)));
                    _currentTimePosition =
                        ((TimeOfDay.now().hour * 60 + TimeOfDay.now().minute) /
                                    60) *
                                _standardHourSectorHeight +
                            _standardHourSectorHeight / 2;
                    
                    return Stack(
                      children: <Widget>[
                            child ?? const SizedBox(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  90, _currentTimePosition, MarginConstants.sideMargin, 0),
                              child: Divider(
                                color: (_selectedDay
                                        .sameDayAs(TimeHelper.getNow()))
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color.fromARGB(0, 255, 255, 255),
                                thickness: 1,
                                height: 1,
                              ),
                            )
                          ] +
                          List.from(
                              events.map((event) => _buildEventCard(event))) +
                          [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  55, _currentTimePosition - 10, 0, 0),
                              child: Circle(
                                  color: (_selectedDay
                                          .sameDayAs(TimeHelper.getNow()))
                                      ? Theme.of(context).colorScheme.primary
                                      : const Color.fromARGB(0, 255, 255, 255),
                                  size: 20),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  57.5, _currentTimePosition - 7.5, 0, 0),
                              child: Circle(
                                  color: (_selectedDay
                                          .sameDayAs(TimeHelper.getNow()))
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : const Color.fromARGB(0, 255, 255, 255),
                                  size: 15),
                            ),
                          ],
                    );
                  },
                ),
              ),
            ),
          ),
          Align(
              alignment: Alignment.topRight,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      0,
                      _topPadding + _standardTopHeightSmall + 5,
                      MarginConstants.sideMargin,
                      0),
                  child: ElevatedButton(
                    onPressed: (() {
                      _scrollController.animateTo(_currentTimePosition - 80,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut);
                    }),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        fixedSize: const Size(40, 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: const Icon(
                      Icons.circle_outlined,
                      size: 22,
                      color: Colors.white,
                    ),
                  ))),
          Align(
            alignment: Alignment.topCenter,
            child: StreamBuilder<Object>(
                stream: _topHeight.stream,
                initialData: _standardTopHeightSmall,
                builder: (context, AsyncSnapshot snapshot) {
                  return _buildDayNavigation(snapshot.data as double);
                }),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    MarginConstants.sideMargin,
                    MarginConstants.sideMargin,
                    MarginConstants.sideMargin,
                    70 + MarginConstants.sideMargin),
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    context.pushNamed(MyTasksPage.routeName);
                  },
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.format_list_bulleted_rounded,
                      size: 30, color: Colors.white),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(MarginConstants.sideMargin),
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    context.pushNamed(MyEventsPage.routeName);
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.calendar_view_day_rounded,
                      size: 30, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:uninav/Databases/college_data.dart';
import 'package:uninav/Models/event_addition_model.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:uninav/Provider/additions_provider.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Event/new_event.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Widgets/Event/event_late_task_container.dart';
import 'package:uninav/Widgets/Event/event_location_container.dart';
import 'package:uninav/Widgets/Event/event_tasks_container.dart';
import 'package:uninav/Widgets/alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Widgets/back_button.dart';

class EventInfoPageArguments {
  final int eventId;

  const EventInfoPageArguments({required this.eventId});
}

class EventInfoPage extends StatefulWidget {
  final EventInfoPageArguments data;

  const EventInfoPage({Key? key, required this.data}) : super(key: key);

  static const String routeName = "EventInfoPage";

  @override
  State<EventInfoPage> createState() => _EventInfoPageState();
}

class _EventInfoPageState extends State<EventInfoPage> {
  @override
  Widget build(BuildContext context) {
    // Get the event data from the provider
    final EventInfoPageArguments data = widget.data;

    // Check if the user's system uses international time format
    final bool international =
        Provider.of<UserProvider>(context, listen: false).getUserData?.international ?? false;

    return Scaffold(
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          // Get the event based on the provided ID
          final Event? event = provider.getEventWithId(data.eventId);

          if (event == null) {
            // Show an error dialog if the event is not found
            return _buildNoEventErrorDialog();
          }

          // Build the event details page
          return _buildEventInfoPage(event, context);
        },
      ),
    );
  }

  Widget _buildNoEventErrorDialog() {
    // Show a dialog when no event is found
    return CustomAlertDialog(
      title: "No Event Found",
      message: Text(
        "We could not find your event. Please try again.",
        style: AppTextStyle.ptSansRegular(
          color: Theme.of(context).highlightColor,
          size: 16,
        ),
      ),
      positiveBtnText: "Okay",
      onPostivePressed: () {
        context.pop();
      },
    );
  }

  Widget _buildEventInfoPage(Event event, BuildContext context) {
    // Build the main content of the event details page
    return Stack(
      children: [
        _buildBackground(event), // Background gradient
        _buildEventDetails(event, context), // Event details and information
      ],
    );
  }

  Widget _buildBackground(Event event) {
    // Build the background gradient
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: const [0, .5],
          colors: [
            HSLColor.fromColor(event.getEventTheme.primary).withLightness(.95).toColor(),
            Colors.white,
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(Event event, BuildContext context) {
    // Build the event details and information
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MarginConstants.sideMargin,
        MediaQuery.of(context).padding.top,
        MarginConstants.sideMargin,
        0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(event), // Top bar with back, delete, and edit buttons
            _buildEventInfo(event), // Event type, title, time, and dates
            const SizedBox(height: MarginConstants.formHeightBetweenSection),
            _buildEventDateProgress(event), // Event date progress indicator
            _buildEventLocation(event), // Event location
            const SizedBox(height: MarginConstants.formHeightBetweenSubsection),
            _buildEventTasks(event), // Event tasks and late tasks
            ..._buildLateTasksContainers(event), // Late tasks containers
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Event event) {
    // Build the top bar with back, delete, and edit buttons
    return SizedBox(
      height: 45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: Align(alignment: Alignment.centerLeft, child: MyBackButton())),
          _buildDeleteButton(event),
          const SizedBox(width: 10),
          _buildEditButton(event),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(Event event) {
    // Build the delete button
    return IconButton(
      onPressed: () {
        _showDeleteEventDialog(event);
      },
      icon: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).highlightColor,
        size: 27,
      ),
    );
  }

  void _showDeleteEventDialog(Event event) {
    // Show a dialog to confirm event deletion
    final dialog = CustomAlertDialog(
      title: "Delete ${event.name}",
      message: Text(
        "Do you wish to delete this event?",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onPostivePressed: () {
        Provider.of<EventsProvider>(context, listen: false).deleteEvent(event.id);
        Provider.of<AdditionsProvider>(context, listen: false).deleteAdditionsForEvent(event.id);
        context.pop();
      },
      positiveBtnText: "Delete",
      negativeBtnText: "Keep",
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  Widget _buildEditButton(Event event) {
    // Build the edit button
    return IconButton(
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) => EventFormPage(
            data: EventFormPageArguments(
              initialCourse: event,
            ),
          ),
        );
      },
      icon: Icon(
        Icons.edit_rounded,
        size: 27,
        color: event.getEventTheme.primary,
      ),
    );
  }

  Widget _buildEventInfo(Event event) {
    // Build the event type, title, time, and dates
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventTypeChip(event), // Event type chip
        const SizedBox(height: 5),
        _buildEventTitleAndTime(event), // Event title and time
        const SizedBox(height: MarginConstants.formHeightBetweenSection),
        _buildEventDates(event), // Event start and end dates
      ],
    );
  }

  Widget _buildEventTypeChip(Event event) {
    // Build the event type chip
    return Chip(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      backgroundColor: event.getEventTheme.secondary,
      avatar: Icon(
        CollegeData.eventTypeIcons[event.formalType.index],
        color: event.getEventTheme.primary,
        size: 20,
      ),
      label: Text(
        event.type,
        style: AppTextStyle.ptSansRegular(
          size: 16,
          color: event.getEventTheme.primary,
        ),
      ),
    );
  }

  Widget _buildEventTitleAndTime(Event event) {
    // Build the event title and time
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            event.name,
            style: AppTextStyle.ptSansBold(
              color: Theme.of(context).highlightColor,
              size: 30.0,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "${TimeHelper.timeToString(event.startTime, international)} - ${TimeHelper.timeToString(event.endTime, international)}",
              textAlign: TextAlign.center,
              style: AppTextStyle.ptSansRegular(
                size: 18.0,
                color: Theme.of(context).highlightColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              (event.repeatType != RepeatTypeEnum.once)
                  ? event.daysToString()
                  : DateFormat.yMMMd().format(event.dates.start),
              style: AppTextStyle.ptSansBold(
                color: Theme.of(context).highlightColor,
                size: 15.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventDates(Event event) {
    // Build event start and end dates
    return Row(
      children: [
        _buildCalendarIcon(Icons.calendar_today),
        _buildDateText("Start: ${DateFormat.MMMEd().format(event.dates.start)}"),
        _buildCalendarIcon(Icons.calendar_month_rounded),
        _buildDateText("End: ${DateFormat.MMMEd().format(event.dates.end)}"),
      ],
    );
  }

  Widget _buildCalendarIcon(IconData icon) {
    // Build a calendar icon
    return Icon(icon, size: 20, color: event.getEventTheme.primary);
  }

  Widget _buildDateText(String text) {
    // Build a date text
    return Text(
      text,
      style: AppTextStyle.ptSansBold(
        color: event.getEventTheme.primary,
        size: 16,
      ),
    );
  }

  Widget _buildEventDateProgress(Event event) {
    // Build the event date progress indicator
    return LinearPercentIndicator(
      lineHeight: 10,
      barRadius: const Radius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: Theme.of(context).dividerColor,
      percent: TimeHelper.getEventDatesPercentProgress(event),
      linearGradient: LinearGradient(
        colors: [
          event.getEventTheme.secondary,
          event.getEventTheme.primary,
        ],
      ),
    );
  }

  Widget _buildEventLocation(Event event) {
    // Build the event location container
    return EventLocationContainer(event: event);
  }

  Widget _buildEventTasks(Event event) {
    // Build the event tasks container
    return EventTasksContainer(
      event: event,
      tasks: Provider.of<AdditionsProvider>(context).getAdditionsForEventId(event.id),
    );
  }

  List<Widget> _buildLateTasksContainers(Event event) {
    // Build containers for late tasks
    final List<EventAddition> tasks = Provider.of<AdditionsProvider>(context)
        .getAdditionsForEventId(event.id)
        .where((element) => !element.finished && element.date.isBefore(TimeHelper.getNow()))
        .toList();

    return [
      Padding(
        padding: const EdgeInsets.all(MarginConstants.sideMargin),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: Theme.of(context).highlightColor,
              size: 25,
            ),
            const SizedBox(width: 10),
            Text(
              "${tasks.length} Late Tasks",
              style: AppTextStyle.ptSansBold(
                color: Theme.of(context).highlightColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 50,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            MarginConstants.sideMargin,
            0,
            MarginConstants.sideMargin,
            0,
          ),
          itemCount: tasks.length,
          scrollDirection: Axis.horizontal,
          separatorBuilder: ((context, index) {
            return const SizedBox(width: 10);
          }),
          itemBuilder: (context, index) {
            return EventLateTaskContainer(
              task: tasks[index],
              icon: CollegeData.additionTypeIcons[tasks[index].type.index],
            );
          },
        ),
      ),
    ];
  }
}

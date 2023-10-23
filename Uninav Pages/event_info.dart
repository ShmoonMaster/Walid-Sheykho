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

// This page is the event information page where the user can get details about the
// event they saved.
class EventInfoPage extends StatefulWidget {
  final EventInfoPageArguments? data;
  const EventInfoPage({Key? key, required this.data}) : super(key: key);

  static const String routeName = "EventInfoPage";

  @override
  State<EventInfoPage> createState() => _EventInfoPageState();
}

class _EventInfoPageState extends State<EventInfoPage> {
  late final EventInfoPageArguments _data;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _data = widget.data!;
    }
  }

  // Show dialog on failed event access error
  Widget _getNoEventErrorDialog() {
    return CustomAlertDialog(
        title: "No Event Found",
        message: Text("We could not find your event. Please try again.",
            style: AppTextStyle.ptSansRegular(
                color: Theme.of(context).highlightColor, size: 16)),
        positiveBtnText: "Okay",
        negativeBtnText: null,
        onPostivePressed: () {
          context.pop();
        },
        onNegativePressed: null);
  }

  // Show dialog for users before they delete events
  void _showDeleteEventDialog(EventsProvider provider, Event event) {
    var dialog = CustomAlertDialog(
        title: "Delete ${event.name}",
        message: Text("Do you wish to delete this event?",
            style: Theme.of(context).textTheme.bodyMedium),
        onPostivePressed: () {
          provider.deleteEvent(event.id);
          Provider.of<AdditionsProvider>(context, listen: false)
              .deleteAdditionsForEvent(event.id);
          context.pop();
        },
        onNegativePressed: null,
        positiveBtnText: "Delete",
        negativeBtnText: "Keep");
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  // Get list of containers for late tasks
  // Takes a list of tasks and builds the containers from them
  List<Widget> _buildLateTasksContainers(List<EventAddition> tasks) {
    DateTime now = TimeHelper.getNow();

    tasks = tasks
        .where((element) => !element.finished && element.date.isBefore(now))
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
            const SizedBox(
              width: 10,
            ),
            Text(
              "${tasks.length} Late Tasks",
              style: AppTextStyle.ptSansBold(
                  color: Theme.of(context).highlightColor, size: 20),
            )
          ],
        ),
      ),
      SizedBox(
        height: 50,
        child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
            itemCount: tasks.length,
            scrollDirection: Axis.horizontal,
            separatorBuilder: ((context, index) {
              return const SizedBox(
                width: 10,
              );
            }),
            itemBuilder: (context, index) {
              return EventLateTaskContainer(
                  task: tasks[index],
                  icon: CollegeData.additionTypeIcons[tasks[index].type.index]);
            }),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool international = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.international ??
        false;

    return Scaffold(
      body: Consumer<EventsProvider>(builder: (context, provider, child) {
        Event? event = provider.getEventWithId(_data.eventId);
        if (event == null) {
          return _getNoEventErrorDialog();
        }

        return Stack(
          children: [
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: const [0, .5],
              colors: [
                HSLColor.fromColor(event.getEventTheme.primary)
                    .withLightness(.95)
                    .toColor(),
                Colors.white,
              ],
            ))),
            Consumer<AdditionsProvider>(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    MarginConstants.sideMargin,
                    MediaQuery.of(context).padding.top,
                    MarginConstants.sideMargin,
                    0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 45,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: MyBackButton())),
                            IconButton(
                              onPressed: () {
                                _showDeleteEventDialog(provider, event);
                              },
                              icon: Icon(
                                Icons.delete_rounded,
                                color: Theme.of(context).highlightColor,
                                size: 27,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            IconButton(
                                onPressed: () {
                                  showCupertinoModalPopup(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          EventFormPage(
                                            data: EventFormPageArguments(
                                              initialCourse: event,
                                            ),
                                          ));
                                },
                                icon: Icon(
                                  Icons.edit_rounded,
                                  size: 27,
                                  color: event.getEventTheme.primary,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Chip(
                        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                        backgroundColor: event.getEventTheme.secondary,
                        avatar: Icon(
                          CollegeData.eventTypeIcons[event.formalType.index],
                          color: event.getEventTheme.primary,
                          size: 20,
                        ),
                        label: Text(event.type,
                            style: AppTextStyle.ptSansRegular(
                                size: 16, color: event.getEventTheme.primary)),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(event.name,
                                style: AppTextStyle.ptSansBold(
                                    color: Theme.of(context).highlightColor,
                                    size: 30.0)),
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
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                (event.repeatType != RepeatTypeEnum.once)
                                    ? event.daysToString()
                                    : DateFormat.yMMMd()
                                        .format(event.dates.start),
                                style: AppTextStyle.ptSansBold(
                                    color: Theme.of(context).highlightColor,
                                    size: 15.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: MarginConstants.formHeightBetweenSection,
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 20, color: event.getEventTheme.primary),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text(
                              DateFormat.MMMEd().format(event.dates.start),
                              style: AppTextStyle.ptSansBold(
                                  color: event.getEventTheme.primary, size: 16),
                            ),
                          ),
                          Icon(Icons.calendar_month_rounded,
                              size: 20, color: event.getEventTheme.primary),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            DateFormat.MMMEd().format(event.dates.end),
                            style: AppTextStyle.ptSansBold(
                                color: event.getEventTheme.primary, size: 16),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: MarginConstants.formHeightBetweenTitleText,
                      ),
                      LinearPercentIndicator(
                        lineHeight: 10,
                        barRadius: const Radius.circular(8),
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        backgroundColor: Theme.of(context).dividerColor,
                        percent: TimeHelper.getEventDatesPercentProgress(event),
                        linearGradient: LinearGradient(colors: [
                          event.getEventTheme.secondary,
                          event.getEventTheme.primary
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              builder: (context, additionProvider, child) {
                return Column(
                  children: [
                        child ?? const SizedBox(),
                        const SizedBox(
                          height: MarginConstants.formHeightBetweenTitleSection,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              MarginConstants.sideMargin,
                              0,
                              MarginConstants.sideMargin,
                              0),
                          child: EventLocationContainer(
                            event: event,
                          ),
                        ),
                        const SizedBox(
                          height: MarginConstants.formHeightBetweenSubsection,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              MarginConstants.sideMargin,
                              0,
                              MarginConstants.sideMargin,
                              0),
                          child: EventTasksContainer(
                              event: event,
                              tasks: additionProvider
                                  .getAdditionsForEventId(event.id)),
                        ),
                      ] +
                      _buildLateTasksContainers(
                          additionProvider.getAdditionsForEventId(event.id)),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

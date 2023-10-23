import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Databases/college_data.dart';
import 'dart:math' as math;
import 'package:uninav/Models/event_addition_model.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:uninav/Provider/additions_provider.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/point_network_helper.dart';
import 'package:uninav/Utilities/schedule_timing_helper.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/Home/home_curves.dart';
import 'package:uninav/Widgets/Home/my_events_widget.dart';
import 'package:uninav/Widgets/Home/my_tasks_widget.dart';
import 'package:uninav/Widgets/Home/my_university_widget.dart';
import 'package:uninav/Widgets/Home/next_event_widget.dart';
import 'package:uninav/Widgets/Home/no_more_events_widget.dart';
import 'package:uninav/Widgets/Home/prominent_event_location_widget.dart';
import 'package:uninav/Widgets/Home/prominent_event_widget.dart';
import 'package:uninav/Widgets/Home/quick_links_row_widget.dart';
import 'package:uninav/Widgets/Home/security_widget.dart';
import 'package:uninav/Widgets/Home/top_home_display.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationStatus { arrived, early, runningLate, toolate }

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  static const String routeName = "HomePage";

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const _minDistanceArrived = .03;
  static const double _topCurvesHeight = 250;

  final ScrollController _scrollController = ScrollController();
  final StreamController<double> _topHeightPercent = StreamController();
  final Stream<Position> _locationStream = Geolocator.getPositionStream();
  final ValueNotifier<bool> _notificationsOn = ValueNotifier(false);

  late bool _internationalTime;

  Position? _tempLocation;
  double _topheightVal = 1;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _checkNotificationPermissions();

    _scrollController.addListener(() async {
      if (_scrollController.offset <= _topCurvesHeight && _scrollController.offset >= 0) {
        _topHeightPercent.add((_topCurvesHeight - _scrollController.offset) / _topCurvesHeight);
      }
      if (_topheightVal != 0 && _scrollController.offset >= _topCurvesHeight) {
        _topHeightPercent.add(0);
      }
      if (_topheightVal != 1 && _scrollController.offset <= 0) {
        _topHeightPercent.add(1);
      }
    });

    _internationalTime = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.international ??
        false;
  }

  @override
  void dispose() {
    _locationStream.drain();
    _scrollController.dispose();
    _topHeightPercent.close();
    _notificationsOn.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _tempLocation = await Geolocator.getCurrentPosition();
    _notificationsOn.value = await _checkAcceptingNotificationsPreference();
  }

  Future<bool> _checkAcceptingNotificationsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("notification") ?? true;
  }

  void _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    if (mounted) {
      setState(() {});
    }
  }

  void _checkNotificationPermissions() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  // This function takes a url, and launches a browser of the given
  // page from the parameter.
  Future<void> _launchUrl(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  Consumer _taskWidget() {
    return Consumer<AdditionsProvider>(builder: (context, provider, child) {
      List<EventAddition> data = provider.getAllAdditions;
      data.sort(((a, b) => a.date.compareTo(b.date)));
      List<EventAddition> finishedAdditions =
          data.where((element) => !element.finished).toList();
      return MyTasksWidget(
        exams: data
            .where((element) =>
                element.type == EventAdditionType.exam && element.finished)
            .length,
        examTotal: data
            .where((element) => element.type == EventAdditionType.exam)
            .length,
        assignments: data
            .where((element) =>
                element.type == EventAdditionType.assignment &&
                element.finished)
            .length,
        assignmentTotal: data
            .where((element) => element.type == EventAdditionType.assignment)
            .length,
        meetings: data
            .where((element) =>
                element.type == EventAdditionType.meeting && element.finished)
            .length,
        meetingTotal: data
            .where((element) => element.type == EventAdditionType.meeting)
            .length,
        total: data.length,
        topFiveAdditions:
            finishedAdditions.sublist(0, math.min(5, finishedAdditions.length)),
      );
    });
  }

  // Gets the consumer for the events that will be displayed
  Consumer _eventsWidget() {
    return Consumer<EventsProvider>(
      key: const Key("Events Consumer"),
      builder: (context, snapshot, child) {
      DateTime now = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      List<Event> eventsTotal = snapshot.getAllEvents
          .where((element) =>
              element.dates.start.isBefore(now) &&
              element.dates.end
                  .isAfter(DateTime(now.year, now.month, now.day - 1)))
          .toList();

      return MyEventsWidget(
        key: const Key("MyEventsWidget"),
        totalEvents: eventsTotal.length,
        courseEvents: eventsTotal
            .where((element) => element.formalType == FormalTypeEnum.course)
            .length,
        activityEvents: eventsTotal
            .where((element) => element.formalType == FormalTypeEnum.activity)
            .length,
        jobEvents: eventsTotal
            .where((element) => element.formalType == FormalTypeEnum.job)
            .length,
      );
    });
  }

  // Gets the rest of the widgets for the home page
  List<Widget> get _getHomePageWidgets {
    List<Widget> homeWidgets = [];
    const SizedBox smallSpacingBox = SizedBox(
      height: MarginConstants.formHeightBetweenTitleSection,
    );
    const SizedBox spacingBox = SizedBox(
      height: MarginConstants.formHeightBetweenSection,
    );
    homeWidgets.addAll([smallSpacingBox, _eventsWidget()]);
    homeWidgets.addAll([smallSpacingBox, _taskWidget()]);
    homeWidgets.addAll([spacingBox, QuickLinksRow(launchUrl: _launchUrl)]);
    homeWidgets.addAll([
      spacingBox,
      MyUniversityWidget(
          universityName: CollegeData.universitySeattleWashingtonInfoData[0],
          universityImageName:
              CollegeData.universitySeattleWashingtonInfoData[1],
          universityHours: CollegeData.universitySeattleWashingtonInfoData[2],
          universityAddress: CollegeData.universitySeattleWashingtonInfoData[3],
          universityNumber: CollegeData.universitySeattleWashingtonInfoData[4],
          color: CollegeData.universitySeattleWashingtonInfoData[5])
    ]);

    homeWidgets.addAll(
        [spacingBox, const SecurityWidget(securityPhoneNumber: "2065230507")]);

    return homeWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(key: const Key("topStack"), children: [
        Align(
          alignment: Alignment.topCenter,
          child: NotificationListener<ScrollNotification>(
            onNotification: (onNotification) {
              if (onNotification is ScrollEndNotification) {
                if (_scrollController.offset / _topCurvesHeight < .5 &&
                    _scrollController.offset > 0) {
                  Future.delayed(const Duration(milliseconds: 1)).then((value) {
                    _scrollController.animateTo(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  });
                } else if (_scrollController.offset / _topCurvesHeight < 1 &&
                    _scrollController.offset / _topCurvesHeight >= .5) {
                  Future.delayed(const Duration(milliseconds: 1)).then((value) {
                    _scrollController.animateTo(_topCurvesHeight,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  });
                }
              }
              return true;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                      SizedBox(
                        height: MediaQuery.of(context).padding.top + _topCurvesHeight + 90,
                      ),
                      Consumer<EventsProvider>(
                          builder: (context, snapshot, child) {
                        Event? promEvent = snapshot.getProminentEvent(null);
                        Event? nextEvent;

                        List<Widget> widgets = [];

                        if (promEvent != null) {
                          final bool inProgress = TimeHelper.inProgress(
                              promEvent.startTime, promEvent.endTime);

                          if (inProgress) {
                            nextEvent =
                                snapshot.getProminentEvent(promEvent.id);
                          }

                          widgets.add(
                            ProminentEventWidget(
                              event: promEvent,
                              inProgress: inProgress,
                              internationalTime: _internationalTime,
                            ),
                          );
                          widgets.add(
                            const SizedBox(
                              height: 5,
                            ),
                          );
                          widgets.add(StreamBuilder<Position>(
                              stream: _locationStream,
                              initialData: _tempLocation,
                              builder: (context, snapshot) {
                                if (snapshot.data == null) {
                                  return ProminentEventLocationWidget(
                                      event: promEvent);
                                }

                                Position data = snapshot.data!;

                                final LatLng location = data.toLatLng;
                                final double distance = (!promEvent.isOnline)
                                    ? PointNetworkHelper
                                        .getMilesDistanceBetweenPoints(location,
                                            promEvent.locationCoordinate!)
                                    : -1;
                                final int minutesRemain =
                                    ScheduleTimingHelper.minutesRemaining(
                                        promEvent, location);
                                LocationStatus status;
                                if (distance <= _minDistanceArrived) {
                                  status = LocationStatus.arrived;
                                } else if (minutesRemain < 0 &&
                                    minutesRemain.abs() >
                                        TimeHelper.getNumberMinutesBetween(
                                            promEvent.startTime,
                                            promEvent.endTime)) {
                                  status = LocationStatus.toolate;
                                } else if (minutesRemain < 0) {
                                  status = LocationStatus.runningLate;
                                } else {
                                  status = LocationStatus.early;
                                }

                                return ProminentEventLocationWidget(
                                    event: promEvent,
                                    data: ProminentEventLocationWidgetExtraData(
                                      status: status,
                                      minutesRemain: minutesRemain,
                                      distance: distance,
                                      locationData: location,
                                    ));
                              }));
                        } else {
                          widgets.add(const NoMoreEvents());
                        }

                        if (nextEvent != null) {
                          widgets.add(Padding(
                            padding: const EdgeInsets.fromLTRB(MarginConstants.sideMargin, 0, MarginConstants.sideMargin, 0),
                            child: NextEventContainer(
                              internationalTime: _internationalTime,
                              event: nextEvent,
                            ),
                          ));
                        }
                        widgets.add(const SizedBox(
                          height: 15,
                        ));
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widgets,
                        );
                      }),
                    ] +
                    _getHomePageWidgets,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: StreamBuilder<double>(
                stream: _topHeightPercent.stream,
                builder: (context, snapshot) {
                  _topheightVal = snapshot.data ?? 1;
                  return Stack(children: [
                    CustomPaint(
                      painter: HomeCurves(
                          frontColor: Theme.of(context).colorScheme.primary,
                          backColor: Theme.of(context).colorScheme.secondary,
                          percent: snapshot.data ?? 1),
                      child: Container(
                        height: MediaQuery.of(context).padding.top + _topCurvesHeight,
                      ),
                    ),
                    Consumer<EventsProvider>(
                        child: Container(
                            height: MediaQuery.of(context).padding.top + _topCurvesHeight),
                        builder: (context, events, child) {
                          DateTime now = DateTime(DateTime.now().year,
                              DateTime.now().month, DateTime.now().day);
                          return CustomPaint(
                            painter: TopHomeDisplay(
                                // This gets the number of events today
                                events: events
                                    .getEventsOnDate(
                                        DateTime(now.year, now.month, now.day),
                                        events.getAllEvents)
                                    .length,
                                percent: snapshot.data ?? 1,
                                primary: Theme.of(context).colorScheme.primary,
                                secondary:
                                    Theme.of(context).colorScheme.secondary),
                            child: child,
                          );
                        })
                  ]);
                }),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                MarginConstants.sideMargin, MediaQuery.of(context).padding.top + 10, MarginConstants.sideMargin, 0),
            child: GestureDetector(
              onTap: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(bottom: MarginConstants.sideMargin),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${AppLocalizations.of(context)!.hello} ${Provider.of<UserProvider>(context).getUserData?.name},",
                        style: AppTextStyle.ptSansRegular(
                            color: Colors.white, size: 20.0),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notification',
                            !(await _checkAcceptingNotificationsPreference()));
                      },
                      icon: ValueListenableBuilder(
                          valueListenable: _notificationsOn,
                          builder: (context, val, child) {
                            return Icon(
                                (val != null && val as bool)
                                    ? Icons.notifications
                                    : Icons.notifications_outlined,
                                size: 30,
                                color: Colors.white);
                          }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

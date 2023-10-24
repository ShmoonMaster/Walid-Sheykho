import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:uninav/Models/campus_event.dart';
import 'package:uninav/Screens/Mapping/navigation_page.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/asset_manager.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/network_helper.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'package:uninav/Widgets/sheet_bar_handle.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LiveEventInfoPage extends StatefulWidget {
  final CampusEvent event;
  const LiveEventInfoPage({Key? key, required this.event}) : super(key: key);

  static const double pageHeight = 750;

  @override
  State<LiveEventInfoPage> createState() => _LiveEventInfoPageState();
}

class _LiveEventInfoPageState extends State<LiveEventInfoPage>
    with SingleTickerProviderStateMixin {
  static const _locationMarkerPath = "assets/images/Campus/locMapIcon.png";

  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;
  late final Future<FocusedTimeDistanceMatrix?> _matrix;
  late final Future<Marker> _locationMarker;
  late final String _mapStyle;

  final TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 0);

  late CampusEvent _event;

  Position? _curLoc;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _matrix = _setDistanceMatrix();
    _event = widget.event;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _colorAnimation = ColorTween(
            begin: const Color.fromARGB(255, 0, 132, 239), end: Colors.white)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.addStatusListener((status) {
      setState(() {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    });

    rootBundle.loadString('assets/main_map_style.txt').then((string) {
      _mapStyle = string;
    });

    _locationMarker = AssetManager.getIconFromString(_locationMarkerPath).then(
        (value) => Future.value(Marker(
            markerId: const MarkerId("loc"),
            icon: value,
            position: _event.loc)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_mapController != null) {
      _mapController!.dispose();
    }

    super.dispose();
  }

  // This function sets the time distance matrix based on the current location
  // and the coordinates of the location on the page.
  // rType: Future (TimeDistanceMatrix)
  Future<FocusedTimeDistanceMatrix?> _setDistanceMatrix() async {
    _curLoc = await Geolocator.getCurrentPosition();
    return await NetworkHelper().getMatrixData(
        retry: 2,
        pathParam: ORSProfile.footWalking,
        startLng: _curLoc!.longitude,
        startLat: _curLoc!.latitude,
        endLng: _event.loc.longitude,
        endLat: _event.loc.latitude);
  }

  String get _getOrganizationString {
    return _event.org ?? "No Organization";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15))),
            padding: const EdgeInsets.all(15),
            child: SafeArea(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SheetBarHandle(),
                      ],
                    ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: MarginConstants.formHeightBetweenSubsection,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _event.name,
                                  maxLines: 2,
                                  style: AppTextStyle.ptSansRegular(
                                      size: 25, color: Colors.black),
                                ),
                              ),
                              PopupMenuButton(
                                  elevation: 0,
                                  offset: const Offset(-40, 10),
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                                  color: Theme.of(context).cardColor,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          bottomLeft: Radius.circular(15),
                                          bottomRight: Radius.circular(15))),
                                  itemBuilder: (context) {
                                    return [
                                      PopupMenuItem(
                                          onTap: () async {
                                            NetworkHelper()
                                                .getNextTwoWeeksOrPreviousLastWeekEvents()
                                                .then((value) {
                                              try {
                                                CampusEvent newEvent = value
                                                    .where((element) =>
                                                        element.id == _event.id)
                                                    .first;
                                                setState(() {
                                                  _event = newEvent;
                                                });
                                              } catch (e) {
                                                // no udpate
                                              }
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 25,
                                                child: Icon(
                                                  Icons.refresh_rounded,
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  size: 25,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Update",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge,
                                              )
                                            ],
                                          )),
                                      if (_event.link != null)
                                        PopupMenuItem(
                                            onTap: () async {
                                              if (await canLaunchUrlString(
                                                  _event.link ?? "")) {
                                                launchUrlString(
                                                    _event.link ?? "");
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                const SizedBox(
                                                  width: 25,
                                                  child: Icon(
                                                    Icons.link_rounded,
                                                    color: Colors.blue,
                                                    size: 25,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  "Open Link",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge,
                                                )
                                              ],
                                            )),
                                    ];
                                  }),
                            ],
                          ),
                          const SizedBox(
                            height: MarginConstants.formHeightBetweenTitleText,
                          ),
                          Text(
                            _getOrganizationString,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ]),
                    Divider(
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                      height: MarginConstants.formHeightBetweenSubsection,
                    ),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: (_event.date.isAfter(DateTime.now()))
                                ? Colors.green
                                : Colors.red,
                            size: 25),
                        const SizedBox(
                          width: MarginConstants.formHeightBetweenTitleSection,
                        ),
                        Flexible(
                          child: Text(
                            "${DateFormat.yMd().add_jm().format(_event.date)} • ${TimeHelper.formattedTimeBetweenTwoDates(_event.date, DateTime.now())}",
                            maxLines: 2,
                            style: AppTextStyle.ptSansMedium(
                                color: (_event.date.isAfter(DateTime.now()))
                                    ? Colors.green
                                    : Colors.red,
                                size: 16),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Icon(Icons.pin_drop_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 25),
                        const SizedBox(
                          width: 15,
                        ),
                        Flexible(
                          child: Text(
                            _event.locName ?? "Unknown",
                            maxLines: 2,
                            style: AppTextStyle.ptSansMedium(
                                color: Theme.of(context).colorScheme.primary,
                                size: 16),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Icon(Icons.meeting_room_rounded,
                            color: Theme.of(context).highlightColor, size: 25),
                        const SizedBox(
                          width: 15,
                        ),
                        Flexible(
                          child: Text(
                            _event.room ?? "Unknown",
                            maxLines: 2,
                            style: AppTextStyle.ptSansRegular(
                                color: Theme.of(context).highlightColor,
                                size: 16),
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        height: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: FutureBuilder<Marker>(
                              future: _locationMarker,
                              builder: (context, snapshot) {
                                return GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                      target: _event.loc, zoom: 16),
                                  trafficEnabled: true,
                                  zoomControlsEnabled: false,
                                  buildingsEnabled: false,
                                  mapToolbarEnabled: false,
                                  mapType: MapType.normal,
                                  compassEnabled: false,
                                  rotateGesturesEnabled: false,
                                  scrollGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  zoomGesturesEnabled: false,
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: false,
                                  onMapCreated: (controller) {
                                    if (mounted) {
                                      _mapController = controller;
                                      controller.setMapStyle(_mapStyle);
                                    }
                                  },
                                  markers: snapshot.data == null
                                      ? {}
                                      : {snapshot.data!},
                                );
                              }),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Divider(
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                      height: 1,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            _event.notes ?? "No Notes",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                      height: 1,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    FutureBuilder(
                        future: _matrix,
                        builder: (context,
                            AsyncSnapshot<FocusedTimeDistanceMatrix?> matrix) {
                          String topText = "";
                          String bottomText = "";

                          if (matrix.data != null) {
                            int min = matrix.data!.minutes.toInt();
                            if (min > 59) {
                              topText += "${min ~/ 60} hr ";
                            }
                            topText += "${min % 60} min";
                            double dist =
                                (matrix.data!.miles.toDouble() * 100).toInt() /
                                    100;
                            bottomText += "$dist mi";
                          }

                          return AnimatedBuilder(
                              animation: _controller,
                              child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showCupertinoDialog<void>(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (BuildContext context) {
                                        return NavigationPage(
                                            data: NavigationPageArguments(
                                                locationName:
                                                    widget.event.locName ??
                                                        _event.loc.toString(),
                                                coordinate: _event.loc,
                                                initialPosition: LatLng(
                                                    _curLoc?.latitude ?? 0,
                                                    _curLoc?.longitude ?? 0)));
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    fixedSize: const Size(double.maxFinite, 50),
                                    splashFactory: NoSplash.splashFactory,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.directions_outlined,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    size: 35,
                                  )),
                              builder: (context, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.timer_outlined,
                                          size: 25, color: Colors.blue),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      (matrix.data == null)
                                          ? Icon(
                                              Icons.more_horiz_rounded,
                                              size: 22,
                                              color: _colorAnimation.value,
                                            )
                                          : Text(topText,
                                              style: AppTextStyle.ptSansBold(
                                                  size: 20,
                                                  color: Colors.blue)),
                                    ]),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.moving_rounded,
                                          size: 22,
                                          color:
                                              Theme.of(context).disabledColor,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        (matrix.data == null)
                                            ? Icon(
                                                Icons.more_horiz_rounded,
                                                size: 22,
                                                color: _colorAnimation.value,
                                              )
                                            : Text(bottomText,
                                                style:
                                                    AppTextStyle.ptSansMedium(
                                                        size: 17,
                                                        color: Theme.of(context)
                                                            .highlightColor)),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    child ?? const SizedBox()
                                  ],
                                );
                              });
                        }),
                    const SizedBox(
                      height: 15,
                    )
                  ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: getCampusEventColors(_event.type)[1],
            ),
            alignment: Alignment.center,
            child: Icon(
              getCampusEventTypeIcon(_event.type),
              color: getCampusEventColors(_event.type)[0],
              size: 20,
            ),
          ),
        )
      ],
    );
  }
}

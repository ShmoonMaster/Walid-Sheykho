import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Mapping/navigation_page.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/asset_manager.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/image_network_helper.dart';
import 'package:uninav/Utilities/network_helper.dart';
import 'package:uninav/Widgets/sheet_bar_handle.dart';

class LocationInfo extends StatefulWidget {
  final String name;
  final LatLng coordinate;
  final Set<String> locKeys;
  final Polygon? polygon;
  final Position? location;
  final FocusedTimeDistanceMatrix? matrixData;
  const LocationInfo(
      {Key? key,
      required this.name,
      required this.coordinate,
      required this.locKeys,
      this.polygon,
      this.matrixData,
      this.location})
      : super(key: key);

  static const double pageHeight = 575;

  @override
  State<LocationInfo> createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo>
    with SingleTickerProviderStateMixin {
  static const _locationMarkerPath = "assets/images/Campus/locMapIcon.png";

  late final Future<FocusedTimeDistanceMatrix?> _matrix;
  late final Future<Image?> _locImage;
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;
  late final Future<Marker> _locationMarker;
  late final String _mapStyle;

  final TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 0);

  Position? _curLoc;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _matrix = _setDistanceMatrix();
    _locImage = ImageNetworkHelper.getCampusLocationImage(
        Provider.of<UserProvider>(context, listen: false)
            .getCampusServerImagePath,
        widget.name);
    _curLoc = widget.location;
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
            position: widget.coordinate)));

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
        endLng: widget.coordinate.longitude,
        endLat: widget.coordinate.latitude);
  }

  String get _getLocationKeysString {
    String tempString = "";
    for (String key in widget.locKeys) {
      tempString += "$key • ";
    }
    return tempString.substring(0, tempString.length - 3);
  }

  bool get _getFavoritePreference {
    return Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.favorites
            .toList()
            .contains(widget.name) ??
        false;
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
            padding: const EdgeInsets.all(MarginConstants.sideMargin),
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
                    const SizedBox(
                      height: MarginConstants.formHeightBetweenSubsection,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.name,
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
                                    onTap: () {
                                      setState(() {
                                        Provider.of<UserProvider>(context,
                                                listen: false)
                                            .setFavorite(widget.name);
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 25,
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            color: Color.fromARGB(
                                                255, 255, 64, 86),
                                            size: 25,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          "Favorite",
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
                      _getLocationKeysString,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: MarginConstants.formHeightBetweenSubsection),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FutureBuilder<Marker>(
                            future: _locationMarker,
                            builder: (context, snapshot) {
                              return GoogleMap(
                                initialCameraPosition: CameraPosition(
                                    target: widget.coordinate,
                                    zoom: (widget.polygon != null) ? 17.5 : 16),
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
                                polygons: (widget.polygon != null)
                                    ? {widget.polygon!}
                                    : {},
                                markers: snapshot.data == null ||
                                        widget.polygon != null
                                    ? {}
                                    : {snapshot.data!},
                              );
                            }),
                      ),
                    ),
                    const SizedBox(height: MarginConstants.formHeightBetweenSubsection),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<Image?>(
                            future: _locImage,
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                return Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Theme.of(context).cardColor),
                                  clipBehavior: Clip.hardEdge,
                                );
                              }
                              Image image = snapshot.data!;

                              return Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: image,
                              );
                            }),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child: FutureBuilder(
                              future: _matrix,
                              initialData: widget.matrixData,
                              builder: (context,
                                  AsyncSnapshot<FocusedTimeDistanceMatrix?>
                                      matrix) {
                                String topText = "";
                                String bottomText = "";

                                if (matrix.data != null) {
                                  int min = matrix.data!.minutes.toInt();
                                  if (min > 59) {
                                    topText += "${min ~/ 60} hr ";
                                  }
                                  topText += "${min % 60} min";
                                  double dist =
                                      (matrix.data!.miles.toDouble() * 100)
                                              .toInt() /
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
                                                      locationName: widget.name,
                                                      coordinate:
                                                          widget.coordinate,
                                                      initialPosition: LatLng(
                                                          _curLoc?.latitude ??
                                                              widget.location
                                                                  ?.latitude ??
                                                              0,
                                                          _curLoc?.longitude ??
                                                              widget.location
                                                                  ?.longitude ??
                                                              0)));
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          fixedSize:
                                              const Size(double.maxFinite, 50),
                                          splashFactory: NoSplash.splashFactory,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          size: 35,
                                        )),
                                    builder: (context, child) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                    color:
                                                        _colorAnimation.value,
                                                  )
                                                : Text(topText,
                                                    style:
                                                        AppTextStyle.ptSansBold(
                                                            size: 20,
                                                            color:
                                                                Colors.blue)),
                                          ]),
                                          const SizedBox(
                                            height: MarginConstants.formHeightBetweenTitleText,
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.moving_rounded,
                                                size: 22,
                                                color: Theme.of(context)
                                                    .disabledColor,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              (matrix.data == null)
                                                  ? Icon(
                                                      Icons.more_horiz_rounded,
                                                      size: 22,
                                                      color:
                                                          _colorAnimation.value,
                                                    )
                                                  : Text(bottomText,
                                                      style: AppTextStyle
                                                          .ptSansMedium(
                                                              size: 17,
                                                              color: Theme.of(
                                                                      context)
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
                        ),
                      ],
                    ),
                  ]),
            ),
          ),
        ),
        if (_getFavoritePreference) Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 255, 197, 193),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              )
      ],
    );
  }
}

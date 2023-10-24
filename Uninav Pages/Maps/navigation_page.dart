import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Models/location_matrix_model.dart';
import 'package:uninav/Models/navigation_step_model.dart';
import 'package:uninav/Provider/navigation_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/asset_manager.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/point_network_helper.dart';
import 'package:uninav/Utilities/time_manager.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:uninav/Widgets/Mapping/navigation_buttons_delegate.dart';

class NavigationPageArguments {
  final LatLng coordinate;
  final LatLng initialPosition;
  final String locationName;
  final String? locationRoom;
  const NavigationPageArguments(
      {required this.coordinate,
      required this.initialPosition,
      required this.locationName,
      this.locationRoom});
}

class NavigationPage extends StatefulWidget {
  final NavigationPageArguments data;
  const NavigationPage({Key? key, required this.data}) : super(key: key);

  static const String routeName = "NavigationPage";

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with SingleTickerProviderStateMixin {
  static const double _curZoom = 20.0;

  late final AnimationController _navigationButtonAnimation;
  late NavigationProvider? _provider;
  late final StreamSubscription<Position> _locationSubscription;
  late final String _mapStyle;
  late final Future<Marker> _marker;

  GoogleMapController? _controller;
  Position? _locationData;
  double _curBearing = 0.0;
  double _targetBrearing = 0.0;
  bool _navMenuStatus = false;
  bool _navigationTrackingMode = true;

  @override
  void initState() {
    super.initState();
    _navigationButtonAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _provider = NavigationProvider(
        start: widget.data.initialPosition, target: widget.data.coordinate);

    rootBundle.loadString('assets/main_map_style.txt').then((string) {
      _mapStyle = string;
    });

    _locationSubscription = Geolocator.getPositionStream().listen((l) {
      _locationData = l;
      _targetBrearing = l.heading;
      double change = (((_targetBrearing - _curBearing) + 540) % 360) - 180;

      if (change.isNegative) {
        _curBearing += math.max(change, -15);
      } else {
        _curBearing += math.min(change, 15);
      }

      double metersUntil = 0;

      if (_provider != null && _provider?.currentLines != null) {
        metersUntil = _provider!.checkStepStatus(l.toLatLng);
      }

      if (!_navigationTrackingMode || _controller == null) {
        return;
      }

      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(l.latitude, l.longitude),
              zoom: _curZoom - metersUntil / 200,
              bearing: _curBearing),
        ),
      );
    });

    _marker =
        AssetManager.getIconFromString('assets/images/Campus/locMapIcon.png')
            .then((value) => Marker(
                markerId: const MarkerId("location"),
                icon: value,
                position: widget.data.coordinate));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    _navigationButtonAnimation.dispose();

    if (_controller != null) {
      _controller!.dispose();
    }

    if (_provider != null) {
      _provider!.dispose();
      _provider = null;
    }

    super.dispose();
  }

  void _closePage() {
    Provider.of<UserProvider>(context, listen: false).setNaviation(false);
    context.pop();
  }

  // This function takes in a position, a current bool and an optional zoom variable,
  // and makes the map change position to the given coordinate.
  void _goToPosition(LatLng position, bool current, [double zoom = 19]) async {
    if (_controller == null) {
      return;
    }
    _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: position,
        bearing: 0.0,
        tilt: (current) ? 15.0 : 0.0,
        zoom: zoom)));
    if (current && mounted) {
      setState(() {
        _navigationTrackingMode = true;
      });
    }
  }

  Padding _buildNavigationButton(
      int index, IconData icon, Color primary, Color container) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ElevatedButton(
        onPressed: () {
          switch (index) {
            case 0:
              if (mounted) {
                _closePage();
              }
              break;
            case 1:
              _goToPosition(widget.data.coordinate, false);
              if (_navigationTrackingMode && mounted) {
                setState(() {
                  _navigationTrackingMode = false;
                });
              }
              break;
            case 2:
              if (_locationData == null) {
                return;
              }
              _goToPosition(
                  LatLng(_locationData!.latitude, _locationData!.longitude),
                  true);
              break;
            default:
              print('nothing');
          }
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: container,
            alignment: Alignment.center,
            maximumSize: const Size(55, 55),
            minimumSize: const Size(55, 55),
            padding: const EdgeInsets.all(0),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        child: Transform.rotate(
          angle: math.pi,
          child: Icon(
            icon,
            size: 30,
            color: primary,
          ),
        ),
      ),
    );
  }

  Column _buildTopNavigation(
      BuildContext context, NavigationStep primaryStep, LocationMatrix matrix) {
    bool international = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.international ??
        false;
    return Column(
      children: [
        Container(
            clipBehavior: Clip.hardEdge,
            padding: EdgeInsets.fromLTRB(
                MarginConstants.standardInternalMargin, MediaQuery.of(context).padding.top + MarginConstants.standardInternalMargin, MarginConstants.standardInternalMargin, MarginConstants.standardInternalMargin),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: Color.fromARGB(255, 82, 82, 82)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primaryStep.instruction,
                  style: AppTextStyle.ptSansBold(color: Colors.white, size: 25),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.moving_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                        "${primaryStep.distance} m • ${(primaryStep.duration * math.pow(10, 2).toInt()).round() / math.pow(10, 2).toInt()} min",
                        style: AppTextStyle.ptSansMedium(size: 16)),
                  ],
                ),
              ],
            )),
        Padding(
          padding: const EdgeInsets.all(MarginConstants.sideMargin),
          child: Container(
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.all(MarginConstants.standardInternalMargin),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), color: Colors.green),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.pin_drop_rounded,
                      color: Color.fromARGB(255, 255, 255, 255), size: 20),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                      widget.data.locationName.substring(
                          0,
                          (widget.data.locationName.contains(" - "))
                              ? widget.data.locationName.indexOf(" - ")
                              : 4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.ptSansRegular(size: 18)),
                ),
                const Icon(Icons.directions_walk_outlined,
                    color: Color.fromARGB(255, 255, 255, 255), size: 20),
                const SizedBox(
                  width: 5,
                ),
                Text(
                    "${TimeHelper.timeToString(matrix.time, international)} • ${(matrix.distance * math.pow(10, 2).toInt()).round() / math.pow(10, 2).toInt()} mi",
                    style: AppTextStyle.ptSansBold(size: 16))
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        90;
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: ChangeNotifierProvider.value(
        value: _provider,
        child: Scaffold(
          body: Consumer<NavigationProvider>(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + MarginConstants.sideMargin,
                      right: MarginConstants.sideMargin),
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Flow(
                      delegate: NavigationButtonsDelegate(
                          animation: _navigationButtonAnimation),
                      children: <Widget>[
                        _buildNavigationButton(
                            2,
                            (_navigationTrackingMode)
                                ? Icons.navigation_rounded
                                : Icons.navigation_outlined,
                            Colors.blue,
                            Colors.blue[100]!),
                        _buildNavigationButton(
                            1,
                            Icons.pin_drop_outlined,
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer),
                        _buildNavigationButton(
                            0, Icons.cancel, Colors.red, Colors.red[100]!),
                        GestureDetector(
                          onTap: () {
                            _navigationButtonAnimation.status ==
                                    AnimationStatus.completed
                                ? _navigationButtonAnimation.reverse()
                                : _navigationButtonAnimation.forward();
                            if (mounted) {
                              setState(() {
                                _navMenuStatus = !_navMenuStatus;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 55,
                              height: 55,
                              padding:
                                  EdgeInsets.all((_navMenuStatus) ? 5 : 8.0),
                              decoration: BoxDecoration(
                                color: (_navMenuStatus)
                                    ? Colors.black
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: AnimatedRotation(
                                duration: const Duration(milliseconds: 150),
                                turns: (!_navMenuStatus) ? -.25 : .25,
                                child: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 30,
                                  color: (!_navMenuStatus)
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              builder: (context, snapshot, child) {
                if (snapshot.getPolyline.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitChasingDots(
                          color: Theme.of(context).colorScheme.primary,
                          size: 40,
                        ),
                        IconButton(
                            onPressed: () {
                              _closePage();
                            },
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: Theme.of(context).disabledColor,
                              size: 30,
                            ))
                      ],
                    ),
                  );
                }
                return Stack(children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: availableHeight,
                      child: Listener(
                        onPointerMove: (move) {
                          if (mounted && _navigationTrackingMode) {
                            setState(() {
                              _navigationTrackingMode = false;
                            });
                          }
                        },
                        child: FutureBuilder<Marker>(
                            future: _marker,
                            builder: (context, markerSnapshot) {
                              return GoogleMap(
                                padding: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                            MarginConstants.sideMargin),
                                trafficEnabled: true,
                                zoomControlsEnabled: false,
                                mapType: MapType.normal,
                                initialCameraPosition: CameraPosition(
                                  target: (_locationData != null)
                                      ? LatLng(_locationData!.latitude,
                                          _locationData!.longitude)
                                      : widget.data.initialPosition,
                                  zoom: _curZoom,
                                  bearing: _curBearing,
                                ),
                                onMapCreated: ((controller) {
                                  if (mounted) {
                                    _controller = controller;
                                    controller.setMapStyle(_mapStyle);
                                  }
                                }),
                                // onTap: ((argument) {
                                //   provider?.checkStepStatus(argument);
                                // }),
                                compassEnabled: false,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                markers: markerSnapshot.hasData
                                    ? {markerSnapshot.data!}
                                    : {},
                                circles: snapshot.circles,
                                polylines: snapshot.getPolyline,
                              );
                            }),
                      ),
                    ),
                  ),
                  child ?? const SizedBox(),
                  Align(
                    alignment: Alignment.topCenter,
                    child: _buildTopNavigation(
                        context, snapshot.getPromStep, snapshot.getNavMatrix),
                  ),
                ]);
              }),
        ),
      ),
    );
  }
}

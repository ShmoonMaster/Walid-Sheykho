import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Databases/campus_data_provider_local.dart';
import 'package:uninav/Databases/college_data.dart';
import 'package:uninav/Models/campus_event.dart';
import 'package:uninav/Models/event_model.dart';
import 'package:uninav/Provider/events_provider.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Screens/Mapping/search_location_page.dart';
import 'package:uninav/Utilities/asset_manager.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/map_page_helper.dart';
import 'package:uninav/Utilities/network_helper.dart';
import 'package:uninav/Widgets/Mapping/location_chip.dart';
import 'package:uninav/Widgets/Mapping/map_toggle_button.dart';
import 'package:uninav/Widgets/Mapping/multiple_events_subpage.dart';
import 'package:uninav/Widgets/Mapping/navigation_chips_bar.dart';
import 'package:uninav/Widgets/transitions.dart';

// This class is the maps page that shows info about the schedule and the campus of the user.
class MapsPage extends StatefulWidget {
  final String? locKey;
  const MapsPage({Key? key, this.locKey}) : super(key: key);

  static const String routeName = "MapPage";

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage>
    with SingleTickerProviderStateMixin {
  static const int _totalLocationKeyCount = 8;
  static const double _curZoom = 19.0;
  static const double _curBearing = 0.0;
  static const double _navigationBarHeight = 125;

  late final AnimationController _loadingLiveChipsAnimationController;
  late final Animation<double?> _colorAnimationValue;
  late final CampusDataProviderLocal _campusDataProviderLocal;
  late final String _mapStyle;
  late final StreamSubscription<Position> _locationSubscription;

  final Set<Circle> _scheduleCircles = HashSet<Circle>();
  final Set<Circle> _liveEventCircles = HashSet<Circle>();
  final Set<Polygon> _campusBuildingPolygons = HashSet<Polygon>();
  final Set<Polyline> _lines = HashSet<Polyline>();
  final Set<Marker> _scheduleMarkers = {};
  final Map<String, List<Marker>> _campusMarkers = {};
  final List<int> _selectedLocations = Uint8List(_totalLocationKeyCount);

  // This is data that dictates the UI of the page and navigation container
  bool _navigationTrackingMode = false;
  double _topPadding = 0;
  int _chosenMapTypeIndex = 0;
  int _chosenEventIndex = -1;
  int _chosenLiveEventIndex = -1;
  bool _showCampusPolygons = true;
  bool _selectedFirstLocationItem = true;

  //location data and objects for the map
  GoogleMapController? _controller;
  Position? _locationData;
  List<CampusEvent>? _liveEvents;
  Map<int, List<Marker>>? _liveEventMarkers;
  BitmapDescriptor? _multipleEventsMarker;
  Map<MapIconType, BitmapDescriptor> _campusMarkerAssets = {};
  Map<CampusEventType, BitmapDescriptor> _liveEventMarkerAssets = {};
  Map<int, BitmapDescriptor> _scheduleAssets = {};
  DateTime _lastLiveEventQueriedTime = DateTime.now();
  List<Event> _weekEvents = [];

  @override
  void initState() {
    super.initState();

    _campusDataProviderLocal = CampusDataProviderLocal.getInstance();
    _locationSubscription = Geolocator.getPositionStream().listen((l) {
      _locationData = l;
      if (!_navigationTrackingMode || _controller == null) {
        return;
      }

      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(l.latitude, l.longitude),
              zoom: _curZoom,
              bearing: l.heading),
        ),
      );
    });

    rootBundle.loadString('assets/main_map_style.txt').then((string) {
      _mapStyle = string;
    });

    _loadingLiveChipsAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _colorAnimationValue = Tween(begin: 0.5, end: 0.0).animate(CurvedAnimation(
        parent: _loadingLiveChipsAnimationController, curve: Curves.easeInOut));

    _loadingLiveChipsAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _loadingLiveChipsAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _loadingLiveChipsAnimationController.forward();
      }
      setState(() {});
    });

    _loadingLiveChipsAnimationController.forward();

    for (String key in CollegeData.searchMapKeys
        .toList()
        .sublist(1, _totalLocationKeyCount + 1)) {
      _campusMarkers.putIfAbsent(key, () => []);
    }

    if (widget.locKey != null && _campusMarkers.containsKey(widget.locKey)) {
      int index = _campusMarkers.keys.toList().indexOf(widget.locKey!);
      _selectedLocations[index] = 1;
      _chosenMapTypeIndex = 0;
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _setMarkerAssets();
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }

    _loadingLiveChipsAnimationController.dispose();
    _locationSubscription.cancel();
    _weekEvents.clear();
    _campusMarkers.clear();
    _scheduleMarkers.clear();
    _liveEvents?.clear();
    _liveEventMarkers?.clear();
    _liveEventCircles.clear();
    _multipleEventsMarker = null;
    _campusMarkerAssets.clear();
    _scheduleAssets.clear();
    _scheduleCircles.clear();
    _lines.clear();
    _campusBuildingPolygons.clear();

    super.dispose();
  }

  // This function sets the assets for the marker image on the map.
  void _setMarkerAssets() async {
    if (_campusMarkerAssets.isEmpty) {
      _campusMarkerAssets = await AssetManager.getAllMapIcons;
    }

    if (_scheduleAssets.isEmpty) {
      _scheduleAssets = await AssetManager.getAllScheduleIcons;
    }

    if (_liveEventMarkerAssets.isEmpty) {
      _liveEventMarkerAssets = await AssetManager.getAllCampusEventsIcons;
    }

    _multipleEventsMarker ??= await AssetManager.getIconFromString(
        "assets/images/CampusEvents/multiple_event_icon.png");

    if (_liveEventMarkers == null ||
        _lastLiveEventQueriedTime.difference(DateTime.now()).inMinutes > 5) {
      _setLiveEventsMarkers();
    }

    if (mounted) {
      setState(() {
        _setScheduleMapObjects();
        _setCampusMapObjects();
      });
    }
  }

  List<Event> _getWeekEvents(List<Event> events) {
    events = events
        .where(
          (element) => !element.isOnline,
        )
        .toList();
    events.sort(
      (a, b) => a.compareTo(b),
    );
    return events;
  }

  void _locationInfoRoute(String location, LatLng coordinate, Set<String> keys,
      List<LatLng>? polygonPoints) {
    Transitions.createLocationInfoRoute(
        context, location, coordinate, keys, polygonPoints, () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _openMultipleEventsSubview(LatLng coordinate) {
    List<CampusEvent> eventsWithLocationAndType = _liveEvents
            ?.where((element) =>
                (element.loc == coordinate) &&
                (_chosenLiveEventIndex == -1 ||
                    _chosenLiveEventIndex == element.type.index))
            .toList() ??
        [];
    if (eventsWithLocationAndType.isEmpty) {
      return;
    }

    Transitions.showMyModalBottomSheet(
        context,
        MultipleEventsSubpage(events: eventsWithLocationAndType),
        Colors.transparent,
        500,
        () {});
  }

  List<Marker> get _getFavoriteMarkers {
    Set<String> favorites = Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.favorites ??
        {};
    return MapPageHelper.getFavoriteMarkers(
        favorites,
        _campusDataProviderLocal,
        _campusMarkerAssets[MapIconType.favorite] ??
            BitmapDescriptor.defaultMarker,
        (String fav, LatLng coordinate) async {
      _locationInfoRoute(
          fav,
          coordinate,
          _campusDataProviderLocal.getCampusLocationKeys(fav),
          _campusDataProviderLocal.getCampusPolygonPoints(fav));
    });
  }

  // This function sets the markers for the schedule.
  void _setScheduleMapObjects() {
    if (!mounted) {
      return;
    }

    int themeIndex =
        (Provider.of<UserProvider>(context, listen: false).getUserData?.theme ??
                1) +
            1;

    List<BitmapDescriptor> markerAssets = [];
    List<FormalTypeEnum> types = FormalTypeEnum.values;
    for (int x = 0; x < types.length; x++) {
      markerAssets.add(_scheduleAssets[x * 10 + themeIndex] ??
          BitmapDescriptor.defaultMarker);
    }
    _scheduleMarkers.clear();
    _scheduleCircles.clear();

    MapPageHelper.setScheduleAssets(
        _weekEvents,
        Theme.of(context).colorScheme.primary,
        _scheduleMarkers,
        _scheduleCircles,
        _lines, (i) async {
      _locationInfoRoute(
          _weekEvents[i].location,
          _weekEvents[i].locationCoordinate!,
          _campusDataProviderLocal
              .getCampusLocationKeys(_weekEvents[i].location),
          _campusDataProviderLocal
              .getCampusPolygonPoints(_weekEvents[i].location));
    }, markerAssets);
  }

  void _setCampusMapObjects() {
    Map<String, List<LatLng>?> polygonPoints =
        _campusDataProviderLocal.getMultipleCampusPolygonPoints(
            _campusDataProviderLocal.getCampusLocationNames);
    polygonPoints.removeWhere((key, value) => value == null);
    polygonPoints.forEach((key, value) {
      _campusBuildingPolygons.add(Polygon(
          polygonId: PolygonId(key),
          consumeTapEvents: true,
          points: value!,
          strokeColor: Colors.transparent,
          fillColor: Theme.of(context).colorScheme.primary.withOpacity(.2),
          onTap: () {
            _locationInfoRoute(
                key,
                _campusDataProviderLocal.getCampusLocationCoordinate(key)!,
                _campusDataProviderLocal.getCampusLocationKeys(key),
                value);
          }));
    });

    for (String location in _campusDataProviderLocal.getCampusLocationNames) {
      LatLng coordinate =
          _campusDataProviderLocal.getCampusLocationCoordinate(location)!;
      Set<String> keys =
          _campusDataProviderLocal.getCampusLocationKeys(location);

      // Set markers
      final typesCommon = (keys).intersection(Set.from(_campusMarkers.keys));
      if (typesCommon.isNotEmpty) {
        _campusMarkers[typesCommon.first]!.add(Marker(
            markerId: MarkerId(location),
            position: coordinate,
            icon: _campusMarkerAssets[
                    AssetManager().getTypeFromString(typesCommon.first)] ??
                BitmapDescriptor.defaultMarker,
            onTap: () {
              _locationInfoRoute(location, coordinate, keys,
                  _campusDataProviderLocal.getCampusPolygonPoints(location));
            }));
      }
    }
  }

  void _setLiveEventsMarkers() async {
    _liveEvents =
        await NetworkHelper().getNextTwoWeeksOrPreviousLastWeekEvents();
    if (_liveEvents?.isNotEmpty ?? false) {
      _loadingLiveChipsAnimationController.stop();
    }

    Map<int, List<Marker>> tempLiveEventMarkers =
        MapPageHelper.setLiveEventAssets(
            _liveEvents!, _openMultipleEventsSubview, (event) async {
      Transitions.createLiveEventInfoRoute(context, event);
    }, _multipleEventsMarker ?? BitmapDescriptor.defaultMarker,
            _liveEventMarkerAssets, _liveEventCircles);

    if (mounted) {
      setState(() {
        _liveEventMarkers = tempLiveEventMarkers;
        _lastLiveEventQueriedTime = DateTime.now();
      });
    }
  }

  // This function returns a set of markers based on the _chosenMapTypeIndex value,
  // which dictates what type of makers are needed to be displayed on the map.
  // rType: Set (Marker)
  Set<Marker> _filterMarkers() {
    switch (_chosenMapTypeIndex) {
      case 0:
        Set<Marker> chosenMarkers = {};
        if (_selectedFirstLocationItem) {
          chosenMarkers.addAll(_getFavoriteMarkers);
        }
        List<String> keys = _campusMarkers.keys.toList();
        for (int i = 0; i < _selectedLocations.length; i++) {
          if (_selectedLocations[i] == 0) {
            continue;
          }
          chosenMarkers.addAll(_campusMarkers[keys[i]] ?? []);
        }
        return chosenMarkers;
      case 1:
        DateTime now = DateTime.now();
        return _scheduleMarkers
            .where((element) => (!_selectedFirstLocationItem ||
                _weekEvents[int.parse(element.markerId.value)]
                    .days
                    .contains(now.weekday - 1)))
            .toSet();
      default:
        if (_liveEventMarkers == null) {
          return {};
        }

        if (_chosenLiveEventIndex == -1) {
          Set<Marker> markers = {};
          for (List<Marker> markersList in _liveEventMarkers!.values) {
            markers.addAll(markersList);
          }
          return markers;
        }

        return _liveEventMarkers![_chosenLiveEventIndex]!.toSet();
    }
  }

  // This function takes in a string of a key for the locations,
  // and it either adds or removes the given key from the key set fields in the class.
  void _addLocKeys(int index) {
    if (index < 0 || index >= _selectedLocations.length) {
      return;
    }
    if (mounted) {
      setState(() {
        _selectedLocations[index] = (_selectedLocations[index] + 1) % 2;
      });
    }
  }

  void _setliveEventIndex(int key) {
    if (mounted) {
      setState(() {
        if (_chosenLiveEventIndex == key) {
          _chosenLiveEventIndex = -1;
        } else {
          _chosenLiveEventIndex = key;
        }
      });
    }
  }

  // This function takes in a position, a current bool and an optional zoom variable,
  // and makes the map change position to the given coordinate.
  void _goToPosition(LatLng position, bool current,
      [double zoom = _curZoom]) async {
    if (_controller == null) {
      return;
    }
    _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: position,
        bearing: 0.0,
        tilt: (current) ? 15.0 : 0.0,
        zoom: zoom)));
    if (mounted) {
      setState(() {
        _navigationTrackingMode = current;
      });
    }
  }

  // This function takes a string of type and and index, where the type name will be displayed
  // and builds a gesture detector with that index that makes a button for the toggle between the map
  // types.
  // rType: GestureDetector
  MapToggleButton _buildMapTypeToggleButton(String type, int index) {
    return MapToggleButton(
        onTap: () {
          if (mounted) {
            setState(() {
              _chosenMapTypeIndex = index;
            });
          }
        },
        info: type,
        active: (_chosenMapTypeIndex == index));
  }

  NavigationChipsBar get _buildScheduleNavigationChips {
    DateTime now = DateTime.now();
    List<Event> relevantEvents = _weekEvents
        .where((element) =>
            !_selectedFirstLocationItem ||
            element.days.contains(now.weekday - 1))
        .toList();
    return NavigationChipsBar(
        onFirstButtonPressed: () {
          if (mounted) {
            setState(() {
              _selectedFirstLocationItem = !_selectedFirstLocationItem;
              _chosenEventIndex = -1;
            });
          }
        },
        firstButtonSelected: _selectedFirstLocationItem,
        firstSelectedIcon: Icons.calendar_today_rounded,
        firstUnselectedIcon: Icons.calendar_month_rounded,
        itemCount: relevantEvents.length,
        itemBuilder: (context, index) {
          return LocationChip(
              active: _chosenEventIndex == index,
              icon: CollegeData
                  .eventTypeIcons[relevantEvents[index].formalType.index],
              name: relevantEvents[index].name,
              index: index,
              update: (int index) {
                setState(() {
                  _navigationTrackingMode = false;
                  _chosenEventIndex = (_chosenEventIndex == index) ? -1 : index;
                });

                if (_chosenEventIndex >= 0) {
                  _goToPosition(
                      relevantEvents[index].locationCoordinate!, false);
                }
              });
        });
  }

  NavigationChipsBar get _buildCampusNavigationChips {
    return NavigationChipsBar(
        onFirstButtonPressed: () {
          if (mounted) {
            setState(() {
              _selectedFirstLocationItem = !_selectedFirstLocationItem;
            });
          }
        },
        firstButtonSelected: _selectedFirstLocationItem,
        firstSelectedIcon: Icons.favorite_rounded,
        firstUnselectedIcon: Icons.favorite_border_rounded,
        itemCount: _selectedLocations.length,
        itemBuilder: (context, index) {
          return LocationChip(
              active: _selectedLocations[index] == 1,
              icon: Icons.pin_drop_rounded,
              name: _campusMarkers.keys.toList()[index],
              index: index,
              update: _addLocKeys);
        });
  }

  NavigationChipsBar get _buildLiveEventsNavigationChips {
    bool isSearching = _liveEventMarkers == null || _liveEventMarkers!.isEmpty;
    List<CampusEventType> liveEventTypes = CampusEventType.values;
    return NavigationChipsBar(
        onFirstButtonPressed: () {
          if (_lastLiveEventQueriedTime.difference(DateTime.now()).inMinutes <
              -1) {
            _setLiveEventsMarkers();
          }
        },
        firstButtonSelected: false,
        firstSelectedIcon: Icons.autorenew_rounded,
        firstUnselectedIcon: Icons.autorenew_rounded,
        itemCount: (isSearching) ? 5 : _liveEventMarkers!.length,
        itemBuilder: (isSearching)
            ? (context, index) {
                double opacityVal =
                    (_colorAnimationValue.value ?? 0.0) - (index * .1);
                if (opacityVal > .5 || opacityVal < 0) {
                  opacityVal = .5 - opacityVal % .5;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                      color: const ui.Color.fromARGB(255, 255, 255, 255)
                          .withOpacity(opacityVal),
                      borderRadius: BorderRadius.circular(15)),
                  width: 100 - index * 10,
                );
              }
            : (context, index) {
                int liveEventTypeIndex =
                    _liveEventMarkers!.keys.toList()[index];
                return LocationChip(
                    active: _chosenLiveEventIndex == liveEventTypeIndex,
                    icon: getCampusEventTypeIcon(
                        liveEventTypes[liveEventTypeIndex]),
                    name: liveEventTypes[liveEventTypeIndex].name,
                    index: liveEventTypeIndex,
                    update: _setliveEventIndex);
              });
  }

  NavigationChipsBar _chipNavigationViewSelector() {
    switch (_chosenMapTypeIndex) {
      case 0:
        return _buildCampusNavigationChips;
      case 1:
        return _buildScheduleNavigationChips;
      default:
        return _buildLiveEventsNavigationChips;
    }
  }

  @override
  Widget build(BuildContext context) {
    _topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Consumer<EventsProvider>(builder: (context, snapshot, child) {
        DateTime now = DateTime.now();
        List<Event> fullWeekEvents = snapshot.getEventsInRange(DateTimeRange(
            start: now.subtract(Duration(days: now.weekday - 1)),
            end: now.add(Duration(days: 7 - now.weekday))));
        List<Event> newEvents = _getWeekEvents(fullWeekEvents);
        _weekEvents = newEvents;
        _setScheduleMapObjects();

        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    0, _navigationBarHeight - 5, 0, 0),
                child: Listener(
                    key: const Key("MainMap"),
                    onPointerMove: (move) {
                      if (_navigationTrackingMode || _chosenEventIndex != -1) {
                        setState(() {
                          _navigationTrackingMode = false;
                          _chosenEventIndex = -1;
                        });
                      }
                    },
                    child: GoogleMap(
                      trafficEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      buildingsEnabled: !_showCampusPolygons,
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: (_locationData != null)
                            ? LatLng(_locationData!.latitude,
                                _locationData!.longitude)
                            : Provider.of<UserProvider>(context, listen: false)
                                .getMyUniveristyCoordinate,
                        zoom: 15,
                        bearing: _curBearing,
                      ),
                      onMapCreated: ((controller) {
                        if (mounted) {
                          _controller = controller;
                          controller.setMapStyle(_mapStyle);
                        }
                      }),
                      compassEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      markers: _filterMarkers(),
                      polygons:
                          (_showCampusPolygons) ? _campusBuildingPolygons : {},
                      circles: (_chosenMapTypeIndex == 1)
                          ? _scheduleCircles
                          : (_chosenMapTypeIndex == 2)
                              ? _liveEventCircles
                              : {},
                      polylines: (_chosenMapTypeIndex == 1) ? _lines : {},
                    )),
              ),
            ),
            SafeArea(
                child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    0,
                    _navigationBarHeight + MarginConstants.sideMargin,
                    MarginConstants.extraSideMargin,
                    0),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _showCampusPolygons = !_showCampusPolygons;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50)),
                    child: (_showCampusPolygons)
                        ? Icon(Icons.location_city_rounded,
                            weight: 0.1,
                            size: 25,
                            color: Theme.of(context).colorScheme.primary)
                        : Icon(Icons.location_city_sharp,
                            size: 25, color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
            )),
            SafeArea(
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            MarginConstants.sideMargin,
                            0,
                            MarginConstants.sideMargin,
                            70 + MarginConstants.sideMargin),
                        child: FloatingActionButton(
                          heroTag: null,
                          onPressed: () {
                            _goToPosition(
                                Provider.of<UserProvider>(context,
                                        listen: false)
                                    .getMyUniveristyCoordinate,
                                false,
                                15);
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Icon(Icons.center_focus_strong_rounded,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary),
                        )))),
            SafeArea(
              child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                      padding: const EdgeInsets.all(MarginConstants.sideMargin),
                      child: FloatingActionButton(
                        heroTag: null,
                        onPressed: () {
                          _goToPosition(
                              (_locationData != null)
                                  ? LatLng(_locationData!.latitude,
                                      _locationData!.longitude)
                                  : Provider.of<UserProvider>(context,
                                          listen: false)
                                      .getMyUniveristyCoordinate,
                              true);
                        },
                        backgroundColor:
                            const ui.Color.fromARGB(255, 167, 227, 255),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: (_navigationTrackingMode)
                            ? const Icon(Icons.near_me_rounded,
                                size: 30, color: Colors.blue)
                            : const Icon(Icons.near_me_outlined,
                                size: 30, color: Colors.black),
                      ))),
            ),
            Container(
              height: _topPadding + _navigationBarHeight,
              padding: EdgeInsets.fromLTRB(
                  0,
                  MediaQuery.of(context).padding.top + 10,
                  0,
                  MarginConstants.sideMargin),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        MarginConstants.sideMargin,
                        0,
                        MarginConstants.sideMargin,
                        0),
                    child: Row(
                      children: [
                        _buildMapTypeToggleButton("Campus", 0),
                        _buildMapTypeToggleButton("My Schedule", 1),
                        _buildMapTypeToggleButton("Live", 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () async {
                                    context.pushNamed(
                                        SearchLocationPage.routeName,
                                        extra: SearchLocationPageArguments(
                                            liveEvents: _liveEvents ?? []));
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 45,
                    child: _chipNavigationViewSelector(),
                  )
                ],
              ),
            )
          ],
        );
      }),
    );
  }
}

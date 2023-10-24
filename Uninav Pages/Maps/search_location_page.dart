import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uninav/Databases/campus_data_provider_local.dart';
import 'package:uninav/Databases/college_data.dart';
import 'package:uninav/Models/campus_event.dart';
import 'package:uninav/Models/search_location.dart';
import 'package:uninav/Provider/user_provider.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Utilities/network_helper.dart';
import 'package:uninav/Widgets/Mapping/live_event_list_cell.dart';
import 'package:uninav/Widgets/Mapping/search_location_container.dart';
import 'package:uninav/Widgets/avator_chip.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:uninav/Widgets/transitions.dart';

class SearchLocationPageArguments {
  final List<CampusEvent> liveEvents;
  const SearchLocationPageArguments({required this.liveEvents});
}

// This page is where the user can search a on campus or anywhere else. It can show the
// the popular locations and their favorite locations.
class SearchLocationPage extends StatefulWidget {
  final SearchLocationPageArguments? data;
  const SearchLocationPage({Key? key, required this.data}) : super(key: key);

  static const String routeName = "SearchLocationPage";

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  late final CampusDataProviderLocal _campusDataProviderLocal;
  late final List<SearchLocation> _allLocations;
  late final List<String> _locationTypes;
  late final StreamController<Set<String>> _favoriteLocations;

  final List<SearchLocation> _selectedLocations = [];
  final List<CampusEvent> _selectedLiveEvents = [];
  final Set<String> _chosenTypes = {};

  late SearchLocationPageArguments _data;
  late TextEditingController _fieldController;

  @override
  void initState() {
    super.initState();
    _favoriteLocations = StreamController();
    _campusDataProviderLocal = CampusDataProviderLocal.getInstance();
    _allLocations =
        _campusDataProviderLocal.getCampusLocationNames.map((location) {
      LatLng coordinate =
          _campusDataProviderLocal.getCampusLocationCoordinate(location) ??
              const LatLng(0, 0);
      return SearchLocation(
          locationName: location, locationCoordinate: coordinate);
    }).toList();

    _locationTypes = CollegeData.searchMapKeys;
    _fieldController = TextEditingController(text: "");
    _setFavoriteLocations();

    if (widget.data != null) {
      _data = widget.data!;
      if (_data.liveEvents.isEmpty) {
        _tryUpdateLiveEvents();
      }
    }
  }

  @override
  void dispose() {
    _fieldController.dispose();
    _allLocations.clear();
    _selectedLocations.clear();
    _selectedLiveEvents.clear();
    _favoriteLocations.close();
    super.dispose();
  }

  void _tryUpdateLiveEvents() async {
    List<CampusEvent> allEvents =
        await NetworkHelper().getNextTwoWeeksOrPreviousLastWeekEvents();
    if (mounted) {
      setState(() {
        _data = SearchLocationPageArguments(liveEvents: allEvents);
      });
    }
  }

  // This function selects a location from the normal selection of
  // places available. It takes a string name and a coordinate of the
  // location.
  void _selectLocation(String location, LatLng coordinate) async {
    FocusScope.of(context).unfocus();

    Transitions.createLocationInfoRoute(
        context,
        location,
        coordinate,
        _campusDataProviderLocal.getCampusLocationKeys(location),
        _campusDataProviderLocal.getCampusPolygonPoints(location), () {
      _setFavoriteLocations();
    });
  }

  // This function clears the data from the search bar.
  void _clearData() {
    _fieldController.clear();
    _runOpenFilter("");
  }

  StatefulBuilder get _buildSheet {
    return StatefulBuilder(builder: (context, setModalState) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * .8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MarginConstants.sideMargin, 10, MarginConstants.sideMargin, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text("Filters",
                style: AppTextStyle.ptSansRegular(
                    color: Theme.of(context).hintColor, size: 20)),
            const SizedBox(height: 15),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: MarginConstants.sideMargin, bottom: MediaQuery.of(context).padding.bottom + MarginConstants.sideMargin),
                child: Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children:
                        List<Widget>.generate(_locationTypes.length, (index) {
                      String type = _locationTypes[index];
                      return GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setModalState(() {
                                if (_chosenTypes.contains(type)) {
                                  _chosenTypes.remove(type);
                                } else {
                                  _chosenTypes.add(type);
                                }
                              });
                            }
                          },
                          child: AvatarChip(
                              active: _chosenTypes.contains(type),
                              colorMain: Theme.of(context).colorScheme.primary,
                              colorSec: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              text: type,
                              icon: Icons.add_rounded));
                    })),
              ),
            ),
          ]),
        ),
      );
    });
  }

  // This function filters the data and shows the relevant locations  on campus given
  // string of the keyword.
  void _runOpenFilter(String enteredKeyword) async {
    enteredKeyword = enteredKeyword.toLowerCase();
    List<SearchLocation> results = [];
    List<CampusEvent> liveEventResults = [];

    if (enteredKeyword.isNotEmpty) {
      results = _allLocations.where((searchLocation) {
        bool checkKeys = false;
        Set<String> keys = _campusDataProviderLocal
            .getCampusLocationKeys(searchLocation.locationName);
        for (String key in keys) {
          checkKeys = checkKeys || key.toLowerCase().contains(enteredKeyword);
        }
        checkKeys = checkKeys ||
            searchLocation.locationName.toLowerCase().contains(enteredKeyword);

        if (_chosenTypes.isNotEmpty) {
          return checkKeys && _chosenTypes.intersection(keys).isNotEmpty;
        }
        return checkKeys;
      }).toList();
      liveEventResults = _data.liveEvents
          .where((element) =>
              element.name.contains(enteredKeyword) ||
              element.type.name.contains(enteredKeyword))
          .toList();
    } else if (_chosenTypes.isNotEmpty) {
      results = _allLocations.where((searchLocation) {
        Set<String> keys = _campusDataProviderLocal
            .getCampusLocationKeys(searchLocation.locationName);
        return _chosenTypes.intersection(keys).isNotEmpty;
      }).toList();
      liveEventResults = [];
    }
    setState(() {
      _selectedLocations.clear();
      _selectedLiveEvents.clear();
      _selectedLocations.addAll(results);
      _selectedLiveEvents.addAll(liveEventResults);
    });
    // Refresh the UI
  }

  // This function gets the favorite locations from the user data and shows them
  // as a list of popular location objects.
  void _setFavoriteLocations() {
    _favoriteLocations.add(Provider.of<UserProvider>(context, listen: false)
            .getUserData
            ?.favorites ??
        {});
  }

  // This function gets the string pertaining to the
  // tag filters for this page.
  String get _getLocationTypeString {
    int count = _chosenTypes.length;

    if (count == _locationTypes.length || count == 0) {
      return "All Locations";
    }

    if (count > 1) {
      return "$count Locations";
    }

    return _chosenTypes.first;
  }

  List<FavoriteLocation> _generateFavoriteLocationContainers(
      List<String> data) {
    return List.generate(data.length, (index) {
      LatLng coor =
          _campusDataProviderLocal.getCampusLocationCoordinate(data[index]) ??
              const LatLng(0, 0);
      return FavoriteLocation(
          locationName: data[index], busyValue: 3.2, locationCoordinate: coor);
    });
  }

  // This function takes a list and returns a neccessay value for the UI.
  int _getLengthOfLocationList(List list) {
    if (list.isEmpty) {
      return 0;
    } else {
      return list.length + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.fromLTRB(MarginConstants.sideMargin,
            MediaQuery.of(context).padding.top, MarginConstants.sideMargin, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MyBackButton(),
              IconButton(
                  onPressed: () {
                    Transitions.showMyModalBottomSheet(
                        context, _buildSheet, Colors.white, null, () {
                      if (mounted) {
                        setState(() {
                          _runOpenFilter(_fieldController.text);
                        });
                      }
                    });
                  },
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 25,
                    color: Theme.of(context).highlightColor,
                  ))
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          SizedBox(
            height: 50,
            child: TextFormField(
                controller: _fieldController,
                autocorrect: false,
                enableSuggestions: false,
                onTap: () {
                  if (_fieldController.text == "") {
                    _runOpenFilter("");
                  }
                },
                keyboardType: TextInputType.streetAddress,
                cursorColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    _runOpenFilter(value);
                  });
                },
                style:
                    AppTextStyle.ptSansRegular(color: Colors.black, size: 18),
                maxLines: 1,
                decoration: InputDecoration(
                  filled: true,
                  isCollapsed: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Icon(Icons.search_rounded,
                        color: Theme.of(context).hintColor, size: 30),
                  ),
                  suffixIcon: (_fieldController.text.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(start: 0.0),
                          child: IconButton(
                            icon: Icon(Icons.cancel,
                                color: Theme.of(context).hintColor, size: 25),
                            onPressed: () => _clearData(),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.fromLTRB(12, 15, 0, 15),
                  fillColor: Theme.of(context).cardColor,
                  enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.circular(15)),
                )),
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
            child: Align(
              alignment: Alignment.topLeft,
              child: StreamBuilder<Set<String>>(
                  stream: _favoriteLocations.stream,
                  builder: (context, snapshot) {
                    List<FavoriteLocation>? favoriteLocationsData =
                        (snapshot.hasData)
                            ? _generateFavoriteLocationContainers(
                                snapshot.data!.toList())
                            : [];
                    return (_fieldController.text.isEmpty &&
                            _chosenTypes.isEmpty)
                        ? SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: MarginConstants.sideMargin),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: MarginConstants.formHeightBetweenTitleSection),
                                      child: Text(
                                        "Favorites",
                                        style: AppTextStyle.ptSansRegular(
                                            size: 22, color: Colors.black),
                                      ),
                                    ),
                                    Builder(builder: (context) {
                                      List<Widget> favoriteContainers =
                                          List.generate(
                                        favoriteLocationsData.length,
                                        (index) {
                                          String keys = _campusDataProviderLocal
                                              .getCampusLocationKeys(
                                                  favoriteLocationsData[index]
                                                      .locationName)
                                              .toString();
                                          return SearchLocationContainer(
                                              locationName:
                                                  favoriteLocationsData[index]
                                                      .locationName,
                                              locationCoor:
                                                  favoriteLocationsData[index]
                                                      .locationCoordinate,
                                              metaData: keys.substring(
                                                  1, keys.length - 1),
                                              pressed: _selectLocation,
                                              isFavorite: true);
                                        },
                                      );

                                      return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: favoriteContainers);
                                    }),
                                    if (favoriteLocationsData.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            MarginConstants
                                                .standardInternalMargin,
                                            MarginConstants
                                                .standardInternalMargin),
                                        child: Text(
                                          "No Favorite Locations Yet",
                                          style: AppTextStyle.ptSansRegular(
                                              color:
                                                  Theme.of(context).hintColor,
                                              size: 18),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: MarginConstants.formHeightBetweenSubsection, bottom: MarginConstants.formHeightBetweenTitleSection), 
                                      child: Text(
                                        "Live Events This Week",
                                        style: AppTextStyle.ptSansRegular(
                                            size: 22, color: Colors.black),
                                      ),
                                    ),
                                    Builder(builder: (context) {
                                      List<Widget> favoriteContainers =
                                          List.generate(_data.liveEvents.length,
                                              (index) {
                                        return LiveEventListCell(
                                            event: _data.liveEvents[index],
                                            pressed: (_) => Transitions
                                                .createLiveEventInfoRoute(
                                                    context,
                                                    _data.liveEvents[index]));
                                      });
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: favoriteContainers,
                                      );
                                    }),
                                    if (_data.liveEvents.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            MarginConstants
                                                .standardInternalMargin,
                                            MarginConstants
                                                .standardInternalMargin),
                                        child: Text(
                                          "No Live Events Yet",
                                          style: AppTextStyle.ptSansRegular(
                                              color:
                                                  Theme.of(context).hintColor,
                                              size: 18),
                                        ),
                                      ),
                                  ]),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom +
                                    MarginConstants.sideMargin,
                                top: MarginConstants.sideMargin),
                            itemCount: _getLengthOfLocationList(
                                    _selectedLocations) +
                                _getLengthOfLocationList(_selectedLiveEvents),
                            itemBuilder: ((context, index) {
                              if (index == 0 &&
                                  _getLengthOfLocationList(
                                          _selectedLiveEvents) >
                                      0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: MarginConstants.formHeightBetweenTitleSection),
                                  child: Text(
                                    "Live Events",
                                    style: AppTextStyle.ptSansRegular(
                                        size: 22, color: Colors.black),
                                  ),
                                );
                              } else if (_getLengthOfLocationList(
                                          _selectedLiveEvents) >
                                      0 &&
                                  index <
                                      _getLengthOfLocationList(
                                          _selectedLiveEvents)) {
                                return LiveEventListCell(
                                    event: _selectedLiveEvents[index - 1],
                                    pressed: (_) =>
                                        Transitions.createLiveEventInfoRoute(
                                            context,
                                            _selectedLiveEvents[index - 1]));
                              }

                              if (index ==
                                  _getLengthOfLocationList(
                                      _selectedLiveEvents)) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: MarginConstants.formHeightBetweenTitleSection),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Campus",
                                        style: AppTextStyle.ptSansRegular(
                                            size: 22, color: Colors.black),
                                      ),
                                      Text(_getLocationTypeString,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                );
                              }

                              int newIndex = index -
                                  _getLengthOfLocationList(
                                      _selectedLiveEvents) -
                                  1;
                              String keys = _campusDataProviderLocal
                                  .getCampusLocationKeys(
                                      _selectedLocations[newIndex].locationName)
                                  .toString();

                              return SearchLocationContainer(
                                locationName:
                                    _selectedLocations[newIndex].locationName,
                                locationCoor: _selectedLocations[newIndex]
                                    .locationCoordinate,
                                metaData: keys.substring(1, keys.length - 1),
                                pressed: _selectLocation,
                                isFavorite: (snapshot.hasData &&
                                    snapshot.data!.contains(
                                        _selectedLocations[newIndex]
                                            .locationName)),
                              );
                            }));
                  }),
            ),
          )
        ]),
      ),
    );
  }
}

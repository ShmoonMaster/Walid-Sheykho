import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uninav/Databases/campus_data_provider_local.dart';
import 'package:uninav/Utilities/app_text_style.dart';
import 'package:uninav/Utilities/constants.dart';
import 'package:uninav/Widgets/Event/select_location_container.dart';
import 'package:uninav/Widgets/back_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SelectLocationArguments {
  final bool? isOnline;
  final String? previousLocationName;
  final String? previousLink;
  final LatLng? previousCoordinate;
  const SelectLocationArguments(
      {this.previousLocationName,
      this.previousLink,
      this.previousCoordinate,
      this.isOnline});
}

// This page is for the user to select a location for an event. It has a search function
// or a map press function.
class SelectLocation extends StatefulWidget {
  final SelectLocationArguments? data;
  const SelectLocation({Key? key, required this.data}) : super(key: key);

  static const String routeName = "SelectLocationPage";

  @override
  State<SelectLocation> createState() => _SelectLocationState();
}

class _SelectLocationState extends State<SelectLocation> {
  late final List<String> _allLocations;
  late final CampusDataProviderLocal _campusDataProviderLocal;
  late final SelectLocationArguments _data;
  late final TextEditingController _campusSearchTextController;
  late final TextEditingController _currentEventLinkTextController;

  LatLng? _currentCoordinate;
  String? _currentLocationName;
  String? _currentLinkName;
  String? _currentLink;
  List<String> _searchingLocations = [];
  bool isOnline = false;
  bool onlineVerified = false;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      _data = widget.data!;
    }

    _campusSearchTextController = TextEditingController(text: "");
    _currentEventLinkTextController = TextEditingController(text: "");

    _campusDataProviderLocal = CampusDataProviderLocal.getInstance();
    _allLocations = _campusDataProviderLocal.getCampusLocationNames;
    _searchingLocations = _allLocations;

    _currentCoordinate = _data.previousCoordinate;
    _currentLink = _data.previousLink;
    if (_data.isOnline != null) {
      if (_data.isOnline!) {
        _currentLinkName = _data.previousLocationName;
        _currentEventLinkTextController.text = _currentLink ?? "";
      } else {
        _currentLocationName = _data.previousLocationName;
      }
    }

    if (_currentLink != null) {
      isOnline = true;
      onlineVerified = true;
    }
  }

  @override
  void dispose() {
    _campusSearchTextController.dispose();
    _currentEventLinkTextController.dispose();
    super.dispose();
  }

  // Launches the given url if it is available
  Future<void> _launchUrl(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  // This function takes a string name and a location coordinate from the search and sets the values,
  // as needed and updates the page.
  void _setLocationOnSearch(String location, LatLng coor) {
    FocusScope.of(context).unfocus();
    if (mounted) {
      if (_currentCoordinate != null &&
          _currentLocationName != null &&
          _currentCoordinate!.latitude == coor.latitude &&
          _currentCoordinate!.longitude == coor.longitude &&
          location == _currentLocationName!) {
        setState(() {
          _currentCoordinate = null;
          _currentLocationName = null;
        });
      } else {
        setState(() {
          _currentCoordinate = coor;
          _currentLocationName = location;
        });
      }
    }
  }

  // This function clears the data from the search bar.
  void clearData() {
    if (mounted) {
      _campusSearchTextController.clear();
      _runOpenFilter("");
    }
  }

  // This function filters the data and shows the relevant locations  on campus given
  // string of the keyword.
  void _runOpenFilter(String enteredKeyword) async {
    late List<String> results;
    if (enteredKeyword.isEmpty) {
      // if the search field is empty or only contains white-space, we'll display all
      results = _allLocations;
    } else {
      results = _allLocations.where((location) {
        return location.toLowerCase().contains(enteredKeyword.toLowerCase());
      }).toList();
    }
    setState(() {
      _searchingLocations = results;
    });
    // Refresh the UI
  }

  // Builds the container that shows the option for online events
  // and the link to that event.
  Column _buildOnlineLinkContainer(BuildContext context) {
    return Column(
      children: [
        Container(
            padding:
                const EdgeInsets.all(MarginConstants.standardInternalMargin),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                color: (!onlineVerified)
                    ? Theme.of(context).cardColor
                    : Colors.blue[100]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 25,
                        color: (onlineVerified)
                            ? Colors.blue
                            : Theme.of(context).highlightColor),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Event Link",
                      style: AppTextStyle.ptSansRegular(
                          color: (onlineVerified)
                              ? Colors.blue
                              : Theme.of(context).highlightColor,
                          size: 20),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                            (onlineVerified)
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 25,
                            color: (onlineVerified)
                                ? Colors.blue
                                : Theme.of(context).highlightColor),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: MarginConstants.formHeightBetweenSection,
                  thickness: 1,
                  color: Theme.of(context).disabledColor,
                ),
                SizedBox(
                  height: SizeConstants.textBoxHeight,
                  child: TextFormField(
                      initialValue: _currentLinkName,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.url,
                      cursorColor: Colors.black,
                      onChanged: (value) async {
                        bool canLaunch = (_currentLink == null)
                            ? false
                            : await canLaunchUrl(Uri.parse(_currentLink!));
                        setState(() {
                          _currentLinkName = (value.isEmpty) ? null : value;
                          onlineVerified = value.isNotEmpty && canLaunch;
                        });
                      },
                      style: AppTextStyle.ptSansRegular(
                          color: Colors.black, size: 18),
                      maxLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        isCollapsed: true,
                        prefixIcon: Padding(
                          padding:
                              const EdgeInsets.only(left: 12.0, right: 8.0),
                          child: Icon(Icons.newspaper_rounded,
                              color: Theme.of(context).hintColor, size: 25),
                        ),
                        contentPadding: const EdgeInsets.all(
                            MarginConstants.standardInternalMargin),
                        fillColor: Colors.white,
                        hintText: "Name",
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(15)),
                      )),
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenSubsection,
                ),
                SizedBox(
                  height: SizeConstants.textBoxHeight,
                  child: TextFormField(
                      controller: _currentEventLinkTextController,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.url,
                      cursorColor: Colors.black,
                      onChanged: (value) async {
                        bool canLaunch = await canLaunchUrl(Uri.parse(value));
                        setState(() {
                          _currentLink = (value.isEmpty) ? null : value;
                          onlineVerified = _currentLinkName != null &&
                              _currentLinkName!.isNotEmpty &&
                              value.isNotEmpty &&
                              canLaunch;
                        });
                      },
                      style: AppTextStyle.ptSansRegular(
                          color: Colors.black, size: 18),
                      maxLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        isCollapsed: true,
                        prefixIcon: Padding(
                          padding:
                              const EdgeInsets.only(left: 12.0, right: 8.0),
                          child: Icon(Icons.link_rounded,
                              color: Theme.of(context).hintColor, size: 30),
                        ),
                        suffixIcon: (_currentLink != null &&
                                _currentLink!.isNotEmpty)
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 0.0),
                                child: IconButton(
                                    icon: Icon(Icons.cancel,
                                        color: Theme.of(context).hintColor,
                                        size: 25),
                                    onPressed: () {
                                      setState(() {
                                        _currentLink = null;
                                        _currentEventLinkTextController.clear();
                                        onlineVerified = false;
                                      });
                                    }),
                              )
                            : null,
                        contentPadding: const EdgeInsets.all(
                            MarginConstants.standardInternalMargin),
                        fillColor: Colors.white,
                        hintText: "Link",
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(15)),
                      )),
                )
              ],
            )),
        GestureDetector(
            onTap: () {
              if (onlineVerified && _currentLink != null) {
                _launchUrl(_currentLink!);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: (onlineVerified)
                    ? Colors.blue[200]
                    : Theme.of(context).disabledColor,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Test Link",
                        style: AppTextStyle.ptSansBold(
                            color: (onlineVerified)
                                ? Colors.blue
                                : Theme.of(context).highlightColor,
                            size: 18)),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: (onlineVerified)
                          ? Colors.blue
                          : Theme.of(context).highlightColor,
                      size: 25,
                    )
                  ]),
            ))
      ],
    );
  }

  // Builds the list of locations for the campus based on the
  // given sorted list of campus buildings.
  ListView get _buildLocationList {
    return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom +
                MarginConstants.sideMargin,
            top: MarginConstants.sideMargin),
        itemCount: _searchingLocations.length,
        separatorBuilder: (context, index) {
          return const SizedBox(
            height: 15,
          );
        },
        itemBuilder: ((context, index) {
          return GestureDetector(
            onTap: () => _setLocationOnSearch(
                _searchingLocations[index],
                _campusDataProviderLocal.getCampusLocationCoordinate(
                        _searchingLocations[index]) ??
                    const LatLng(0, 0)),
            child: SelectLocationContainer(
              key: Key(_searchingLocations[index]),
              locationName: _searchingLocations[index],
              active: (_currentCoordinate != null &&
                  _campusDataProviderLocal.getCampusLocationCoordinate(
                          _searchingLocations[index]) ==
                      _currentCoordinate),
            ),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.fromLTRB(MarginConstants.sideMargin,
            MediaQuery.of(context).padding.top, MarginConstants.sideMargin, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: MyBackButton(
                          onPressed: () {
                            if ((!isOnline &&
                                    (_currentLocationName == null ||
                                        _currentCoordinate == null)) ||
                                (isOnline && (_currentLink == null))) {
                              Navigator.pop(context);
                              return;
                            }
                            if (isOnline) {
                              Navigator.pop(context, [
                                false,
                                ((_currentLinkName != null)
                                    ? _currentLinkName
                                    : "Event Link"),
                                _currentLink
                              ]);
                              return;
                            }
                            Navigator.pop(context, [
                              true,
                              _currentLocationName,
                              _currentCoordinate
                            ]);
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (mounted && isOnline) {
                          setState(() {
                            isOnline = false;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              size: 25,
                              color: (isOnline)
                                  ? Theme.of(context).disabledColor
                                  : Theme.of(context).highlightColor),
                          const SizedBox(
                            width: 5,
                          ),
                          Text("In Person",
                              style: (isOnline)
                                  ? AppTextStyle.ptSansRegular(
                                      color: Theme.of(context).disabledColor,
                                      size: 20)
                                  : AppTextStyle.ptSansBold(
                                      color: Theme.of(context).highlightColor,
                                      size: 20))
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (mounted && !isOnline) {
                          setState(() {
                            isOnline = true;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.cloud_outlined,
                              size: 25,
                              color: (isOnline)
                                  ? Theme.of(context).highlightColor
                                  : Theme.of(context).disabledColor),
                          const SizedBox(
                            width: 5,
                          ),
                          Text("Online",
                              style: (!isOnline)
                                      ? AppTextStyle.ptSansRegular(
                                          color:
                                              Theme.of(context).disabledColor,
                                          size: 20)
                                      : AppTextStyle.ptSansBold(
                                          color:
                                              Theme.of(context).highlightColor,
                                          size: 20))
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: MarginConstants.formHeightBetweenTitleSection,
                ),
              ] +
              ((!isOnline)
                  ? [
                      SizedBox(
                        height: SizeConstants.searchBoxHeight,
                        child: TextFormField(
                            controller: _campusSearchTextController,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Colors.black,
                            onChanged: (value) {
                              if (mounted) {
                                _runOpenFilter(value);
                              }
                            },
                            style: AppTextStyle.ptSansRegular(
                                color: Colors.black, size: 18),
                            maxLines: 1,
                            decoration: InputDecoration(
                              filled: true,
                              isCollapsed: true,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, right: 8.0),
                                child: Icon(Icons.search_rounded,
                                    color: Theme.of(context).hintColor,
                                    size: 30),
                              ),
                              suffixIcon: (_campusSearchTextController
                                      .text.isNotEmpty)
                                  ? Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 0.0),
                                      child: IconButton(
                                        icon: Icon(Icons.cancel,
                                            color: Theme.of(context).hintColor,
                                            size: 25),
                                        onPressed: () => clearData(),
                                      ),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.all(
                                  MarginConstants.standardInternalMargin),
                              fillColor: Theme.of(context).cardColor,
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.transparent, width: 0),
                                  borderRadius: BorderRadius.circular(15)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.transparent, width: 0),
                                  borderRadius: BorderRadius.circular(15)),
                            )),
                      ),
                      const SizedBox(
                        height: MarginConstants.formHeightBetweenTitleSection,
                      ),
                      Divider(
                        thickness: 1,
                        color: Theme.of(context).dividerColor,
                        height: 1,
                      ),
                      Expanded(child: _buildLocationList),
                    ]
                  : [_buildOnlineLinkContainer(context)]),
        ),
      ),
    );
  }
}

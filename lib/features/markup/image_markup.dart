import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:namer_app/main.dart';
import 'package:provider/provider.dart';
import 'markers_provider.dart';
import 'constrained_draggable.dart';
import 'package:universal_io/io.dart';
import 'custom_marker_painter.dart';

bool isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

class AssetImage extends StatefulWidget {
  final String image;

  AssetImage({
    super.key,
    required this.image,
  });

  @override
  State<AssetImage> createState() {
    return _AssetImageState();
  }
}

class _AssetImageState extends State<AssetImage> {
  bool _imageReady = false;
  late ImageStream _imageStream;
  late ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    final image =
        Image.asset("assets/images/${widget.image}", fit: BoxFit.contain);
    _imageStream = image.image.resolve(ImageConfiguration());

    // Listener to track when the image is loaded
    _listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        setState(() {
          _imageReady = true;
        });
      },
      onError: (exception, stackTrace) {
        setState(() {
          _imageReady = false; // You can handle errors here
        });
      },
    );

    // Add the listener
    _imageStream.addListener(_listener);
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed to prevent memory leaks
    _imageStream.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final image = Container(
          decoration: BoxDecoration(
              border: Border.all(
            // Border opacity removed
            color: Color.fromARGB(100, 200, 200, 255), // Border color
            width: 1, // Border width
          )),
          child:
              Image.asset("assets/images/${widget.image}", fit: BoxFit.contain),
        );

        // If image is not ready, show loading indicator
        if (!_imageReady) {
          return Center(child: CircularProgressIndicator());
        }

        // Once image is ready, return the image widget
        return image;
      },
    );
  }
}

class ImageMarkup extends StatefulWidget {
  final ItemImage image;
  final bool debug;

  ImageMarkup(this.image, this.debug);

  @override
  State<ImageMarkup> createState() {
    return _ImageMarkupState();
  }
}

class _ImageMarkupState extends State<ImageMarkup> with WidgetsBindingObserver {
  final GlobalKey _imageKey =
      GlobalKey(); // Key to track the image's position and size
  late TransformationController _transformationController;
  double _scaleFactor = 1;
  bool _imageReady = false;
  bool _delayedRender = false;
  final Map<String, FocusNode> _focusNodes = {};
  MarkerData? _currentMarker;

  get zoomLevel => _scaleFactor;
  Size? _lastScreenSize;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imageKey.currentContext != null) {
        setState(() {
          _imageReady = true;
        });
        // Start the delay after the image is ready
        _delayMarkerRender();
      }
    });
  }

// Delay the rendering of markers by 500ms (adjust time as needed)
  void _delayMarkerRender() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _delayedRender = true;
        });
      }
    });
  }

  void setCurrentMarker(MarkerData marker) {
    setState(() {
      _currentMarker = marker;
    });
  }

  String _getMarkerKey(dynamic marker) {
    return marker.hashCode
        .toString(); // Example, replace with marker.id if applicable
  }

  @override
  void dispose() {
    // Dispose of all FocusNodes when the widget is disposed to prevent memory leaks
    _focusNodes.forEach((key, focusNode) {
      focusNode.dispose();
    });
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    _scaleFactor = matrix.getMaxScaleOnAxis();
  }

  void resetScale() {
    // Reset the TransformationController to its default (identity matrix)
    _transformationController.value = Matrix4.identity();
    setState(() {
      _scaleFactor = 1.0; // Optionally, keep track of the zoom level.
    });
  }

  @override
  void didUpdateWidget(covariant ImageMarkup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the image has changed
    if (widget.image != oldWidget.image) {
      // Reset the flags and scale when the image changes
      resetScale();
      setState(() {
        _imageReady = false;
        _delayedRender = false;
      });

      // Trigger the image loading process again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_imageKey.currentContext != null) {
          setState(() {
            _imageReady = true;
          });
          _delayMarkerRender();
        }
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Listen for screen size changes
    final screenSize = WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;

    if (_lastScreenSize == null || _lastScreenSize != screenSize) {
      setState(() {
        _lastScreenSize = screenSize;

        // Perform any actions needed when screen size changes
        _imageReady = false;
        _delayedRender = false;
      });

      // Restart image readiness and marker rendering process
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_imageKey.currentContext != null) {
          setState(() {
            _imageReady = true;
          });
          _delayMarkerRender();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //Normalize the local marker position
    Offset normalize(Offset offset) {
      final RenderBox renderBox =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      final imageSize = renderBox.size;
      Offset normalizedPosition =
          Offset(offset.dx / imageSize.width, offset.dy / imageSize.height);
      
      return normalizedPosition;
    }

    // Get the point from the normalized global position
    Point getPoint(Offset offset) {
      final RenderBox renderBox =
          _imageKey.currentContext!.findRenderObject() as RenderBox;

      final imageSize = renderBox.size; // Size of the image

      final normalizedPosition =
          Offset(offset.dx * imageSize.width, offset.dy * imageSize.height);
      final Point point = Point(normalizedPosition.dx, normalizedPosition.dy);
      //final Point point = Point(normalizedPosition.dx / _scaleFactor, normalizedPosition.dy / _scaleFactor);

      return point;
    }

    void moveMarker(MarkerData marker, Offset offset) {
      setState(() {
        Offset normalizedPosition = normalize(offset);
        widget.image.provider.hideMarker(marker, false);
          widget.image.provider
            .updateMarkerPosition(marker, normalizedPosition);
        });
    }

    return Consumer<MarkersProvider>(
      builder: (context, provider, child) {
        return InteractiveViewer(
          transformationController: _transformationController,
          clipBehavior:
              Clip.antiAliasWithSaveLayer, // To prevent clipping if needed
          onInteractionEnd: (details) {
            // Update the zoom level when interaction ends
            setState(() {
              _scaleFactor = _transformationController.value.getMaxScaleOnAxis();
            });
          },
          panEnabled: true, // Enable panning
          scaleEnabled: true, // Enable zooming
          minScale: 1.0, // Minimum zoom scale
          maxScale: 10.0, // Maximum zoom scale
          child: Center(
            child: GestureDetector(
              onTapUp: (details) async {
                MarkerData newMarker = MarkersProvider.getEmptyMarker();
                newMarker.position = normalize(details.localPosition);
                // Show the input dialog to add a new marker
                final markerData = await _showInputDialog(
                    newMarker, widget.image.provider, context);
                if (markerData != null) {
                  setState(() {
                    widget.image.provider
                        .addMarker(markerData); // Add marker and update state
                  });
                } else {}
              },
              child: Container(
                decoration: widget.debug
                    ? BoxDecoration(
                        color:
                            Colors.yellow.withOpacity(.1), // Background color
                        // border: Border.all(
                        //    color: Colors.blue, // Border color
                        //    width: 1, // Border width
                        // ),
                      )
                    : null,
                child: Stack(
                  children: [
                    AssetImage(key: _imageKey, image: widget.image.image),
                    // Render markers
                    if (_imageReady && _delayedRender)
                      ...widget.image.provider.markers.map((marker) {
                        final String markerKey = _getMarkerKey(marker);
                        final Point point = getPoint(marker.position);
                        
                        final left =
                            point.x.toDouble() - MarkersProvider.offset.x;
                        final top =
                            point.y.toDouble() - MarkersProvider.offset.y;
                        final imageBox = _imageKey.currentContext!
                            .findRenderObject() as RenderBox;

                        // Ensure a unique FocusNode exists for this marker
                        if (!_focusNodes.containsKey(markerKey)) {
                          _focusNodes[markerKey] = FocusNode();
                        }
                        final FocusNode focusNode = _focusNodes[markerKey]!;
                        return FocusTraversalGroup(
                          child: Positioned(
                            left: left,
                            top: top,
                            child: Focus(
                              focusNode: focusNode,
                              child: GestureDetector(
                                onTapUp: (details) async {
                                  setState(() {
                                    FocusScope.of(context)
                                        .requestFocus(focusNode);
                                    setCurrentMarker(marker);
                                  });
                                  
                                  final updatedMarker = await _showInputDialog(
                                      marker, widget.image.provider, context);

                                  if (updatedMarker != null) {
                                    if (updatedMarker.delete == true) {
                                      setState(() {
                                        widget.image.provider
                                            .removeMarker(marker);
                                        FocusScope.of(context)
                                            .requestFocus(focusNode);
                                        setCurrentMarker(marker);
                                      });
                                    } else {
                                      setState(() {
                                        marker.info = updatedMarker.info;
                                      });
                                    }
                                  }
                                },
                                // onLongPress: () {
                                //   setState(() {
                                //     widget.image.provider.removeMarker(marker);
                                //   });
                                // },

                                child: ConstrainedDraggable(
                                  //maxSimultaneousDrags: _scaleFactor > 1 ? 0 : 1,
                                  pointerOffset: MarkersProvider.offset,
                                  renderBox: imageBox,
                                  scale: _scaleFactor,
                                  feedback: Transform.scale(
                                    scale:
                                        _scaleFactor, // Apply your zoom level or desired scale here
                                    child: _buildMarker(marker,
                                        Point(left, top), imageBox, true, true),
                                  ),
                                  child: _buildMarker(
                                      marker,
                                      Point(left, top),
                                      imageBox,
                                      focusNode.hasFocus ||
                                          _currentMarker == marker,
                                      false),
                                  onDragStarted: () {
                                    setState(() {
                                      FocusScope.of(context)
                                          .requestFocus(focusNode);
                                      setCurrentMarker(marker);
                                    });
                                  },
                                  onDragEnd: (details) {
                                    final RenderBox renderBox = _imageKey
                                        .currentContext!
                                        .findRenderObject() as RenderBox;
                                    final containerPosition =
                                        renderBox.localToGlobal(Offset
                                            .zero); // Global position of the image

                                    final adjusted = Offset(
                                        (details.offset.dx -
                                            containerPosition.dx +
                                            MarkersProvider.offset.x) / _scaleFactor,
                                        (details.offset.dy -
                                            containerPosition.dy +
                                            MarkersProvider.offset.y)  / _scaleFactor);
                                    
                                    moveMarker(marker, adjusted);
                                  },
                                  onDragUpdate: (details) {
                                    if (!marker.hide) {
                                      setState(() {
                                        widget.image.provider
                                            .hideMarker(marker, true);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarker(MarkerData marker, Point position, RenderBox renderBox,
      bool hasFocus, bool hideText) {
    final shortDescription = marker.info.shortDescription;
    if (marker.hide) {
      return SizedBox.shrink();
    }
    return Stack(
      children: [
        SizedBox(
          width: MarkersProvider.width,
          height: MarkersProvider.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: .8,
                child: CustomPaint(
                  key: ValueKey(marker),
                  size: Size(
                      MarkersProvider.iconSize,
                      MarkersProvider
                          .iconSize), // Define the size of the custom icon
                  painter: CustomMarkerPainter(
                      dotColor: hasFocus ? Colors.yellow : marker.color,
                      borderColor: hasFocus ? Colors.yellow : marker.color,
                      highlightColor: hasFocus
                          ? Colors.black
                          : Colors.white), // Use the custom painter for drawing
                ),
              ),
              if (marker.isShowText! && !hideText)
                Positioned(
                  bottom: position.y >
                          renderBox.size.height - MarkersProvider.height
                      ? MarkersProvider.height - 10
                      : 0, // Adjust this value to position the text relative to the icon
                  left:
                      position.x > renderBox.size.width - MarkersProvider.width
                          ? 0
                          : null,
                  right: position.x < 0 ? 0 : null,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Set the white background for the text
                        borderRadius:
                            BorderRadius.circular(3), // Rounded corners
                        border: Border.all(
                          color: Colors.black87.withAlpha(150), // Border color
                          width: .25, // Border width
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.0,
                          vertical: 0), // Add horizontal and vertical padding
                      child: Text(
                        shortDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          letterSpacing: .75,
                          color: Colors.black,
                          fontSize: 8,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<MarkerData?> _showInputDialog(
      MarkerData marker, MarkersProvider provider, BuildContext context) {
    TextEditingController shortController =
        TextEditingController(text: marker.info.shortDescription);
    TextEditingController longController =
        TextEditingController(text: marker.info.longDescription);

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final newMarker = marker.info.shortDescription == '';

    final ismobile = isMobile();

    return showDialog<MarkerData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Marker Info'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  autofocus: ismobile ? false : true,
                  decoration: InputDecoration(
                    labelText: "Title *", // Add an asterisk
                    border: OutlineInputBorder(),
                  ),
                  controller: shortController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "A title is required";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: longController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Description", // Add an asterisk
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            newMarker
                ? SizedBox.shrink()
                : IconButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.red),
                      foregroundColor:
                          WidgetStateProperty.all<Color>(Colors.white),
                    ),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      marker.delete = true;
                      Navigator.of(context).pop(marker);
                    }),
            OutlinedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    const Color.fromARGB(255, 76, 147, 175)),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  // The form is valid, do something
                  //marker.position = normalizedPosition;
                  marker.info = MarkerDescription(
                      shortDescription: shortController.text,
                      longDescription: longController.text);
                  Navigator.of(context).pop(marker);
                }
              },
              child: Text(newMarker ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

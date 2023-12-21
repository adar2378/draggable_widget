library draggable_widget;

import 'dart:math';

import 'package:flutter/material.dart';

import 'model/anchor_docker.dart';

export 'model/anchor_docker.dart';

class DraggableWidget extends StatefulWidget {
  /// The widget that will be displayed as dragging widget
  final Widget child;

  /// The horizontal padding around the widget
  final double horizontalSpace;

  /// The vertical padding around the widget
  final double verticalSpace;

  /// Intial location of the widget, default to [AnchoringPosition.bottomRight]
  final AnchoringPosition initialPosition;

  /// Intially should the widget be visible or not, default to [true]
  final bool initialVisibility;

  /// The top bottom pargin to create the bottom boundary for the widget, for example if you have a [BottomNavigationBar],
  /// then you may need to set the bottom boundary so that the draggable button can't get on top of the [BottomNavigationBar]
  final double bottomMargin;

  /// The top bottom pargin to create the top boundary for the widget, for example if you have a [AppBar],
  /// then you may need to set the bottom boundary so that the draggable button can't get on top of the [AppBar]
  final double topMargin;

  /// Status bar's height, default to 24
  final double statusBarHeight;

  /// Shadow's border radius for the draggable widget, default to 10
  final double shadowBorderRadius;

  /// A drag controller to show/hide or move the widget around the screen
  final DragController? dragController;

  /// [BoxShadow] when the widget is not being dragged, default to
  /// ```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 4),
  ///    blurRadius: 2,
  ///  ),
  /// ```

  final BoxShadow normalShadow;

  /// [BoxShadow] when the widget is being dragged
  ///```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 10),
  ///    blurRadius: 10,
  ///  ),
  /// ```
  final BoxShadow draggingShadow;

  /// How much should the [DraggableWidget] be scaled when it is being dragged, default to 1.1
  final double dragAnimationScale;

  /// Touch Delay Duration. Default value is zero. When set, drag operations will trigger after the duration.
  final Duration touchDelay;

  DraggableWidget({
    Key? key,
    required this.child,
    this.horizontalSpace = 0,
    this.verticalSpace = 0,
    this.initialPosition = AnchoringPosition.bottomRight,
    this.initialVisibility = true,
    this.bottomMargin = 0,
    this.topMargin = 0,
    this.statusBarHeight = 24,
    this.shadowBorderRadius = 10,
    this.dragController,
    this.dragAnimationScale = 1.1,
    this.touchDelay = Duration.zero,
    this.normalShadow = const BoxShadow(
      color: Colors.black38,
      offset: Offset(0, 4),
      blurRadius: 2,
    ),
    this.draggingShadow = const BoxShadow(
      color: Colors.black38,
      offset: Offset(0, 10),
      blurRadius: 10,
    ),
  })  : assert(statusBarHeight >= 0),
        assert(horizontalSpace >= 0),
        assert(verticalSpace >= 0),
        assert(bottomMargin >= 0),
        super(key: key);
  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget>
    with SingleTickerProviderStateMixin {
  double top = 0, left = 0;
  double boundary = 0;
  late AnimationController animationController;
  late Animation animation;
  double hardLeft = 0, hardTop = 0;
  bool offstage = true;

  AnchoringPosition? currentDocker;

  double widgetHeight = 18;
  double widgetWidth = 50;

  double middleAreaTop = 72;
  double middleAreaLeft = 72;

  final key = GlobalKey();

  bool dragging = false;

  late AnchoringPosition currentlyDocked;

  bool? visible;

  bool get currentVisibility => visible ?? widget.initialVisibility;

  bool isStillTouching = false;

  @override
  void initState() {
    currentlyDocked = widget.initialPosition;
    hardTop = widget.topMargin;
    animationController = AnimationController(
      value: 1,
      vsync: this,
      duration: Duration(milliseconds: 150),
    )
      ..addListener(() {
        if (currentDocker != null) {
          animateWidget(currentDocker!);
        }
      })
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            hardLeft = left;
            hardTop = top;
          }
        },
      );

    animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    widget.dragController?._addState(this);

    if (WidgetsBinding.instance != null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        final widgetSize = getWidgetSize(key);
        if (widgetSize != null) {
          setState(() {
            widgetHeight = widgetSize.height;
            widgetWidth = widgetSize.width;

            middleAreaLeft = MediaQuery.of(context).size.width * 0.1;
            middleAreaTop = MediaQuery.of(context).size.height * 0.1;
          });
        }

        await Future.delayed(Duration(
          milliseconds: 100,
        ));
        setState(() {
          offstage = false;
          boundary = MediaQuery.of(context).size.height - widget.bottomMargin;
          if (widget.initialPosition == AnchoringPosition.bottomRight) {
            top = boundary - widgetHeight + widget.statusBarHeight;
            left = MediaQuery.of(context).size.width - widgetWidth;
          } else if (widget.initialPosition == AnchoringPosition.bottomLeft) {
            top = boundary - widgetHeight + widget.statusBarHeight;
            left = 0;
          } else if (widget.initialPosition == AnchoringPosition.topRight) {
            top = widget.topMargin;
            left = MediaQuery.of(context).size.width - widgetWidth;
          } else if (widget.initialPosition == AnchoringPosition.topLeft) {
            top = widget.topMargin;
            left = 0;
          } else if (widget.initialPosition == AnchoringPosition.topCenter) {
            top = widget.topMargin;
            left = MediaQuery.of(context).size.width / 2 - widgetWidth / 2;
          } else if (widget.initialPosition == AnchoringPosition.bottomCenter) {
            top = boundary - widgetHeight + widget.statusBarHeight;
            left = MediaQuery.of(context).size.width / 2 - widgetWidth / 2;
          } else if (widget.initialPosition == AnchoringPosition.leftCenter) {
            top = MediaQuery.of(context).size.height / 2 - widgetHeight / 2;
            left = 0;
          } else if (widget.initialPosition == AnchoringPosition.rightCenter) {
            top = MediaQuery.of(context).size.height / 2 - widgetHeight / 2;
            left = MediaQuery.of(context).size.width - widgetWidth;
          } else {
            top = MediaQuery.of(context).size.height / 2 - widgetHeight / 2;
            left = MediaQuery.of(context).size.width / 2 - widgetWidth / 2;
          }
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableWidget oldWidget) {
    if (offstage == false && WidgetsBinding.instance != null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        final widgetSize = getWidgetSize(key);
        if (widgetSize != null) {
          setState(() {
            widgetHeight = widgetSize.height;
            widgetWidth = widgetSize.width;
          });
        }
        setState(() {
          boundary = MediaQuery.of(context).size.height - widget.bottomMargin;
          animateWidget(currentlyDocked);
        });
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: AnimatedSwitcher(
        duration: Duration(
          milliseconds: 150,
        ),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: !currentVisibility
            ? Container()
            : Listener(
                onPointerUp: (v) {
                  if (!isStillTouching) {
                    return;
                  }
                  isStillTouching = false;

                  final p = v.position;
                  currentDocker = determineDocker(p.dx, p.dy);
                  setState(() {
                    dragging = false;
                  });
                  if (animationController.isAnimating) {
                    animationController.stop();
                  }
                  animationController.reset();
                  animationController.forward();
                },
                onPointerDown: (v) async {
                  isStillTouching = false;
                  await Future.delayed(widget.touchDelay);
                  isStillTouching = true;
                },
                onPointerMove: (v) async {
                  if (!isStillTouching) {
                    return;
                  }
                  if (animationController.isAnimating) {
                    animationController.stop();
                    animationController.reset();
                  }

                  setState(() {
                    dragging = true;
                    if (v.position.dy < boundary &&
                        v.position.dy > widget.topMargin) {
                      top = max(v.position.dy - (widgetHeight) / 2, 0);
                    }

                    left = max(v.position.dx - (widgetWidth) / 2, 0);

                    hardLeft = left;
                    hardTop = top;
                  });
                },
                child: Offstage(
                  offstage: offstage,
                  child: Container(
                    key: key,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.horizontalSpace,
                      vertical: widget.verticalSpace,
                    ),
                    child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.shadowBorderRadius),
                          boxShadow: [
                            dragging
                                ? widget.draggingShadow
                                : widget.normalShadow
                            // BoxShadow(
                            //   color: Colors.black38,
                            //   offset: dragging ? Offset(0, 10) : Offset(0, 4),
                            //   blurRadius: dragging ? 10 : 2,
                            // )
                          ],
                        ),
                        child: Transform.scale(
                            scale: dragging ? widget.dragAnimationScale : 1,
                            child: widget.child)),
                  ),
                ),
              ),
      ),
    );
  }

  AnchoringPosition determineDocker(double x, double y) {
    final double totalHeight = boundary;
    final double totalWidth = MediaQuery.of(context).size.width;

    if (x < totalWidth / 2 - middleAreaLeft && y < totalHeight / 2 - middleAreaTop) {
      return AnchoringPosition.topLeft;
    } else if (x < totalWidth / 2 - middleAreaLeft && y > totalHeight / 2 + middleAreaTop) {
      return AnchoringPosition.bottomLeft;
    } else if (x > totalWidth / 2 + middleAreaLeft && y < totalHeight / 2 - middleAreaTop) {
      return AnchoringPosition.topRight;
    } else if (x > totalWidth / 2 + middleAreaLeft && y > totalHeight / 2 + middleAreaTop) {
      return AnchoringPosition.bottomRight;
    } else if (x == x.clamp(totalWidth / 2 - middleAreaLeft, totalWidth / 2 + middleAreaLeft) && y < totalHeight / 2 - middleAreaTop) {
      return AnchoringPosition.topCenter;
    } else if (x == x.clamp(totalWidth / 2 - middleAreaLeft, totalWidth / 2 + middleAreaLeft) && y > totalHeight / 2 + middleAreaTop) {
      return AnchoringPosition.bottomCenter;
    } else if (x < totalWidth / 2 - middleAreaLeft && y == y.clamp(totalHeight / 2 - middleAreaTop, totalHeight / 2 + middleAreaTop)) {
      return AnchoringPosition.leftCenter;
    } else if (x > totalWidth / 2 + middleAreaLeft && y == y.clamp(totalHeight / 2 - middleAreaTop, totalHeight / 2 + middleAreaTop)) {
      return AnchoringPosition.rightCenter;
    } else {
      return AnchoringPosition.center;
    }
  }

  void animateWidget(AnchoringPosition docker) {
    final double totalHeight = boundary;
    final double totalWidth = MediaQuery.of(context).size.width;

    switch (docker) {
      case AnchoringPosition.topLeft:
        setState(() {
          left = (1 - animation.value) * hardLeft;
          if (animation.value == 0) {
            top = hardTop;
          } else {
            top = ((1 - animation.value) * hardTop +
                (widget.topMargin * (animation.value)));
          }
          currentlyDocked = AnchoringPosition.topLeft;
        });
        break;
      case AnchoringPosition.topRight:
        double remainingDistanceX = (totalWidth - widgetWidth - hardLeft);
        setState(() {
          left = hardLeft + (animation.value) * remainingDistanceX;
          if (animation.value == 0) {
            top = hardTop;
          } else {
            top = ((1 - animation.value) * hardTop +
                (widget.topMargin * (animation.value)));
          }
          currentlyDocked = AnchoringPosition.topRight;
        });
        break;
      case AnchoringPosition.bottomLeft:
        double remainingDistanceY = (totalHeight - widgetHeight - hardTop);
        setState(() {
          left = (1 - animation.value) * hardLeft;
          top = hardTop +
              (animation.value) * remainingDistanceY +
              (widget.statusBarHeight * animation.value);
          currentlyDocked = AnchoringPosition.bottomLeft;
        });
        break;
      case AnchoringPosition.bottomRight:
        double remainingDistanceX = (totalWidth - widgetWidth - hardLeft);
        double remainingDistanceY = (totalHeight - widgetHeight - hardTop);
        setState(() {
          left = hardLeft + (animation.value) * remainingDistanceX;
          top = hardTop +
              (animation.value) * remainingDistanceY +
              (widget.statusBarHeight * animation.value);
          currentlyDocked = AnchoringPosition.bottomRight;
        });
        break;
      case AnchoringPosition.center:
        double remainingDistanceX =
            (totalWidth / 2 - (widgetWidth / 2)) - hardLeft;
        double remainingDistanceY =
            (totalHeight / 2 - (widgetHeight / 2)) - hardTop;
        // double remainingDistanceX = (totalWidth - widgetWidth - hardLeft) / 2.0;
        // double remainingDistanceY = (totalHeight - widgetHeight - hardTop) / 2.0;
        setState(() {
          left = (animation.value) * remainingDistanceX + hardLeft;
          top = (animation.value) * remainingDistanceY + hardTop;
          currentlyDocked = AnchoringPosition.center;
        });
        break;
      case AnchoringPosition.topCenter:
        double remainingDistanceX =
            (totalWidth / 2 - (widgetWidth / 2)) - hardLeft;
        setState(() {
          left = (animation.value) * remainingDistanceX + hardLeft;
          if (animation.value == 0) {
            top = hardTop;
          } else {
            top = ((1 - animation.value) * hardTop +
                (widget.topMargin * (animation.value)));
          }
          currentlyDocked = AnchoringPosition.topCenter;
        });
        break;
      case AnchoringPosition.bottomCenter:
        double remainingDistanceX =
            (totalWidth / 2 - (widgetWidth / 2)) - hardLeft;
        double remainingDistanceY = (totalHeight - widgetHeight - hardTop);
        setState(() {
          left = (animation.value) * remainingDistanceX + hardLeft;
          top = hardTop +
              (animation.value) * remainingDistanceY +
              (widget.statusBarHeight * animation.value);
        });
        currentlyDocked = AnchoringPosition.bottomCenter;
        break;
      case AnchoringPosition.leftCenter:
        double remainingDistanceY =
            (totalHeight / 2 - (widgetHeight / 2)) - hardTop;
        setState(() {
          left = (1 - animation.value) * hardLeft;
          top = (animation.value) * remainingDistanceY + hardTop;
          currentlyDocked = AnchoringPosition.leftCenter;
        });
        break;
      case AnchoringPosition.rightCenter:
        double remainingDistanceX = (totalWidth - widgetWidth - hardLeft);
        double remainingDistanceY =
            (totalHeight / 2 - (widgetHeight / 2)) - hardTop;
        setState(() {
          left = hardLeft + (animation.value) * remainingDistanceX;
          top = (animation.value) * remainingDistanceY + hardTop;
          currentlyDocked = AnchoringPosition.rightCenter;
        });
        break;
      default:
    }
  }

  Size? getWidgetSize(GlobalKey key) {
    final keyContext = key.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      return box.size;
    } else {
      return null;
    }
  }

  void _showWidget() {
    setState(() {
      visible = true;
    });
  }

  void _hideWidget() {
    setState(() {
      visible = false;
    });
  }

  void _animateTo(AnchoringPosition anchoringPosition) {
    if (animationController.isAnimating) {
      animationController.stop();
    }
    animationController.reset();
    currentDocker = anchoringPosition;
    animationController.forward();
  }

  Offset _getCurrentPosition() {
    return Offset(left, top);
  }
}

class DragController {
  _DraggableWidgetState? _widgetState;
  void _addState(_DraggableWidgetState _widgetState) {
    this._widgetState = _widgetState;
  }

  /// Jump to any [AnchoringPosition] programatically
  void jumpTo(AnchoringPosition anchoringPosition) {
    _widgetState?._animateTo(anchoringPosition);
  }

  /// Get the current screen [Offset] of the widget
  Offset? getCurrentPosition() {
    return _widgetState?._getCurrentPosition();
  }

  /// Makes the widget visible
  void showWidget() {
    _widgetState?._showWidget();
  }

  /// Hide the widget
  void hideWidget() {
    _widgetState?._hideWidget();
  }
}

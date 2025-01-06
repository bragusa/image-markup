import 'dart:math';

import 'package:flutter/material.dart';

class ConstrainedDraggable<T extends Object> extends StatefulWidget {
  final Widget child;
  final Widget feedback;
  final Widget? childWhenDragging;
  final RenderBox? renderBox;
  final Axis? axis;
  final Offset initialPosition;
  final void Function()? onDragStarted;
  final void Function(DraggableDetails)? onDragEnd;
  final DraggableCanceledCallback? onDraggableCanceled;
  final void Function()? onDragCompleted;
  final DragUpdateCallback? onDragUpdate;
  final Point? pointerOffset;
  final int? maxSimultaneousDrags;

  const ConstrainedDraggable({
    super.key,
    required this.child,
    required this.feedback,
    this.childWhenDragging,
    this.renderBox,
    this.axis,
    this.initialPosition = Offset.zero,
    this.onDragStarted,
    this.onDragEnd,
    this.onDraggableCanceled,
    this.onDragCompleted,
    this.onDragUpdate,
    this.pointerOffset, 
    this.maxSimultaneousDrags
  });

  @override
  ConstrainedDraggableState<T> createState() => ConstrainedDraggableState<T>();
}

class ConstrainedDraggableState<T extends Object> extends State<ConstrainedDraggable<T>> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition; // Initialize the position from the parent
  }

  Offset _constrainOffset(Offset offset, RenderBox renderBox) {
    // Get the global bounds of the RenderBox
    final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
    print('pointerOffset: ${widget.pointerOffset}');
    final Rect bounds = Rect.fromLTWH(
      globalPosition.dx - (widget.pointerOffset?.x ?? 0),
      globalPosition.dy - (widget.pointerOffset?.y ?? 0),
      renderBox.size.width - (widget.pointerOffset?.x ?? 0),
      renderBox.size.height - (widget.pointerOffset?.y ?? 0),
    );

    // Constrain the offset within these bounds
    double left = offset.dx.clamp(bounds.left, bounds.right);
    double top = offset.dy.clamp(bounds.top, bounds.bottom);
    
    print('top: $top, left: $left');
    print('bounds.left: ${bounds.left}, bounds.right: ${bounds.right}');
    print('bounds.top: ${bounds.top}, bounds.bottom: ${bounds.bottom}');

    return Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable<T>(
        maxSimultaneousDrags: widget.maxSimultaneousDrags,
        feedback: widget.feedback,
        childWhenDragging: widget.childWhenDragging,
        onDragStarted: widget.onDragStarted,
        onDragEnd: (details) {
        final RenderBox renderBox = widget.renderBox ?? context.findRenderObject() as RenderBox;
        final Offset constrainedOffset = _constrainOffset(details.offset, renderBox);

          setState(() {
            position = constrainedOffset; // Update the position in the state
          });

          if (widget.onDragEnd != null) {
            widget.onDragEnd!(DraggableDetails(
              velocity: details.velocity,
              offset: constrainedOffset,
            ));
          }
        },
        onDraggableCanceled: widget.onDraggableCanceled,
        onDragCompleted: widget.onDragCompleted,
        onDragUpdate: widget.onDragUpdate,
        child: widget.child,
      ),
    );
  }
}

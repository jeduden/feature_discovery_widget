import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

/// Based on Flutters CompositeTransform widgets/layers,
/// but relaxed the requirements. since it is fine for feature overlays to lag a frame behind.
/// It is better than to have to figure out the paint order of a large app and guarantee it as application developer.

/// An object that a [LooseLeaderLayer] can register with.
///
/// An instance of this class should be provided as the [LooseLeaderLayer.link] and
/// the [LooseFollowerLayer.link] properties to cause the [LooseFollowerLayer] to follow
/// the [LooseLeaderLayer].
///
/// See also:
///
///  * [CompositedTransformLooseTarget], the widget that creates a [LooseLeaderLayer].
///  * [CompositedTransformLooseFollower], the widget that creates a [LooseFollowerLayer].
///  * [RenderLooseLeaderLayer] and [RenderLooseFollowerLayer], the corresponding
///    render objects.
class LooseLayerLink {
  /// The currently-registered [LooseLeaderLayer], if any.
  LooseLeaderLayer? get leader => _leader;
  LooseLeaderLayer? _leader;

  /// The total size of [leader]'s contents.
  ///
  /// Generally this should be set by the [RenderObject] that paints on the
  /// registered [leader] layer (for instance a [RenderLooseLeaderLayer] that shares
  /// this link with its followers). This size may be outdated before and during
  /// layout.
  Size? leaderSize;

  @override
  String toString() => '${describeIdentity(this)}(${ _leader != null ? "<linked>" : "<dangling>" })';
}

/// A composited layer that can be followed by a [LooseFollowerLayer].
///
/// This layer collapses the accumulated offset into a transform and passes
/// [Offset.zero] to its child layers in the [addToScene]/[addChildrenToScene]
/// methods, so that [applyTransform] will work reliably.
class LooseLeaderLayer extends ContainerLayer {
  /// Creates a leader layer.
  ///
  /// The [link] property must not be null, and must not have been provided to
  /// any other [LooseLeaderLayer] layers that are [attached] to the layer tree at
  /// the same time.
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  LooseLeaderLayer({ required this.link, required this.offset });

  /// The object with which this layer should register.
  ///
  /// The link will be established when this layer is [attach]ed, and will be
  /// cleared when this layer is [detach]ed.
  final LooseLayerLink link;

  /// Offset from parent in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  Offset offset;

  /// {@macro flutter.rendering.FollowerLayer.alwaysNeedsAddToScene}
  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void attach(Object owner) {
    super.attach(owner);
    assert(link.leader == null);
    _lastOffset = null;
    link._leader = this;
  }

  @override
  void detach() {
    //assert(link.leader == this); seems to not make sense to be this strict in our case.
    link._leader = null;
    _lastOffset = null;
    super.detach();
  }

  /// The offset the last time this layer was composited.
  ///
  /// This is reset to null when the layer is attached or detached, to help
  /// catch cases where the follower layer ends up before the leader layer, but
  /// not every case can be detected.
  Offset? _lastOffset;

  @override
  bool findAnnotations<S extends Object>(AnnotationResult<S> result, Offset localPosition, { required bool onlyFirst }) {
    
    return super.findAnnotations<S>(result, localPosition - offset, onlyFirst: onlyFirst);
  }

  @override
  void addToScene(SceneBuilder builder, [ Offset layerOffset = Offset.zero ]) {
    
    _lastOffset = offset + layerOffset;
    if (_lastOffset != Offset.zero)
      engineLayer = builder.pushTransform(
        Matrix4.translationValues(_lastOffset!.dx, _lastOffset!.dy, 0.0).storage,
        oldLayer: engineLayer as TransformEngineLayer?,
      );
    addChildrenToScene(builder);
    if (_lastOffset != Offset.zero)
      builder.pop();
  }

  /// Applies the transform that would be applied when compositing the given
  /// child to the given matrix.
  ///
  /// See [ContainerLayer.applyTransform] for details.
  ///
  /// The `child` argument may be null, as the same transform is applied to all
  /// children.
  @override
  void applyTransform(Layer? child, Matrix4 transform) {
    assert(_lastOffset != null);
    if (_lastOffset != Offset.zero)
      transform.translate(_lastOffset!.dx, _lastOffset!.dy);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(DiagnosticsProperty<LooseLayerLink>('link', link));
  }
}

/// A composited layer that applies a transformation matrix to its children such
/// that they are positioned to match a [LeaderLayer].
///
/// If any of the ancestors of this layer have a degenerate matrix (e.g. scaling
/// by zero), then the [FollowerLayer] will not be able to transform its child
/// to the coordinate space of the [LeaderLayer].
///
/// A [linkedOffset] property can be provided to further offset the child layer
/// from the leader layer, for example if the child is to follow the linked
/// layer at a distance rather than directly overlapping it.
class LooseFollowerLayer extends ContainerLayer {
  /// Creates a follower layer.
  ///
  /// The [link] property must not be null.
  ///
  /// The [unlinkedOffset], [linkedOffset], and [showWhenUnlinked] properties
  /// must be non-null before the compositing phase of the pipeline.
  LooseFollowerLayer({
    required LooseLayerLink link,
    this.showWhenUnlinked = true,
    this.unlinkedOffset = Offset.zero,
    this.linkedOffset = Offset.zero,
  }) : assert(link != null), _link = link;

  /// The link to the [LeaderLayer].
  ///
  /// The same object should be provided to a [LeaderLayer] that is earlier in
  /// the layer tree. When this layer is composited, it will apply a transform
  /// that moves its children to match the position of the [LeaderLayer].
  LooseLayerLink get link => _link;
  set link(LooseLayerLink value) {
    assert(value != null);
    _link = value;
  }
  LooseLayerLink _link;

  /// Whether to show the layer's contents when the [link] does not point to a
  /// [LeaderLayer].
  ///
  /// When the layer is linked, children layers are positioned such that they
  /// have the same global position as the linked [LeaderLayer].
  ///
  /// When the layer is not linked, then: if [showWhenUnlinked] is true,
  /// children are positioned as if the [LooseFollowerLayer] was a [ContainerLayer];
  /// if it is false, then children are hidden.
  ///
  /// The [showWhenUnlinked] property must be non-null before the compositing
  /// phase of the pipeline.
  bool? showWhenUnlinked;

  /// Offset from parent in the parent's coordinate system, used when the layer
  /// is not linked to a [LeaderLayer].
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [unlinkedOffset] property must be non-null before the compositing
  /// phase of the pipeline.
  ///
  /// See also:
  ///
  ///  * [linkedOffset], for when the layers are linked.
  Offset? unlinkedOffset;

  /// Offset from the origin of the leader layer to the origin of the child
  /// layers, used when the layer is linked to a [LeaderLayer].
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [linkedOffset] property must be non-null before the compositing phase
  /// of the pipeline.
  ///
  /// See also:
  ///
  ///  * [unlinkedOffset], for when the layer is not linked.
  Offset? linkedOffset;

  Offset? _lastOffset;
  Matrix4? _lastTransform;
  Matrix4? _invertedTransform;
  bool _inverseDirty = true;

  Offset? _transformOffset(Offset localPosition) {
    if (_inverseDirty) {
      final trans = getLastTransform();
      if(trans == null) {
        return null;
      }
      _invertedTransform = Matrix4.tryInvert(trans);
      _inverseDirty = false;
    }
    if (_invertedTransform == null)
      return null;
    final Vector4 vector = Vector4(localPosition.dx, localPosition.dy, 0.0, 1.0);
    final Vector4 result = _invertedTransform!.transform(vector);
    return Offset(result[0] - linkedOffset!.dx, result[1] - linkedOffset!.dy);
  }

  @override
  bool findAnnotations<S extends Object>(AnnotationResult<S> result, Offset localPosition, { required bool onlyFirst }) {
    if (link.leader == null) {
      if (showWhenUnlinked!) {
        return super.findAnnotations(result, localPosition - unlinkedOffset!, onlyFirst: onlyFirst);
      }
      return false;
    }
    final Offset? transformedOffset = _transformOffset(localPosition);
    if (transformedOffset == null) {
      return false;
    }
    return super.findAnnotations<S>(result, transformedOffset, onlyFirst: onlyFirst);
  }

  /// The transform that was used during the last composition phase.
  ///
  /// If the [link] was not linked to a [LooseLeaderLayer], or if this layer has
  /// a degenerate matrix applied, then this will be null.
  ///
  /// This method returns a new [Matrix4] instance each time it is invoked.
  Matrix4? getLastTransform() {
    if (_lastTransform == null)
      return null;
    final Matrix4 result = Matrix4.translationValues(-_lastOffset!.dx, -_lastOffset!.dy, 0.0);
    result.multiply(_lastTransform!);
    return result;
  }

  /// Call [applyTransform] for each layer in the provided list.
  ///
  /// The list is in reverse order (deepest first). The first layer will be
  /// treated as the child of the second, and so forth. The first layer in the
  /// list won't have [applyTransform] called on it. The first layer may be
  /// null.
  static Matrix4 _collectTransformForLayerChain(List<ContainerLayer?> layers) {
    // Initialize our result matrix.
    final Matrix4 result = Matrix4.identity();
    // Apply each layer to the matrix in turn, starting from the last layer,
    // and providing the previous layer as the child.
    for (int index = layers.length - 1; index > 0; index -= 1)
      layers[index]?.applyTransform(layers[index - 1], result);
    return result;
  }

  /// Find the common ancestor of two layers [a] and [b] by searching towards
  /// the root of the tree, and append each ancestor of [a] or [b] visited along
  /// the path to [ancestorsA] and [ancestorsB] respectively.
  ///
  /// Returns null if [a] [b] do not share a common ancestor, in which case the
  /// results in [ancestorsA] and [ancestorsB] are undefined.
  static Layer? _pathsToCommonAncestor(
    Layer? a,
    Layer? b,
    List<ContainerLayer?> ancestorsA,
    List<ContainerLayer?> ancestorsB,
  ) {
    // No common ancestor found.
    if (a == null || b == null)
      return null;

    if (identical(a, b))
      return a;

    if (a.depth < b.depth) {
      ancestorsB.add(b.parent);
      return _pathsToCommonAncestor(a, b.parent, ancestorsA, ancestorsB);
    } else if (a.depth > b.depth) {
      ancestorsA.add(a.parent);
      return _pathsToCommonAncestor(a.parent, b, ancestorsA, ancestorsB);
    }

    ancestorsA.add(a.parent);
    ancestorsB.add(b.parent);
    return _pathsToCommonAncestor(a.parent, b.parent, ancestorsA, ancestorsB);
  }

  /// Populate [_lastTransform] given the current state of the tree.
  void _establishTransform() {
    assert(link != null);
    _lastTransform = null;
    final LooseLeaderLayer? leader = link.leader;
    // Check to see if we are linked.
    if (leader == null)
      return;
    // If we're linked, check the link is valid.
    assert(
      leader.owner == owner,
      'Linked LeaderLayer anchor is not in the same layer tree as the FollowerLayer.',
    );
    if(leader._lastOffset == null) {
      // LeaderLayer anchor must have been rendered at least once
      return;
    }

    // Stores [leader, ..., commonAncestor] after calling _pathsToCommonAncestor.
    final List<ContainerLayer?> forwardLayers = <ContainerLayer>[leader];
    // Stores [this (follower), ..., commonAncestor] after calling
    // _pathsToCommonAncestor.
    final List<ContainerLayer?> inverseLayers = <ContainerLayer>[this];

    final Layer? ancestor = _pathsToCommonAncestor(
      leader, this,
      forwardLayers, inverseLayers,
    );
    assert(ancestor != null);

    final Matrix4 forwardTransform = _collectTransformForLayerChain(forwardLayers);
    // Further transforms the coordinate system to a hypothetical child (null)
    // of the leader layer, to account for the leader's additional paint offset
    // and layer offset (LeaderLayer._lastOffset).
    leader.applyTransform(null, forwardTransform);
    forwardTransform.translate(linkedOffset!.dx, linkedOffset!.dy);

    final Matrix4 inverseTransform = _collectTransformForLayerChain(inverseLayers);

    if (inverseTransform.invert() == 0.0) {
      // We are in a degenerate transform, so there's not much we can do.
      return;
    }
    // Combine the matrices and store the result.
    inverseTransform.multiply(forwardTransform);
    _lastTransform = inverseTransform;
    _inverseDirty = true;
  }

  /// {@template LooseFollowerLayer.alwaysNeedsAddToScene}
  /// This disables retained rendering.
  ///
  /// A [LooseFollowerLayer] copies changes from a [LeaderLayer] that could be anywhere
  /// in the Layer tree, and that leader layer could change without notifying the
  /// follower layer. Therefore we have to always call a follower layer's
  /// [addToScene]. In order to call follower layer's [addToScene], leader layer's
  /// [addToScene] must be called first so leader layer must also be considered
  /// as [alwaysNeedsAddToScene].
  /// {@endtemplate}
  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(SceneBuilder builder, [ Offset layerOffset = Offset.zero ]) {
    assert(link != null);
    assert(showWhenUnlinked != null);
    if (link.leader == null && !showWhenUnlinked!) {
      _lastTransform = null;
      _lastOffset = null;
      _inverseDirty = true;
      engineLayer = null;
      return;
    }
    _establishTransform();
    if (_lastTransform != null) {
      engineLayer = builder.pushTransform(
        _lastTransform!.storage,
        oldLayer: engineLayer as TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
      _lastOffset = unlinkedOffset! + layerOffset;
    } else {
      _lastOffset = null;
      final Matrix4 matrix = Matrix4.translationValues(unlinkedOffset!.dx, unlinkedOffset!.dy, .0);
      engineLayer = builder.pushTransform(
        matrix.storage,
        oldLayer: engineLayer as TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
    }
    _inverseDirty = true;
  }

  @override
  void applyTransform(Layer? child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    if (_lastTransform != null) {
      transform.multiply(_lastTransform!);
    } else {
      transform.multiply(Matrix4.translationValues(unlinkedOffset!.dx, unlinkedOffset!.dy, 0));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LooseLayerLink>('link', link));
    properties.add(TransformProperty('transform', getLastTransform(), defaultValue: null));
  }
}

/// Provides an anchor for a [RenderLooseFollowerLayer].
///
/// See also:
///
///  * [CompositedTransformLooseTarget], the corresponding widget.
///  * [LooseLeaderLayer], the layer that this render object creates.
class RenderLooseLeaderLayer extends RenderProxyBox {
  /// Creates a render object that uses a [LooseLeaderLayer].
  ///
  /// The [link] must not be null.
  RenderLooseLeaderLayer({
    required LooseLayerLink link,
    RenderBox? child,
  }) : assert(link != null),
       _link = link,
       super(child);

  /// The link object that connects this [RenderLooseLeaderLayer] with one or more
  /// [RenderLooseFollowerLayer]s.
  ///
  /// This property must not be null. The object must not be associated with
  /// another [RenderLooseLeaderLayer] that is also being painted.
  LooseLayerLink get link => _link;
  LooseLayerLink _link;
  set link(LooseLayerLink value) {
    assert(value != null);
    if (_link == value)
      return;
    _link.leaderSize = null;
    _link = value;
    if (_previousLayoutSize != null) {
      _link.leaderSize = _previousLayoutSize;
    }
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  // The latest size of this [RenderBox], computed during the previous layout
  // pass. It should always be equal to [size], but can be accessed even when
  // [debugDoingThisResize] and [debugDoingThisLayout] are false.
  Size? _previousLayoutSize;

  @override
  void performLayout() {
    super.performLayout();
    _previousLayoutSize = size;
    link.leaderSize = size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final LooseLeaderLayer? leaderLayer = layer as LooseLeaderLayer?;

    if (leaderLayer == null || leaderLayer.link != link) {
      layer = LooseLeaderLayer(link: link, offset: offset);
    } else {
      leaderLayer
        ..offset = offset;
    }
    context.pushLayer(layer!, super.paint, Offset.zero);
    assert(layer != null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LooseLayerLink>('link', link));
  }
}


/// Transform the child so that its origin is [offset] from the origin of the
/// [RenderLooseLeaderLayer] with the same [LooseLayerLink].
///
/// The [RenderLooseLeaderLayer] in question must be earlier in the paint order.
///
/// Hit testing on descendants of this render object will only work if the
/// target position is within the box that this render object's parent considers
/// to be hittable.
///
/// See also:
///
///  * [CompositedTransformLooseFollower], the corresponding widget.
///  * [FollowerLayer], the layer that this render object creates.
class RenderLooseFollowerLayer extends RenderProxyBox {
  /// Creates a render object that uses a [FollowerLayer].
  ///
  /// The [link] and [offset] arguments must not be null.
  RenderLooseFollowerLayer({
    required LooseLayerLink link,
    bool showWhenUnlinked = true,
    Offset offset = Offset.zero,
    Alignment leaderAnchor = Alignment.topLeft,
    Alignment followerAnchor = Alignment.topLeft,
    RenderBox? child,
  }) : assert(link != null),
       assert(showWhenUnlinked != null),
       assert(offset != null),
       _link = link,
       _showWhenUnlinked = showWhenUnlinked,
       _offset = offset,
       _leaderAnchor = leaderAnchor,
       _followerAnchor = followerAnchor,
       super(child);

  /// The link object that connects this [RenderFollowerLayer] with a
  /// [RenderLeaderLayer] earlier in the paint order.
  LooseLayerLink get link => _link;
  LooseLayerLink _link;
  set link(LooseLayerLink value) {
    assert(value != null);
    if (_link == value)
      return;
    _link = value;
    markNeedsPaint();
  }

  /// Whether to show the render object's contents when there is no
  /// corresponding [RenderLooseLeaderLayer] with the same [link].
  ///
  /// When the render object is linked, the child is positioned such that it has
  /// the same global position as the linked [RenderLooseLeaderLayer].
  ///
  /// When the render object is not linked, then: if [showWhenUnlinked] is true,
  /// the child is visible and not repositioned; if it is false, then child is
  /// hidden, and its hit testing is also disabled.
  bool get showWhenUnlinked => _showWhenUnlinked;
  bool _showWhenUnlinked;
  set showWhenUnlinked(bool value) {
    assert(value != null);
    if (_showWhenUnlinked == value)
      return;
    _showWhenUnlinked = value;
    markNeedsPaint();
  }

  /// The offset to apply to the origin of the linked [RenderLooseLeaderLayer] to
  /// obtain this render object's origin.
  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    assert(value != null);
    if (_offset == value)
      return;
    _offset = value;
    markNeedsPaint();
  }

  /// The anchor point on the linked [RenderLooseLeaderLayer] that [followerAnchor]
  /// will line up with.
  ///
  /// {@template flutter.rendering.RenderFollowerLayer.leaderAnchor}
  /// For example, when [leaderAnchor] and [followerAnchor] are both
  /// [Alignment.topLeft], this [RenderLooseFollowerLayer] will be top left aligned
  /// with the linked [RenderLooserLeaderLayer]. When [leaderAnchor] is
  /// [Alignment.bottomLeft] and [followerAnchor] is [Alignment.topLeft], this
  /// [RenderLooseFollowerLayer] will be left aligned with the linked
  /// [RenderLooseLeaderLayer], and its top edge will line up with the
  /// [RenderLooseLeaderLayer]'s bottom edge.
  /// {@endtemplate}
  ///
  /// Defaults to [Alignment.topLeft].
  Alignment get leaderAnchor => _leaderAnchor;
  Alignment _leaderAnchor;
  set leaderAnchor(Alignment value) {
    assert(value != null);
    if (_leaderAnchor == value)
      return;
    _leaderAnchor = value;
    markNeedsPaint();
  }

  /// The anchor point on this [RenderFollowerLayer] that will line up with
  /// [followerAnchor] on the linked [RenderLeaderLayer].
  ///
  /// {@macro flutter.rendering.RenderFollowerLayer.leaderAnchor}
  ///
  /// Defaults to [Alignment.topLeft].
  Alignment get followerAnchor => _followerAnchor;
  Alignment _followerAnchor;
  set followerAnchor(Alignment value) {
    assert(value != null);
    if (_followerAnchor == value)
      return;
    _followerAnchor = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  /// The layer we created when we were last painted.
  @override
  LooseFollowerLayer? get layer => super.layer as LooseFollowerLayer?;

  /// Return the transform that was used in the last composition phase, if any.
  ///
  /// If the [FollowerLayer] has not yet been created, was never composited, or
  /// was unable to determine the transform (see
  /// [FollowerLayer.getLastTransform]), this returns the identity matrix (see
  /// [new Matrix4.identity].
  Matrix4 getCurrentTransform() {
    return layer?.getLastTransform() ?? Matrix4.identity();
  }

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    // Disables the hit testing if this render object is hidden or leader doesnt have an offset yet
    if ((link.leader == null && !showWhenUnlinked) || link.leader?._lastOffset ==null)
      return false;
    // RenderFollowerLayer objects don't check if they are
    // themselves hit, because it's confusing to think about
    // how the untransformed size and the child's transformed
    // position interact.
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    return result.addWithPaintTransform(
      transform: getCurrentTransform(),
      position: position,
      hitTest: (BoxHitTestResult result, Offset? position) {
        return super.hitTestChildren(result, position: position!);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Size? leaderSize = link.leaderSize;
    assert(
      link.leaderSize != null || (link.leader == null || leaderAnchor == Alignment.topLeft),
      '$link: layer is linked to ${link.leader} but a valid leaderSize is not set. '
      'leaderSize is required when leaderAnchor is not Alignment.topLeft '
      '(current value is $leaderAnchor).',
    );
    final Offset effectiveLinkedOffset = leaderSize == null
      ? this.offset
      : leaderAnchor.alongSize(leaderSize) - followerAnchor.alongSize(size) + this.offset;
    assert(showWhenUnlinked != null);
    if (layer == null) {
      layer = LooseFollowerLayer(
        link: link,
        showWhenUnlinked: showWhenUnlinked,
        linkedOffset: effectiveLinkedOffset,
        unlinkedOffset: offset,
      );
    } else {
      layer
        ?..link = link
        ..showWhenUnlinked = showWhenUnlinked
        ..linkedOffset = effectiveLinkedOffset
        ..unlinkedOffset = offset;
    }
    context.pushLayer(
      layer!,
      super.paint,
      Offset.zero,
      childPaintBounds: const Rect.fromLTRB(
        // We don't know where we'll end up, so we have no idea what our cull rect should be.
        double.negativeInfinity,
        double.negativeInfinity,
        double.infinity,
        double.infinity,
      ),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(getCurrentTransform());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LooseLayerLink>('link', link));
    properties.add(DiagnosticsProperty<bool>('showWhenUnlinked', showWhenUnlinked));
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(TransformProperty('current transform matrix', getCurrentTransform()));
  }
}


/// A widget that can be targeted by a [CompositedTransformLooseFollower].
///
/// When this widget is composited during the compositing phase (which comes
/// after the paint phase, as described in [WidgetsBinding.drawFrame]), it
/// updates the [link] object so that any [CompositedTransformLooseFollower] widgets
/// that are subsequently composited in the next frame and were given the same
/// [LooseLayerLink] can position themselves at the same screen location.
///
/// A single [CompositedTransformLooseTarget] can be followed by multiple
/// [CompositedTransformLooseFollower] widgets.
///
/// [CompositedTransformLooseFollower] may occur ealier in the paint order, since
/// this updates happen in the next frame.
///
/// See also:
///
///  * [CompositedTransformLooseFollower], the widget that can target this one.
///  * Compare with [CompositedTransformTarget] which has no delay but has stricter requirements.
///  * [LooseLeaderLayer], the layer that implements this widget's logic.
class CompositedTransformLooseTarget extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// The [link] property must not be null, and must not be currently being used
  /// by any other [CompositedTransformLooseTarget] object that is in the tree.
  const CompositedTransformLooseTarget({
    Key? key,
    required this.link,
    Widget? child,
  }) : assert(link != null),
       super(key: key, child: child);

  /// The link object that connects this [CompositedTransformLooseTarget] with one or
  /// more [CompositedTransformLooseFollower]s.
  ///
  /// This property must not be null. The object must not be associated with
  /// another [CompositedTransformLooseTarget] that is also being painted.
  final LooseLayerLink link;

  @override
  RenderLooseLeaderLayer createRenderObject(BuildContext context) {
    return RenderLooseLeaderLayer(
      link: link,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLooseLeaderLayer renderObject) {
    renderObject.link = link;
  }
}


/// A widget that follows a [CompositedTransformLooseTarget].
///
/// When this widget is composited during the compositing phase (which comes
/// after the paint phase, as described in [WidgetsBinding.drawFrame]), it
/// applies a transformation that brings [targetAnchor] of the linked
/// [CompositedTransformLooseTarget] and [followerAnchor] of this widget together.
/// The two anchor points will have the same global coordinates, unless [offset]
/// is not [Offset.zero], in which case [followerAnchor] will be offset by
/// [offset] in the linked [CompositedTransformLooseTarget]'s coordinate space.
///
/// The [LayerLink] object used as the [link] must be the same object as that
/// provided to the matching [CompositedTransformLooseTarget].
///
/// The [CompositedTransformLooseTarget] does not need to come earlier in the paint order than
/// this [CompositedTransformLooseFollower] - when this happens the follower will lag one frame behind.
///
/// Hit testing on descendants of this widget will only work if the target
/// position is within the box that this widget's parent considers to be
/// hittable. If the parent covers the screen, this is trivially achievable, so
/// this widget is usually used as the root of an [OverlayEntry] in an app-wide
/// [Overlay] (e.g. as created by the [MaterialApp] widget's [Navigator]).
///
/// See also:
///
///  * [CompositedTransformLooseTarget], the widget that this widget can target.
///  * [LooseFollowerLayer], the layer that implements this widget's logic.
///  * [Transform], which applies an arbitrary transform to a child.
class CompositedTransformLooseFollower extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// The [link] property must not be null. If it was also provided to a
  /// [CompositedTransformTarget], that widget must come earlier in the paint
  /// order.
  ///
  /// The [showWhenUnlinked] and [offset] properties must also not be null.
  const CompositedTransformLooseFollower({
    Key? key,
    required this.link,
    this.showWhenUnlinked = true,
    this.offset = Offset.zero,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
    Widget? child,
  }) : assert(link != null),
       assert(showWhenUnlinked != null),
       assert(offset != null),
       assert(targetAnchor != null),
       assert(followerAnchor != null),
       super(key: key, child: child);

  /// The link object that connects this [CompositedTransformLooseFollower] with a
  /// [CompositedTransformLooseTarget].
  ///
  /// This property must not be null.
  final LooseLayerLink link;

  /// Whether to show the widget's contents when there is no corresponding
  /// [CompositedTransformLooseTarget] with the same [link].
  ///
  /// When the widget is linked, the child is positioned such that it has the
  /// same global position as the linked [CompositedTransformLooseTarget].
  ///
  /// When the widget is not linked, then: if [showWhenUnlinked] is true, the
  /// child is visible and not repositioned; if it is false, then child is
  /// hidden.
  final bool showWhenUnlinked;

  /// The anchor point on the linked [CompositedTransformLooseTarget] that
  /// [followerAnchor] will line up with.
  ///
  /// {@template flutter.widgets.CompositedTransformFollower.targetAnchor}
  /// For example, when [targetAnchor] and [followerAnchor] are both
  /// [Alignment.topLeft], this widget will be top left aligned with the linked
  /// [CompositedTransformLooseTarget]. When [targetAnchor] is
  /// [Alignment.bottomLeft] and [followerAnchor] is [Alignment.topLeft], this
  /// widget will be left aligned with the linked [CompositedTransformLooseTarget],
  /// and its top edge will line up with the [CompositedTransformLooseTarget]'s
  /// bottom edge.
  /// {@endtemplate}
  ///
  /// Defaults to [Alignment.topLeft].
  final Alignment targetAnchor;

  /// The anchor point on this widget that will line up with [followerAnchor] on
  /// the linked [CompositedTransformLooseTarget].
  ///
  /// {@macro flutter.widgets.CompositedTransformFollower.targetAnchor}
  ///
  /// Defaults to [Alignment.topLeft].
  final Alignment followerAnchor;

  /// The additional offset to apply to the [targetAnchor] of the linked
  /// [CompositedTransformLooseTarget] to obtain this widget's [followerAnchor]
  /// position.
  final Offset offset;

  @override
  RenderLooseFollowerLayer createRenderObject(BuildContext context) {
    return RenderLooseFollowerLayer(
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      offset: offset,
      leaderAnchor: targetAnchor,
      followerAnchor: followerAnchor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLooseFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..offset = offset
      ..leaderAnchor = targetAnchor
      ..followerAnchor = followerAnchor;
  }
}
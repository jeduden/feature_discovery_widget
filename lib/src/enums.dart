/// Controls how content that overflows the background should be handled.
///
/// The default for [DescribedFeatureOverlay] is [ignore].
///
/// Modes:
///
///  * [ignore] will render the content as is, even if it exceeds the
///    boundaries of the background circle.
///  * [clipContent] will not render any content that is outside the background's area,
///    i.e. clip the content.
///    Additionally, it will pass any hit events that occur outside of the inner area
///    to the UI below the overlay, so you do not have to worry about that.
///  * [extendBackground] will expand the background circle if necessary.
///    The radius will be increased until the content fits within the circle's area
///    and a padding of 4 will be added.
///  * [wrapBackground] does what [extendBackground] does if the content is larger than the background,
///    but it will shrink the background if it is smaller than the content additionally.
///    This will never be smaller than `min(screenWidth, screenHeight) + 4`
///    because the furthest point of empty content will be `min(screenWidth, screenHeight)` away from the center of the overlay
///    as it is given that dimension as its width for layout reasons.
enum OverflowMode {
  ignore,
  clipContent,
  extendBackground,
  wrapBackground,
}

/// The Flutter SDK has a State class called OverlayState.
/// Thus, this cannot be called OverlayState.
enum FeatureOverlayState {
  closed,
  onOpening,
  opening,
  opened,
  completing,
  onCompleted,
  dismissing,
}



/// Specifies how the content should be positioned relative to the tap target.
///
/// Orientations:
///
///  * [trivial], which lets the library decide where the content should be placed.
///    Make sure to test this for every overlay because the trivial positioning can fail sometimes.
///  * [above], which will layout the content above the tap target.
///  * [below], which will layout the content below the tap target.
enum ContentLocation {
  above,
  below,
  trivial,
}

import 'package:flutter/widgets.dart';

/// Declares a contract to remember which Features were already viewed by user
/// It does not store the order.
/// All methods receive the complete list of the feature ids participating
/// in the tour. 
/// [FeatureOverlayConfigProvider] is responsible for maintaing an instance. 
abstract class FeatureTourPersistence {

  /// Set the complete list of all tour feature ids
  Future<void> setTourFeatureIds(List<String> tourFeatureIds);

  /// Streams as set of ids of features that the user has previously completed
  /// The stream is updated as directly after the coompleted features ids are persisted.
  Stream<Set<String>> get completedFeaturesStream;

  /// Marks [featureId] as completed and must be stored persistently when the function returns.
  /// Receives [featureTourContext] from [FeatureTour]
  /// Must update [completedFeaturesStream]
  Future<void> completeFeature(BuildContext featureTourContext, String featureId);

  /// Marks [featureId] as dismissed. 
  /// Receives [featureTourContext] from [FeatureTour]
  /// The implementation may be implemented in a few ways:
  /// - just abort the tour for this session.
  /// - abort the tour persistently
  /// - skip to the next feature
  /// - ask user how to proceed
  /// Must update [completedFeaturesStream] the persisted state changed.
  Future<void> dismissFeature(BuildContext featureTourContext, String featureId);
}
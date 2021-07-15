/// Declares a contract to remember which Features were already viewed by user
/// It does not store the order.
/// All methods receive the complete list of the feature ids participating
/// in the tour. This allows instantiating the instance on demand 
/// without keeping it in a StatefulWidget.
abstract class FeatureTourPersistence {

  /// Returns a set of ids of features that the user has previously completed
  Future<Set<String>> completedFeatures(List<String> tourFeatureIds);

  /// Marks [featureId] as completed and must be stored persistently when the function returns.
  Future<void> completeFeature(String featureId,List<String> tourFeatureIds);

  /// Marks [featureId] as dismissed. 
  /// The implementation may be implemented in a few ways:
  /// - just abort the tour for this session.
  /// - abort the tour persistently
  /// - skip to the next feature
  /// - ask user how to proceed
  Future<void> dismissFeature(String featureId,List<String> tourFeatureIds);
}
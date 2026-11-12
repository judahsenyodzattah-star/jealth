/// Historical evaluation results recorded when the models were trained and
/// compared in the project's Jupyter notebook.
///
/// These numbers are fixed records of that offline evaluation. They are not
/// measured by the app and they do not change at runtime.
class ModelEvaluation {
  const ModelEvaluation({
    required this.name,
    required this.shortName,
    required this.testAccuracy,
    required this.testPrecision,
    required this.testRecall,
    required this.testF1,
    required this.testRocAuc,
    required this.cvAccuracy,
    required this.cvF1,
    required this.cvRocAuc,
    this.isSelected = false,
  });

  final String name;
  final String shortName;

  // Hold-out test set (100 records). Precision, recall and F1 are for class 1.
  final double testAccuracy;
  final double testPrecision;
  final double testRecall;
  final double testF1;
  final double testRocAuc;

  // Five-fold cross-validation means.
  final double cvAccuracy;
  final double cvF1;
  final double cvRocAuc;

  /// The model chosen for the application.
  final bool isSelected;
}

/// Confusion matrix of the selected model on the 100-record test set.
class ConfusionMatrix {
  const ConfusionMatrix({
    required this.trueNegatives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.truePositives,
  });

  final int trueNegatives;
  final int falsePositives;
  final int falseNegatives;
  final int truePositives;

  int get total =>
      trueNegatives + falsePositives + falseNegatives + truePositives;
  int get correct => trueNegatives + truePositives;
  int get actualNegatives => trueNegatives + falsePositives;
  int get actualPositives => falseNegatives + truePositives;
  int get predictedPositives => falsePositives + truePositives;
  int get predictedNegatives => trueNegatives + falseNegatives;

  /// Accuracy of always predicting the more common class in this test set.
  double get majorityBaselineAccuracy =>
      (actualPositives > actualNegatives ? actualPositives : actualNegatives) /
      total;
}

/// Metrics that can be compared across the three candidate models.
enum ComparisonMetric {
  accuracy('Accuracy', 'Share of all test records classified correctly.'),
  precision(
    'Precision',
    'Of the records predicted as class 1, the share that really were class 1.',
  ),
  recall(
    'Recall',
    'Of the records that really were class 1, the share the model found.',
  ),
  f1('F1-score', 'Balance (harmonic mean) of precision and recall.'),
  rocAuc(
    'ROC-AUC',
    'How well the model ranks class 1 above class 0. 0.5 is random guessing.',
  );

  const ComparisonMetric(this.label, this.description);

  final String label;
  final String description;

  double testValue(ModelEvaluation model) => switch (this) {
    accuracy => model.testAccuracy,
    precision => model.testPrecision,
    recall => model.testRecall,
    f1 => model.testF1,
    rocAuc => model.testRocAuc,
  };
}

abstract final class EvaluationData {
  static const ModelEvaluation logisticRegression = ModelEvaluation(
    name: 'Logistic Regression',
    shortName: 'Log. Reg.',
    testAccuracy: 0.56,
    testPrecision: 0.562,
    testRecall: 0.774,
    testF1: 0.651,
    testRocAuc: 0.505,
    cvAccuracy: 0.535,
    cvF1: 0.614,
    cvRocAuc: 0.531,
    isSelected: true,
  );

  static const ModelEvaluation decisionTree = ModelEvaluation(
    name: 'Decision Tree',
    shortName: 'Dec. Tree',
    testAccuracy: 0.47,
    testPrecision: 0.500,
    testRecall: 0.226,
    testF1: 0.312,
    testRocAuc: 0.497,
    cvAccuracy: 0.475,
    cvF1: 0.537,
    cvRocAuc: 0.478,
  );

  static const ModelEvaluation randomForest = ModelEvaluation(
    name: 'Random Forest',
    shortName: 'Rand. Forest',
    testAccuracy: 0.52,
    testPrecision: 0.542,
    testRecall: 0.604,
    testF1: 0.571,
    testRocAuc: 0.521,
    cvAccuracy: 0.492,
    cvF1: 0.542,
    cvRocAuc: 0.494,
  );

  static const List<ModelEvaluation> models = [
    logisticRegression,
    decisionTree,
    randomForest,
  ];

  /// Logistic Regression on the test set.
  static const ConfusionMatrix confusionMatrix = ConfusionMatrix(
    trueNegatives: 15,
    falsePositives: 32,
    falseNegatives: 12,
    truePositives: 41,
  );

  static const int crossValidationFolds = 5;

  /// ROC-AUC of a model that guesses at random.
  static const double randomRocAuc = 0.5;
}

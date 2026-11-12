import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/core/constants/api_config.dart';
import 'package:jealth/core/constants/app_constants.dart';
import 'package:jealth/core/constants/dataset_info.dart';
import 'package:jealth/features/analytics/models/model_evaluation.dart';

void main() {
  test('displayed version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+?)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(AppConstants.version, match!.group(1));
    expect(AppConstants.buildNumber, match.group(2));
  });

  test("app identity uses the J'ealth name", () {
    expect(AppConstants.appName, "J'ealth");
    expect(AppConstants.subtitle, 'AI-Powered Heart Disease Classification');
    expect(AppConstants.tagline, 'Explore Health Through Machine Learning');
  });

  group('ApiConfig', () {
    test('is not configured when no address is given', () {
      const config = ApiConfig(baseUrl: null);
      expect(config.isConfigured, isFalse);
      expect(ApiConfig.normalizeBaseUrl(''), isNull);
      expect(ApiConfig.normalizeBaseUrl('   '), isNull);
    });

    test('normalises and validates addresses', () {
      expect(
        ApiConfig.normalizeBaseUrl(' http://localhost:8000/ '),
        'http://localhost:8000',
      );
      expect(ApiConfig.validateBaseUrl('http://10.0.2.2:8000'), isNull);
      expect(ApiConfig.validateBaseUrl('localhost:8000'), isNotNull);
      expect(ApiConfig.validateBaseUrl('ftp://example.com'), isNotNull);
      expect(ApiConfig.validateBaseUrl('https://x.test/?a=1'), isNotNull);
    });

    test('a runtime address overrides the build-time default', () {
      final config = ApiConfig.resolve(runtimeBaseUrl: 'https://api.test/');
      expect(config.baseUrl, 'https://api.test');
      expect(config.isConfigured, isTrue);
    });
  });

  group('historical evaluation data', () {
    test('dataset counts are consistent', () {
      expect(DatasetInfo.totalRecords, 500);
      expect(
        DatasetInfo.trainingRecords + DatasetInfo.testingRecords,
        DatasetInfo.totalRecords,
      );
      expect(
        DatasetInfo.classOneRecords + DatasetInfo.classZeroRecords,
        DatasetInfo.totalRecords,
      );
      expect(DatasetInfo.inputFeatures, 10);
    });

    test('confusion matrix agrees with the reported metrics', () {
      const m = EvaluationData.confusionMatrix;
      const lr = EvaluationData.logisticRegression;
      expect(m.total, DatasetInfo.testingRecords);
      expect(m.correct / m.total, closeTo(lr.testAccuracy, 0.0005));
      expect(
        m.truePositives / m.predictedPositives,
        closeTo(lr.testPrecision, 0.0005),
      );
      expect(
        m.truePositives / m.actualPositives,
        closeTo(lr.testRecall, 0.0005),
      );
      expect(m.majorityBaselineAccuracy, closeTo(0.53, 1e-9));
    });

    test('reported values are the documented ones', () {
      const lr = EvaluationData.logisticRegression;
      const dt = EvaluationData.decisionTree;
      const rf = EvaluationData.randomForest;
      expect(
        [
          lr.testAccuracy,
          lr.testPrecision,
          lr.testRecall,
          lr.testF1,
          lr.testRocAuc,
        ],
        [0.56, 0.562, 0.774, 0.651, 0.505],
      );
      expect(
        [
          dt.testAccuracy,
          dt.testPrecision,
          dt.testRecall,
          dt.testF1,
          dt.testRocAuc,
        ],
        [0.47, 0.500, 0.226, 0.312, 0.497],
      );
      expect(
        [
          rf.testAccuracy,
          rf.testPrecision,
          rf.testRecall,
          rf.testF1,
          rf.testRocAuc,
        ],
        [0.52, 0.542, 0.604, 0.571, 0.521],
      );
      expect([lr.cvAccuracy, lr.cvF1, lr.cvRocAuc], [0.535, 0.614, 0.531]);
      expect([dt.cvAccuracy, dt.cvF1, dt.cvRocAuc], [0.475, 0.537, 0.478]);
      expect([rf.cvAccuracy, rf.cvF1, rf.cvRocAuc], [0.492, 0.542, 0.494]);
      expect(EvaluationData.models.where((m) => m.isSelected), [lr]);
    });
  });
}

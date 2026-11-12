import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/core/constants/api_config.dart';
import 'package:jealth/core/network/dio_client.dart';
import 'package:jealth/features/classification/models/patient_input.dart';
import 'package:jealth/services/prediction_service.dart';

void main() {
  const liveBaseUrl = String.fromEnvironment('JEALTH_API_BASE_URL');

  test(
    'Flutter prediction service reaches the live FastAPI backend',
    () async {
    final config = ApiConfig.resolve();
    expect(config.isConfigured, isTrue);

    final dio = createDio(config);
    addTearDown(dio.close);
    final service = HttpPredictionService(dio, config);
    final health = await service.checkHealth();
    expect(health.isConnected, isTrue);

    const input = PatientInput(
      age: 68,
      sex: Sex.male,
      bloodPressure: 105,
      cholesterol: 191,
      bmi: 38,
      smoker: YesNo.yes,
      diabetes: YesNo.yes,
      physicalActivity: 0,
      familyHistory: YesNo.no,
      stressLevel: 2,
    );
    final result = await service.predict(input);

    expect(result.predictedClass.value, anyOf(0, 1));
    expect(result.modelScore, inInclusiveRange(0, 1));
    expect(result.modelVersion, isNotEmpty);
    },
    skip: liveBaseUrl.isEmpty
        ? 'Run with --dart-define=JEALTH_API_BASE_URL=http://127.0.0.1:8000'
        : null,
  );
}

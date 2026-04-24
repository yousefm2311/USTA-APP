import 'package:flutter_test/flutter_test.dart';
import 'package:usta/app/services/backend_status_service.dart';

void main() {
  test('html payloads are detected correctly', () {
    expect(
      looksLikeServerHtmlPayload(
        '<!DOCTYPE html><html><body>Server Error</body></html>',
      ),
      isTrue,
    );
    expect(
      looksLikeServerHtmlPayload(
        'anything',
        contentType: 'text/html; charset=utf-8',
      ),
      isTrue,
    );
    expect(
      looksLikeServerHtmlPayload({
        'message': 'ok',
      }, contentType: 'application/json'),
      isFalse,
    );
  });

  test(
    'only outage gateway statuses are treated as immediate backend outage',
    () {
      expect(isBackendUnavailableStatus(502), isTrue);
      expect(isBackendUnavailableStatus(503), isTrue);
      expect(isBackendUnavailableStatus(504), isTrue);
      expect(isBackendUnavailableStatus(500), isFalse);
      expect(isBackendUnavailableStatus(404), isFalse);
    },
  );
}

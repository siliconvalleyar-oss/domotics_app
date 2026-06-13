import 'package:flutter_test/flutter_test.dart';
import 'package:domotics_app/main.dart';
import 'package:domotics_app/models/broker_config.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(DomoticsApp(
      config: BrokerConfig(
        host: 'test.mosquitto.org',
        port: 1883,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Domótica'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:darwin_walk/main.dart'; // <-- важно, имя пакета = имени проекта

void main() {
  testWidgets('Приложение загружается', (WidgetTester tester) async {
    // Собираем наше приложение
    await tester.pumpWidget(const DarwinApp());

    // Проверяем, что на экране есть заголовок
    expect(find.text('Прогулка Дарвина'), findsOneWidget);
  });
}

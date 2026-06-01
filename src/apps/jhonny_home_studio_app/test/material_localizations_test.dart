import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre o calendário com MaterialLocalizations em pt-BR', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        locale: const Locale('pt', 'BR'),
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showDatePicker(
                  context: context,
                  locale: const Locale('pt', 'BR'),
                  initialDate: DateTime(2026, 6),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                );
              },
              child: const Text('Abrir calendário'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir calendário'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    final context = tester.element(find.byType(DatePickerDialog));
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
  });
}

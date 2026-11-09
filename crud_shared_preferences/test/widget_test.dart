import 'package:crud_shared_preferences/models/produto.dart';
import 'package:crud_shared_preferences/widgets/produto_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Valida o cadastro e aceita quantidade zero', (tester) async {
    Produto? resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado = await showDialog<Produto>(
                  context: context,
                  builder: (_) => const ProdutoDialog(),
                );
              },
              child: const Text('Novo produto'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Novo produto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(resultado, isNull);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '  Caderno  ');
    await tester.enterText(campos.at(1), '0');
    await tester.enterText(campos.at(2), '-1');

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um preço maior que zero.'), findsOneWidget);
    expect(
      find.text('Informe um inteiro maior ou igual a zero.'),
      findsOneWidget,
    );
    expect(resultado, isNull);

    await tester.enterText(campos.at(1), '12,50');
    await tester.enterText(campos.at(2), '0');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(resultado?.nome, 'Caderno');
    expect(resultado?.preco, 12.5);
    expect(resultado?.quantidade, 0);
  });
}

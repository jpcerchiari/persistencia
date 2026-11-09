import 'package:flutter/material.dart';

import 'screens/produtos_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    const titulo = 'CRUD com SharedPreferences';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: titulo,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const ProdutosPage(titulo: titulo),
    );
  }
}

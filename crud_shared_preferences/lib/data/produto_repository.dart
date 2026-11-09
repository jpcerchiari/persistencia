import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/produto.dart';

class ProdutoRepository {
  static const _chave = 'crud.produtos';
  final _prefs = SharedPreferencesAsync();

  Future<List<Produto>> listar({
    String busca = '',
    bool ordenarPorNome = false,
  }) async {
    final texto = await _prefs.getString(_chave);
    if (texto == null || texto.isEmpty) return [];

    final dados = jsonDecode(texto) as List<dynamic>;
    final termo = busca.trim().toLowerCase();
    final produtos = dados
        .map((item) => Produto.fromMap(Map<String, Object?>.from(item as Map)))
        .where((produto) => produto.nome.toLowerCase().contains(termo))
        .toList();

    produtos.sort((a, b) {
      if (ordenarPorNome) {
        final porNome = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        if (porNome != 0) return porNome;
      }
      return b.id.compareTo(a.id);
    });
    return produtos;
  }

  // shortcut: grava a lista inteira, usar SQLite se houver escritas em várias abas.
  Future<void> _salvarLista(List<Produto> produtos) async {
    final mapas = produtos.map((produto) => produto.toMap()).toList();
    await _prefs.setString(_chave, jsonEncode(mapas));
  }

  Future<void> inserir(Produto produto) async {
    final produtos = await listar();
    final maiorId = produtos.isEmpty ? 0 : produtos.first.id;
    produtos.add(
      Produto(
        id: maiorId + 1,
        nome: produto.nome,
        preco: produto.preco,
        quantidade: produto.quantidade,
      ),
    );
    await _salvarLista(produtos);
  }

  Future<void> atualizar(Produto produto) async {
    final produtos = await listar();
    final indice = produtos.indexWhere((item) => item.id == produto.id);
    if (indice == -1) throw StateError('Produto não encontrado.');
    produtos[indice] = produto;
    await _salvarLista(produtos);
  }

  Future<void> excluir(int id) async {
    final produtos = await listar();
    final indice = produtos.indexWhere((produto) => produto.id == id);
    if (indice == -1) throw StateError('Produto não encontrado.');
    produtos.removeAt(indice);
    await _salvarLista(produtos);
  }
}

import 'package:flutter/material.dart';

import '../data/produto_repository.dart';
import '../models/produto.dart';
import '../widgets/produto_dialog.dart';

class ProdutosPage extends StatefulWidget {
  final String titulo;

  const ProdutosPage({super.key, required this.titulo});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final _repositorio = ProdutoRepository();
  late Future<List<Produto>> _produtos;
  String _busca = '';
  bool _ordenarPorNome = false;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _produtos = _repositorio.listar();
  }

  void _carregar() {
    setState(() {
      _produtos = _repositorio.listar(
        busca: _busca,
        ordenarPorNome: _ordenarPorNome,
      );
    });
  }

  Future<void> _gravar(
    Future<void> Function() operacao,
    String mensagem,
  ) async {
    setState(() => _processando = true);
    try {
      await operacao();
      if (!mounted) return;
      _carregar();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gravar a alteração.')),
      );
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _abrirFormulario([Produto? original]) async {
    if (_processando) return;
    final produto = await showDialog<Produto>(
      context: context,
      builder: (_) => ProdutoDialog(produto: original),
    );
    if (!mounted || produto == null) return;
    if (original == null) {
      await _gravar(() => _repositorio.inserir(produto), 'Produto cadastrado.');
    } else {
      await _gravar(
        () => _repositorio.atualizar(produto),
        'Produto atualizado.',
      );
    }
  }

  Future<void> _excluir(Produto produto) async {
    if (_processando) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('Deseja excluir "${produto.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!mounted || confirmou != true) return;
    await _gravar(() => _repositorio.excluir(produto.id), 'Produto excluído.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nome',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) {
                _busca = valor;
                _carregar();
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Ordenar por nome'),
            subtitle: Text(
              _ordenarPorNome ? 'Nome crescente' : 'ID decrescente',
            ),
            value: _ordenarPorNome,
            onChanged: (valor) {
              _ordenarPorNome = valor;
              _carregar();
            },
          ),
          Expanded(
            child: FutureBuilder<List<Produto>>(
              future: _produtos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: OutlinedButton(
                      onPressed: _carregar,
                      child: const Text('Erro ao carregar. Tentar novamente'),
                    ),
                  );
                }

                final produtos = snapshot.data!;
                if (produtos.isEmpty) {
                  return Center(
                    child: Text(
                      _busca.trim().isEmpty
                          ? 'Nenhum produto cadastrado.'
                          : 'Nenhum produto encontrado.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: produtos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, indice) {
                    final produto = produtos[indice];
                    final preco = produto.preco
                        .toStringAsFixed(2)
                        .replaceAll('.', ',');
                    return ListTile(
                      leading: CircleAvatar(child: Text('${produto.id}')),
                      title: Text(produto.nome),
                      subtitle: Text(
                        'R\$ $preco • Quantidade: ${produto.quantidade} • ${produto.categoria}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar ${produto.nome}',
                            onPressed: _processando
                                ? null
                                : () => _abrirFormulario(produto),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Excluir ${produto.nome}',
                            onPressed: _processando
                                ? null
                                : () => _excluir(produto),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processando ? null : () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
    );
  }
}

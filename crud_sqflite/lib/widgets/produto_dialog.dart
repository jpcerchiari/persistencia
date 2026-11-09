import 'package:flutter/material.dart';

import '../models/produto.dart';

class ProdutoDialog extends StatefulWidget {
  final Produto? produto;

  const ProdutoDialog({super.key, this.produto});

  @override
  State<ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends State<ProdutoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _preco;
  late final TextEditingController _quantidade;
  late final TextEditingController _categoria;

  @override
  void initState() {
    super.initState();
    final produto = widget.produto;
    _nome = TextEditingController(text: produto?.nome);
    _preco = TextEditingController(
      text: produto?.preco.toString().replaceAll('.', ','),
    );
    _quantidade = TextEditingController(text: produto?.quantidade.toString());
    _categoria = TextEditingController(text: produto?.categoria);
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    _quantidade.dispose();
    _categoria.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      Produto(
        id: widget.produto?.id ?? 0,
        nome: _nome.text.trim(),
        preco: double.parse(_preco.text.trim().replaceAll(',', '.')),
        quantidade: int.parse(_quantidade.text.trim()),
        categoria: _categoria.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.produto == null ? 'Cadastrar produto' : 'Editar produto',
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nome,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome do produto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) =>
                      (valor ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _preco,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço (ex.: 19,90)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final preco = double.tryParse(
                      (valor ?? '').trim().replaceAll(',', '.'),
                    );
                    if (preco == null || !preco.isFinite || preco <= 0) {
                      return 'Informe um preço maior que zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantidade,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final quantidade = int.tryParse((valor ?? '').trim());
                    if (quantidade == null || quantidade < 0) {
                      return 'Informe um inteiro maior ou igual a zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoria,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) => (valor ?? '').trim().isEmpty
                      ? 'Informe a categoria.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}

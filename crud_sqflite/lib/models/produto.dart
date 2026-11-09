class Produto {
  final int id;
  final String nome;
  final double preco;
  final int quantidade;
  final String categoria;

  const Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.quantidade,
    required this.categoria,
  });

  factory Produto.fromMap(Map<String, Object?> mapa) {
    return Produto(
      id: (mapa['id'] as num).toInt(),
      nome: mapa['nome'] as String,
      preco: (mapa['preco'] as num).toDouble(),
      quantidade: (mapa['quantidade'] as num).toInt(),
      categoria: mapa['categoria'] as String,
    );
  }
}

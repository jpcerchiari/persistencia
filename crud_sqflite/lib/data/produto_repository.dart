import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/produto.dart';

class ProdutoRepository {
  Future<Database>? _abertura;

  Future<Database> _banco() async {
    try {
      return await (_abertura ??= _abrirBanco());
    } catch (_) {
      _abertura = null;
      rethrow;
    }
  }

  Future<Database> _abrirBanco() async {
    final fabrica = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;
    final caminho = join(await fabrica.getDatabasesPath(), 'produtos.db');
    return fabrica.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, versao) async {
          await _criarCategorias(db);
          await db.execute('''
            CREATE TABLE produtos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nome TEXT NOT NULL,
              preco REAL NOT NULL,
              quantidade INTEGER NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
              categoria_id INTEGER NOT NULL REFERENCES categorias(id)
            )
          ''');
        },
        onUpgrade: (db, versaoAnterior, versaoAtual) async {
          if (versaoAnterior < 2) {
            await _criarCategorias(db);
            final categoriaId = await _categoriaId(db, 'Sem categoria');
            await db.execute('''
              ALTER TABLE produtos ADD COLUMN
                quantidade INTEGER NOT NULL DEFAULT 0 CHECK (quantidade >= 0)
            ''');
            await db.execute('''
              ALTER TABLE produtos ADD COLUMN
                categoria_id INTEGER REFERENCES categorias(id)
            ''');
            await db.update('produtos', {'categoria_id': categoriaId});
          }
        },
      ),
    );
  }

  Future<void> _criarCategorias(Database db) {
    return db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL UNIQUE COLLATE NOCASE
      )
    ''');
  }

  Future<int> _categoriaId(DatabaseExecutor db, String nome) async {
    await db.insert('categorias', {
      'nome': nome,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final categorias = await db.query(
      'categorias',
      columns: ['id'],
      where: 'nome = ?',
      whereArgs: [nome],
    );
    return categorias.single['id'] as int;
  }

  Future<List<Produto>> listar({
    String busca = '',
    bool ordenarPorNome = false,
  }) async {
    final db = await _banco();
    final ordem = ordenarPorNome
        ? 'p.nome COLLATE NOCASE, p.id DESC'
        : 'p.id DESC';
    final registros = await db.rawQuery(
      '''
      SELECT p.id, p.nome, p.preco, p.quantidade, c.nome AS categoria
      FROM produtos p
      JOIN categorias c ON c.id = p.categoria_id
      WHERE instr(lower(p.nome), lower(?)) > 0
      ORDER BY $ordem
    ''',
      [busca.trim()],
    );
    return registros.map(Produto.fromMap).toList();
  }

  Future<void> inserir(Produto produto) async {
    final db = await _banco();
    await db.transaction((transacao) async {
      final categoriaId = await _categoriaId(transacao, produto.categoria);
      await transacao.insert('produtos', {
        'nome': produto.nome,
        'preco': produto.preco,
        'quantidade': produto.quantidade,
        'categoria_id': categoriaId,
      });
    });
  }

  Future<void> atualizar(Produto produto) async {
    final db = await _banco();
    await db.transaction((transacao) async {
      final categoriaId = await _categoriaId(transacao, produto.categoria);
      final alterados = await transacao.update(
        'produtos',
        {
          'nome': produto.nome,
          'preco': produto.preco,
          'quantidade': produto.quantidade,
          'categoria_id': categoriaId,
        },
        where: 'id = ?',
        whereArgs: [produto.id],
      );
      if (alterados == 0) throw StateError('Produto não encontrado.');
    });
  }

  Future<void> excluir(int id) async {
    final db = await _banco();
    final excluidos = await db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (excluidos == 0) throw StateError('Produto não encontrado.');
  }
}

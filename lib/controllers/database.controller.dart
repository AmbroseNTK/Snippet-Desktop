import 'dart:ui';

import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/snippet.model.dart';

class DBProvider {
  // singleton
  static final DBProvider _instance = DBProvider._internal();
  factory DBProvider() => _instance;
  DBProvider._internal();

  late Future<Database> _database;

  var cachedSnippets = <Snippet>[].obs;

  Future<void> init() async {
    _database = openDatabase(
      join(await getDatabasesPath(), 'snippet.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE snippets(id STRING PRIMARY KEY, title TEXT, description TEXT, tags TEXT, code TEXT, language TEXT, timestamp INTEGER)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    var cached = await list();
    cachedSnippets.value = cached;
  }

  Future<void> insertSnippet(Snippet snippet) async {
    // Get a reference to the database.
    final db = await _database;
    // Insert the Snippet into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same snippet is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'snippets',
      snippet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // delete
  Future<void> deleteSnippet(String id) async {
    // Get a reference to the database.
    final db = await _database;
    // Remove the Snippet from the database.
    await db.delete(
      'snippets',
      // Use a `where` clause to delete a specific snippet.
      where: "id = ?",
      // Pass the Snippet's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  // update
  Future<void> updateSnippet(Snippet snippet) async {
    // Get a reference to the database.
    final db = await _database;
    // Update the given Snippet.
    await db.update(
      'snippets',
      snippet.toMap(),
      // Ensure that the Snippet has a matching id.
      where: "id = ?",
      // Pass the Snippet
      whereArgs: [snippet.id],
    );
  }

  // get sorted by timestamp desc
  Future<List<Snippet>> list() async {
    // Get a reference to the database.
    final db = await _database;
    // Query the table for all The Snippets.
    final List<Map<String, dynamic>> maps = await db.query('snippets');

    // Convert the List<Map<String, dynamic> into a List<Snippet>.
    var result = List.generate(maps.length, (i) {
      return Snippet(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        tags: maps[i]['tags'],
        code: maps[i]['code'],
        language: maps[i]['language'],
        timestamp: maps[i]['timestamp'],
      );
    });
    // remove cached snippets
    cachedSnippets.clear();
    // add new snippets
    cachedSnippets.addAll(result);
    // sort by timestamp desc
    cachedSnippets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    cachedSnippets.refresh();
    return result;
  }
}

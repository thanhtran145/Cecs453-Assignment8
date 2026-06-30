// Provider that manages the list of Notes from Lab 7.
// Handles: add, update, delete, and persistence via SharedPreferences.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

const _kNotesKey = 'notes_list';

class NoteProvider extends ChangeNotifier {
  final List<Note> _notes = [];
  int _nextId = 1;

  List<Note> get notes => List.unmodifiable(_notes);

  // ── Load from SharedPreferences ───────────────────────────────────────────

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotesKey);
    if (raw != null) {
      final List<dynamic> jsonList = jsonDecode(raw);
      _notes.clear();
      for (final item in jsonList) {
        _notes.add(Note.fromJson(item as Map<String, dynamic>));
      }
      // Keep _nextId ahead of any existing id so new notes never collide.
      if (_notes.isNotEmpty) {
        _nextId = _notes.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    notifyListeners();
  }

  // ── Save to SharedPreferences ─────────────────────────────────────────────

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await prefs.setString(_kNotesKey, encoded);
  }

  // ── Add a new note ────────────────────────────────────────────────────────

  Future<void> addNote({
    required String title,
    required String description,
  }) async {
    final note = Note(
      id: _nextId++,
      title: title,
      description: description,
      date: DateTime.now(),
    );
    _notes.add(note);
    await _saveToPrefs();
    notifyListeners();
  }

  // ── Update an existing note ───────────────────────────────────────────────

  Future<void> updateNote({
    required int id,
    required String title,
    required String description,
  }) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notes[index].title = title;
    _notes[index].description = description;
    await _saveToPrefs();
    notifyListeners();
  }

  // ── Delete a note ─────────────────────────────────────────────────────────

  Future<void> deleteNote(int id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveToPrefs();
    notifyListeners();
  }
}

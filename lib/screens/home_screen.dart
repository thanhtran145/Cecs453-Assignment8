import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/note_provider.dart';
import '../models/note.dart';
import '../widgets/note_dialog.dart';

/// This screen is shown after a successful login (Lab 8) and is the Lab 7
/// notes app's home screen — satisfying the "connect to the home screen of
/// lab assignment 7" video requirement. Sign-out lives in the app bar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>().notes;
    final user = context.watch<AuthService>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE8EAF6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Signed in as ${user?.email ?? 'Google account'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? const Center(
                    child: Text(
                      'No notes yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(note: note);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => NoteDialog(
        onSave: (title, desc) {
          context.read<NoteProvider>().addNote(
                title: title,
                description: desc,
              );
        },
      ),
    );
  }
}

// ── Note card widget (from Lab 7, unchanged behavior) ───────────────────────

class _NoteCard extends StatefulWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _editing = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _descCtrl = TextEditingController(text: widget.note.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: ID badge + action icons ──────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${widget.note.id}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),

                // ── Edit (pen) icon — toggles inline edit mode ────────────
                IconButton(
                  icon: Icon(
                    _editing ? Icons.check : Icons.edit,
                    color: _editing ? Colors.green : Colors.blueGrey,
                  ),
                  tooltip: _editing ? 'Save changes' : 'Edit note',
                  onPressed: () {
                    if (_editing) {
                      context.read<NoteProvider>().updateNote(
                            id: widget.note.id,
                            title: _titleCtrl.text.trim().isEmpty
                                ? widget.note.title
                                : _titleCtrl.text.trim(),
                            description: _descCtrl.text.trim().isEmpty
                                ? widget.note.description
                                : _descCtrl.text.trim(),
                          );
                    }
                    setState(() => _editing = !_editing);
                  },
                ),

                // ── Delete (trash) icon ────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  tooltip: 'Delete note',
                  onPressed: () =>
                      context.read<NoteProvider>().deleteNote(widget.note.id),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _editing
                ? TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      isDense: true,
                    ),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : Text(
                    widget.note.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
            const SizedBox(height: 4),
            _editing
                ? TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      isDense: true,
                    ),
                    maxLines: 3,
                  )
                : Text(widget.note.description),
            const SizedBox(height: 8),
            Text(
              _formatDate(widget.note.date),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

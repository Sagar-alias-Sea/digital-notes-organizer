import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NotesApp());

const _ink = Color(0xFF24332E);
const _muted = Color(0xFF89938D);
const _paper = Color(0xFFF7F8F4);
const _green = Color(0xFF315C4B);

class Note {
  Note({
    required this.title,
    required this.body,
    required this.category,
    required this.color,
    required this.updatedAt,
    this.isPinned = false,
  });

  String title;
  String body;
  String category;
  int color;
  DateTime updatedAt;
  bool isPinned;

  Map<String, Object> toJson() => {
    'title': title,
    'body': body,
    'category': category,
    'color': color,
    'updatedAt': updatedAt.toIso8601String(),
    'isPinned': isPinned,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    category: json['category'] as String? ?? 'Personal',
    color: json['color'] as int? ?? 0,
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    isPinned: json['isPinned'] as bool? ?? false,
  );
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});
  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final List<Note> _notes = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('notes');
    if (saved != null) {
      try {
        _notes.addAll(
          (jsonDecode(saved) as List).map(
            (e) => Note.fromJson(e as Map<String, dynamic>),
          ),
        );
      } catch (_) {
        // Start clean if a saved note is malformed.
      }
    }
    if (_notes.isEmpty) {
      _notes.addAll([
        Note(
          title: 'A slower kind of morning',
          body:
              'Make coffee. Open the windows. Let the day begin before the notifications do.',
          category: 'Journal',
          color: 0,
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
          isPinned: true,
        ),
        Note(
          title: 'Ideas for the weekend',
          body:
              'Visit the little bookshop on the corner\nPick up flowers for the kitchen\nTry that lemon pasta recipe',
          category: 'Personal',
          color: 1,
          updatedAt: DateTime.now().subtract(const Duration(hours: 7)),
        ),
        Note(
          title: 'Design reading list',
          body:
              '• The Shape of Design — Frank Chimero\n• Grid Systems — Josef Müller-Brockmann',
          category: 'Work',
          color: 2,
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Note(
          title: 'Remember the little things',
          body: 'Call Mum\nWater the basil\nBook a table for Friday',
          category: 'Personal',
          color: 3,
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);
      await _saveNotes();
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notes',
      jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _deleteNote(Note note) async {
    setState(() => _notes.remove(note));
    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Little Notes',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(seedColor: _green, surface: _paper),
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: _paper,
        foregroundColor: _ink,
      ),
    ),
    home: Builder(
      builder: (navigatorContext) => _loaded
          ? NotesHome(
              notes: _notes,
              onEdit: ([note]) => _editNoteFromContext(navigatorContext, note),
              onDelete: _deleteNote,
            )
          : const Scaffold(
              body: Center(child: CircularProgressIndicator(color: _green)),
            ),
    ),
  );

  Future<void> _editNoteFromContext(
    BuildContext navigatorContext, [
    Note? note,
  ]) async {
    final result = await Navigator.of(navigatorContext).push<Note>(
      MaterialPageRoute(
        builder: (_) => NoteEditor(note: note),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (note == null) {
        _notes.insert(0, result);
      } else {
        final index = _notes.indexOf(note);
        if (index >= 0) _notes[index] = result;
      }
    });
    await _saveNotes();
  }
}

class NotesHome extends StatefulWidget {
  const NotesHome({
    super.key,
    required this.notes,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Note> notes;
  final Future<void> Function([Note?]) onEdit;
  final Future<void> Function(Note) onDelete;
  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  int _tab = 0;
  String _query = '';
  String _category = 'All';
  final _searchController = TextEditingController();
  static const _categories = ['All', 'Personal', 'Work', 'Journal'];
  final _colors = const [
    Color(0xFFE7EBDD),
    Color(0xFFF4E7D5),
    Color(0xFFE4EAF0),
    Color(0xFFF1E2E4),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.notes.where((note) {
      final matchesTab = _tab != 1 || note.isPinned;
      final matchesCategory = _category == 'All' || note.category == _category;
      final matchesSearch =
          _query.isEmpty ||
          '${note.title} ${note.body} ${note.category}'.toLowerCase().contains(
            _query.toLowerCase(),
          );
      return matchesTab && matchesCategory && matchesSearch;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final pinned = filtered.where((n) => n.isPinned).toList();
    final others = filtered.where((n) => !n.isPinned).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              sliver: SliverToBoxAdapter(child: _header()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              sliver: SliverToBoxAdapter(child: _searchBox()),
            ),
            if (_tab == 0)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 21, 22, 0),
                sliver: SliverToBoxAdapter(child: _categoryRow()),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 0),
              sliver: SliverToBoxAdapter(
                child: _sectionTitle(
                  _tab == 1 ? 'Pinned notes' : 'Your notes',
                  filtered.length,
                ),
              ),
            ),
            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nothing here yet. Add a note to get started.',
                    style: TextStyle(color: _muted),
                  ),
                ),
              )
            else ...[
              if (pinned.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
                  sliver: SliverToBoxAdapter(child: _sectionLabel('PINNED')),
                ),
                _noteGrid(pinned),
              ],
              if (others.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    pinned.isEmpty ? 15 : 23,
                    22,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: _sectionLabel('RECENT')),
                ),
                _noteGrid(others),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 105)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onEdit(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New note',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE9F0EA),
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _category = 'All';
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'All notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.push_pin_outlined),
            selectedIcon: Icon(Icons.push_pin_rounded),
            label: 'Pinned',
          ),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE5ECE5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: _green, size: 22),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'little notes',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -.5,
              ),
            ),
            Text(
              'A quiet place for your thoughts',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: PopupMenuButton<String>(
          tooltip: 'More options',
          icon: const Icon(Icons.more_horiz_rounded, color: _ink),
          onSelected: (value) {
            if (value == 'new') widget.onEdit();
            if (value == 'pinned') setState(() => _tab = 1);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'new', child: Text('Create a note')),
            PopupMenuItem(value: 'pinned', child: Text('View pinned notes')),
          ],
        ),
      ),
    ],
  );

  Widget _searchBox() => Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFECEFEB)),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search_rounded, color: _muted),
        hintText: 'Search your notes',
        hintStyle: const TextStyle(color: Color(0xFFA8B0AA), fontSize: 14),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _categoryRow() => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final selected = _category == category;
        return ChoiceChip(
          label: Text(category),
          selected: selected,
          onSelected: (_) => setState(() => _category = category),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : _muted,
          ),
          backgroundColor: Colors.white,
          selectedColor: _green,
          side: BorderSide(color: selected ? _green : const Color(0xFFE9EDE8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        );
      },
    ),
  );

  Widget _sectionTitle(String title, int count) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -.4,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDE8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _green,
          ),
        ),
      ),
    ],
  );
  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 1.5,
      color: _muted,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _noteGrid(List<Note> notes) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(22, 11, 22, 0),
    sliver: SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _noteCard(notes[index]),
        childCount: notes.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 188,
      ),
    ),
  );

  Widget _noteCard(Note note) {
    final background = _colors[note.color % _colors.length];
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onEdit(note),
        onLongPress: () => _showActions(note),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.15,
                        color: _ink.withValues(alpha: .60),
                      ),
                    ),
                  ),
                  if (note.isPinned)
                    const Icon(Icons.push_pin_rounded, size: 15, color: _green),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontSize: 15,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink.withValues(alpha: .68),
                    height: 1.35,
                    fontSize: 11.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateLabel(note.updatedAt),
                      style: TextStyle(
                        color: _ink.withValues(alpha: .48),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Note options',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showActions(note),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: _ink.withValues(alpha: .55),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today · ${_time(date)}';
    }
    if (now.difference(date).inDays < 2) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$hour:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _showActions(Note note) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit note'),
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onEdit(note);
            },
          ),
          ListTile(
            leading: Icon(
              note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            ),
            title: Text(note.isPinned ? 'Unpin note' : 'Pin note'),
            onTap: () async {
              setState(() => note.isPinned = !note.isPinned);
              await _saveForHome();
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFB64C48),
            ),
            title: const Text(
              'Delete note',
              style: TextStyle(color: Color(0xFFB64C48)),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onDelete(note);
            },
          ),
        ],
      ),
    ),
  );
  Future<void> _saveForHome() async {
    final state = context.findAncestorStateOfType<_NotesAppState>();
    await state?._saveNotes();
  }
}

class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key, this.note});
  final Note? note;
  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String _category;
  late int _color;
  static const _categories = ['Personal', 'Work', 'Journal'];
  final _colors = const [
    Color(0xFFE7EBDD),
    Color(0xFFF4E7D5),
    Color(0xFFE4EAF0),
    Color(0xFFF1E2E4),
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _body = TextEditingController(text: widget.note?.body ?? '');
    _category = widget.note?.category ?? 'Personal';
    _color = widget.note?.color ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your note a title first.')),
      );
      return;
    }
    Navigator.pop(
      context,
      Note(
        title: title,
        body: _body.text.trim(),
        category: _category,
        color: _color,
        updatedAt: DateTime.now(),
        isPinned: widget.note?.isPinned ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.note == null ? 'A new thought' : 'Edit note',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            'Save',
            style: TextStyle(color: _green, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(23, 14, 23, 30),
        children: [
          TextField(
            controller: _title,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -.6,
            ),
            decoration: const InputDecoration(
              hintText: 'Give it a title',
              hintStyle: TextStyle(color: Color(0xFFB0B8B2)),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.folder_open_outlined, color: _muted, size: 17),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  style: const TextStyle(color: _ink, fontSize: 13),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
              ),
              const Spacer(),
              Text(
                'COLOR',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(
                _colors.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _color = i),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == i ? _green : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _color == i
                        ? const Icon(Icons.check, size: 12, color: _green)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFFE7EBE6)),
          const SizedBox(height: 15),
          TextField(
            controller: _body,
            minLines: 12,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: _ink, height: 1.65, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Start writing…',
              hintStyle: TextStyle(color: Color(0xFFB0B8B2)),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    ),
  );
}

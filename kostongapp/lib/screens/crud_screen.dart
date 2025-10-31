import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CrudScreen extends StatefulWidget {
  final String token;
  final String type; // contoh: 'kost', 'users', 'booking'

  const CrudScreen({super.key, required this.token, required this.type});

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  List<dynamic> items = [];
  bool loading = true;

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    final response = await ApiService.fetchCollection(widget.token, widget.type);
    if (mounted) {
      setState(() {
        items = response['data'] ?? [];
        loading = false;
      });
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    _formData.clear();
    if (existing != null) _formData.addAll(existing);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Tambah ${widget.type}' : 'Edit ${widget.type}'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ..._formData.keys.map((key) {
                  return TextFormField(
                    initialValue: _formData[key]?.toString() ?? '',
                    decoration: InputDecoration(labelText: key),
                    onSaved: (v) => _formData[key] = v ?? '',
                  );
                }),
                if (_formData.isEmpty)
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Field contoh'),
                    onSaved: (v) => _formData['nama'] = v,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              _formKey.currentState?.save();
              Navigator.pop(context);

              if (existing == null) {
                await ApiService.createData(widget.token, widget.type, _formData);
              } else {
                await ApiService.updateData(widget.token, widget.type, existing['_id'], _formData);
              }
              _loadData();
            },
            child: Text(existing == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await ApiService.deleteData(widget.token, widget.type, id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD ${widget.type.toUpperCase()}'),
        backgroundColor: Color(0xFF667eea),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF667eea)))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item['nama_lengkap'] ??
                        item['name'] ??
                        item['title'] ??
                        item['email'] ??
                        'Data Tanpa Nama'),
                    subtitle: Text(item['_id'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _createOrEdit(existing: item),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(item['_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF667eea),
        child: Icon(Icons.add),
        onPressed: () => _createOrEdit(),
      ),
    );
  }
}

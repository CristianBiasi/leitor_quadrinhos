import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';

class AddComicScreen extends StatefulWidget {
  const AddComicScreen({super.key});

  @override
  State<AddComicScreen> createState() => _AddComicScreenState();
}

class _AddComicScreenState extends State<AddComicScreen> {
  bool _loading = false;

  Future<void> _selectFiles() async {
    final granted = await PermissionUtils.requestStoragePermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de acesso aos arquivos negada. Ative nas configurações do Android.',
          ),
        ),
      );
      return;
    }

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['cbz', 'cbr', 'zip', 'rar'],
      );
    } catch (_) {
      // fallback sem filtro de extensão (necessário em alguns dispositivos Android 16)
      result = await FilePicker.platform.pickFiles(allowMultiple: true);
    }

    if (!mounted || result == null) return;

    setState(() {
      _loading = true;
    });

    final provider = context.read<LibraryProvider>();

    int imported = 0;

    for (final file in result.files) {
      if (file.path != null) {
        final comic = await provider.addComic(file.path!);

        if (comic != null) {
          imported++;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$imported quadrinho(s) importado(s)')),
    );

    Navigator.pop(context);
  }

  Future<void> _selectFolder() async {
    final folder = await FilePicker.platform.getDirectoryPath();

    if (!mounted || folder == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importação por pasta será implementada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Livros')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.menu_book_rounded,
              size: 120,
              color: AppTheme.accent,
            ),

            const SizedBox(height: 20),

            const Text(
              'Importar Quadrinhos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Selecione um ou vários arquivos CBR/CBZ',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('Selecionar Arquivos'),
                onPressed: _loading ? null : _selectFiles,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Importar Pasta'),
                onPressed: _loading ? null : _selectFolder,
              ),
            ),

            const SizedBox(height: 30),

            if (_loading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Importando...'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

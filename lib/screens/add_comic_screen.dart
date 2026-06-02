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

    // FileType.any é necessário porque .cbr/.cbz não têm MIME type reconhecido
    // pelo seletor nativo do Android — com FileType.custom os arquivos ficam
    // desabilitados para seleção. A validação de extensão é feita abaixo.
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (!mounted || result == null) return;

    setState(() {
      _loading = true;
    });

    final provider = context.read<LibraryProvider>();

    int imported = 0;
    int skipped = 0;

    for (final file in result.files) {
      if (file.path == null) continue;

      final ext = file.path!.split('.').last.toLowerCase();
      if (!['cbr', 'cbz', 'zip', 'rar'].contains(ext)) {
        skipped++;
        continue;
      }

      final comic = await provider.addComic(file.path!);
      if (comic != null) imported++;
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    final msg = skipped > 0
        ? '$imported quadrinho(s) importado(s). $skipped arquivo(s) ignorado(s) (formato não suportado).'
        : '$imported quadrinho(s) importado(s)';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    Navigator.pop(context);
  }

  Future<void> _selectFolder() async {
    final folder = await FilePicker.getDirectoryPath();

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

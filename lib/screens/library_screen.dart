import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../widget/comic_card.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _addComic(BuildContext context) async {
    final provider = context.read<LibraryProvider>();

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'cbz',
        'cbr',
      ],
    );

    if (result == null) return;

    for (final file in result.files) {
      if (file.path != null) {
        await provider.addComic(file.path!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {

        return Scaffold(
          appBar: AppBar(
            title: const Text('Minha Biblioteca'),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () => _addComic(context),
            child: const Icon(Icons.add),
          ),

          body: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.comics.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.60,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {

              final comic = provider.comics[i];

              return ComicCard(
                comic: comic,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(comic: comic),
                    ),
                  );
                },
                onLongPress: () async {
                  final provider = context.read<LibraryProvider>();
                  final collections = provider.collections;
                  String? selected;

                  await showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text('Adicionar à coleção'),
                        content: StatefulBuilder(
                          builder: (_, setState) {
                            return DropdownButton<String>(
                              value: selected,
                              isExpanded: true,
                              hint: const Text('Selecione uma coleção'),
                              items: collections
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  selected = v;
                                });
                              },
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: selected == null
                                ? null
                                : () async {
                                    final navigator = Navigator.of(context);
                                    await provider.addComicToCollection(
                                      comic.id,
                                      selected!,
                                    );
                                    navigator.pop();
                                  },
                            child: const Text('Salvar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

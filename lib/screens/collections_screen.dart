import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../widget/collection_card.dart';
import 'collection_detail_screen.dart';

class CollectionsScreen extends StatelessWidget {

  const CollectionsScreen({super.key});

  Future<void> createCollection(BuildContext context) async {

    final txt = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova Coleção'),
        content: TextField(
          controller: txt,
          decoration: const InputDecoration(
            hintText: 'Nome da coleção',
          ),
        ),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: (){
              context.read<LibraryProvider>()
                .createCollection(txt.text);

              Navigator.pop(context);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<LibraryProvider>(
      builder: (_, provider, _){

        return Scaffold(
          appBar: AppBar(
            title: const Text('Coleções'),
          ),

          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: (){
              createCollection(context);
            },
          ),

          body: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.collections.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .75,
            ),
            itemBuilder: (_, i){

              final collection =
                  provider.collections[i];

              return CollectionCard(
                collection: collection,
                comicCount:
                    collection.comicIds.length,
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                        CollectionDetailScreen(
                          collectionId:
                            collection.id,
                        ),
                    ),
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
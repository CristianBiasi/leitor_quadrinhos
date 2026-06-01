import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../widget/comic_card.dart';
import 'reader_screen.dart';

class CollectionDetailScreen extends StatelessWidget {

  final String collectionId;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {

    final provider =
        context.watch<LibraryProvider>();

    final comics =
        provider.comicsInCollection(
          collectionId,
        );

    final collection =
        provider.getCollection(
          collectionId,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(collection?.name ?? ''),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: comics.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: .6,
        ),
        itemBuilder: (_, i){

          final comic = comics[i];

          return ComicCard(
            comic: comic,
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                    ReaderScreen(
                      comic: comic,
                    ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
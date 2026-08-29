import 'package:flutter/material.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('図鑑', style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

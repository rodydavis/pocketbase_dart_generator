import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketbase/pocketbase.dart';

import 'generated/client.dart';
import 'generated/collections/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'PocketBase Demo';
    return MaterialApp(
      title: title,
      theme: ThemeData.dark(),
      home: const Example(title: title),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key, required this.title});

  final String title;

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  HiveClient? client;

  @override
  void initState() {
    super.initState();
    final db = PocketBase('https://pocketbase.io');
    db.admins.authViaEmail('test@example.com', '123456').then((value) async {
      client = HiveClient(db);
      await client!.init();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (client != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: FutureBuilder<List<Posts>>(
          future: client!.getPosts(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!;
              if (data.isEmpty) {
                return const Center(child: Text('No posts found'));
              }
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final post = data[index];
                  return ListTile(title: Text(post.title));
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

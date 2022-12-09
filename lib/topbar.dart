import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'controllers/database.controller.dart';
import 'models/snippet.model.dart';

class TopBar extends StatelessWidget {
  final void Function() onSidebarToggleButtonPressed;

  TopBar({Key? key, required this.onSidebarToggleButtonPressed})
      : super(key: key);

  var uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.0,
      child: Row(
        children: [
          const SizedBox(width: 4.0),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: onSidebarToggleButtonPressed,
              child: const Icon(
                Icons.menu,
              ),
            ),
          ),
          const SizedBox(
            width: 4.0,
          ),
          OutlinedButton.icon(
              onPressed: () async {
                await DBProvider().insertSnippet(Snippet(
                    id: uuid.v4(),
                    title: "Untitled snippet",
                    description: "No description",
                    tags: "",
                    code: "",
                    language: "Dart",
                    timestamp: DateTime.now().millisecondsSinceEpoch));
                await DBProvider().list();
              },
              icon: const Icon(Icons.add),
              label: const Text("New snippet")),

          const Spacer(),
          // Flexible(
          //   child: Material(
          //     color: Colors.transparent,
          //     child: TextFormField(
          //         style: const TextStyle(fontSize: 15),
          //         decoration:
          //             const InputDecoration(prefixIcon: Icon(Icons.search))),
          //   ),
          // ),

          // Padding(
          //   padding: const EdgeInsets.only(right: 10.0),
          //   child: OutlinedButton(
          //     onPressed: () {},
          //     child: const Text("Login with Google"),
          //   ),
          // ),
        ],
      ),
    );
  }
}

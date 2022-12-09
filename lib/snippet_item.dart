import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnippetItem extends GetWidget {
  String? title = "Untitled snippet";
  String? description = "";
  int? timestamp = DateTime.now().millisecondsSinceEpoch;

  Function() onTap;

  SnippetItem(
      {super.key,
      this.title,
      this.description,
      this.timestamp,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title ?? "Untitled snippet",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(description ?? "", style: const TextStyle(fontSize: 14)),
              Text(
                  DateTime.fromMillisecondsSinceEpoch(
                          timestamp ?? DateTime.now().millisecondsSinceEpoch)
                      .toString(),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

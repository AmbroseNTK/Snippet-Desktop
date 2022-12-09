import 'dart:async';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/highlight_core.dart';

import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/shell.dart';
import 'package:highlight/languages/scala.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:snippet_desktop/controllers/database.controller.dart';
import 'package:snippet_desktop/models/snippet.model.dart';

class SnippetEditor extends GetWidget {
  Rx<Mode> selectedLanguage = dart.obs;

  var selectedLanguageId = 0.obs;
  var code = "";
  late CodeController _controller;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  Snippet? snippet;

  SnippetEditor({super.key, this.darkMode = true, this.snippet}) {
    var language = languages[0];
    if (snippet != null) {
      code = snippet!.code;
      _titleController = TextEditingController(text: snippet!.title);
      _descriptionController =
          TextEditingController(text: snippet!.description);
      _tagsController = TextEditingController(text: snippet!.tags);
      language = nameToMode(snippet!.language);
      selectedLanguageId.value = languages.indexOf(language);
    } else {
      code = "";
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _tagsController = TextEditingController();
    }
    _controller = CodeController(text: code, language: language);
  }

  bool darkMode = true;

  final List<Mode> languages = [
    dart,
    java,
    javascript,
    kotlin,
    python,
    ruby,
    swift,
    cpp,
    cs,
    css,
    go,
    yaml,
    xml,
    json,
    sql,
    typescript,
    php,
    rust,
    shell,
    scala,
    markdown,
    bash,
  ];
  final List<String> languageNames = [
    "Dart",
    "Java",
    "Javascript",
    "Kotlin",
    "Python",
    "Ruby",
    "Swift",
    "C++",
    "C#",
    "CSS",
    "Go",
    "YAML",
    "XML",
    "JSON",
    "SQL",
    "Typescript",
    "PHP",
    "Rust",
    "Shell",
    "Scala",
    "Markdown",
    "Bash",
  ];

  String modeToName(Mode mode) {
    for (var i = 0; i < languages.length; i++) {
      if (languages[i] == mode) {
        return languageNames[i];
      }
    }
    return '';
  }

  Mode nameToMode(String name) {
    for (var i = 0; i < languageNames.length; i++) {
      if (languageNames[i] == name) {
        return languages[i];
      }
    }
    return dart;
  }

  Timer? _debounce;

  void _onSnippetChange(String data) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async {
      await updateSnippet();
    });
  }

  Future<void> updateSnippet() async {
    if (snippet == null) {
      return Future.value();
    }
    await DBProvider().updateSnippet(Snippet(
      id: snippet!.id,
      title: _titleController.text,
      description: _descriptionController.text,
      tags: _tagsController.text,
      code: code,
      language: modeToName(selectedLanguage.value),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    await DBProvider().list();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(children: [
            Flexible(
              flex: 3,
              child: TextFormField(
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                controller: _titleController,
                onChanged: _onSnippetChange,
              ),
            ),
            const Spacer(),
            IconButton(
                iconSize: 15,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                },
                icon: const Icon(Icons.copy)),
            IconButton(
                iconSize: 15,
                onPressed: () async {
                  print(snippet!.id);
                  if (snippet == null) {
                    return;
                  }
                  await DBProvider().deleteSnippet(snippet!.id);
                  await DBProvider().list();
                },
                icon: const Icon(Icons.delete))
          ]),
          TextFormField(
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
            controller: _descriptionController,
            onChanged: _onSnippetChange,
          ),
          TextFormField(
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Tags (comma delimiter)',
            ),
            controller: _tagsController,
            onChanged: _onSnippetChange,
          ),
          Row(children: [
            const Text("Language: "),
            const Spacer(),
            Obx(
              () => DropdownButton(
                value: selectedLanguageId.value,
                items: languages
                    .map((e) => DropdownMenuItem(
                          value: languages.indexOf(e),
                          child: Text(modeToName(e)),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedLanguageId.value = value ?? 0;
                  selectedLanguage.value = languages[value ?? 0];
                  _controller.language = languages[value ?? 0];
                  _onSnippetChange("");
                },
              ),
            ),
          ]),
          CodeTheme(
              data: CodeThemeData(
                  styles: darkMode ? atomOneDarkTheme : atomOneLightTheme),
              child: CodeField(
                maxLines: 50,
                onChanged: (data) {
                  code = data;
                  _onSnippetChange("");
                },
                controller: _controller,
                textStyle: GoogleFonts.firaCode(
                  fontSize: 14,
                ),
              ))
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_acrylic/widgets/visual_effect_subview_container/visual_effect_subview_container.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:snippet_desktop/controllers/database.controller.dart';
import 'package:snippet_desktop/models/snippet.model.dart';
import 'package:snippet_desktop/sidebar.dart';
import 'package:snippet_desktop/snippet_editor.dart';
import 'package:snippet_desktop/snippet_item.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DBProvider().init();
  await Window.initialize();
  if (Platform.isWindows) {
    await Window.hideWindowControls();
  }
  if (Platform.isMacOS) {
    Window.makeTitlebarTransparent();
    Window.enableFullSizeContentView();
  }

  runApp(const MyApp());
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      appWindow
        ..minSize = const Size(512, 820)
        ..size = const Size(512, 820)
        ..alignment = Alignment.center
        ..show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Snippet",
      theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          splashFactory: InkRipple.splashFactory,
          textTheme: Typography.blackCupertino),
      darkTheme: ThemeData.dark().copyWith(
          splashFactory: InkRipple.splashFactory,
          textTheme: Typography.whiteCupertino),
      themeMode: ThemeMode.system,
      home: const MyAppBody(),
    );
  }
}

enum InterfaceBrightness {
  light,
  dark,
  auto,
}

extension InterfaceBrightnessExtension on InterfaceBrightness {
  bool getIsDark(BuildContext? context) {
    if (this == InterfaceBrightness.light) return false;
    if (this == InterfaceBrightness.auto) {
      if (context == null) return true;
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }

    return true;
  }

  Color getForegroundColor(BuildContext? context) {
    return getIsDark(context) ? Colors.white : Colors.black;
  }
}

class MyAppBody extends StatefulWidget {
  const MyAppBody({Key? key}) : super(key: key);

  @override
  MyAppBodyState createState() => MyAppBodyState();
}

class MyAppBodyState extends State<MyAppBody> {
  WindowEffect effect = WindowEffect.acrylic;
  Color color =
      Platform.isWindows ? const Color(0xCC222222) : Colors.transparent;
  InterfaceBrightness brightness =
      Platform.isMacOS ? InterfaceBrightness.auto : InterfaceBrightness.dark;
  MacOSBlurViewState macOSBlurViewState =
      MacOSBlurViewState.followsWindowActiveState;

  var uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    setWindowEffect(effect);
  }

  void setWindowEffect(WindowEffect? value) {
    Window.setEffect(
      effect: value!,
      color: color,
      dark: brightness == InterfaceBrightness.dark,
    );
    if (Platform.isMacOS) {
      if (brightness != InterfaceBrightness.auto) {
        Window.overrideMacOSBrightness(
            dark: brightness == InterfaceBrightness.dark);
      }
    }
    setState(() => effect = value);
  }

  void setBrightness(InterfaceBrightness brightness) {
    this.brightness = brightness;
    if (this.brightness == InterfaceBrightness.dark) {
      color = Platform.isWindows ? const Color(0xCC222222) : Colors.transparent;
    } else {
      color = Platform.isWindows ? const Color(0x22DDDDDD) : Colors.transparent;
    }
    setWindowEffect(effect);
  }

  Rx<Snippet?> selectedSnippet = Rx<Snippet?>(null);

  @override
  Widget build(BuildContext context) {
    // The [TitlebarSafeArea] widget is required when running on macOS and enabling
    // the full-size content view using [Window.setFullSizeContentView]. It ensures
    // that its child is not covered by the macOS title bar.
    return TitlebarSafeArea(
      child: SidebarFrame(
        macOSBlurViewState: macOSBlurViewState,
        sidebar: SizedBox.expand(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Obx(() {
              return ListView.builder(
                itemCount: DBProvider().cachedSnippets.length,
                itemBuilder: (context, index) {
                  var snippet = DBProvider().cachedSnippets[index];
                  return SnippetItem(
                    key: ValueKey(uuid.v4()),
                    title: snippet.title,
                    description: snippet.description,
                    timestamp: snippet.timestamp,
                    onTap: () {
                      selectedSnippet.value = snippet;
                    },
                  );
                },
              );
            }),
          ),
        ),
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WindowTitleBar(
                      brightness: brightness,
                    ),
                    Obx(() => selectedSnippet.value != null
                        ? SnippetEditor(
                            key: ValueKey(selectedSnippet.value?.id ?? "null"),
                            darkMode: brightness == Brightness.dark,
                            snippet: selectedSnippet.value,
                          )
                        : Center(
                            child: Text("Create or edit your snippets!",
                                style: GoogleFonts.quicksand(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView buildEffectMenu(BuildContext context) {
    return SingleChildScrollView(
      child: Theme(
        data: brightness.getIsDark(context)
            ? ThemeData.dark()
            : ThemeData.light(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: (Platform.isWindows
                  ? WindowEffect.values.take(7)
                  : WindowEffect.values)
              .map(
                (effect) => RadioListTile<WindowEffect>(
                  title: Text(effect.toString(),
                      style: TextStyle(
                        fontSize: 14.0,
                        color: brightness.getForegroundColor(context),
                      )),
                  value: effect,
                  groupValue: this.effect,
                  onChanged: setWindowEffect,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  final InterfaceBrightness brightness;
  const WindowTitleBar({Key? key, required this.brightness}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isWindows
        ? Container(
            width: MediaQuery.of(context).size.width,
            height: 32.0,
            color: Colors.transparent,
            child: MoveWindow(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(),
                  ),
                  MinimizeWindowButton(
                    colors: WindowButtonColors(
                      iconNormal: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      iconMouseDown: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      iconMouseOver: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      normal: Colors.transparent,
                      mouseOver: brightness == InterfaceBrightness.light
                          ? Colors.black.withOpacity(0.04)
                          : Colors.white.withOpacity(0.04),
                      mouseDown: brightness == InterfaceBrightness.light
                          ? Colors.black.withOpacity(0.08)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  MaximizeWindowButton(
                    colors: WindowButtonColors(
                      iconNormal: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      iconMouseDown: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      iconMouseOver: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      normal: Colors.transparent,
                      mouseOver: brightness == InterfaceBrightness.light
                          ? Colors.black.withOpacity(0.04)
                          : Colors.white.withOpacity(0.04),
                      mouseDown: brightness == InterfaceBrightness.light
                          ? Colors.black.withOpacity(0.08)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  CloseWindowButton(
                    onPressed: () {
                      appWindow.close();
                    },
                    colors: WindowButtonColors(
                      iconNormal: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      iconMouseDown: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      iconMouseOver: brightness == InterfaceBrightness.light
                          ? Colors.black
                          : Colors.white,
                      normal: Colors.transparent,
                      mouseOver: brightness == InterfaceBrightness.light
                          ? Colors.black.withOpacity(0.04)
                          : Colors.white.withOpacity(0.04),
                      mouseDown: brightness == InterfaceBrightness.light
                          ? Colors.black.withOpacity(0.08)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}

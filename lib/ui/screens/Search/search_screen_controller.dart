import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '/utils/app_link_controller.dart' show ProcessLink;
import '/services/music_service.dart';
import '/ui/navigator.dart';

class SearchScreenController extends GetxController with ProcessLink {
  final textInputController = TextEditingController();
  final musicServices = Get.find<MusicServices>();
  final suggestionList = [].obs;
  final historyQuerylist = [].obs;
  late Box<dynamic> queryBox;
  final urlPasted = false.obs;

  // Speech to Text related
  final _speech = SpeechToText();
  final isListening = false.obs;
  final showVoiceOverlay = false.obs;
  final recognizedText = ''.obs;
  // The last finalized result from speech recognition
  String _lastRecognizedWords = '';

  // Desktop search bar related
  final focusNode = FocusNode();
  final isSearchBarInFocus = false.obs;

  @override
  onInit() {
    _init();
    super.onInit();
  }

  _init() async {
    if (GetPlatform.isDesktop) {
      focusNode.addListener(() {
        isSearchBarInFocus.value = focusNode.hasFocus;
      });
    }
    queryBox = await Hive.openBox("searchQuery");
    historyQuerylist.value = queryBox.values.toList().reversed.toList();

    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint("Speech initialization failed: $e");
    }
  }

  Future<void> onChanged(String text) async {
    if (text.contains("https://")) {
      urlPasted.value = true;
      return;
    }
    urlPasted.value = false;
    suggestionList.value = await musicServices.getSearchSuggestion(text);
  }

  Future<void> suggestionInput(String txt) async {
    textInputController.text = txt;
    textInputController.selection =
        TextSelection.collapsed(offset: textInputController.text.length);
    await onChanged(txt);
  }

  Future<void> addToHistryQueryList(String txt) async {
    if (historyQuerylist.length > 9) {
      final queryForRemoval = queryBox.getAt(0);
      await queryBox.deleteAt(0);
      historyQuerylist.removeWhere((element) => element == queryForRemoval);
    }
    if (!historyQuerylist.contains(txt)) {
      await queryBox.add(txt);
      historyQuerylist.insert(0, txt);
    }

    //reset current query and suggestionlist
    reset();
  }

  void reset() {
    urlPasted.value = false;
    textInputController.text = "";
    suggestionList.clear();
  }

  Future<void> removeQueryFromHistory(String txt) async {
    final index = queryBox.values.toList().indexOf(txt);
    await queryBox.deleteAt(index);
    historyQuerylist.remove(txt);
  }

  void startListening() async {
    if (GetPlatform.isDesktop) return;

    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }
    }

    _lastRecognizedWords = '';
    _isDone = false;
    recognizedText.value = '';
    textInputController.text = '';
    suggestionList.clear();

    // Dismiss keyboard before showing the voice overlay
    FocusManager.instance.primaryFocus?.unfocus();

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _onSpeechDone();
        }
      },
      onError: (errorNotification) {
        debugPrint("Speech recognition error: $errorNotification");
        _onSpeechDone();
      },
    );

    if (available) {
      isListening.value = true;
      showVoiceOverlay.value = true;
      _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;
          recognizedText.value = result.recognizedWords;
          textInputController.text = result.recognizedWords;
          textInputController.selection =
              TextSelection.collapsed(offset: textInputController.text.length);
          onChanged(result.recognizedWords);

          // Auto-stop: finalResult fires reliably on Android when pauseFor
          // expires or the user stops talking — more reliable than onStatus.
          if (result.finalResult) {
            _onSpeechDone();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    }
  }

  void stopListening() async {
    await _speech.stop();
    _onSpeechDone();
  }

  bool _isDone = false;

  void _onSpeechDone() {
    if (_isDone) return; // prevent double-fire from onStatus + finalResult
    _isDone = true;
    isListening.value = false;
    showVoiceOverlay.value = false;
    if (_lastRecognizedWords.isNotEmpty) {
      // Slight delay so overlay dismisses smoothly first
      Future.delayed(const Duration(milliseconds: 150), () {
        addToHistryQueryList(_lastRecognizedWords);
        Get.toNamed(
          ScreenNavigationSetup.searchResultScreen,
          id: ScreenNavigationSetup.id,
          arguments: _lastRecognizedWords,
        );
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    textInputController.dispose();
    queryBox.close();
    super.dispose();
  }
}

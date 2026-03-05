import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryController extends ChangeNotifier {
  final List<Story> stories;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isMuted = true;

  StoryController({required this.stories, int initialIndex = 0}) : _currentIndex = initialIndex;

  int get currentIndex => _currentIndex;
  bool get isPaused => _isPaused;
  bool get isMuted => _isMuted;
  Story get currentStory => stories[_currentIndex];

  void next() {
    if (_currentIndex < stories.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void pause() {
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';

class PresentationPage extends StatefulWidget {
  const PresentationPage({super.key});

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  List<String> _words = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _wpm = 800.0;
  double _fontSize = 48.0;
  Timer? _timer;
  bool _isLoading = true;
  bool _isProgressLocked = true;

  @override
  void initState() {
    super.initState();
    _loadClipboardText();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadClipboardText() async {
    try {
      FlutterClipboard.paste().then((text) {
        if (text.isNotEmpty) {
          setState(() {
            _words = _splitIntoWords(text);
            _isLoading = false;
          });
        } else {
          setState(() {
            _words = ['Clipboard is empty'];
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _words = ['Error reading clipboard'];
        _isLoading = false;
      });
    }
  }

  List<String> _splitIntoWords(String text) {
    // Split by whitespace and filter out empty strings
    return text.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  void _togglePlayPause() {
    // If we're at the end, restart from beginning
    if (!_isPlaying && _currentIndex >= _words.length - 1) {
      setState(() {
        _currentIndex = 0;
        _isPlaying = true;
      });
      _startPresentation();
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
      });

      if (_isPlaying) {
        _startPresentation();
      } else {
        _timer?.cancel();
      }
    }
  }

  void _startPresentation() {
    _timer?.cancel();
    
    // Calculate delay based on WPM
    int delayMs = (60000 / _wpm).round();
    
    _timer = Timer.periodic(Duration(milliseconds: delayMs), (timer) {
      setState(() {
        if (_currentIndex < _words.length - 1) {
          _currentIndex++;
        } else {
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _resetPresentation() {
    _timer?.cancel();
    setState(() {
      _currentIndex = 0;
      _isPlaying = false;
    });
  }

  void _goBack3Seconds() {
    // Calculate words shown in 3 seconds at current WPM
    // WPM = words per minute, so words per second = WPM / 60
    // Words in 3 seconds = (WPM / 60) * 3
    int wordsToGoBack = ((_wpm / 60) * 3).round();
    
    setState(() {
      _currentIndex = (_currentIndex - wordsToGoBack).clamp(0, _words.length - 1);
    });
    
    // Restart timer if currently playing
    if (_isPlaying) {
      _startPresentation();
    }
  }

  void _toggleProgressLock() {
    setState(() {
      _isProgressLocked = !_isProgressLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Presentation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _isLoading = true;
                _isPlaying = false;
                _currentIndex = 0;
              });
              _loadClipboardText();
            },
            tooltip: 'Reload from clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPresentation,
            tooltip: 'Reset to beginning',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _words.isEmpty
                        ? const Text('No text available')
                        : Text(
                            _words[_currentIndex],
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress indicator
                      Row(
                        children: [
                          Text(
                            '${_currentIndex + 1} / ${_words.length}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isProgressLocked
                              ? LinearProgressIndicator(
                                  value: _words.isEmpty 
                                      ? 0 
                                      : (_currentIndex + 1) / _words.length,
                                )
                              : Slider(
                                  value: _words.isEmpty 
                                      ? 0 
                                      : _currentIndex.toDouble(),
                                  min: 0,
                                  max: _words.isEmpty 
                                      ? 0 
                                      : (_words.length - 1).toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      _currentIndex = value.round();
                                    });
                                    if (_isPlaying) {
                                      _startPresentation();
                                    }
                                  },
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isProgressLocked ? Icons.lock : Icons.lock_open,
                              size: 20,
                            ),
                            onPressed: _toggleProgressLock,
                            tooltip: _isProgressLocked 
                                ? 'Unlock progress bar' 
                                : 'Lock progress bar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // WPM Control
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('WPM:', style: TextStyle(fontSize: 16)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _wpm,
                              min: 100,
                              max: 1200,
                              divisions: 22,
                              label: _wpm.round().toString(),
                              onChanged: (value) {
                                setState(() {
                                  _wpm = value;
                                });
                                if (_isPlaying) {
                                  _startPresentation(); // Restart with new speed
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${_wpm.round()}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      // Font Size Control
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Font:', style: TextStyle(fontSize: 16)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: 24,
                              max: 96,
                              divisions: 18,
                              label: _fontSize.round().toString(),
                              onChanged: (value) {
                                setState(() {
                                  _fontSize = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${_fontSize.round()}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Control Buttons
                      Row(
                        children: [
                          // Go back 3 seconds button
                          SizedBox(
                            width: 70,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _words.isEmpty ? null : _goBack3Seconds,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.replay, size: 24),
                                  Text('-3s', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Play/Pause/Restart Button
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _words.isEmpty ? null : _togglePlayPause,
                                icon: Icon(
                                  _isPlaying 
                                    ? Icons.pause 
                                    : (_currentIndex >= _words.length - 1 
                                        ? Icons.restart_alt 
                                        : Icons.play_arrow),
                                  size: 32,
                                ),
                                label: Text(
                                  _isPlaying 
                                    ? 'Pause' 
                                    : (_currentIndex >= _words.length - 1 
                                        ? 'Restart' 
                                        : 'Play'),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

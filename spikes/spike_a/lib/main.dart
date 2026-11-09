// Spike A — Office Engine Test App
// Tests Apache POI DOCX/XLSX open-edit-save-reopen cycle
// This is NOT production code — minimal UI for spike testing only.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SpikeAApp());

class SpikeAApp extends StatelessWidget {
  const SpikeAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spike A — Office Engine',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const SpikeAScreen(),
    );
  }
}

class SpikeAScreen extends StatefulWidget {
  const SpikeAScreen({super.key});

  @override
  State<SpikeAScreen> createState() => _SpikeAScreenState();
}

class _SpikeAScreenState extends State<SpikeAScreen> {
  static const _channel = MethodChannel('com.example.spikea/poi_spike');
  final _log = <String>[];
  bool _running = false;

  void _addLog(String msg) {
    setState(() => _log.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg'));
  }

  Future<void> _runAllTests() async {
    setState(() {
      _running = true;
      _log.clear();
    });

    try {
      // Step 1: Check POI loaded
      _addLog('═══ Checking POI availability ═══');
      final info = await _channel.invokeMapMethod<String, dynamic>('getInfo');
      if (info != null) {
        _addLog('POI Version: ${info['poi_version']}');
        _addLog('DOCX class: ${info['docx_class']}');
        _addLog('XLSX class: ${info['xlsx_class']}');
        _addLog('Status: ${info['status']}');
      } else {
        _addLog('ERROR: POI not loaded');
        return;
      }

      // Step 2: Copy test fixtures to app's file directory
      final dir = Directory('/data/data/com.example.spikea.spike_a_office/files/spike_test');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      // Copy synth_simple.docx from assets
      _addLog('');
      _addLog('═══ DOCX Edit Verification Cycle ═══');
      final docxInput = '${dir.path}/synth_simple.docx';
      final docxOutput = '${dir.path}/synth_simple_edited.docx';
      await _copyAsset('fixtures/synth_simple.docx', docxInput);
      _addLog('Copied fixture: synth_simple.docx');

      final docxResult = await _channel.invokeMapMethod<String, dynamic>('testDocx', {
        'inputPath': docxInput,
        'outputPath': docxOutput,
        'editText': 'SPIKE_A_EDIT_MARKER',
      });
      if (docxResult != null) {
        _addLog('Status: ${docxResult['status']}');
        _addLog('Open time: ${docxResult['open_time_ms']} ms');
        _addLog('Edit time: ${docxResult['edit_time_ms']} ms');
        _addLog('Save time: ${docxResult['save_time_ms']} ms');
        _addLog('Reopen time: ${docxResult['reopen_time_ms']} ms');
        _addLog('Total cycle: ${docxResult['total_cycle_time_ms']} ms');
        _addLog('Edit preserved: ${docxResult['edit_preserved']}');
        _addLog('ZIP valid: ${docxResult['zip_structure_valid']}');
        _addLog('Original untouched: ${docxResult['original_untouched']}');
        _addLog('Paragraphs: ${docxResult['paragraph_count']}');
        _addLog('CYCLE: ${docxResult['cycle_passed'] == true ? '✅ PASS' : '❌ FAIL'}');
        if (docxResult['error'] != null) _addLog('Error: ${docxResult['error']}');
      }

      // Step 3: XLSX test
      _addLog('');
      _addLog('═══ XLSX Edit Verification Cycle ═══');
      final xlsxInput = '${dir.path}/synth_simple.xlsx';
      final xlsxOutput = '${dir.path}/synth_simple_edited.xlsx';
      await _copyAsset('fixtures/synth_simple.xlsx', xlsxInput);
      _addLog('Copied fixture: synth_simple.xlsx');

      final xlsxResult = await _channel.invokeMapMethod<String, dynamic>('testXlsx', {
        'inputPath': xlsxInput,
        'outputPath': xlsxOutput,
        'editValue': 'SPIKE_A_EDIT',
      });
      if (xlsxResult != null) {
        _addLog('Status: ${xlsxResult['status']}');
        _addLog('Open time: ${xlsxResult['open_time_ms']} ms');
        _addLog('Edit time: ${xlsxResult['edit_time_ms']} ms');
        _addLog('Save time: ${xlsxResult['save_time_ms']} ms');
        _addLog('Reopen time: ${xlsxResult['reopen_time_ms']} ms');
        _addLog('Total cycle: ${xlsxResult['total_cycle_time_ms']} ms');
        _addLog('Edit preserved: ${xlsxResult['edit_preserved']}');
        _addLog('ZIP valid: ${xlsxResult['zip_structure_valid']}');
        _addLog('Original untouched: ${xlsxResult['original_untouched']}');
        _addLog('Sheets: ${xlsxResult['sheet_count']}, Rows: ${xlsxResult['row_count']}');
        _addLog('CYCLE: ${xlsxResult['cycle_passed'] == true ? '✅ PASS' : '❌ FAIL'}');
        if (xlsxResult['error'] != null) _addLog('Error: ${xlsxResult['error']}');
      }

      _addLog('');
      _addLog('═══ All tests complete ═══');
    } catch (e) {
      _addLog('FATAL ERROR: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _copyAsset(String assetPath, String destPath) async {
    final data = await rootBundle.load(assetPath);
    await File(destPath).writeAsBytes(data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spike A — Apache POI Test')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _running ? null : _runAllTests,
              icon: _running
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(_running ? 'Running...' : 'Run Edit Verification Cycle'),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, i) => Text(
                  _log[i],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: _log[i].contains('PASS')
                        ? Colors.greenAccent
                        : _log[i].contains('FAIL') || _log[i].contains('ERROR')
                            ? Colors.redAccent
                            : _log[i].contains('═══')
                                ? Colors.cyanAccent
                                : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

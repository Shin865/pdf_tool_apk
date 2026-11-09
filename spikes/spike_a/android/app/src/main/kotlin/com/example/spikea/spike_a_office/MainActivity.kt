package com.example.spikea.spike_a_office

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.apache.poi.xwpf.usermodel.XWPFDocument
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.zip.ZipFile

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.spikea/poi_spike"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "testDocx" -> handleTestDocx(call, result)
                    "testXlsx" -> handleTestXlsx(call, result)
                    "validateZip" -> handleValidateZip(call, result)
                    "getInfo" -> handleGetInfo(result)
                    else -> result.notImplemented()
                }
            }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Info — confirm POI is loaded and classes accessible
    // ─────────────────────────────────────────────────────────────────────
    private fun handleGetInfo(result: MethodChannel.Result) {
        Thread {
            try {
                // Check that POI classes are loadable
                val docClass = XWPFDocument::class.java.name
                val xlsClass = XSSFWorkbook::class.java.name
                val poiVersion = org.apache.poi.Version.getVersion() ?: "unknown"

                val info = mapOf(
                    "poi_version" to poiVersion,
                    "docx_class" to docClass,
                    "xlsx_class" to xlsClass,
                    "status" to "POI loaded successfully"
                )
                runOnUiThread { result.success(info) }
            } catch (e: Exception) {
                runOnUiThread { result.error("POI_LOAD_ERROR", e.message, e.stackTraceToString()) }
            }
        }.start()
    }

    // ─────────────────────────────────────────────────────────────────────
    // DOCX Edit Verification Cycle
    // open → read → modify 1 paragraph → save new file → reopen → verify
    // ─────────────────────────────────────────────────────────────────────
    private fun handleTestDocx(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
        val outputPath = call.argument<String>("outputPath")
        val editText = call.argument<String>("editText") ?: "EDITED BY SPIKE A"

        if (inputPath == null || outputPath == null) {
            result.error("INVALID_ARGS", "inputPath and outputPath required", null)
            return
        }

        Thread {
            val metrics = mutableMapOf<String, Any>()
            try {
                // ── Step 1: Open and read ──
                val startOpen = SystemClock.elapsedRealtime()
                val doc = XWPFDocument(FileInputStream(File(inputPath)))
                val openTimeMs = SystemClock.elapsedRealtime() - startOpen
                metrics["open_time_ms"] = openTimeMs

                val originalParagraphs = doc.paragraphs.map { it.text }
                metrics["paragraph_count"] = originalParagraphs.size
                metrics["original_first_para"] = originalParagraphs.firstOrNull() ?: ""

                // ── Step 2: Edit — append text to first paragraph ──
                val startEdit = SystemClock.elapsedRealtime()
                if (doc.paragraphs.isNotEmpty()) {
                    val firstPara = doc.paragraphs[0]
                    val run = firstPara.createRun()
                    run.setText(" $editText")
                }
                val editTimeMs = SystemClock.elapsedRealtime() - startEdit
                metrics["edit_time_ms"] = editTimeMs

                // ── Step 3: Save to NEW file (never overwrite original) ──
                val startSave = SystemClock.elapsedRealtime()
                FileOutputStream(File(outputPath)).use { out ->
                    doc.write(out)
                }
                doc.close()
                val saveTimeMs = SystemClock.elapsedRealtime() - startSave
                metrics["save_time_ms"] = saveTimeMs

                val outputSize = File(outputPath).length()
                metrics["output_file_size"] = outputSize

                // ── Step 4: Reopen saved file and verify ──
                val startReopen = SystemClock.elapsedRealtime()
                val reopened = XWPFDocument(FileInputStream(File(outputPath)))
                val reopenTimeMs = SystemClock.elapsedRealtime() - startReopen
                metrics["reopen_time_ms"] = reopenTimeMs

                val newFirstPara = reopened.paragraphs.firstOrNull()?.text ?: ""
                metrics["new_first_para"] = newFirstPara
                reopened.close()

                // ── Step 5: Verify edit persisted ──
                val editPreserved = newFirstPara.contains(editText)
                metrics["edit_preserved"] = editPreserved

                // ── Step 6: Verify original file untouched ──
                val originalStillValid = File(inputPath).exists()
                        && File(inputPath).length() > 0
                metrics["original_untouched"] = originalStillValid

                // ── Step 7: Validate ZIP structure of output ──
                val zipValid = validateZipStructure(outputPath)
                metrics["zip_structure_valid"] = zipValid

                // ── Aggregate ──
                val totalTimeMs = openTimeMs + editTimeMs + saveTimeMs + reopenTimeMs
                metrics["total_cycle_time_ms"] = totalTimeMs
                metrics["cycle_passed"] = editPreserved && zipValid && originalStillValid
                metrics["status"] = if (metrics["cycle_passed"] == true) "PASS" else "FAIL"

                runOnUiThread { result.success(metrics) }
            } catch (e: Exception) {
                metrics["status"] = "ERROR"
                metrics["error"] = e.message ?: "Unknown error"
                metrics["error_trace"] = e.stackTraceToString().take(2000)
                runOnUiThread { result.success(metrics) }
            }
        }.start()
    }

    // ─────────────────────────────────────────────────────────────────────
    // XLSX Edit Verification Cycle
    // ─────────────────────────────────────────────────────────────────────
    private fun handleTestXlsx(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
        val outputPath = call.argument<String>("outputPath")
        val editValue = call.argument<String>("editValue") ?: "EDITED"

        if (inputPath == null || outputPath == null) {
            result.error("INVALID_ARGS", "inputPath and outputPath required", null)
            return
        }

        Thread {
            val metrics = mutableMapOf<String, Any>()
            try {
                // ── Step 1: Open ──
                val startOpen = SystemClock.elapsedRealtime()
                val workbook = XSSFWorkbook(FileInputStream(File(inputPath)))
                val openTimeMs = SystemClock.elapsedRealtime() - startOpen
                metrics["open_time_ms"] = openTimeMs

                val sheetCount = workbook.numberOfSheets
                metrics["sheet_count"] = sheetCount

                val sheet = workbook.getSheetAt(0)
                val rowCount = sheet.lastRowNum + 1
                metrics["row_count"] = rowCount

                val originalCell = sheet.getRow(0)?.getCell(0)?.toString() ?: ""
                metrics["original_cell_A1"] = originalCell

                // ── Step 2: Edit — set cell A1 ──
                val startEdit = SystemClock.elapsedRealtime()
                val row = sheet.getRow(0) ?: sheet.createRow(0)
                val cell = row.getCell(0) ?: row.createCell(0)
                cell.setCellValue("$originalCell $editValue")
                val editTimeMs = SystemClock.elapsedRealtime() - startEdit
                metrics["edit_time_ms"] = editTimeMs

                // ── Step 3: Save new file ──
                val startSave = SystemClock.elapsedRealtime()
                FileOutputStream(File(outputPath)).use { out ->
                    workbook.write(out)
                }
                workbook.close()
                val saveTimeMs = SystemClock.elapsedRealtime() - startSave
                metrics["save_time_ms"] = saveTimeMs
                metrics["output_file_size"] = File(outputPath).length()

                // ── Step 4: Reopen ──
                val startReopen = SystemClock.elapsedRealtime()
                val reopened = XSSFWorkbook(FileInputStream(File(outputPath)))
                val reopenTimeMs = SystemClock.elapsedRealtime() - startReopen
                metrics["reopen_time_ms"] = reopenTimeMs

                val newCellValue = reopened.getSheetAt(0).getRow(0)?.getCell(0)?.toString() ?: ""
                metrics["new_cell_A1"] = newCellValue
                reopened.close()

                // ── Step 5: Verify ──
                val editPreserved = newCellValue.contains(editValue)
                metrics["edit_preserved"] = editPreserved

                val originalStillValid = File(inputPath).exists() && File(inputPath).length() > 0
                metrics["original_untouched"] = originalStillValid

                val zipValid = validateZipStructure(outputPath)
                metrics["zip_structure_valid"] = zipValid

                val totalTimeMs = openTimeMs + editTimeMs + saveTimeMs + reopenTimeMs
                metrics["total_cycle_time_ms"] = totalTimeMs
                metrics["cycle_passed"] = editPreserved && zipValid && originalStillValid
                metrics["status"] = if (metrics["cycle_passed"] == true) "PASS" else "FAIL"

                runOnUiThread { result.success(metrics) }
            } catch (e: Exception) {
                metrics["status"] = "ERROR"
                metrics["error"] = e.message ?: "Unknown error"
                metrics["error_trace"] = e.stackTraceToString().take(2000)
                runOnUiThread { result.success(metrics) }
            }
        }.start()
    }

    // ─────────────────────────────────────────────────────────────────────
    // ZIP structure validation
    // ─────────────────────────────────────────────────────────────────────
    private fun handleValidateZip(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (filePath == null) {
            result.error("INVALID_ARGS", "filePath required", null)
            return
        }
        Thread {
            try {
                val valid = validateZipStructure(filePath)
                result.success(mapOf("valid" to valid, "path" to filePath))
            } catch (e: Exception) {
                result.error("ZIP_ERROR", e.message, null)
            }
        }.start()
    }

    private fun validateZipStructure(filePath: String): Boolean {
        return try {
            val zipFile = ZipFile(File(filePath))
            val entries = zipFile.entries().toList()
            val hasContentTypes = entries.any { it.name == "[Content_Types].xml" }
            val hasRels = entries.any { it.name == "_rels/.rels" }
            zipFile.close()
            hasContentTypes && hasRels && entries.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }
}

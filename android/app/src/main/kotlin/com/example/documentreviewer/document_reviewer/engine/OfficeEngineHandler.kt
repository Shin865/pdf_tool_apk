package com.example.documentreviewer.document_reviewer.engine

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.apache.poi.xwpf.usermodel.*
import org.apache.poi.xssf.usermodel.*
import org.apache.poi.wp.usermodel.HeaderFooterType
import org.apache.poi.ss.usermodel.CellType
import org.apache.poi.ss.usermodel.DateUtil
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.Executors
import java.util.zip.ZipFile

class OfficeEngineHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "docx_getParagraphs" -> docxGetParagraphs(call, result)
            "docx_getStructure" -> docxGetStructure(call, result)
            "docx_updateParagraph" -> docxUpdateParagraph(call, result)
            "docx_appendParagraph" -> docxAppendParagraph(call, result)
            "docx_addHeading" -> docxAddHeading(call, result)
            "docx_addTable" -> docxAddTable(call, result)
            "docx_updateTableCell" -> docxUpdateTableCell(call, result)
            "docx_addPageBreak" -> docxAddPageBreak(call, result)
            "docx_setHeader" -> docxSetHeader(call, result)
            "docx_setFooter" -> docxSetFooter(call, result)
            "docx_insertImage" -> docxInsertImage(call, result)
            "xlsx_getSheetNames" -> xlsxGetSheetNames(call, result)
            "xlsx_getSheetData" -> xlsxGetSheetData(call, result)
            "xlsx_updateCell" -> xlsxUpdateCell(call, result)
            "xlsx_addSheet" -> xlsxAddSheet(call, result)
            "xlsx_renameSheet" -> xlsxRenameSheet(call, result)
            "xlsx_addRow" -> xlsxAddRow(call, result)
            "xlsx_deleteRow" -> xlsxDeleteRow(call, result)
            "office_validateZip" -> officeValidateZip(call, result)
            else -> result.notImplemented()
        }
    }

    private fun postSuccess(result: MethodChannel.Result, data: Any?) {
        mainHandler.post { result.success(data) }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String?, details: Any? = null) {
        mainHandler.post { result.error(code, message, details) }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DOCX Methods
    // ─────────────────────────────────────────────────────────────────────────

    private fun docxGetParagraphs(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        executor.execute {
            try {
                val file = File(filePath)
                if (!file.exists()) {
                    postError(result, "NOT_FOUND", "File not found: $filePath")
                    return@execute
                }
                FileInputStream(file).use { input ->
                    val doc = XWPFDocument(input)
                    val paragraphs = doc.paragraphs.mapIndexed { idx, p ->
                        mapOf(
                            "index" to idx,
                            "text" to p.text,
                            "style" to (p.style ?: ""),
                            "isHeading" to (p.style?.startsWith("Heading") == true)
                        )
                    }
                    doc.close()
                    postSuccess(result, paragraphs)
                }
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxGetStructure(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        executor.execute {
            try {
                val file = File(filePath)
                if (!file.exists()) {
                    postError(result, "NOT_FOUND", "File not found: $filePath")
                    return@execute
                }
                FileInputStream(file).use { input ->
                    val doc = XWPFDocument(input)
                    val paragraphs = doc.paragraphs.mapIndexed { idx, p ->
                        val style = p.style ?: ""
                        val headingLevel = if (style.startsWith("Heading ")) {
                            style.removePrefix("Heading ").toIntOrNull() ?: 1
                        } else {
                            0
                        }
                        mapOf(
                            "index" to idx,
                            "text" to p.text,
                            "style" to style,
                            "headingLevel" to headingLevel
                        )
                    }

                    val tables = doc.tables.mapIndexed { tIdx, tbl ->
                        val rows = tbl.rows.map { row ->
                            row.tableCells.map { cell -> cell.text ?: "" }
                        }
                        mapOf(
                            "index" to tIdx,
                            "rowCount" to tbl.numberOfRows,
                            "rows" to rows
                        )
                    }

                    val headerText = doc.headerList?.firstOrNull()?.text ?: ""
                    val footerText = doc.footerList?.firstOrNull()?.text ?: ""

                    doc.close()
                    postSuccess(result, mapOf(
                        "paragraphs" to paragraphs,
                        "tables" to tables,
                        "header" to headerText,
                        "footer" to footerText
                    ))
                }
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxUpdateParagraph(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val paragraphIndex = call.argument<Int>("index") ?: return result.error("INVALID_ARGS", "index required", null)
        val newText = call.argument<String>("text") ?: return result.error("INVALID_ARGS", "text required", null)
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                if (paragraphIndex < 0 || paragraphIndex >= doc.paragraphs.size) {
                    doc.close()
                    postError(result, "INVALID_INDEX", "Paragraph index out of range")
                    return@execute
                }
                val p = doc.paragraphs[paragraphIndex]
                while (p.runs.isNotEmpty()) {
                    p.removeRun(0)
                }
                val run = p.createRun()
                run.setText(newText)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxAppendParagraph(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val text = call.argument<String>("text") ?: return result.error("INVALID_ARGS", "text required", null)
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val p = doc.createParagraph()
                val run = p.createRun()
                run.setText(text)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxAddHeading(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val text = call.argument<String>("text") ?: return result.error("INVALID_ARGS", "text required", null)
        val level = call.argument<Int>("level") ?: 1
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val p = doc.createParagraph()
                p.style = "Heading $level"
                val run = p.createRun()
                run.setText(text)
                run.isBold = true
                run.fontSize = when (level) {
                    1 -> 18
                    2 -> 16
                    3 -> 14
                    else -> 12
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxAddTable(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val rowsCount = call.argument<Int>("rows") ?: 2
        val colsCount = call.argument<Int>("cols") ?: 2
        val initialData = call.argument<List<List<String>>>("data")
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val table = doc.createTable(rowsCount, colsCount)
                if (initialData != null) {
                    for (r in 0 until Math.min(rowsCount, initialData.size)) {
                        val rowData = initialData[r]
                        val tableRow = table.getRow(r)
                        for (c in 0 until Math.min(colsCount, rowData.size)) {
                            val cell = tableRow.getCell(c) ?: tableRow.addNewTableCell()
                            cell.text = rowData[c]
                        }
                    }
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxUpdateTableCell(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val tableIndex = call.argument<Int>("tableIndex") ?: 0
        val rowIdx = call.argument<Int>("row") ?: 0
        val colIdx = call.argument<Int>("col") ?: 0
        val text = call.argument<String>("text") ?: ""
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                if (tableIndex < 0 || tableIndex >= doc.tables.size) {
                    doc.close()
                    postError(result, "INVALID_INDEX", "Table index out of bounds")
                    return@execute
                }
                val tbl = doc.tables[tableIndex]
                val row = tbl.getRow(rowIdx)
                val cell = row?.getCell(colIdx)
                if (cell == null) {
                    doc.close()
                    postError(result, "INVALID_INDEX", "Cell at ($rowIdx, $colIdx) not found")
                    return@execute
                }
                cell.text = text

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxAddPageBreak(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val p = doc.createParagraph()
                p.isPageBreak = true

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxSetHeader(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val headerText = call.argument<String>("text") ?: ""
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val header = doc.createHeader(HeaderFooterType.DEFAULT)
                val p = header.createParagraph()
                val run = p.createRun()
                run.setText(headerText)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxSetFooter(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val footerText = call.argument<String>("text") ?: ""
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val footer = doc.createFooter(HeaderFooterType.DEFAULT)
                val p = footer.createParagraph()
                val run = p.createRun()
                run.setText(footerText)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    private fun docxInsertImage(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val imagePath = call.argument<String>("imagePath") ?: return result.error("INVALID_ARGS", "imagePath required", null)
        val width = call.argument<Int>("width") ?: 300
        val height = call.argument<Int>("height") ?: 200
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val imgFile = File(imagePath)
                if (!imgFile.exists()) {
                    postError(result, "NOT_FOUND", "Image file not found: $imagePath")
                    return@execute
                }
                val doc = FileInputStream(File(filePath)).use { XWPFDocument(it) }
                val p = doc.createParagraph()
                val run = p.createRun()
                val format = if (imagePath.endsWith(".png", true)) {
                    org.apache.poi.xwpf.usermodel.Document.PICTURE_TYPE_PNG
                } else {
                    org.apache.poi.xwpf.usermodel.Document.PICTURE_TYPE_JPEG
                }
                FileInputStream(imgFile).use { imgStream ->
                    run.addPicture(
                        imgStream,
                        format,
                        imgFile.name,
                        org.apache.poi.util.Units.toEMU(width.toDouble()),
                        org.apache.poi.util.Units.toEMU(height.toDouble())
                    )
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { doc.write(it) }
                doc.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "DOCX_ERROR", t.message)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // XLSX Methods
    // ─────────────────────────────────────────────────────────────────────────

    private fun xlsxGetSheetNames(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        executor.execute {
            try {
                val file = File(filePath)
                if (!file.exists()) {
                    postError(result, "NOT_FOUND", "File not found: $filePath")
                    return@execute
                }
                val wb = FileInputStream(file).use { XSSFWorkbook(it) }
                val names = (0 until wb.numberOfSheets).map { wb.getSheetName(it) }
                wb.close()
                postSuccess(result, names)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun xlsxGetSheetData(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val sheetIndex = call.argument<Int>("sheetIndex") ?: 0

        executor.execute {
            try {
                val wb = FileInputStream(File(filePath)).use { XSSFWorkbook(it) }
                if (sheetIndex < 0 || sheetIndex >= wb.numberOfSheets) {
                    wb.close()
                    postError(result, "INVALID_INDEX", "Sheet index out of bounds: $sheetIndex")
                    return@execute
                }
                val sheet = wb.getSheetAt(sheetIndex)
                val rows = mutableListOf<List<Map<String, Any?>>>()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)

                for (r in sheet) {
                    val cells = mutableListOf<Map<String, Any?>>()
                    val lastCol = Math.max(0, r.lastCellNum.toInt())
                    for (c in 0 until lastCol) {
                        val cell = r.getCell(c)
                        var value = ""
                        var formula: String? = null
                        var isBold = false
                        var isItalic = false

                        if (cell != null) {
                            val font = wb.getFontAt(cell.cellStyle.fontIndex)
                            isBold = font?.bold == true
                            isItalic = font?.italic == true

                            when (cell.cellType) {
                                CellType.NUMERIC -> {
                                    value = if (DateUtil.isCellDateFormatted(cell)) {
                                        cell.dateCellValue?.let { dateFormat.format(it) } ?: ""
                                    } else {
                                        val d = cell.numericCellValue
                                        if (d == d.toLong().toDouble()) d.toLong().toString() else d.toString()
                                    }
                                }
                                CellType.STRING -> value = cell.stringCellValue ?: ""
                                CellType.FORMULA -> {
                                    formula = "=" + (cell.cellFormula ?: "")
                                    value = try {
                                        val d = cell.numericCellValue
                                        if (d == d.toLong().toDouble()) d.toLong().toString() else d.toString()
                                    } catch (e: Exception) {
                                        try { cell.stringCellValue ?: formula } catch (_: Exception) { formula }
                                    }
                                }
                                CellType.BOOLEAN -> value = cell.booleanCellValue.toString()
                                else -> value = cell.toString()
                            }
                        }

                        cells.add(mapOf(
                            "value" to value,
                            "formula" to formula,
                            "bold" to isBold,
                            "italic" to isItalic
                        ))
                    }
                    rows.add(cells)
                }
                wb.close()
                postSuccess(result, rows)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun xlsxUpdateCell(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val sheetIndex = call.argument<Int>("sheetIndex") ?: 0
        val rowIdx = call.argument<Int>("row") ?: return result.error("INVALID_ARGS", "row required", null)
        val colIdx = call.argument<Int>("col") ?: return result.error("INVALID_ARGS", "col required", null)
        val value = call.argument<String>("value") ?: ""
        val formula = call.argument<String>("formula")
        val bold = call.argument<Boolean>("bold") ?: false
        val italic = call.argument<Boolean>("italic") ?: false
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val wb = FileInputStream(File(filePath)).use { XSSFWorkbook(it) }
                if (sheetIndex < 0 || sheetIndex >= wb.numberOfSheets) {
                    wb.close()
                    postError(result, "INVALID_INDEX", "Sheet index out of bounds: $sheetIndex")
                    return@execute
                }
                val sheet = wb.getSheetAt(sheetIndex)
                var row = sheet.getRow(rowIdx)
                if (row == null) row = sheet.createRow(rowIdx)
                var cell = row.getCell(colIdx)
                if (cell != null) {
                    row.removeCell(cell)
                }
                cell = row.createCell(colIdx)

                if (!formula.isNullOrBlank()) {
                    val cleanFormula = if (formula.startsWith("=")) formula.substring(1) else formula
                    cell.cellFormula = cleanFormula
                } else {
                    val numericVal = value.toDoubleOrNull()
                    if (numericVal != null) {
                        cell.setCellValue(numericVal)
                    } else {
                        cell.setCellValue(value)
                    }
                }

                if (bold || italic) {
                    val style = wb.createCellStyle()
                    val font = wb.createFont()
                    font.bold = bold
                    font.italic = italic
                    style.setFont(font)
                    cell.cellStyle = style
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { wb.write(it) }
                wb.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun xlsxAddSheet(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val sheetName = call.argument<String>("sheetName") ?: "Sheet"
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val wb = FileInputStream(File(filePath)).use { XSSFWorkbook(it) }
                wb.createSheet(sheetName)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { wb.write(it) }
                wb.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun xlsxRenameSheet(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val sheetIndex = call.argument<Int>("sheetIndex") ?: 0
        val newName = call.argument<String>("newName") ?: return result.error("INVALID_ARGS", "newName required", null)
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val wb = FileInputStream(File(filePath)).use { XSSFWorkbook(it) }
                if (sheetIndex < 0 || sheetIndex >= wb.numberOfSheets) {
                    wb.close()
                    postError(result, "INVALID_INDEX", "Sheet index out of bounds")
                    return@execute
                }
                wb.setSheetName(sheetIndex, newName)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { wb.write(it) }
                wb.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun xlsxAddRow(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val sheetIndex = call.argument<Int>("sheetIndex") ?: 0
        val values = call.argument<List<String>>("values") ?: emptyList()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val wb = FileInputStream(File(filePath)).use { XSSFWorkbook(it) }
                if (sheetIndex < 0 || sheetIndex >= wb.numberOfSheets) {
                    wb.close()
                    postError(result, "INVALID_INDEX", "Sheet index out of bounds")
                    return@execute
                }
                val sheet = wb.getSheetAt(sheetIndex)
                val newRowIdx = sheet.lastRowNum + 1
                val row = sheet.createRow(newRowIdx)
                values.forEachIndexed { c, v ->
                    val cell = row.createCell(c)
                    val num = v.toDoubleOrNull()
                    if (num != null) cell.setCellValue(num) else cell.setCellValue(v)
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { wb.write(it) }
                wb.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun xlsxDeleteRow(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val sheetIndex = call.argument<Int>("sheetIndex") ?: 0
        val rowIndex = call.argument<Int>("rowIndex") ?: return result.error("INVALID_ARGS", "rowIndex required", null)
        val outputPath = call.argument<String>("outputPath") ?: filePath

        executor.execute {
            try {
                val wb = FileInputStream(File(filePath)).use { XSSFWorkbook(it) }
                if (sheetIndex < 0 || sheetIndex >= wb.numberOfSheets) {
                    wb.close()
                    postError(result, "INVALID_INDEX", "Sheet index out of bounds")
                    return@execute
                }
                val sheet = wb.getSheetAt(sheetIndex)
                val row = sheet.getRow(rowIndex)
                if (row != null) {
                    sheet.removeRow(row)
                    // Shift rows up if needed
                    if (rowIndex < sheet.lastRowNum) {
                        sheet.shiftRows(rowIndex + 1, sheet.lastRowNum, -1)
                    }
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { wb.write(it) }
                wb.close()
                postSuccess(result, true)
            } catch (t: Throwable) {
                postError(result, "XLSX_ERROR", t.message)
            }
        }
    }

    private fun officeValidateZip(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        executor.execute {
            try {
                val file = File(filePath)
                if (!file.exists() || file.length() == 0L) {
                    postSuccess(result, false)
                    return@execute
                }
                ZipFile(file).use { zip ->
                    val valid = zip.getEntry("[Content_Types].xml") != null
                    postSuccess(result, valid)
                }
            } catch (t: Throwable) {
                postSuccess(result, false)
            }
        }
    }
}

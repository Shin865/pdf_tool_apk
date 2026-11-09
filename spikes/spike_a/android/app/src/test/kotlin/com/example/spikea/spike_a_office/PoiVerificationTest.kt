package com.example.spikea.spike_a_office

import org.apache.poi.xwpf.usermodel.XWPFDocument
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.zip.ZipFile

class PoiVerificationTest {

    private fun findFixture(name: String): File {
        val candidates = listOf(
            File("../../../../test/fixtures/$name"),
            File("../../../test/fixtures/$name"),
            File("../../fixtures/$name"),
            File("fixtures/$name"),
            File("D:/PDF_TOOL_APK/test/fixtures/$name")
        )
        for (c in candidates) {
            if (c.exists()) return c.canonicalFile
        }
        throw IllegalArgumentException("Fixture $name not found in candidates: $candidates")
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(8192)
            var read: Int
            while (input.read(buffer).also { read = it } > 0) {
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun validateZip(file: File, requiredEntries: List<String>): Boolean {
        return try {
            ZipFile(file).use { zip ->
                for (entry in requiredEntries) {
                    if (zip.getEntry(entry) == null) {
                        return false
                    }
                }
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    @Test
    fun testDocxEditVerificationCycle() {
        val fixturePath = findFixture("synth_simple.docx")
        assertTrue("Fixture file must exist at $fixturePath", fixturePath.exists())
        val originalSha = sha256(fixturePath)
        val originalLength = fixturePath.length()

        val tempOutputFile = File.createTempFile("poi_test_out_", ".docx")
        tempOutputFile.deleteOnExit()

        val startTime = System.currentTimeMillis()

        // 1. Open fixture
        val doc = XWPFDocument(FileInputStream(fixturePath))
        val openTime = System.currentTimeMillis() - startTime
        println("DOCX open time: ${openTime}ms, paragraphs: ${doc.paragraphs.size}")

        assertTrue("Should have paragraphs", doc.paragraphs.isNotEmpty())

        // 2. Modify paragraph text
        val p0 = doc.paragraphs[0]
        val originalText = p0.text
        println("Original p0 text: $originalText")

        // Append text to first paragraph run
        if (p0.runs.isNotEmpty()) {
            p0.runs[0].setText("MODIFIED_BY_POI: " + p0.runs[0].text(), 0)
        } else {
            val r = p0.createRun()
            r.setText("MODIFIED_BY_POI: New text")
        }

        // Add a new paragraph
        val newP = doc.createParagraph()
        val newRun = newP.createRun()
        newRun.setText("APPENDED_PARAGRAPH_TIMESTAMP_${System.currentTimeMillis()}")

        // 3. Save to new file
        val saveStart = System.currentTimeMillis()
        FileOutputStream(tempOutputFile).use { out ->
            doc.write(out)
        }
        doc.close()
        val saveTime = System.currentTimeMillis() - saveStart
        println("DOCX save time: ${saveTime}ms, output size: ${tempOutputFile.length()} bytes")

        // 4. Force-close simulation & Reopen
        val reopenStart = System.currentTimeMillis()
        val reopenedDoc = XWPFDocument(FileInputStream(tempOutputFile))
        val reopenTime = System.currentTimeMillis() - reopenStart
        println("DOCX reopen time: ${reopenTime}ms, paragraphs: ${reopenedDoc.paragraphs.size}")

        // 5. Verify contents
        val reopenedP0 = reopenedDoc.paragraphs[0].text
        println("Reopened p0 text: $reopenedP0")
        assertTrue("Modified text must contain prefix", reopenedP0.contains("MODIFIED_BY_POI"))

        val allText = reopenedDoc.paragraphs.joinToString("\n") { it.text }
        assertTrue("Appended paragraph must be present", allText.contains("APPENDED_PARAGRAPH"))
        reopenedDoc.close()

        // 6. Validate ZIP structure (standard OOXML)
        val validZip = validateZip(tempOutputFile, listOf("[Content_Types].xml", "word/document.xml"))
        assertTrue("DOCX output must be valid ZIP with required OOXML entries", validZip)

        // 7. Verify original file is UNTOUCHED
        val postSha = sha256(fixturePath)
        assertEquals("Original file SHA-256 must NOT change", originalSha, postSha)
        assertEquals("Original file length must NOT change", originalLength, fixturePath.length())

        println("DOCX verification cycle PASSED successfully!")
    }

    @Test
    fun testXlsxEditVerificationCycle() {
        val fixturePath = findFixture("synth_simple.xlsx")
        assertTrue("Fixture file must exist at $fixturePath", fixturePath.exists())
        val originalSha = sha256(fixturePath)
        val originalLength = fixturePath.length()

        val tempOutputFile = File.createTempFile("poi_test_out_", ".xlsx")
        tempOutputFile.deleteOnExit()

        val startTime = System.currentTimeMillis()

        // 1. Open fixture
        val workbook = XSSFWorkbook(FileInputStream(fixturePath))
        val openTime = System.currentTimeMillis() - startTime
        println("XLSX open time: ${openTime}ms, sheets: ${workbook.numberOfSheets}")

        assertTrue("Should have at least 1 sheet", workbook.numberOfSheets > 0)
        val sheet = workbook.getSheetAt(0)

        // 2. Modify cell (0, 0)
        var row0 = sheet.getRow(0)
        if (row0 == null) row0 = sheet.createRow(0)
        var cell0 = row0.getCell(0)
        if (cell0 == null) cell0 = row0.createCell(0)
        val originalCellValue = cell0.toString()
        println("Original cell (0,0): $originalCellValue, type: ${cell0.cellType}")
        cell0.setCellValue("MODIFIED_POI_CELL")
        println("After setCellValue cell (0,0): ${cell0.stringCellValue}, type: ${cell0.cellType}")

        // Add a new row
        val lastRowNum = sheet.lastRowNum
        val newRow = sheet.createRow(lastRowNum + 1)
        val newCell = newRow.createCell(0)
        newCell.setCellValue("NEW_POI_ROW_${System.currentTimeMillis()}")

        // 3. Save to new file
        val saveStart = System.currentTimeMillis()
        FileOutputStream(tempOutputFile).use { out ->
            workbook.write(out)
        }
        workbook.close()
        val saveTime = System.currentTimeMillis() - saveStart
        println("XLSX save time: ${saveTime}ms, output size: ${tempOutputFile.length()} bytes")

        // 4. Force-close simulation & Reopen
        val reopenStart = System.currentTimeMillis()
        val reopenedWb = XSSFWorkbook(FileInputStream(tempOutputFile))
        val reopenTime = System.currentTimeMillis() - reopenStart
        println("XLSX reopen time: ${reopenTime}ms, sheets: ${reopenedWb.numberOfSheets}")

        // 5. Verify contents
        val reopenedSheet = reopenedWb.getSheetAt(0)
        println("Reopened sheet physicalNumberOfRows: ${reopenedSheet.physicalNumberOfRows}, lastRowNum: ${reopenedSheet.lastRowNum}")
        for (r in reopenedSheet) {
            val rowStr = (0 until r.lastCellNum).joinToString(", ") { c -> r.getCell(c)?.toString() ?: "<null>" }
            println("Row ${r.rowNum}: $rowStr")
        }
        val val0 = reopenedSheet.getRow(0).getCell(0).stringCellValue
        println("Reopened cell (0,0): $val0")
        assertEquals("Cell value must match modified text", "MODIFIED_POI_CELL", val0)

        val newRowVal = reopenedSheet.getRow(lastRowNum + 1).getCell(0).stringCellValue
        assertTrue("New row cell must contain prefix", newRowVal.contains("NEW_POI_ROW"))
        reopenedWb.close()

        // 6. Validate ZIP structure (standard OOXML)
        val validZip = validateZip(tempOutputFile, listOf("[Content_Types].xml", "xl/workbook.xml"))
        assertTrue("XLSX output must be valid ZIP with required OOXML entries", validZip)

        // 7. Verify original file is UNTOUCHED
        val postSha = sha256(fixturePath)
        assertEquals("Original file SHA-256 must NOT change", originalSha, postSha)
        assertEquals("Original file length must NOT change", originalLength, fixturePath.length())

        println("XLSX verification cycle PASSED successfully!")
    }
}
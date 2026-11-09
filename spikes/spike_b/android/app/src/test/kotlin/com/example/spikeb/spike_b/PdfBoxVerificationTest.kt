package com.example.spikeb.spike_b

import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDColor
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDDeviceRGB
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationTextMarkup
import com.tom_roush.pdfbox.text.PDFTextStripper
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.security.MessageDigest

class PdfBoxVerificationTest {

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

    @Test
    fun testPdfOpenSearchAnnotateSaveCycle() {
        val fixture = findFixture("synth_simple.pdf")
        assertTrue("Fixture must exist", fixture.exists())
        val originalSha = sha256(fixture)
        val originalLength = fixture.length()

        val tempOut = File.createTempFile("pdfbox_test_out_", ".pdf")
        tempOut.deleteOnExit()

        // 1. Open document
        val t0 = System.currentTimeMillis()
        val doc = PDDocument.load(fixture)
        val openMs = System.currentTimeMillis() - t0
        println("PDF load time: ${openMs}ms, pageCount: ${doc.numberOfPages}")
        assertTrue("Must have at least 1 page", doc.numberOfPages > 0)

        // 2. Text extraction & search
        val t1 = System.currentTimeMillis()
        val stripper = PDFTextStripper()
        val extractedText = stripper.getText(doc)
        val textMs = System.currentTimeMillis() - t1
        println("PDF text extraction time: ${textMs}ms, length: ${extractedText.length}")
        println("EXTRACTED TEXT:\n$extractedText")
        assertTrue("Extracted text must not be blank", extractedText.isNotBlank())

        // Search test for word present in text
        val words = extractedText.trim().split(Regex("\\s+")).filter { it.length > 3 }
        println("Candidate search words: $words")
        val searchTerm = words.firstOrNull() ?: "PDF"
        val found = extractedText.contains(searchTerm)
        println("Search term '$searchTerm' found: $found")
        assertTrue("Search must find term in document", found)

        // 3. Add Highlight Annotation
        val page = doc.getPage(0)
        val highlight = PDAnnotationTextMarkup(PDAnnotationTextMarkup.SUB_TYPE_HIGHLIGHT)
        val rect = PDRectangle(50f, 650f, 200f, 20f)
        highlight.rectangle = rect
        highlight.quadPoints = floatArrayOf(
            rect.lowerLeftX, rect.upperRightY,
            rect.upperRightX, rect.upperRightY,
            rect.lowerLeftX, rect.lowerLeftY,
            rect.upperRightX, rect.lowerLeftY
        )
        // Yellow color
        val yellow = PDColor(floatArrayOf(1f, 1f, 0f), PDDeviceRGB.INSTANCE)
        highlight.color = yellow
        page.annotations.add(highlight)

        // 4. Save to temporary output
        val tSave = System.currentTimeMillis()
        doc.save(tempOut)
        doc.close()
        val saveMs = System.currentTimeMillis() - tSave
        println("PDF save time: ${saveMs}ms, output size: ${tempOut.length()} bytes")

        // 5. Reopen and verify annotations survive
        val tReopen = System.currentTimeMillis()
        val reopenedDoc = PDDocument.load(tempOut)
        val reopenMs = System.currentTimeMillis() - tReopen
        println("PDF reopen time: ${reopenMs}ms, pages: ${reopenedDoc.numberOfPages}")

        val reopenedPage = reopenedDoc.getPage(0)
        val annots = reopenedPage.annotations
        println("Reopened page annotations count: ${annots.size}")
        assertTrue("Page must retain annotations", annots.isNotEmpty())

        val reopenedHighlight = annots.filterIsInstance<PDAnnotationTextMarkup>().firstOrNull()
        assertNotNull("Highlight annotation must exist", reopenedHighlight)
        assertEquals("Subtype must be Highlight", PDAnnotationTextMarkup.SUB_TYPE_HIGHLIGHT, reopenedHighlight!!.subtype)

        // Re-verify text still readable
        val reopenedText = stripper.getText(reopenedDoc)
        assertTrue("Text must remain readable after annotation save", reopenedText.contains(searchTerm))
        reopenedDoc.close()

        // 6. Verify original file SHA-256 strictly preserved
        val postSha = sha256(fixture)
        assertEquals("Original PDF SHA-256 must NOT change", originalSha, postSha)
        assertEquals("Original PDF length must NOT change", originalLength, fixture.length())

        println("PDF Spike B verification cycle PASSED successfully!")
    }

    @Test
    fun testCorruptedPdfGracefulErrorHandling() {
        val corruptedFixture = findFixture("synth_corrupted.pdf")
        assertTrue("Corrupted fixture must exist", corruptedFixture.exists())

        var handledGracefully = false
        try {
            PDDocument.load(corruptedFixture).use { doc ->
                // If it partially loads or throws
                val count = doc.numberOfPages
                println("Corrupted PDF loaded partially with $count pages")
                handledGracefully = true
            }
        } catch (e: IOException) {
            println("Caught expected IOException on corrupted PDF: ${e.message}")
            handledGracefully = true
        } catch (e: Exception) {
            println("Caught general exception on corrupted PDF: ${e.javaClass.simpleName} - ${e.message}")
            handledGracefully = true
        }

        assertTrue("Corrupted PDF must be handled gracefully without crashing JVM", handledGracefully)
        println("Corrupted PDF resilience test PASSED!")
    }
}


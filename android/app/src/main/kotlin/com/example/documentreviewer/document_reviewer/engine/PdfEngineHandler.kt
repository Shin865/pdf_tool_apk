package com.example.documentreviewer.document_reviewer.engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDColor
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDDeviceRGB
import com.tom_roush.pdfbox.pdmodel.graphics.image.LosslessFactory
import com.tom_roush.pdfbox.cos.COSName
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationMarkup
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationTextMarkup
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDBorderStyleDictionary
import com.tom_roush.pdfbox.text.PDFTextStripper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class PdfEngineHandler(private val context: Context) {

    init {
        try {
            PDFBoxResourceLoader.init(context)
        } catch (e: Exception) {
            android.util.Log.e("PdfEngineHandler", "Failed to init PDFBoxResourceLoader", e)
        }
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pdf_getPageCount" -> getPageCount(call, result)
            "pdf_renderPage" -> renderPage(call, result)
            "pdf_extractText" -> extractText(call, result)
            "pdf_searchText" -> searchText(call, result)
            "pdf_addHighlight" -> addHighlight(call, result)
            "pdf_addUnderline" -> addUnderline(call, result)
            "pdf_addInk" -> addInk(call, result)
            "pdf_addText" -> addText(call, result)
            "pdf_addImage" -> addImage(call, result)
            "pdf_rotatePage" -> rotatePage(call, result)
            "pdf_deletePages" -> deletePages(call, result)
            "pdf_reorderPages" -> reorderPages(call, result)
            "pdf_mergePdfs" -> mergePdfs(call, result)
            "pdf_splitPdf" -> splitPdf(call, result)
            "pdf_close" -> closePdf(call, result)
            else -> result.notImplemented()
        }
    }

    private fun getPageCount(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath is required", null)
        val password = call.argument<String>("password")
        val file = File(filePath)
        if (!file.exists()) return result.error("NOT_FOUND", "File does not exist: $filePath", null)

        if (password != null) {
            Thread {
                try {
                    val doc = PDDocument.load(file, password)
                    val count = doc.numberOfPages
                    val decFile = File(context.cacheDir, "dec_${file.name}")
                    doc.isAllSecurityToBeRemoved = true
                    doc.save(decFile)
                    doc.close()
                    result.success(count)
                } catch (e: Exception) {
                    val msg = e.message ?: ""
                    if (msg.contains("password", ignoreCase = true) || e.javaClass.simpleName.contains("Password", ignoreCase = true)) {
                        result.error("PASSWORD_REQUIRED", "Invalid password", null)
                    } else {
                        result.error("PDF_ERROR", "Cannot decrypt PDF: $msg", null)
                    }
                }
            }.start()
            return
        }

        try {
            val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(pfd)
            val pageCount = renderer.pageCount
            renderer.close()
            pfd.close()
            result.success(pageCount)
        } catch (e: Exception) {
            // Fallback to PdfBox if PdfRenderer fails (e.g. password or corrupted)
            Thread {
                try {
                    val doc = PDDocument.load(file)
                    if (doc.isEncrypted) {
                        doc.close()
                        result.error("PASSWORD_REQUIRED", "Password required for encrypted PDF", null)
                    } else {
                        val count = doc.numberOfPages
                        doc.close()
                        result.success(count)
                    }
                } catch (e2: Exception) {
                    val msg = e2.message ?: ""
                    if (msg.contains("password", ignoreCase = true) || e2.javaClass.simpleName.contains("Password", ignoreCase = true)) {
                        result.error("PASSWORD_REQUIRED", "Password required", null)
                    } else {
                        result.error("PDF_ERROR", "Cannot open PDF: ${e.message}", null)
                    }
                }
            }.start()
        }
    }

    private fun closePdf(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (filePath != null) {
            val file = File(filePath)
            val decFile = File(context.cacheDir, "dec_${file.name}")
            if (decFile.exists()) {
                decFile.delete()
            }
        }
        result.success(true)
    }

    private fun renderPage(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        val scale = (call.argument<Double>("scale") ?: 1.0).toFloat()
        val outputPath = call.argument<String>("outputPath") ?: return result.error("INVALID_ARGS", "outputPath required", null)

        val file = File(filePath)
        if (!file.exists()) return result.error("NOT_FOUND", "File not found", null)

        val decFile = File(context.cacheDir, "dec_${file.name}")
        val targetFile = if (decFile.exists()) decFile else file

        Thread {
            var pfd: ParcelFileDescriptor? = null
            var renderer: PdfRenderer? = null
            var page: PdfRenderer.Page? = null
            try {
                pfd = ParcelFileDescriptor.open(targetFile, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(pfd)
                if (pageIndex < 0 || pageIndex >= renderer.pageCount) {
                    result.error("INVALID_PAGE", "Page index out of bounds", null)
                    return@Thread
                }
                page = renderer.openPage(pageIndex)
                val width = (page.width * scale).toInt()
                val height = (page.height * scale).toInt()

                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                FileOutputStream(outFile).use { out ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 95, out)
                }
                bitmap.recycle()

                result.success(mapOf(
                    "outputPath" to outputPath,
                    "width" to width,
                    "height" to height
                ))
            } catch (e: Exception) {
                result.error("RENDER_ERROR", e.message, null)
            } finally {
                page?.close()
                renderer?.close()
                pfd?.close()
            }
        }.start()
    }

    private fun extractText(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") // null means all pages

        Thread {
            try {
                PDDocument.load(File(filePath)).use { doc ->
                    val stripper = PDFTextStripper()
                    if (pageIndex != null) {
                        stripper.startPage = pageIndex + 1
                        stripper.endPage = pageIndex + 1
                    }
                    val text = stripper.getText(doc)
                    result.success(text)
                }
            } catch (e: Exception) {
                result.error("EXTRACT_ERROR", e.message, null)
            }
        }.start()
    }

    private fun searchText(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val query = call.argument<String>("query") ?: return result.error("INVALID_ARGS", "query required", null)

        Thread {
            try {
                val matches = mutableListOf<Map<String, Any>>()
                PDDocument.load(File(filePath)).use { doc ->
                    val stripper = PDFTextStripper()
                    for (p in 1..doc.numberOfPages) {
                        stripper.startPage = p
                        stripper.endPage = p
                        val text = stripper.getText(doc)
                        var index = text.indexOf(query, 0, ignoreCase = true)
                        while (index >= 0) {
                            val snippetStart = Math.max(0, index - 30)
                            val snippetEnd = Math.min(text.length, index + query.length + 30)
                            val snippet = text.substring(snippetStart, snippetEnd).replace('\n', ' ')

                            matches.add(mapOf(
                                "pageIndex" to (p - 1),
                                "charOffset" to index,
                                "snippet" to snippet
                            ))
                            index = text.indexOf(query, index + query.length, ignoreCase = true)
                        }
                    }
                }
                result.success(matches)
            } catch (e: Exception) {
                result.error("SEARCH_ERROR", e.message, null)
            }
        }.start()
    }

    private fun addHighlight(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        val x = (call.argument<Double>("x") ?: 0.0).toFloat()
        val y = (call.argument<Double>("y") ?: 0.0).toFloat()
        val width = (call.argument<Double>("width") ?: 100.0).toFloat()
        val height = (call.argument<Double>("height") ?: 20.0).toFloat()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                if (pageIndex < 0 || pageIndex >= doc.numberOfPages) {
                    doc.close()
                    result.error("INVALID_PAGE", "Page $pageIndex out of range", null)
                    return@Thread
                }
                val page = doc.getPage(pageIndex)
                val highlight = PDAnnotationTextMarkup(PDAnnotationTextMarkup.SUB_TYPE_HIGHLIGHT)
                val rect = PDRectangle(x, y, width, height)
                highlight.rectangle = rect
                highlight.quadPoints = floatArrayOf(
                    rect.lowerLeftX, rect.upperRightY,
                    rect.upperRightX, rect.upperRightY,
                    rect.lowerLeftX, rect.lowerLeftY,
                    rect.upperRightX, rect.lowerLeftY
                )
                highlight.color = PDColor(floatArrayOf(1f, 1f, 0f), PDDeviceRGB.INSTANCE)
                page.annotations.add(highlight)

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("HIGHLIGHT_ERROR", e.message, null)
            }
        }.start()
    }

    private fun addUnderline(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        val x = (call.argument<Double>("x") ?: 0.0).toFloat()
        val y = (call.argument<Double>("y") ?: 0.0).toFloat()
        val width = (call.argument<Double>("width") ?: 100.0).toFloat()
        val height = (call.argument<Double>("height") ?: 20.0).toFloat()
        val r = (call.argument<Double>("r") ?: 0.0).toFloat()
        val g = (call.argument<Double>("g") ?: 0.0).toFloat()
        val b = (call.argument<Double>("b") ?: 1.0).toFloat()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                if (pageIndex < 0 || pageIndex >= doc.numberOfPages) {
                    doc.close()
                    result.error("INVALID_PAGE", "Page $pageIndex out of range", null)
                    return@Thread
                }
                val page = doc.getPage(pageIndex)
                val underline = PDAnnotationTextMarkup(PDAnnotationTextMarkup.SUB_TYPE_UNDERLINE)
                val rect = PDRectangle(x, y, width, height)
                underline.rectangle = rect
                underline.quadPoints = floatArrayOf(
                    rect.lowerLeftX, rect.upperRightY,
                    rect.upperRightX, rect.upperRightY,
                    rect.lowerLeftX, rect.lowerLeftY,
                    rect.upperRightX, rect.lowerLeftY
                )
                underline.color = PDColor(floatArrayOf(r, g, b), PDDeviceRGB.INSTANCE)
                page.annotations.add(underline)

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("UNDERLINE_ERROR", e.message, null)
            }
        }.start()
    }

    private fun addInk(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        @Suppress("UNCHECKED_CAST")
        val points = call.argument<List<List<Double>>>("points") ?: listOf()
        val strokeWidth = (call.argument<Double>("strokeWidth") ?: 2.0).toFloat()
        val r = (call.argument<Double>("r") ?: 0.0).toFloat()
        val g = (call.argument<Double>("g") ?: 0.0).toFloat()
        val b = (call.argument<Double>("b") ?: 0.0).toFloat()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                if (pageIndex < 0 || pageIndex >= doc.numberOfPages) {
                    doc.close()
                    result.error("INVALID_PAGE", "Page $pageIndex out of range", null)
                    return@Thread
                }
                val page = doc.getPage(pageIndex)
                val ink = PDAnnotationMarkup()
                ink.cosObject.setName(COSName.SUBTYPE, PDAnnotationMarkup.SUB_TYPE_INK)

                var minX = Float.MAX_VALUE
                var minY = Float.MAX_VALUE
                var maxX = Float.MIN_VALUE
                var maxY = Float.MIN_VALUE

                val flatPoints = mutableListOf<Float>()
                for (pt in points) {
                    if (pt.size >= 2) {
                        val px = pt[0].toFloat()
                        val py = pt[1].toFloat()
                        flatPoints.add(px)
                        flatPoints.add(py)
                        if (px < minX) minX = px
                        if (py < minY) minY = py
                        if (px > maxX) maxX = px
                        if (py > maxY) maxY = py
                    }
                }

                if (flatPoints.isNotEmpty()) {
                    ink.setInkList(arrayOf(flatPoints.toFloatArray()))
                    ink.setRectangle(PDRectangle(minX, minY, (maxX - minX).coerceAtLeast(1f), (maxY - minY).coerceAtLeast(1f)))
                    ink.setColor(PDColor(floatArrayOf(r, g, b), PDDeviceRGB.INSTANCE))
                    val bs = PDBorderStyleDictionary()
                    bs.width = strokeWidth
                    ink.setBorderStyle(bs)
                    try {
                        ink.constructAppearances(doc)
                    } catch (_: Exception) {}
                    page.annotations.add(ink)
                }

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("INK_ERROR", e.message, null)
            }
        }.start()
    }

    private fun addText(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        val text = call.argument<String>("text") ?: ""
        val x = (call.argument<Double>("x") ?: 50.0).toFloat()
        val y = (call.argument<Double>("y") ?: 50.0).toFloat()
        val fontSize = (call.argument<Double>("fontSize") ?: 12.0).toFloat()
        val r = (call.argument<Double>("r") ?: 0.0).toFloat()
        val g = (call.argument<Double>("g") ?: 0.0).toFloat()
        val b = (call.argument<Double>("b") ?: 0.0).toFloat()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                if (pageIndex < 0 || pageIndex >= doc.numberOfPages) {
                    doc.close()
                    result.error("INVALID_PAGE", "Page $pageIndex out of range", null)
                    return@Thread
                }
                val page = doc.getPage(pageIndex)
                val cs = PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true)
                cs.beginText()
                cs.setFont(PDType1Font.HELVETICA_BOLD, fontSize)
                cs.setNonStrokingColor(PDColor(floatArrayOf(r, g, b), PDDeviceRGB.INSTANCE))
                cs.newLineAtOffset(x, y)
                cs.showText(text)
                cs.endText()
                cs.close()

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("TEXT_ERROR", e.message, null)
            }
        }.start()
    }

    private fun addImage(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        val imagePath = call.argument<String>("imagePath") ?: return result.error("INVALID_ARGS", "imagePath required", null)
        val x = (call.argument<Double>("x") ?: 50.0).toFloat()
        val y = (call.argument<Double>("y") ?: 50.0).toFloat()
        val width = (call.argument<Double>("width") ?: 150.0).toFloat()
        val height = (call.argument<Double>("height") ?: 50.0).toFloat()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                if (pageIndex < 0 || pageIndex >= doc.numberOfPages) {
                    doc.close()
                    result.error("INVALID_PAGE", "Page $pageIndex out of range", null)
                    return@Thread
                }
                val page = doc.getPage(pageIndex)
                val imgFile = File(imagePath)
                if (imgFile.exists()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        val pdImage = LosslessFactory.createFromImage(doc, bitmap)
                        val cs = PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true)
                        cs.drawImage(pdImage, x, y, width, height)
                        cs.close()
                        bitmap.recycle()
                    }
                }

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("IMAGE_ERROR", e.message, null)
            }
        }.start()
    }

    private fun rotatePage(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        val degrees = call.argument<Int>("degrees") ?: 90
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                if (pageIndex < 0 || pageIndex >= doc.numberOfPages) {
                    doc.close()
                    result.error("INVALID_PAGE", "Page $pageIndex out of range", null)
                    return@Thread
                }
                val page = doc.getPage(pageIndex)
                page.rotation = (page.rotation + degrees) % 360

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("ROTATE_ERROR", e.message, null)
            }
        }.start()
    }

    private fun deletePages(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        @Suppress("UNCHECKED_CAST")
        val pageIndices = (call.argument<List<Int>>("pageIndices") ?: listOf()).sortedDescending()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                for (p in pageIndices) {
                    if (p >= 0 && p < doc.numberOfPages && doc.numberOfPages > 1) {
                        doc.removePage(p)
                    }
                }

                doc.save(File(outputPath))
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("DELETE_PAGES_ERROR", e.message, null)
            }
        }.start()
    }

    private fun reorderPages(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        @Suppress("UNCHECKED_CAST")
        val newOrder = call.argument<List<Int>>("newOrder") ?: listOf()
        val outputPath = call.argument<String>("outputPath") ?: filePath

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                val newDoc = PDDocument()
                for (idx in newOrder) {
                    if (idx >= 0 && idx < doc.numberOfPages) {
                        newDoc.addPage(doc.getPage(idx))
                    }
                }

                newDoc.save(File(outputPath))
                newDoc.close()
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("REORDER_ERROR", e.message, null)
            }
        }.start()
    }

    private fun mergePdfs(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val filePaths = call.argument<List<String>>("filePaths") ?: listOf()
        val outputPath = call.argument<String>("outputPath") ?: return result.error("INVALID_ARGS", "outputPath required", null)

        Thread {
            try {
                val mergedDoc = PDDocument()
                val loadedDocs = mutableListOf<PDDocument>()
                for (p in filePaths) {
                    val f = File(p)
                    if (f.exists()) {
                        val d = PDDocument.load(f)
                        loadedDocs.add(d)
                        for (i in 0 until d.numberOfPages) {
                            mergedDoc.addPage(d.getPage(i))
                        }
                    }
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                mergedDoc.save(outFile)
                mergedDoc.close()
                for (d in loadedDocs) {
                    d.close()
                }
                result.success(true)
            } catch (e: Exception) {
                result.error("MERGE_ERROR", e.message, null)
            }
        }.start()
    }

    private fun splitPdf(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_ARGS", "filePath required", null)
        val startPage = call.argument<Int>("startPage") ?: 0
        val endPage = call.argument<Int>("endPage") ?: 0
        val outputPath = call.argument<String>("outputPath") ?: return result.error("INVALID_ARGS", "outputPath required", null)

        Thread {
            try {
                val doc = PDDocument.load(File(filePath))
                val splitDoc = PDDocument()
                val lastPage = endPage.coerceAtMost(doc.numberOfPages - 1)
                for (i in startPage..lastPage) {
                    if (i >= 0 && i < doc.numberOfPages) {
                        splitDoc.addPage(doc.getPage(i))
                    }
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                splitDoc.save(outFile)
                splitDoc.close()
                doc.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("SPLIT_ERROR", e.message, null)
            }
        }.start()
    }
}


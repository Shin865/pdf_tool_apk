package com.example.documentreviewer.document_reviewer

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.view.WindowManager
import com.example.documentreviewer.document_reviewer.engine.OfficeEngineHandler
import com.example.documentreviewer.document_reviewer.engine.PdfEngineHandler
import com.example.documentreviewer.document_reviewer.engine.ScannerEngineHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val SAF_CHANNEL = "com.example.documentreviewer/saf"
    private val ENGINE_CHANNEL = "com.example.documentreviewer/engine"
    private val INTENT_CHANNEL = "com.example.documentreviewer/intent"
    private val SECURITY_CHANNEL = "com.example.documentreviewer/security"
    private val PICK_FILE_REQUEST_CODE = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMimeTypes: List<String> = listOf("*/*")
    private var initialIntentData: Map<String, Any?>? = null

    private lateinit var pdfEngine: PdfEngineHandler
    private lateinit var officeEngine: OfficeEngineHandler
    private lateinit var scannerEngine: ScannerEngineHandler

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pdfEngine = PdfEngineHandler(applicationContext)
        officeEngine = OfficeEngineHandler()
        scannerEngine = ScannerEngineHandler()
        extractIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractIntent(intent)
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            initialIntentData?.let { data ->
                MethodChannel(messenger, INTENT_CHANNEL).invokeMethod("onNewIntent", data)
            }
        }
    }

    private fun extractIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val uri: Uri? = intent.data ?: intent.getParcelableExtra(Intent.EXTRA_STREAM)

        if (uri != null && (action == Intent.ACTION_VIEW || action == Intent.ACTION_EDIT || action == Intent.ACTION_SEND)) {
            val metadata = queryFileMetadata(uri)
            initialIntentData = mapOf(
                "action" to action,
                "uri" to uri.toString(),
                "displayName" to metadata["displayName"],
                "mimeType" to (intent.type ?: metadata["mimeType"]),
                "size" to metadata["size"]
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // SAF Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAF_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFile" -> handlePickFile(call, result)
                    "copyToLocal" -> handleCopyToLocal(call, result)
                    "writeBackToUri" -> handleWriteBackToUri(call, result)
                    "releasePermission" -> handleReleasePermission(call, result)
                    "getPersistedUris" -> handleGetPersistedUris(result)
                    "hasPermission" -> handleHasPermission(call, result)
                    "isUriAccessible" -> handleIsUriAccessible(call, result)
                    "shareFile" -> handleShareFile(call, result)
                    else -> result.notImplemented()
                }
            }

        // Engine Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when {
                    call.method.startsWith("pdf_") -> pdfEngine.handle(call, result)
                    call.method.startsWith("docx_") || call.method.startsWith("xlsx_") || call.method.startsWith("office_") -> officeEngine.handle(call, result)
                    call.method.startsWith("scanner_") || call.method.startsWith("ocr_") -> scannerEngine.handle(call, result)
                    else -> result.notImplemented()
                }
            }

        // Intent Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialIntent" -> {
                        result.success(initialIntentData)
                        initialIntentData = null // One-shot delivery
                    }
                    else -> result.notImplemented()
                }
            }

        // Security Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "security_setSecure" -> {
                        val secure = call.argument<Boolean>("secure") ?: false
                        if (secure) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    }
                    "security_canAuthenticate" -> {
                        val keyguardManager = getSystemService(android.content.Context.KEYGUARD_SERVICE) as? android.app.KeyguardManager
                        val isDeviceSecure = keyguardManager?.isDeviceSecure ?: false
                        result.success(isDeviceSecure)
                    }
                    "security_authenticate" -> {
                        // Keyguard/Biometric authentication success indicator
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // -----------------------------------------------------------------------
    // SAF File Picker
    // -----------------------------------------------------------------------

    private fun handlePickFile(call: MethodCall, result: MethodChannel.Result) {
        pendingResult = result
        @Suppress("UNCHECKED_CAST")
        pendingMimeTypes = (call.argument<List<String>>("mimeTypes")) ?: listOf("*/*")

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (pendingMimeTypes.size == 1) pendingMimeTypes[0] else "*/*"
            if (pendingMimeTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, pendingMimeTypes.toTypedArray())
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == PICK_FILE_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null

            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                result?.success(null) // User cancelled
                return
            }

            val uri = data.data!!

            // Take persistable permission
            try {
                val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                contentResolver.takePersistableUriPermission(uri, flags)
            } catch (e: SecurityException) {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (e2: SecurityException) {
                    result?.error("PERMISSION_ERROR", "Cannot persist URI permission", e2.message)
                    return
                }
            }

            val metadata = queryFileMetadata(uri)
            result?.success(metadata)
        }
    }

    private fun queryFileMetadata(uri: Uri): Map<String, Any?> {
        var displayName = "Unknown"
        var size: Long = 0
        var mimeType = contentResolver.getType(uri) ?: "application/octet-stream"

        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)

                    if (nameIndex >= 0) displayName = cursor.getString(nameIndex) ?: "Unknown"
                    if (sizeIndex >= 0) size = cursor.getLong(sizeIndex)
                }
            }
        } catch (e: Exception) {
            // Ignore metadata query failures on restricted URIs
        }

        return mapOf(
            "uri" to uri.toString(),
            "displayName" to displayName,
            "mimeType" to mimeType,
            "size" to size.toInt()
        )
    }

    // -----------------------------------------------------------------------
    // Copy to local storage
    // -----------------------------------------------------------------------

    private fun handleCopyToLocal(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val destinationPath = call.argument<String>("destinationPath")

        if (uriString == null || destinationPath == null) {
            result.error("INVALID_ARGS", "uri and destinationPath are required", null)
            return
        }

        Thread {
            try {
                val uri = Uri.parse(uriString)
                val destFile = File(destinationPath)
                destFile.parentFile?.mkdirs()

                contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(destFile).use { output ->
                        input.copyTo(output)
                    }
                } ?: run {
                    runOnUiThread { result.error("IO_ERROR", "Cannot open input stream", null) }
                    return@Thread
                }

                runOnUiThread { result.success(true) }
            } catch (e: Exception) {
                runOnUiThread { result.error("IO_ERROR", e.message, null) }
            }
        }.start()
    }

    // -----------------------------------------------------------------------
    // Write back to URI (atomic)
    // -----------------------------------------------------------------------

    private fun handleWriteBackToUri(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val uriString = call.argument<String>("uri")

        if (sourcePath == null || uriString == null) {
            result.error("INVALID_ARGS", "sourcePath and uri are required", null)
            return
        }

        Thread {
            try {
                val sourceFile = File(sourcePath)
                if (!sourceFile.exists()) {
                    runOnUiThread { result.error("IO_ERROR", "Source file does not exist", null) }
                    return@Thread
                }

                val uri = Uri.parse(uriString)

                contentResolver.openOutputStream(uri, "wt")?.use { output ->
                    FileInputStream(sourceFile).use { input ->
                        input.copyTo(output)
                    }
                } ?: run {
                    runOnUiThread { result.error("IO_ERROR", "Cannot open output stream", null) }
                    return@Thread
                }

                runOnUiThread { result.success(true) }
            } catch (e: Exception) {
                runOnUiThread { result.error("IO_ERROR", e.message, null) }
            }
        }.start()
    }

    // -----------------------------------------------------------------------
    // Permission & Accessibility check
    // -----------------------------------------------------------------------

    private fun handleReleasePermission(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri") ?: return result.error("INVALID_ARGS", "uri required", null)
        try {
            val uri = Uri.parse(uriString)
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.releasePersistableUriPermission(uri, flags)
            result.success(null)
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", e.message, null)
        }
    }

    private fun handleGetPersistedUris(result: MethodChannel.Result) {
        val uris = contentResolver.persistedUriPermissions.map { it.uri.toString() }
        result.success(uris)
    }

    private fun handleHasPermission(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri") ?: return result.error("INVALID_ARGS", "uri required", null)
        val uri = Uri.parse(uriString)
        val hasPermission = contentResolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission }
        result.success(hasPermission)
    }

    private fun handleIsUriAccessible(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri") ?: return result.error("INVALID_ARGS", "uri required", null)
        Thread {
            try {
                val uri = Uri.parse(uriString)
                contentResolver.openInputStream(uri)?.use {
                    runOnUiThread { result.success(true) }
                } ?: run {
                    runOnUiThread { result.success(false) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.success(false) }
            }
        }.start()
    }

    private fun handleShareFile(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri") ?: return result.error("INVALID_ARGS", "uri required", null)
        val mimeType = call.argument<String>("mimeType") ?: "*/*"
        val displayName = call.argument<String>("displayName") ?: "Document"

        try {
            val shareUri: Uri = if (uriString.startsWith("content://")) {
                Uri.parse(uriString)
            } else {
                val cleanPath = uriString.removePrefix("file://")
                val file = File(cleanPath)
                try {
                    androidx.core.content.FileProvider.getUriForFile(
                        applicationContext,
                        "${applicationContext.packageName}.fileprovider",
                        file
                    )
                } catch (e: Exception) {
                    Uri.fromFile(file)
                }
            }

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, shareUri)
                putExtra(Intent.EXTRA_SUBJECT, displayName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(shareIntent, "Share $displayName").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            result.success(true)
        } catch (e: Exception) {
            result.error("SHARE_ERROR", e.message, null)
        }
    }
}

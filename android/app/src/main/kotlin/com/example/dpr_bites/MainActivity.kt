package com.example.dpr_bites

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.net.Uri
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"dpr_bites/downloads"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"saveImageToDownloads" -> {
					val args = call.arguments as? Map<*, *>
					val bytes = args?.get("bytes") as? ByteArray
					val fileName = args?.get("fileName") as? String ?: "QRIS_Payment.jpg"
					val mimeType = args?.get("mimeType") as? String ?: "image/jpeg"
					if (bytes == null) {
						result.error("ARG_ERROR", "bytes is null", null)
						return@setMethodCallHandler
					}
					try {
						val uri = saveToDownloads(bytes, fileName, mimeType)
						result.success(uri)
					} catch (e: Exception) {
						result.error("SAVE_FAILED", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun saveToDownloads(bytes: ByteArray, fileName: String, mimeType: String): String {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val resolver = applicationContext.contentResolver
			val contentValues = ContentValues().apply {
				put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
				put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
				put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
				put(MediaStore.MediaColumns.IS_PENDING, 1)
			}
			val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
			val itemUri = resolver.insert(collection, contentValues)
				?: throw IOException("Failed to create MediaStore record")

			resolver.openOutputStream(itemUri)?.use { output ->
				output.write(bytes)
			} ?: throw IOException("Failed to open output stream")

			// Mark as complete
			contentValues.clear()
			contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
			resolver.update(itemUri, contentValues, null, null)

			itemUri.toString()
		} else {
			// Legacy path for < Android Q
			val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
			if (!dir.exists()) dir.mkdirs()
			var outFile = File(dir, fileName)
			val name = outFile.nameWithoutExtension
			val ext = if (outFile.extension.isNotEmpty()) "." + outFile.extension else ""
			var i = 1
			while (outFile.exists()) {
				outFile = File(dir, "${name}_$i$ext")
				i++
			}
			FileOutputStream(outFile).use { it.write(bytes) }
			// Trigger media scan so the file appears in file managers immediately
			try {
				val uri = Uri.fromFile(outFile)
				sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
			} catch (_: Exception) { }
			outFile.absolutePath
		}
	}
}

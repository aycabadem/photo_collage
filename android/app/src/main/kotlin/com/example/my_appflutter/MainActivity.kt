package com.example.my_appflutter

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.provider.MediaStore
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val galleryChannel = "collage/gallery"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, galleryChannel)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "openGallery" -> {
            try {
              openGallery()
              result.success(null)
            } catch (ex: ActivityNotFoundException) {
              result.error("OPEN_GALLERY_FAILED", "No gallery app available.", null)
            } catch (ex: Exception) {
              result.error("OPEN_GALLERY_FAILED", ex.message, null)
            }
          }
          else -> result.notImplemented()
        }
      }
  }

  private fun openGallery() {
    val intent = Intent(Intent.ACTION_MAIN).apply {
      addCategory(Intent.CATEGORY_APP_GALLERY)
      addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
    try {
      startActivity(intent)
    } catch (ex: ActivityNotFoundException) {
      val fallback = Intent(Intent.ACTION_VIEW).apply {
        setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*")
        addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      }
      startActivity(fallback)
    }
  }
}

//
//  NativeTextViewPlugin.kt
//  flutter_native_text_view
//
//  Created by Ioseph Magno on 12/09/2023.
//

package dev.henryleunghk.flutter_native_text_view

import android.app.Activity
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class `NativeTextViewPlugin`: FlutterPlugin/*, ActivityAware */{

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    binding
            .platformViewRegistry
            .registerViewFactory("flutter_native_text_view", NativeViewFactory(binding/*,activity*/))
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {}

}
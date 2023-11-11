//
//  NativeTextView.kt
//  flutter_native_text_view
//
//  Created by Ioseph Magno on 12/09/2023.
//

package dev.henryleunghk.flutter_native_text_view

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.text.TextWatcher
import android.util.Log
import android.util.TypedValue
import android.view.GestureDetector
import android.view.GestureDetector.SimpleOnGestureListener
import android.view.Gravity
import android.view.View
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import android.view.MotionEvent

val TAG: String = "NativeTextView"

internal class NativeTextView(
        context: Context,
        id: Int,
        creationParams: Map<String?, Any?>,
        channel: MethodChannel,
) : PlatformView, MethodChannel.MethodCallHandler  {

    private val context: Context
    private val minLines: Int
    private val maxLines: Int

    private val scaledDensity: Float

    private val textView: TextView

    override fun getView(): View {
        return textView
    }

    override fun dispose() {
    }

    init {
        this.context = context
        scaledDensity = context.resources.displayMetrics.scaledDensity

        textView = TextView(context)
        textView.setTextIsSelectable(true)

        //textView.setPadding(0, 0, 0, 4)
        //textView.gravity = Gravity.TOP

        //Set background color to transparent
        textView.setBackgroundColor(Color.argb(0,255, 255, 255))

        //textView.hint = creationParams["placeholder"] as String
        //textView.setText("")

        minLines = 0 as Int

        maxLines = creationParams["maxLines"] as Int
        //textView.setMaxLines(maxLines)
        Log.d(TAG, "maxLines:$maxLines")

        textView.text = creationParams["text"] as String

        // set lineHeight as a parameter of fontsize
        textView.setLineHeight(((textView.textSize) * 1.2).toInt())


        val gestureDetector = GestureDetector(context, object : SimpleOnGestureListener() {
            // fix to upgrade to compilesdk 33
            //   override fun onSingleTapUp(e: MotionEvent?): Boolean {
            override fun onSingleTapUp(e: MotionEvent): Boolean {

                if (!textView.hasFocus()) {
                    textView.requestFocus()
                }
                channel.invokeMethod("singleTapRecognized", null)
                Log.e(TAG, "onSingleTapUp: ")
                return super.onSingleTapUp(e)
            }
        })

        textView.setOnTouchListener { v, event ->
            gestureDetector.onTouchEvent(event)
        }

        /*
        textView.setOnTouchListener(View.OnTouchListener { view, motionEvent ->
            when (motionEvent.action){
                MotionEvent.ACTION_DOWN -> {
                    //code here
                    }
                }
                MotionEvent.ACTION_UP -> {
                    //code here
                }
            }
            view?.onTouchEvent(motionEvent) ?: true
        })
         */


        if (creationParams["fontColor"] != null) {
            val rgbMap = creationParams["fontColor"] as Map<String, Float>
            val color = Color.argb(
                    rgbMap["alpha"] as Int,
                    rgbMap["red"] as Int,
                    rgbMap["green"] as Int,
                    rgbMap["blue"] as Int
            )
            textView.setTextColor(color)
        }


        if (creationParams["fontSize"] != null) {
            val fontSize = creationParams["fontSize"] as Double
            //  Log.d(TAG, "fontSize:$fontSize")
            textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, fontSize.toFloat())
            textView.textSize = fontSize.toFloat()
        }

        if (creationParams["fontWeight"] != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            when (creationParams["fontWeight"] as String) {
                "FontWeight.w100" -> {
                    textView.typeface = Typeface.create(textView.typeface, 100, false)
                }
                "FontWeight.w200" -> {
                    textView.typeface = Typeface.create(textView.typeface, 200, false)
                }
                "FontWeight.w300" -> {
                    textView.typeface = Typeface.create(textView.typeface, 300, false)
                }
                "FontWeight.w400" -> {
                    textView.typeface = Typeface.create(textView.typeface, 400, false)
                }
                "FontWeight.w500" -> {
                    textView.typeface = Typeface.create(textView.typeface, 500, false)
                }
                "FontWeight.w600" -> {
                    textView.typeface = Typeface.create(textView.typeface, 600, false)
                }
                "FontWeight.w700" -> {
                    textView.typeface = Typeface.create(textView.typeface, 700, false)
                }
                "FontWeight.w800" -> {
                    textView.typeface = Typeface.create(textView.typeface, 800, false)
                }
                "FontWeight.w900" -> {
                    textView.typeface = Typeface.create(textView.typeface, 900, false)
                }
            }
        }

        if (creationParams["textAlign"] != null) {
            when (creationParams["textAlign"] as String) {
                "TextAlign.left" -> {
                    textView.gravity = Gravity.LEFT or Gravity.CENTER_VERTICAL
                }
                "TextAlign.right" -> {
                    textView.gravity = Gravity.RIGHT or Gravity.CENTER_VERTICAL
                }
                "TextAlign.center" -> {
                    textView.gravity = Gravity.CENTER
                }
                "TextAlign.justify" -> {
                    textView.gravity = Gravity.FILL or Gravity.CENTER_VERTICAL
                }
                "TextAlign.start" -> {
                    textView.gravity = Gravity.START or Gravity.CENTER_VERTICAL
                }
                "TextAlign.end" -> {
                    textView.gravity = Gravity.END or Gravity.CENTER_VERTICAL
                }
            }
        }


        //val width = creationParams["width"] as Double
        // textView.maxWidth = width.toInt()


        channel.setMethodCallHandler(this)
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {

            //Calculate _contentHeight passed to dart code. This makes textfield height to increase when user adds new lines
            "getContentHeight" -> {
                //Log.d(TAG, "lineCount:" + textView.lineCount)
                //Log.d(TAG, "lineHeight:" + textView.lineHeight)
                //Log.d(TAG, "scaledDensity:" + scaledDensity)
                //Log.d(TAG, "minLines:" + minLines)

                val multiplier = 0.16 //0.16

                var contentHeight = ((textView.lineHeight.toDouble() / scaledDensity) * textView.lineCount
                        + (textView.lineCount * (textView.lineHeight) / scaledDensity * multiplier)).toDouble()

                //Log.d(TAG, "contentHeight:" + contentHeight)
                result.success(contentHeight.toDouble())

            }
            // Calculate _lineHeight passed for dart code
            "getLineHeight" -> {
                val lineHeight = textView.lineHeight / scaledDensity
                //Log.d(TAG, "getLineHeight:$lineHeight")
                result.success(lineHeight.toDouble())
            }

            //Add currentLineCount
            "currentLineCount" -> {
                val currentLines = textView.lineCount
                //    Log.d(TAG, "currentLines:$currentLines")
                result.success(textView.lineCount.toInt())
            }
            // Show LightTheme Placeholder
            "showPlaceholderLightTheme" -> {
                // val rgbMap = creationParams["placeholderFontColor"] as Map<String, Float>
                val color = Color.argb(255 as Int, 175 as Int, 175 as Int, 175 as Int)
                textView.setHintTextColor(color)
            }
            // Show NightTheme Placeholder
            "showPlaceholderNightTheme" -> {
                // val rgbMap = creationParams["placeholderFontColor"] as Map<String, Float>
                val color = Color.argb(230 as Int, 255 as Int, 255 as Int, 255 as Int)
                textView.setHintTextColor(color)
            }

            "setText" -> {
                val text = call.argument<String>("text")
                textView.text = text
            }
        }
    }
}
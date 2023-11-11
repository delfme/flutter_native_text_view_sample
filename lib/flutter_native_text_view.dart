import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeTextView extends StatefulWidget {
  final String text;
  final BoxDecoration? decoration;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final int minLines;

  /// Called when the widget is disposed
  ///
  /// Default: null
  final VoidCallback? onDispose;

  const NativeTextView(
      this.text, {
        Key? key,
        this.decoration,
        this.style,
        this.textAlign = TextAlign.start,
        this.minLines = 1,
        this.maxLines = 0,
        this.onDispose,
      }) : super(key: key);

  static const viewType = 'flutter_native_text_view';

  @override
  NativeTextViewState createState() => NativeTextViewState();

  // Expose text
  static String? getText() {
    return NativeTextViewState.text;
  }

}

class NativeTextViewState extends State<NativeTextView> {
  late MethodChannel _channel;

  double _lineHeight = 22.0;
  double _contentHeight = 0.0;
  static int currentLineCount = 1;
  static String text = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //Inform that the textfield got disposed
    widget.onDispose?.call();
    super.dispose();
  }

  void _createMethodChannel(int nativeViewId) {
    _channel = MethodChannel("flutter_native_text_view$nativeViewId")
      ..setMethodCallHandler(_onMethodCall);
    _channel.invokeMethod("getLineHeight").then((value) {
      if (value != null) {
        _lineHeight = value;
        setState(() {});
      }
    });

    // delay 150ms to give time to native side to return a
    // correct value for linesCount
    Future.delayed(const Duration(milliseconds: 120), () {
      _channel.invokeMethod("currentLineCount").then((value) {
        final intValue = value.ceil();
        if (intValue != null) {
          setState(() {
            currentLineCount = intValue;
          });
          _minHeight();
          _maxHeight();
        }
        //debugPrint('currentLines ${intValue}');
      });
    });

    _channel.invokeMethod("getContentHeight").then((value) {
      if (value != null) {
        _contentHeight = value;
        setState(() {});
      }
    });

  }

  Future<bool?> _onMethodCall(MethodCall call) async {

    throw MissingPluginException(
        "NativeTextView._onMethodCall: No handler for ${call.method}");
  }

  double _minHeight() {
      return currentLineCount * _lineHeight + 14;

  }

  double _maxHeight() {
    if (widget.maxLines > 0) return widget.maxLines * _lineHeight + 6;
    if ( _contentHeight > _minHeight()) {
      return _contentHeight;
    }

    return _minHeight();
  }

  Map<String, dynamic> _buildCreationParams(BoxConstraints constraints) {
    // Set text to state property in order to
    // expose it via getText()
    text = widget.text;

    Map<String, dynamic> params = {
      "width": constraints.maxWidth,
      "text": widget.text,
      "textAlign": widget.textAlign.toString(),
      "maxLines": widget.maxLines,
    };

    if (widget.style != null && widget.style?.fontSize != null) {
      params = {
        ...params,
        "fontSize": widget.style?.fontSize,
      };
    }

    if (widget.style != null && widget.style?.fontWeight != null) {
      params = {
        ...params,
        "fontWeight": widget.style?.fontWeight.toString(),
      };
    }

    if (widget.style != null && widget.style?.color != null) {
      params = {
        ...params,
        "fontColor": {
          "red": widget.style?.color?.red,
          "green": widget.style?.color?.green,
          "blue": widget.style?.color?.blue,
          "alpha": widget.style?.color?.alpha,
        }
      };
    }

    return params;
  }

  Widget _platformView(BoxConstraints layout) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: NativeTextView.viewType,
          surfaceFactory: (context, controller) => AndroidViewSurface(
            controller: controller as AndroidViewController,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          ),
          onCreatePlatformView: (PlatformViewCreationParams params) {
            // Note: use initExpensiveAndroidView (hybrid composition)
            // otherwise magnifying lens wont be visible during text
            // selection
            return PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: NativeTextView.viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: _buildCreationParams(layout),
              creationParamsCodec: const StandardMessageCodec(),
            )
              ..addOnPlatformViewCreatedListener((_) {
                params.onPlatformViewCreated(_);
                _createMethodChannel(_);
              })
              ..create();
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: NativeTextView.viewType,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: _buildCreationParams(layout),
          onPlatformViewCreated: _createMethodChannel,
        );
      default:
        return UiKitView(
          viewType: NativeTextView.viewType,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: _buildCreationParams(layout),
          onPlatformViewCreated: _createMethodChannel,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: _minHeight(),
        maxHeight: _maxHeight(),
      ),
      child: LayoutBuilder(
        builder: (context, layout) => Container(
            decoration: widget.decoration,
            child: _platformView(layout)
        ),
      ),
    );
  }
}



import 'dart:developer' as developer;
import 'dart:ui' as ui show Image;

import '../flutter.dart';

@immutable
class DecorationImagePlus implements DecorationImage {
  final int puzzleWidth, puzzleHeight, pieceIndex;


  const DecorationImagePlus({
    @required this.image,
    @required this.puzzleWidth,
    @required this.puzzleHeight,
    @required this.pieceIndex,
    this.colorFilter,
    this.fit,
    this.alignment = Alignment.center,
    this.centerSlice,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  })  : assert(image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        assert(puzzleHeight > 1 &&
            puzzleHeight > 1 &&
            pieceIndex >= 0 &&
            pieceIndex < (puzzleHeight * puzzleWidth));


  final ImageProvider image;

  final ColorFilter colorFilter;



  final BoxFit fit;

  
  final AlignmentGeometry alignment;

  
  final Rect centerSlice;

 
  final ImageRepeat repeat;

 
  final bool matchTextDirection;

  final double scale = 1.0;

  
  DecorationImagePainterPlus createPainter(VoidCallback onChanged) {
    assert(onChanged != null);
    return DecorationImagePainterPlus._(this, onChanged);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    return other is DecorationImagePlus &&
        other.runtimeType == runtimeType &&
        image == other.image &&
        colorFilter == other.colorFilter &&
        fit == other.fit &&
        alignment == other.alignment &&
        centerSlice == other.centerSlice &&
        repeat == other.repeat &&
        matchTextDirection == other.matchTextDirection;
  }

  @override
  int get hashCode => hashValues(image, colorFilter, fit, alignment,
      centerSlice, repeat, matchTextDirection);

  @override
  String toString() {
    final List<String> properties = <String>[];
    properties.add('$image');
    if (colorFilter != null) properties.add('$colorFilter');
    if (fit != null &&
        !(fit == BoxFit.fill && centerSlice != null) &&
        !(fit == BoxFit.scaleDown && centerSlice == null)) {
      properties.add('$fit');
    }
    properties.add('$alignment');
    if (centerSlice != null) properties.add('centerSlice: $centerSlice');
    if (repeat != ImageRepeat.noRepeat) properties.add('$repeat');
    if (matchTextDirection) properties.add('match text direction');
    return '$runtimeType(${properties.join(", ")})';
  }

  @override
  ImageErrorListener get onError => (error, stackTrace) {
        developer.log(
            'Failed to load image.\n'
            '$error\n'
            '$stackTrace',
            name: 'slide_puzzle.decoration_image_plus');
      };
}


class DecorationImagePainterPlus implements DecorationImagePainter {
  DecorationImagePainterPlus._(this._details, this._onChanged)
      : assert(_details != null);

  final DecorationImagePlus _details;
  final VoidCallback _onChanged;

  ImageStream _imageStream;
  ImageInfo _image;

 
  void paint(Canvas canvas, Rect rect, Path clipPath,
      ImageConfiguration configuration) {
    assert(canvas != null);
    assert(rect != null);
    assert(configuration != null);

    if (_details.matchTextDirection) {
      assert(() {
        // We check this first so that the assert will fire immediately, not just
        // when the image is ready.
        if (configuration.textDirection == null) {
          throw FlutterError(
              'ImageDecoration.matchTextDirection can only be used when a TextDirection is available.\n'
              'When DecorationImagePainter.paint() was called, there was no text direction provided '
              'in the ImageConfiguration object to match.\n'
              'The DecorationImage was:\n'
              '  $_details\n'
              'The ImageConfiguration was:\n'
              '  $configuration');
        }
        return true;
      }());
    }

    final ImageStream newImageStream = _details.image.resolve(configuration);
    if (newImageStream.key != _imageStream?.key) {
      final listener = ImageStreamListener(_imageListener);
      _imageStream?.removeListener(listener);
      _imageStream = newImageStream;
      _imageStream.addListener(listener);
    }
    if (_image == null) return;

    if (clipPath != null) {
      canvas.save();
      canvas.clipPath(clipPath);
    }

    _paintImage(
      canvas: canvas,
      puzzleWidth: _details.puzzleWidth,
      puzzleHeight: _details.puzzleHeight,
      pieceIndex: _details.pieceIndex,
      rect: rect,
      image: _image.image,
      scale: _image.scale,
      colorFilter: _details.colorFilter,
      fit: _details.fit,
      alignment: _details.alignment.resolve(configuration.textDirection),
    );

    if (clipPath != null) canvas.restore();
  }

  void _imageListener(ImageInfo value, bool synchronousCall) {
    if (_image == value) return;
    _image = value;
    assert(_onChanged != null);
    if (!synchronousCall) _onChanged();
  }

  
  @mustCallSuper
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_imageListener));
  }

  @override
  String toString() {
    return '$runtimeType(stream: $_imageStream, image: $_image) for $_details';
  }
}

void _paintImage(
    {@required Canvas canvas,
    @required Rect rect,
    @required ui.Image image,
    @required int puzzleWidth,
    @required int puzzleHeight,
    @required int pieceIndex,
    double scale = 1.0,
    ColorFilter colorFilter,
    BoxFit fit,
    Alignment alignment = Alignment.center}) {
  assert(canvas != null);
  assert(image != null);
  assert(alignment != null);

  if (rect.isEmpty) return;
  final outputSize = rect.size;
  final inputSize = Size(image.width.toDouble(), image.height.toDouble());
  fit ??= BoxFit.scaleDown;
  final FittedSizes fittedSizes =
      applyBoxFit(fit, inputSize / scale, outputSize);
  final Size sourceSize = fittedSizes.source * scale;
  final destinationSize = fittedSizes.destination;
  final Paint paint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.medium;
  if (colorFilter != null) paint.colorFilter = colorFilter;
  final double halfWidthDelta =
      (outputSize.width - destinationSize.width) / 2.0;
  final double halfHeightDelta =
      (outputSize.height - destinationSize.height) / 2.0;
  final double dx = halfWidthDelta + (alignment.x) * halfWidthDelta;
  final double dy = halfHeightDelta + alignment.y * halfHeightDelta;
  final Offset destinationPosition = rect.topLeft.translate(dx, dy);
  final Rect destinationRect = destinationPosition & destinationSize;
  final Rect sourceRect =
      alignment.inscribe(sourceSize, Offset.zero & inputSize);

  final sliceSize =
      Size(sourceRect.width / puzzleWidth, sourceRect.height / puzzleHeight);

  final col = pieceIndex % puzzleWidth;
  final row = pieceIndex ~/ puzzleWidth;

  final sliceRect = Rect.fromLTWH(
      sourceRect.left + col * sliceSize.width,
      sourceRect.top + row * sliceSize.height,
      sliceSize.width,
      sliceSize.height);

  canvas.drawImageRect(image, sliceRect, destinationRect, paint);
}

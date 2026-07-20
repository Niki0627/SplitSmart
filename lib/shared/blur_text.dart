// lib/shared/blur_text.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class BlurTextSegment {
  final String text;
  final TextStyle style;
  BlurTextSegment(this.text, this.style);
}

class BlurText extends StatefulWidget {
  final String text;
  final String animateBy; // 'words' or 'letters'
  final String direction; // 'top' or 'bottom'
  final int delay; // Delay between elements in ms
  final double stepDuration; // Duration of single segment animation in seconds
  final VoidCallback? onAnimationComplete;
  final TextStyle? style;
  final List<TextSpan>? customSpans;

  const BlurText({
    super.key,
    required this.text,
    this.animateBy = 'words',
    this.direction = 'top',
    this.delay = 200,
    this.stepDuration = 0.35,
    this.onAnimationComplete,
    this.style,
    this.customSpans,
  });

  @override
  State<BlurText> createState() => _BlurTextState();
}

class _BlurTextState extends State<BlurText> {
  int _completedCount = 0;

  @override
  Widget build(BuildContext context) {
    final List<BlurTextSegment> segments = [];
    if (widget.customSpans != null) {
      for (final span in widget.customSpans!) {
        final text = span.text ?? '';
        final style = span.style ?? widget.style ?? const TextStyle();
        if (widget.animateBy == 'words') {
          final words = text.split(' ');
          for (final w in words) {
            if (w.isNotEmpty) segments.add(BlurTextSegment(w, style));
          }
        } else {
          final chars = text.split('');
          for (final c in chars) {
            segments.add(BlurTextSegment(c, style));
          }
        }
      }
    } else {
      final style = widget.style ?? const TextStyle();
      if (widget.animateBy == 'words') {
        final words = widget.text.split(' ');
        for (final w in words) {
          segments.add(BlurTextSegment(w, style));
        }
      } else {
        final chars = widget.text.split('');
        for (final c in chars) {
          segments.add(BlurTextSegment(c, style));
        }
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(segments.length, (index) {
        final seg = segments[index];
        final delay = index * widget.delay;
        
        Widget cell = _BlurTextSegmentWidget(
          text: seg.text,
          style: seg.style,
          delayMs: delay,
          durationSeconds: widget.stepDuration,
          direction: widget.direction,
          onComplete: () {
            _completedCount++;
            if (_completedCount == segments.length) {
              widget.onAnimationComplete?.call();
            }
          },
        );

        if (widget.animateBy == 'words' && index < segments.length - 1) {
          cell = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              cell,
              const SizedBox(width: 6),
            ],
          );
        }

        return cell;
      }),
    );
  }
}

class _BlurTextSegmentWidget extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int delayMs;
  final double durationSeconds;
  final String direction;
  final VoidCallback? onComplete;

  const _BlurTextSegmentWidget({
    required this.text,
    required this.style,
    required this.delayMs,
    required this.durationSeconds,
    required this.direction,
    this.onComplete,
  });

  @override
  State<_BlurTextSegmentWidget> createState() => _BlurTextSegmentWidgetState();
}

class _BlurTextSegmentWidgetState extends State<_BlurTextSegmentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _yOffset;
  late Animation<double> _blur;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.durationSeconds * 1000).round()),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    final double startY = widget.direction == 'top' ? -50.0 : 50.0;
    _yOffset = Tween<double>(begin: startY, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _blur = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _timer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() {
          _started = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Opacity(
        opacity: 0.0,
        child: Text(widget.text, style: widget.style),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget textWidget = Text(widget.text, style: widget.style);
        
        if (_blur.value > 0.1) {
          textWidget = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: _blur.value, sigmaY: _blur.value),
            child: textWidget,
          );
        }

        textWidget = Transform.translate(
          offset: Offset(0, _yOffset.value),
          child: textWidget,
        );

        return Opacity(
          opacity: _opacity.value,
          child: textWidget,
        );
      },
    );
  }
}

/*
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/tarot_card.dart';
import '../services/tarot_service.dart';

class TarotCardWidget extends StatefulWidget {
  final TarotCard card;
  final double rotationValue;
  final bool isReversed;
  final bool allowReversed;
  final bool allowOnTap;
  final bool allowTilt;

  const TarotCardWidget({
    super.key,
    required this.card,
    required this.rotationValue,
    this.isReversed = false,
    this.allowOnTap = true,
    this.allowReversed = true,
    this.allowTilt = true,
  });

  @override
  State<TarotCardWidget> createState() => _TarotCardWidgetState();
}

class _TarotCardWidgetState extends State<TarotCardWidget> with SingleTickerProviderStateMixin {
  // 定义的变量区
  late AnimationController _flipController;
  late AnimationController _tiltController;

  double _rawTiltX = 0.0; // 目标 X 轴旋转 (上下)
  double _rawTiltY = 0.0; // 目标 Y 轴旋转 (左右)
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 翻转动画：0.0 为背面，1.0 为正面
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isFaceUp ? 1.0 : 0.0,
    );

    // 处理进入和退出的平滑权重
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  // 处理点击翻转逻辑
  void _handleTap() {
    if (!widget.animateOnTap || _flipController.isAnimating) return;

    HapticFeedback.mediumImpact();
    if (_flipController.value > 0.5) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }
  void _onPanDown(DragDownDetails details) {
    if (!widget.allowTilt) return;
    _updateTiltValues(details.localPosition);
    _tiltController.forward();
    setState(() => _isPressed = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.allowTilt) return;
    _updateTiltValues(details.localPosition);
  }

  void _updateTiltValues(Offset localPosition) {
    setState(() {
      // 这里的 102 和 180 对应卡牌宽高的一半
      double dx = (localPosition.dx - 102) / 102;
      double dy = (localPosition.dy - 180) / 180;
      _rawTiltX = dy.clamp(-1.2, 1.2) * 0.22;
      _rawTiltY = -dx.clamp(-1.2, 1.2) * 0.22;
    });
  }

  void _deactivate() {
    if (!_isPressed) return;
    _tiltController.reverse().then((_) {
      if (mounted && !_isPressed) {
        setState(() { _rawTiltX = 0.0; _rawTiltY = 0.0; });
      }
    });
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _deactivate(),
      onPanCancel: () => _deactivate(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _tiltController]),
        builder: (context, child) {
          // 计算当前的翻转角度：从 0 到 -pi
          double rotationValue = _flipController.value * -pi;
          double absAngle = rotationValue.abs() % (2 * pi);
          bool showFront = absAngle > pi / 2 && absAngle < 1.5 * pi;

          double targetZRotation = (widget.isReversed && widget.allowReversed) ? pi : 0;

          return TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(begin: Offset.zero, end: Offset(_rawTiltX, _rawTiltY)),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            builder: (context, smoothedTilt, child) {
              double finalTiltX = smoothedTilt.dx * _tiltController.value;
              double finalTiltY = smoothedTilt.dy * _tiltController.value;
              // 翻转过程中产生轻微放大感
              double flipScale = 1.0 + (sin(_flipController.value * pi).abs() * 0.1);
              // 按下时的缩放
              double pressScale = 1.0 + (0.05 * _tiltController.value);
              double finalScale = flipScale * pressScale;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: targetZRotation),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutBack,
                builder: (context, zRotation, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008) // 透视感
                      ..rotateX(finalTiltX)
                      ..rotateY(finalTiltY + rotationValue)
                      ..rotateZ(zRotation)
                      ..scale(finalScale),
                    child: _buildCardContent(showFront),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  /*
  // 手势处理逻辑
  // 触碰瞬间即刻计算，消除第一帧跳跃
  void _onPanDown(DragDownDetails details) {
    if (!widget.allowTilt) return;
    HapticFeedback.selectionClick();

    _updateTiltValues(details.localPosition); // 立即计算初始角度
    _tiltController.forward();
    setState(() => _isPressed = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.allowTilt) return;
    _updateTiltValues(details.localPosition);
  }

  // 提取通用的坐标计算逻辑
  void _updateTiltValues(Offset localPosition) {
    setState(() {
      double dx = (localPosition.dx - 102) / 102;
      double dy = (localPosition.dy - 180) / 180;
      // 保持你认可的方向逻辑
      _rawTiltX = dy.clamp(-1.2, 1.2) * 0.22;
      _rawTiltY = -dx.clamp(-1.2, 1.2) * 0.22;
    });
  }

  void _deactivate() {
    if (!_isPressed) return;
    _tiltController.reverse().then((_) {
      if (mounted && !_isPressed) {
        setState(() {
          _rawTiltX = 0.0;
          _rawTiltY = 0.0;
        });
      }
    });
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    double absAngle = widget.rotationValue.abs() % (2 * pi);
    bool showFront = absAngle > pi / 2 && absAngle < 1.5 * pi;
    double targetZRotation = (widget.isReversed && widget.allowReversed)
        ? pi
        : 0;

    return GestureDetector(
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _deactivate(),
      onPanCancel: () => _deactivate(),
      child: AnimatedBuilder(
        animation: _tiltController,
        builder: (context, child) {
          // 使用 TweenAnimationBuilder 对倾斜角度进行二次平滑
          return TweenAnimationBuilder<Offset>(
            // 将当前的 X,Y 倾斜目标值封装成 Offset 传入
            tween: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(_rawTiltX, _rawTiltY)
            ),
            duration: const Duration(milliseconds: 150), // 极其短促的追赶动画
            curve: Curves.easeOutCubic, // 丝滑的减速曲线
            builder: (context, smoothedTilt, child) {
              // 最终旋转量 = 平滑后的目标值 * 缩放控制器的权重
              double finalTiltX = smoothedTilt.dx * _tiltController.value;
              double finalTiltY = smoothedTilt.dy * _tiltController.value;
              double currentScale = 1.0 + (0.05 * _tiltController.value);

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: targetZRotation),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutBack,
                builder: (context, zRotation, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008)
                      ..rotateX(finalTiltX)
                      ..rotateY(finalTiltY + widget.rotationValue)
                      ..rotateZ(zRotation)
                      ..scale(currentScale),
                    child: _buildCardContent(showFront),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
*/
  Widget _buildCardContent(bool showFront) {
    return !showFront
        ? _buildBack()
        : Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: _buildFront(),
    );
  }

  // 卡牌正面
  Widget _buildFront() {
    return _buildCardFrame(
      isFront: true,
      child: Padding(
        // 这里控制白色边框的等比例间距
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: Image.asset(
          widget.card.fullPath,
          fit: BoxFit.contain, // 确保图片在白框内等比例缩放
        ),
      ),
    );
  }

  // 卡牌背面
  Widget _buildBack() {
    return _buildCardFrame(
      isFront: false,
      child: Image.asset(
        TarotService.cardBackPath,
        fit: BoxFit.cover, // 卡背图案铺满
      ),
    );
  }

  // 卡牌外壳构造器
  Widget _buildCardFrame({required Widget child, bool isFront = false}) {
    return Container(
      width: 204, // 调宽后的比例
      height: 360,
      decoration: BoxDecoration(
        // 正面使用纯白底色形成边框，背面使用深色
        color: isFront ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(7),
        // 已移除 BoxShadow
        border: Border.all(
          color: Colors.black87.withValues(alpha: 0.6), // 边框
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        // 确保内部内容不超出边框
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }
}
*/
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/tarot_card.dart';
import '../services/tarot_service.dart';

class TarotCardWidget extends StatefulWidget {
  final TarotCard card;
  // 控制字段
  final bool isFaceUp;       // 翻转状态 (0=背面, 1=正面)
  final bool isReversed;     // 逆位状态 (0=正位, 1=逆位)
  final bool animateOnTap;   // 是否允许点击触发翻转
  final VoidCallback? onFlip; // 翻转回调

  final bool allowReversed;  // 是否允许显示逆位 (如果不允许，强制正位)
  final bool enableTilt;     // 是否开启3D倾斜

  const TarotCardWidget({
    super.key,
    required this.card,
    this.isFaceUp = false,
    this.isReversed = false,
    this.animateOnTap = true,
    this.onFlip,
    this.allowReversed = true,
    this.enableTilt = true,
  });

  @override
  State<TarotCardWidget> createState() => _TarotCardWidgetState();
}

class _TarotCardWidgetState extends State<TarotCardWidget> with TickerProviderStateMixin {
  // 翻面控制器 (Flip): Y轴旋转
  late AnimationController _flipController;

  // 逆位控制器 (Reverse): Z轴旋转 【新增】
  late AnimationController _reverseController;

  // 倾斜控制器 (Tilt): 按压与跟随
  late AnimationController _tiltController;

  double _rawTiltX = 0.0;
  double _rawTiltY = 0.0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 初始化翻面状态
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isFaceUp ? 1.0 : 0.0,
    );

    // 初始化逆位状态
    // 如果初始就是逆位，value 设为 1.0，否则 0.0
    _reverseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: (widget.isReversed && widget.allowReversed) ? 1.0 : 0.0,
    );

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  // 监听父组件的所有参数变化
  @override
  void didUpdateWidget(TarotCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听翻面变化
    if (widget.isFaceUp != oldWidget.isFaceUp) {
      widget.isFaceUp ? _flipController.forward() : _flipController.reverse();
    }

    // 监听逆位变化
    // 只要外部的 switch 开关一动，这里就会触发动画
    if (widget.isReversed != oldWidget.isReversed && widget.allowReversed) {
      if (widget.isReversed) {
        _reverseController.forward(); // 转到 180度
      } else {
        _reverseController.reverse(); // 转回 0度
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _reverseController.dispose(); // 记得销毁
    _tiltController.dispose();
    super.dispose();
  }

  // 点击逻辑
  void _handleTap() {
    if (!widget.animateOnTap || _flipController.isAnimating) return;

    HapticFeedback.mediumImpact();

    if (_flipController.value >= 0.5) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }

    if (widget.onFlip != null) widget.onFlip!();
  }

  // ... (PanDown, PanUpdate, Deactivate 逻辑保持不变) ...
  void _onPanDown(DragDownDetails details) {
    if (!widget.enableTilt) return;
    _updateTiltValues(details.localPosition);
    _tiltController.forward();
    setState(() => _isPressed = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableTilt) return;
    _updateTiltValues(details.localPosition);
  }

  void _updateTiltValues(Offset localPosition) {
    const double width = 204.0;
    const double height = 360.0;

    setState(() {
      double dx = (localPosition.dx - (width / 2)) / (width / 2);
      double dy = (localPosition.dy - (height / 2)) / (height / 2);

      _rawTiltX = dy.clamp(-1.2, 1.2) * 0.22;
      _rawTiltY = -dx.clamp(-1.2, 1.2) * 0.22;
    });
  }

  void _deactivate() {
    if (!_isPressed) return;
    _tiltController.reverse().then((_) {
      if (mounted && !_isPressed) {
        setState(() {
          _rawTiltX = 0.0;
          _rawTiltY = 0.0;
        });
      }
    });
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _deactivate(),
      onPanCancel: () => _deactivate(),
      child: AnimatedBuilder(
        // 合并监听三个控制器：翻面、逆位、倾斜
        animation: Listenable.merge([_flipController, _reverseController, _tiltController]),
        builder: (context, child) {
          // 计算翻转角度 (Y轴)
          double flipRotation = _flipController.value * pi;

          // 计算逆位角度 (Z轴)
          // 使用 Curve 曲线让旋转更丝滑
          double reverseVal = Curves.easeInOutBack.transform(_reverseController.value);
          double zRotation = reverseVal * pi;

          // 判断当前正反面
          bool showFront = _flipController.value >= 0.5;

          return TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(begin: Offset.zero, end: Offset(_rawTiltX, _rawTiltY)),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            builder: (context, smoothedTilt, child) {
              double finalTiltX = smoothedTilt.dx * _tiltController.value;
              double finalTiltY = smoothedTilt.dy * _tiltController.value;

              double flipScale = 1.0 + (sin(_flipController.value * pi).abs() * 0.1);
              double pressScale = 1.0 + (0.05 * _tiltController.value);
              double finalScale = flipScale * pressScale;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(finalTiltX)
                  ..rotateY(finalTiltY + flipRotation)
                  ..rotateZ(zRotation) // 这里直接应用控制器计算出的角度
                  ..scale(finalScale),
                child: _buildCardContent(showFront),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCardContent(bool showFront) {
    if (showFront) {
      // 正面：因为父级 Matrix4 已经翻转了180度，这里需要再翻转一次 Y 轴，
      // 否则图片和文字会是镜像的 (左右颠倒)
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: _buildFront(),
      );
    } else {
      // 背面
      return _buildBack();
    }
  }

  Widget _buildFront() {
    return _buildCardFrame(
      isFront: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: Image.asset(
          widget.card.fullPath, // 使用 Model 中的字段
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildBack() {
    return _buildCardFrame(
      isFront: false,
      child: Image.asset(
        TarotService.cardBackPath, // 确保这个路径在 Service 中定义正确
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCardFrame({required Widget child, bool isFront = false}) {
    return Container(
      width: 204,
      height: 360,
      decoration: BoxDecoration(
        color: isFront ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.black87.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: isFront ? [
          // 可以在这里加你喜欢的金色阴影，如果需要的话
          // BoxShadow(color: Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 10)
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }
}
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DiceRollScreen extends StatefulWidget {
  const DiceRollScreen({super.key});

  @override
  State<DiceRollScreen> createState() => _DiceRollScreenState();
}

class _DiceRollScreenState extends State<DiceRollScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotXAnimation;
  late Animation<double> _rotYAnimation;

  final double diceSize = 130.0;

  double _currentRotX = 0.0;
  double _currentRotY = 0.0;
  double _lastVibrateAngle = 0.0;

  // 摇一摇相关状态
  bool _isShakeEnabled = false;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotXAnimation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _rotYAnimation = Tween<double>(begin: 0, end: 0).animate(_controller);

    _controller.addListener(() {
      double currentAngleSum = _rotXAnimation.value.abs() + _rotYAnimation.value.abs();
      if ((currentAngleSum - _lastVibrateAngle).abs() > pi / 3) {
        HapticFeedback.selectionClick();
        _lastVibrateAngle = currentAngleSum;
      }
    });

    // 监听手机加速度传感器 (不包含重力)
    _accelerometerSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!_isShakeEnabled) return;

      // 计算三轴加速度向量的长度
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // 当摇晃力度超过阈值 (15.0) 时触发
      if (acceleration > 15.0) {
        final now = DateTime.now();
        // 设置 400 毫秒的防抖时间。
        // 在这 400ms 内持续摇晃，由于动画会被不断打断重开，会形成非常逼真的“持续翻滚”物理效果。
        if (now.difference(_lastShakeTime).inMilliseconds > 400) {
          _rollDice();
          _lastShakeTime = now;
        }
      }
    });
  }

  void _rollDice() {
    if (_controller.isAnimating) {
      _currentRotX = _rotXAnimation.value;
      _currentRotY = _rotYAnimation.value;
      _controller.stop();
    }

    int targetFace = Random().nextInt(6) + 1;
    double targetRotX = 0;
    double targetRotY = 0;

    switch (targetFace) {
      case 1: targetRotX = 0; targetRotY = 0; break;
      case 6: targetRotX = 0; targetRotY = pi; break;
      case 2: targetRotX = 0; targetRotY = pi / 2; break;
      case 5: targetRotX = 0; targetRotY = -pi / 2; break;
      case 3: targetRotX = pi / 2; targetRotY = 0; break;
      case 4: targetRotX = -pi / 2; targetRotY = 0; break;
    }

    targetRotX += (Random().nextBool() ? 1 : -1) * (2 * pi * 2);
    targetRotY += (Random().nextBool() ? 1 : -1) * (2 * pi * 2);

    _rotXAnimation = Tween<double>(
      begin: _currentRotX,
      end: targetRotX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _rotYAnimation = Tween<double>(
      begin: _currentRotY,
      end: targetRotY,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _lastVibrateAngle = _currentRotX.abs() + _currentRotY.abs();

    HapticFeedback.mediumImpact();

    _controller.forward(from: 0).then((_) {
      _currentRotX = _rotXAnimation.value % (2 * pi);
      _currentRotY = _rotYAnimation.value % (2 * pi);
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel(); // 别忘了释放传感器监听
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("3D Virtual Dice"),
        // 移除了原本在这里的 actions (Switch 开关)
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _rollDice,
        child: SizedBox.expand(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return IgnorePointer(
                  child: _build3DDice(),
                );
              },
            ),
          ),
        ),
      ),
      // 新增：右下角的圆形悬浮按钮
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,

        onPressed: () {
          setState(() {
            _isShakeEnabled = !_isShakeEnabled;
          });
          // 开启时给一点轻微的震动反馈
          if (_isShakeEnabled) {
            HapticFeedback.selectionClick();
          }
        },
        // 强制设为正圆形
        shape: const CircleBorder(),
        // 根据状态动态改变颜色，开启是显眼的琥珀色，关闭是低调的灰色
        backgroundColor: _isShakeEnabled ? Colors.amber.shade700 : Colors.grey.shade400,
        // 根据状态切换图标
        child: Icon(
          _isShakeEnabled ? Icons.vibration : Icons.mobile_off,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _build3DDice() {
    double halfSize = diceSize / 2;

    Matrix4 rotationMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..rotateX(_rotXAnimation.value)
      ..rotateY(_rotYAnimation.value);

    List<_DiceFaceData> faces = [
      _DiceFaceData(1, 0, 0, -halfSize, Matrix4.identity()..translate(0.0, 0.0, -halfSize)),
      _DiceFaceData(6, 0, 0, halfSize, Matrix4.identity()..translate(0.0, 0.0, halfSize)..rotateY(pi)),
      _DiceFaceData(2, halfSize, 0, 0, Matrix4.identity()..translate(halfSize, 0.0, 0.0)..rotateY(pi / 2)),
      _DiceFaceData(5, -halfSize, 0, 0, Matrix4.identity()..translate(-halfSize, 0.0, 0.0)..rotateY(-pi / 2)),
      _DiceFaceData(3, 0, -halfSize, 0, Matrix4.identity()..translate(0.0, -halfSize, 0.0)..rotateX(-pi / 2)),
      _DiceFaceData(4, 0, halfSize, 0, Matrix4.identity()..translate(0.0, halfSize, 0.0)..rotateX(pi / 2)),
    ];

    for (var face in faces) {
      var m = rotationMatrix.storage;
      face.transformedZ = m[2] * face.cx + m[6] * face.cy + m[10] * face.cz + m[14];
    }

    faces.sort((a, b) => b.transformedZ.compareTo(a.transformedZ));

    return Transform(
      alignment: Alignment.center,
      transform: rotationMatrix,
      child: Stack(
        alignment: Alignment.center,
        children: faces.map((face) {
          return Transform(
            alignment: Alignment.center,
            transform: face.transform,
            child: _buildFaceWidget(face.number),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaceWidget(int number) {
    return Container(
      width: diceSize,
      height: diceSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1)
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: _buildDots(number),
    );
  }

  Widget _buildDots(int number) {
    Widget dot = Container(
      width: diceSize * 0.18,
      height: diceSize * 0.18,
      decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
    );

    switch (number) {
      case 1:
        return Center(child: Container(width: diceSize * 0.3, height: diceSize * 0.3, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)));
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Align(alignment: Alignment.topRight, child: dot), Align(alignment: Alignment.bottomLeft, child: dot)],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Align(alignment: Alignment.topRight, child: dot), Center(child: dot), Align(alignment: Alignment.bottomLeft, child: dot)],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
            Center(child: dot),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot, dot]),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class _DiceFaceData {
  final int number;
  final double cx, cy, cz;
  final Matrix4 transform;
  double transformedZ = 0;

  _DiceFaceData(this.number, this.cx, this.cy, this.cz, this.transform);
}
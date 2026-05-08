import 'dart:math' as math;
import 'package:flutter/material.dart';


class AnimalIllustration extends StatelessWidget {
  final String illustrationId;
  final Color ink;
  final double size;

  const AnimalIllustration({
    super.key,
    required this.illustrationId,
    required this.ink,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnimalPainter(id: illustrationId, ink: ink),
      ),
    );
  }
}

class _AnimalPainter extends CustomPainter {
  final String id;
  final Color ink;
  _AnimalPainter({required this.id, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    switch (id) {
      case 'tiger':    _drawTiger(canvas, size); break;
      case 'eagle':    _drawEagle(canvas, size); break;
      case 'fox':      _drawFox(canvas, size); break;
      case 'stag':     _drawStag(canvas, size); break;
      case 'hedgehog': _drawHedgehog(canvas, size); break;
      case 'tortoise': _drawTortoise(canvas, size); break;
      case 'wolf':     _drawWolf(canvas, size); break;
      case 'owl':      _drawOwl(canvas, size); break;
      default:         _drawOwl(canvas, size);
    }
  }

  Paint _stroke([double w = 1.6]) => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill() => Paint()..color = ink..style = PaintingStyle.fill;

  // ═══════════════════════════════════════════════════════════
  //  TIGER — 호랑이 (얼굴 위주, 격자무늬)
  // ═══════════════════════════════════════════════════════════
  void _drawTiger(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.28;

    // 얼굴 윤곽
    final face = Path()
      ..moveTo(cx - r, cy - r * 0.2)
      ..quadraticBezierTo(cx - r * 1.1, cy + r * 0.6, cx - r * 0.5, cy + r * 1.1)
      ..quadraticBezierTo(cx, cy + r * 1.3, cx + r * 0.5, cy + r * 1.1)
      ..quadraticBezierTo(cx + r * 1.1, cy + r * 0.6, cx + r, cy - r * 0.2)
      ..quadraticBezierTo(cx + r * 1.05, cy - r * 0.9, cx + r * 0.55, cy - r * 0.95)
      ..lineTo(cx + r * 0.3, cy - r * 0.6)
      ..lineTo(cx - r * 0.3, cy - r * 0.6)
      ..lineTo(cx - r * 0.55, cy - r * 0.95)
      ..quadraticBezierTo(cx - r * 1.05, cy - r * 0.9, cx - r, cy - r * 0.2)
      ..close();
    c.drawPath(face, _stroke(2));

    // 귀 안쪽
    c.drawLine(
        Offset(cx - r * 0.45, cy - r * 0.85), Offset(cx - r * 0.4, cy - r * 0.55), _stroke(1.2));
    c.drawLine(
        Offset(cx + r * 0.45, cy - r * 0.85), Offset(cx + r * 0.4, cy - r * 0.55), _stroke(1.2));

    // 눈
    c.drawOval(Rect.fromCenter(
      center: Offset(cx - r * 0.35, cy - r * 0.1), width: r * 0.28, height: r * 0.18,
    ), _stroke(1.5));
    c.drawOval(Rect.fromCenter(
      center: Offset(cx + r * 0.35, cy - r * 0.1), width: r * 0.28, height: r * 0.18,
    ), _stroke(1.5));
    c.drawCircle(Offset(cx - r * 0.35, cy - r * 0.1), r * 0.05, _fill());
    c.drawCircle(Offset(cx + r * 0.35, cy - r * 0.1), r * 0.05, _fill());

    // 코
    final nose = Path()
      ..moveTo(cx - r * 0.12, cy + r * 0.2)
      ..lineTo(cx + r * 0.12, cy + r * 0.2)
      ..lineTo(cx, cy + r * 0.4)
      ..close();
    c.drawPath(nose, _fill());

    // 입
    c.drawLine(Offset(cx, cy + r * 0.4), Offset(cx, cy + r * 0.65), _stroke(1.5));
    final mouthL = Path()
      ..moveTo(cx, cy + r * 0.65)
      ..quadraticBezierTo(cx - r * 0.2, cy + r * 0.85, cx - r * 0.35, cy + r * 0.7);
    final mouthR = Path()
      ..moveTo(cx, cy + r * 0.65)
      ..quadraticBezierTo(cx + r * 0.2, cy + r * 0.85, cx + r * 0.35, cy + r * 0.7);
    c.drawPath(mouthL, _stroke(1.5));
    c.drawPath(mouthR, _stroke(1.5));

    // 줄무늬 — 이마
    for (int i = 0; i < 5; i++) {
      final x = cx - r * 0.35 + i * r * 0.18;
      final y1 = cy - r * 0.55;
      final y2 = cy - r * 0.3 - (i == 2 ? r * 0.05 : 0);
      c.drawLine(Offset(x, y1), Offset(x, y2), _stroke(1.8));
    }
    // 줄무늬 — 양 볼
    for (int i = 0; i < 4; i++) {
      final yy = cy + r * 0.1 + i * r * 0.18;
      c.drawLine(Offset(cx - r * 0.95, yy), Offset(cx - r * 0.7, yy + r * 0.05), _stroke(1.6));
      c.drawLine(Offset(cx + r * 0.7, yy + r * 0.05), Offset(cx + r * 0.95, yy), _stroke(1.6));
    }

    // 수염
    for (int i = 0; i < 3; i++) {
      final yy = cy + r * 0.45 + i * r * 0.1;
      c.drawLine(Offset(cx - r * 0.35, yy), Offset(cx - r * 0.85, yy - r * 0.08 + i * r * 0.06), _stroke(1.0));
      c.drawLine(Offset(cx + r * 0.35, yy), Offset(cx + r * 0.85, yy - r * 0.08 + i * r * 0.06), _stroke(1.0));
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  EAGLE — 날개 펼친 모습
  // ═══════════════════════════════════════════════════════════
  void _drawEagle(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.4;

    // 몸통
    final body = Path()
      ..moveTo(cx, cy - r * 0.55)
      ..quadraticBezierTo(cx + r * 0.12, cy, cx + r * 0.08, cy + r * 0.5)
      ..quadraticBezierTo(cx, cy + r * 0.7, cx - r * 0.08, cy + r * 0.5)
      ..quadraticBezierTo(cx - r * 0.12, cy, cx, cy - r * 0.55)
      ..close();
    c.drawPath(body, _stroke(1.8));

    // 머리
    c.drawCircle(Offset(cx, cy - r * 0.65), r * 0.15, _stroke(1.8));
    // 부리
    final beak = Path()
      ..moveTo(cx - r * 0.05, cy - r * 0.62)
      ..lineTo(cx - r * 0.22, cy - r * 0.55)
      ..lineTo(cx - r * 0.05, cy - r * 0.5)
      ..close();
    c.drawPath(beak, _fill());
    // 눈
    c.drawCircle(Offset(cx + r * 0.04, cy - r * 0.7), r * 0.025, _fill());

    // 왼쪽 날개
    final wingL = Path()
      ..moveTo(cx - r * 0.08, cy - r * 0.3)
      ..quadraticBezierTo(cx - r * 0.7, cy - r * 0.6, cx - r, cy - r * 0.2)
      ..quadraticBezierTo(cx - r * 0.7, cy + r * 0.05, cx - r * 0.1, cy);
    c.drawPath(wingL, _stroke(2));

    // 왼날개 깃털 라인
    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      final x1 = cx - r * 0.1 - t * r * 0.85;
      final y1 = cy - r * 0.05 + (t < 0.5 ? -t * r * 0.4 : -(1 - t) * r * 0.4);
      final x2 = x1 + r * 0.05;
      final y2 = y1 + r * 0.18;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(1.0));
    }
    // 왼날개 끝 깃 (스플레이드)
    for (int i = 0; i < 5; i++) {
      final ang = math.pi + 0.2 + i * 0.18;
      final x1 = cx - r;
      final y1 = cy - r * 0.2;
      final x2 = x1 + math.cos(ang) * r * 0.3;
      final y2 = y1 + math.sin(ang) * r * 0.3;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(1.5));
    }

    // 오른쪽 날개 (대칭)
    final wingR = Path()
      ..moveTo(cx + r * 0.08, cy - r * 0.3)
      ..quadraticBezierTo(cx + r * 0.7, cy - r * 0.6, cx + r, cy - r * 0.2)
      ..quadraticBezierTo(cx + r * 0.7, cy + r * 0.05, cx + r * 0.1, cy);
    c.drawPath(wingR, _stroke(2));

    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      final x1 = cx + r * 0.1 + t * r * 0.85;
      final y1 = cy - r * 0.05 + (t < 0.5 ? -t * r * 0.4 : -(1 - t) * r * 0.4);
      final x2 = x1 - r * 0.05;
      final y2 = y1 + r * 0.18;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(1.0));
    }
    for (int i = 0; i < 5; i++) {
      final ang = -0.2 - i * 0.18;
      final x1 = cx + r;
      final y1 = cy - r * 0.2;
      final x2 = x1 + math.cos(ang) * r * 0.3;
      final y2 = y1 + math.sin(ang) * r * 0.3;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(1.5));
    }

    // 발톱
    final tail = Path()
      ..moveTo(cx - r * 0.06, cy + r * 0.55)
      ..lineTo(cx, cy + r * 0.78)
      ..lineTo(cx + r * 0.06, cy + r * 0.55);
    c.drawPath(tail, _stroke(1.5));
  }

  // ═══════════════════════════════════════════════════════════
  //  FOX — 영리한 옆모습
  // ═══════════════════════════════════════════════════════════
  void _drawFox(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.32;

    // 머리 (삼각형 풍)
    final head = Path()
      ..moveTo(cx - r, cy - r * 0.5)
      ..lineTo(cx - r * 0.7, cy - r * 1.05)
      ..lineTo(cx - r * 0.4, cy - r * 0.7)
      ..lineTo(cx + r * 0.4, cy - r * 0.7)
      ..lineTo(cx + r * 0.7, cy - r * 1.05)
      ..lineTo(cx + r, cy - r * 0.5)
      ..quadraticBezierTo(cx + r * 1.1, cy + r * 0.3, cx + r * 0.6, cy + r * 0.7)
      ..lineTo(cx, cy + r * 1.05)        // 코끝 (긴 주둥이)
      ..lineTo(cx - r * 0.6, cy + r * 0.7)
      ..quadraticBezierTo(cx - r * 1.1, cy + r * 0.3, cx - r, cy - r * 0.5)
      ..close();
    c.drawPath(head, _stroke(2));

    // 귀 안쪽
    final earL = Path()
      ..moveTo(cx - r * 0.7, cy - r * 1.0)
      ..lineTo(cx - r * 0.55, cy - r * 0.75)
      ..lineTo(cx - r * 0.85, cy - r * 0.75)
      ..close();
    c.drawPath(earL, _fill());
    final earR = Path()
      ..moveTo(cx + r * 0.7, cy - r * 1.0)
      ..lineTo(cx + r * 0.55, cy - r * 0.75)
      ..lineTo(cx + r * 0.85, cy - r * 0.75)
      ..close();
    c.drawPath(earR, _fill());

    // 흰 얼굴 패치 (V자 hatching)
    for (int i = 0; i < 8; i++) {
      final t = i / 7.0;
      final y = cy - r * 0.1 + t * r * 0.6;
      final w = (1 - t) * r * 0.6;
      c.drawLine(Offset(cx - w, y), Offset(cx + w, y), _stroke(0.8));
    }

    // 눈
    c.drawCircle(Offset(cx - r * 0.35, cy - r * 0.3), r * 0.07, _fill());
    c.drawCircle(Offset(cx + r * 0.35, cy - r * 0.3), r * 0.07, _fill());

    // 코
    final nose = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy + r * 1.0), width: r * 0.18, height: r * 0.13,
      ));
    c.drawPath(nose, _fill());

    // 콧대 라인
    c.drawLine(Offset(cx, cy + r * 0.1), Offset(cx, cy + r * 0.95), _stroke(1.2));

    // 텍스처 hatching (왼쪽 볼)
    for (int i = 0; i < 5; i++) {
      final t = i / 4.0;
      final x1 = cx - r * (0.7 + t * 0.2);
      final y1 = cy + r * (-0.2 + t * 0.6);
      final x2 = x1 + r * 0.2;
      final y2 = y1 + r * 0.05;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(1.0));
    }
    for (int i = 0; i < 5; i++) {
      final t = i / 4.0;
      final x1 = cx + r * (0.7 + t * 0.2);
      final y1 = cy + r * (-0.2 + t * 0.6);
      final x2 = x1 - r * 0.2;
      final y2 = y1 + r * 0.05;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(1.0));
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  STAG — 뿔 강조
  // ═══════════════════════════════════════════════════════════
  void _drawStag(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2 + s.height * 0.1;
    final r = s.width * 0.22;

    // 얼굴
    final face = Path()
      ..moveTo(cx - r, cy - r * 0.4)
      ..quadraticBezierTo(cx - r * 1.05, cy + r * 0.3, cx - r * 0.7, cy + r * 0.9)
      ..lineTo(cx - r * 0.3, cy + r * 1.4)
      ..lineTo(cx + r * 0.3, cy + r * 1.4)
      ..lineTo(cx + r * 0.7, cy + r * 0.9)
      ..quadraticBezierTo(cx + r * 1.05, cy + r * 0.3, cx + r, cy - r * 0.4)
      ..quadraticBezierTo(cx + r * 0.4, cy - r * 0.7, cx, cy - r * 0.55)
      ..quadraticBezierTo(cx - r * 0.4, cy - r * 0.7, cx - r, cy - r * 0.4)
      ..close();
    c.drawPath(face, _stroke(2));

    // 귀
    _drawLeaf(c, Offset(cx - r * 1.1, cy - r * 0.5), r * 0.5, -0.4);
    _drawLeaf(c, Offset(cx + r * 1.1, cy - r * 0.5), r * 0.5, 0.4);

    // 뿔 — 좌우 가지 (크게, 화려하게)
    _drawAntler(c, cx, cy - r * 0.55, r * 1.4, isLeft: true);
    _drawAntler(c, cx, cy - r * 0.55, r * 1.4, isLeft: false);

    // 눈
    c.drawCircle(Offset(cx - r * 0.4, cy + r * 0.3), r * 0.08, _fill());
    c.drawCircle(Offset(cx + r * 0.4, cy + r * 0.3), r * 0.08, _fill());

    // 코
    c.drawOval(Rect.fromCenter(
      center: Offset(cx, cy + r * 1.2), width: r * 0.35, height: r * 0.22,
    ), _fill());

    // 입
    c.drawLine(Offset(cx, cy + r * 1.32), Offset(cx, cy + r * 1.45), _stroke(1.2));
  }

  void _drawLeaf(Canvas c, Offset o, double sz, double tilt) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..quadraticBezierTo(o.dx + math.sin(tilt) * sz * 0.4 + sz * 0.2, o.dy - sz * 0.5,
          o.dx + math.sin(tilt) * sz, o.dy - sz)
      ..quadraticBezierTo(o.dx + math.sin(tilt) * sz * 0.4 - sz * 0.2, o.dy - sz * 0.5,
          o.dx, o.dy)
      ..close();
    c.drawPath(path, _stroke(1.5));
  }

  void _drawAntler(Canvas c, double rootX, double rootY, double size,
      {required bool isLeft}) {
    final dir = isLeft ? -1 : 1;
    final main = Path()
      ..moveTo(rootX + dir * size * 0.2, rootY)
      ..lineTo(rootX + dir * size * 0.5, rootY - size * 0.4)
      ..lineTo(rootX + dir * size * 0.4, rootY - size * 0.85);
    c.drawPath(main, _stroke(2));

    // 가지 1
    c.drawLine(
      Offset(rootX + dir * size * 0.5, rootY - size * 0.4),
      Offset(rootX + dir * size * 0.85, rootY - size * 0.5),
      _stroke(1.8),
    );
    // 가지 2
    c.drawLine(
      Offset(rootX + dir * size * 0.45, rootY - size * 0.65),
      Offset(rootX + dir * size * 0.75, rootY - size * 0.85),
      _stroke(1.8),
    );
    // 가지 3
    c.drawLine(
      Offset(rootX + dir * size * 0.42, rootY - size * 0.78),
      Offset(rootX + dir * size * 0.58, rootY - size * 1.0),
      _stroke(1.8),
    );
    // 끝 가지 두 갈래
    c.drawLine(
      Offset(rootX + dir * size * 0.4, rootY - size * 0.85),
      Offset(rootX + dir * size * 0.3, rootY - size * 1.05),
      _stroke(1.8),
    );
    c.drawLine(
      Offset(rootX + dir * size * 0.4, rootY - size * 0.85),
      Offset(rootX + dir * size * 0.5, rootY - size * 1.1),
      _stroke(1.8),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HEDGEHOG
  // ═══════════════════════════════════════════════════════════
  void _drawHedgehog(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2 + s.height * 0.05;
    final r = s.width * 0.34;

    // 몸 (둥근 반원)
    final body = Path()
      ..moveTo(cx - r, cy + r * 0.4)
      ..quadraticBezierTo(cx - r, cy - r * 0.6, cx - r * 0.3, cy - r * 0.7)
      ..quadraticBezierTo(cx + r, cy - r * 0.6, cx + r, cy + r * 0.4)
      ..close();
    c.drawPath(body, _stroke(2));

    // 가시 (수많은 짧은 선)
    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      // 반원 위쪽에서 랜덤 위치
      final ang = math.pi + rng.nextDouble() * math.pi;
      final dist = 0.6 + rng.nextDouble() * 0.4;
      final px = cx + math.cos(ang) * r * dist;
      final py = cy + math.sin(ang) * r * dist * 1.0;
      // 가시는 바깥 방향
      final out = 0.18 + rng.nextDouble() * 0.12;
      final ex = cx + math.cos(ang) * r * (dist + out);
      final ey = cy + math.sin(ang) * r * (dist + out) * 1.0;
      c.drawLine(Offset(px, py), Offset(ex, ey), _stroke(1.2));
    }

    // 얼굴 (앞쪽 빨간 부분 — 흰 영역으로 표현)
    final face = Path()
      ..moveTo(cx - r * 0.95, cy + r * 0.1)
      ..quadraticBezierTo(cx - r * 1.15, cy - r * 0.3, cx - r * 0.95, cy - r * 0.55)
      ..quadraticBezierTo(cx - r * 0.4, cy - r * 0.65, cx - r * 0.2, cy + r * 0.05)
      ..quadraticBezierTo(cx - r * 0.5, cy + r * 0.3, cx - r * 0.95, cy + r * 0.1)
      ..close();
    c.drawPath(face, _stroke(1.6));

    // 코끝
    c.drawCircle(Offset(cx - r * 1.05, cy - r * 0.3), r * 0.08, _fill());

    // 눈
    c.drawCircle(Offset(cx - r * 0.55, cy - r * 0.3), r * 0.06, _fill());

    // 발
    c.drawArc(
      Rect.fromCenter(center: Offset(cx - r * 0.4, cy + r * 0.5),
          width: r * 0.3, height: r * 0.2),
      0, math.pi, false, _stroke(1.4),
    );
    c.drawArc(
      Rect.fromCenter(center: Offset(cx + r * 0.5, cy + r * 0.5),
          width: r * 0.3, height: r * 0.2),
      0, math.pi, false, _stroke(1.4),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TORTOISE
  // ═══════════════════════════════════════════════════════════
  void _drawTortoise(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final w = s.width * 0.42;
    final h = s.height * 0.22;

    // 등껍질 (크게)
    final shell = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy), width: w * 2, height: h * 2,
      ));
    c.drawPath(shell, _stroke(2));

    // 등껍질 무늬 (육각 패턴)
    final hexR = w * 0.18;
    for (int row = -1; row <= 1; row++) {
      for (int col = -2; col <= 2; col++) {
        final dx = col * hexR * 1.7 + (row % 2 == 0 ? 0 : hexR * 0.85);
        final dy = row * hexR * 1.5;
        if (dx * dx / (w * w) + dy * dy / (h * h) > 0.7) continue;
        _drawHex(c, Offset(cx + dx, cy + dy), hexR * 0.85);
      }
    }

    // 머리 (앞쪽, 왼쪽)
    final head = Path()
      ..moveTo(cx - w * 0.95, cy - h * 0.1)
      ..quadraticBezierTo(cx - w * 1.45, cy - h * 0.2, cx - w * 1.5, cy + h * 0.2)
      ..quadraticBezierTo(cx - w * 1.45, cy + h * 0.5, cx - w * 0.95, cy + h * 0.3)
      ..close();
    c.drawPath(head, _stroke(1.8));
    // 눈
    c.drawCircle(Offset(cx - w * 1.3, cy + h * 0.0), h * 0.12, _fill());

    // 다리 4개 (스텀프)
    for (final pos in [
      Offset(cx - w * 0.65, cy + h * 0.95),
      Offset(cx + w * 0.65, cy + h * 0.95),
      Offset(cx - w * 0.6, cy - h * 0.9),
      Offset(cx + w * 0.6, cy - h * 0.9),
    ]) {
      c.drawOval(
        Rect.fromCenter(center: pos, width: w * 0.3, height: h * 0.4),
        _stroke(1.6),
      );
    }

    // 꼬리
    c.drawLine(Offset(cx + w * 0.95, cy + h * 0.05),
        Offset(cx + w * 1.2, cy + h * 0.2), _stroke(1.6));
  }

  void _drawHex(Canvas c, Offset center, double r) {
    final p = Path();
    for (int i = 0; i < 6; i++) {
      final ang = -math.pi / 2 + i * math.pi / 3;
      final x = center.dx + math.cos(ang) * r;
      final y = center.dy + math.sin(ang) * r;
      if (i == 0) p.moveTo(x, y); else p.lineTo(x, y);
    }
    p.close();
    c.drawPath(p, _stroke(1.2));
  }

  // ═══════════════════════════════════════════════════════════
  //  WOLF
  // ═══════════════════════════════════════════════════════════
  void _drawWolf(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2 + s.height * 0.05;
    final r = s.width * 0.3;

    // 얼굴 (다이아몬드 풍)
    final face = Path()
      ..moveTo(cx - r * 1.1, cy - r * 0.5)
      ..lineTo(cx - r * 0.85, cy - r * 1.15)   // 왼쪽 귀 끝
      ..lineTo(cx - r * 0.45, cy - r * 0.8)
      ..lineTo(cx + r * 0.45, cy - r * 0.8)
      ..lineTo(cx + r * 0.85, cy - r * 1.15)   // 오른쪽 귀
      ..lineTo(cx + r * 1.1, cy - r * 0.5)
      ..lineTo(cx + r * 0.55, cy + r * 0.4)
      ..lineTo(cx, cy + r * 1.2)               // 코끝
      ..lineTo(cx - r * 0.55, cy + r * 0.4)
      ..close();
    c.drawPath(face, _stroke(2));

    // 흰털 V (이마부터 코까지)
    final whiteV = Path()
      ..moveTo(cx - r * 0.35, cy - r * 0.5)
      ..lineTo(cx, cy + r * 1.1)
      ..lineTo(cx + r * 0.35, cy - r * 0.5);
    c.drawPath(whiteV, _stroke(1.4));

    // 눈
    c.drawOval(Rect.fromCenter(
      center: Offset(cx - r * 0.45, cy - r * 0.2), width: r * 0.3, height: r * 0.18,
    ), _fill());
    c.drawOval(Rect.fromCenter(
      center: Offset(cx + r * 0.45, cy - r * 0.2), width: r * 0.3, height: r * 0.18,
    ), _fill());

    // 코
    final nose = Path()
      ..moveTo(cx - r * 0.12, cy + r * 0.95)
      ..lineTo(cx + r * 0.12, cy + r * 0.95)
      ..lineTo(cx, cy + r * 1.18)
      ..close();
    c.drawPath(nose, _fill());

    // 측면 hatching
    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      final x1 = cx - r * 0.95 + t * r * 0.3;
      final y1 = cy - r * 0.4 + t * r * 0.5;
      final x2 = cx - r * 0.6 + t * r * 0.2;
      final y2 = y1;
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(0.9));
      c.drawLine(Offset(s.width - x1, y1), Offset(s.width - x2, y2), _stroke(0.9));
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  OWL
  // ═══════════════════════════════════════════════════════════
  void _drawOwl(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.32;

    // 몸통 (라운드 사각형 풍)
    final body = Path()
      ..moveTo(cx - r * 0.9, cy - r * 0.5)
      ..quadraticBezierTo(cx - r * 1.0, cy - r * 1.2, cx - r * 0.55, cy - r * 1.2) // 왼쪽 귀
      ..lineTo(cx - r * 0.3, cy - r * 0.95)
      ..lineTo(cx + r * 0.3, cy - r * 0.95)
      ..lineTo(cx + r * 0.55, cy - r * 1.2)
      ..quadraticBezierTo(cx + r, cy - r * 1.2, cx + r * 0.9, cy - r * 0.5)
      ..quadraticBezierTo(cx + r * 1.05, cy + r * 0.5, cx + r * 0.6, cy + r * 1.05)
      ..lineTo(cx - r * 0.6, cy + r * 1.05)
      ..quadraticBezierTo(cx - r * 1.05, cy + r * 0.5, cx - r * 0.9, cy - r * 0.5)
      ..close();
    c.drawPath(body, _stroke(2));

    // 큰 눈 두 개
    c.drawCircle(Offset(cx - r * 0.4, cy - r * 0.3), r * 0.32, _stroke(1.8));
    c.drawCircle(Offset(cx + r * 0.4, cy - r * 0.3), r * 0.32, _stroke(1.8));
    c.drawCircle(Offset(cx - r * 0.4, cy - r * 0.3), r * 0.18, _fill());
    c.drawCircle(Offset(cx + r * 0.4, cy - r * 0.3), r * 0.18, _fill());

    // 부리
    final beak = Path()
      ..moveTo(cx - r * 0.08, cy)
      ..lineTo(cx + r * 0.08, cy)
      ..lineTo(cx, cy + r * 0.2)
      ..close();
    c.drawPath(beak, _fill());

    // 가슴 V 무늬 패턴 (3줄)
    for (int row = 0; row < 3; row++) {
      final yy = cy + r * 0.35 + row * r * 0.22;
      for (int i = -2; i <= 2; i++) {
        final x = cx + i * r * 0.22 + (row % 2 == 0 ? 0 : r * 0.11);
        if ((x - cx).abs() > r * 0.7 - row * r * 0.05) continue;
        final p = Path()
          ..moveTo(x - r * 0.07, yy)
          ..lineTo(x, yy + r * 0.08)
          ..lineTo(x + r * 0.07, yy);
        c.drawPath(p, _stroke(1.0));
      }
    }

    // 발
    c.drawLine(Offset(cx - r * 0.2, cy + r * 1.0),
        Offset(cx - r * 0.2, cy + r * 1.18), _stroke(1.4));
    c.drawLine(Offset(cx + r * 0.2, cy + r * 1.0),
        Offset(cx + r * 0.2, cy + r * 1.18), _stroke(1.4));
  }

  @override
  bool shouldRepaint(covariant _AnimalPainter old) =>
      old.id != id || old.ink != ink;
}

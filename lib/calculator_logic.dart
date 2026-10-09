/// Matnli ifodani hisoblaydigan oddiy rekursiv parser.
/// Qo'llab-quvvatlanadi: + − × ÷ %, qavslarsiz, unar minus.
class CalculatorLogic {
  /// [expr] masalan: "12+3×4÷2". Xatolikda [FormatException] otadi.
  static double evaluate(String expr) {
    final p = _Parser(expr);
    final v = p.parseExpression();
    if (!p.atEnd) throw const FormatException('Noto\'g\'ri ifoda');
    if (v.isNaN || v.isInfinite) throw const FormatException('Xatolik');
    return v;
  }

  /// Natijani chiroyli ko'rinishga keltiradi (ortiqcha nollarsiz).
  static String format(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    var s = v.toStringAsPrecision(12);
    if (s.contains('e')) return s;
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}

class _Parser {
  _Parser(this.s);
  final String s;
  int i = 0;

  bool get atEnd => i >= s.length;

  double parseExpression() {
    var v = _term();
    while (!atEnd && (s[i] == '+' || s[i] == '−')) {
      final op = s[i++];
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _unary();
    while (!atEnd && (s[i] == '×' || s[i] == '÷')) {
      final op = s[i++];
      final r = _unary();
      if (op == '÷' && r == 0) throw const FormatException('0 ga bo\'lib bo\'lmaydi');
      v = op == '×' ? v * r : v / r;
    }
    return v;
  }

  double _unary() {
    if (!atEnd && s[i] == '−') {
      i++;
      return -_unary();
    }
    return _number();
  }

  double _number() {
    final start = i;
    while (!atEnd && (RegExp(r'[0-9.]').hasMatch(s[i]))) {
      i++;
    }
    if (start == i) throw const FormatException('Son kutilgan edi');
    var v = double.parse(s.substring(start, i));
    while (!atEnd && s[i] == '%') {
      i++;
      v /= 100;
    }
    return v;
  }
}

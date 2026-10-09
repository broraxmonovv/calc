import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_logic.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const CalcApp());
}

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulyator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14151A),
      ),
      home: const CalculatorPage(),
    );
  }
}

enum _Kind { number, operator, function, equals }

class _Key {
  const _Key(this.label, this.kind);
  final String label;
  final _Kind kind;
}

const _keys = <_Key>[
  _Key('AC', _Kind.function), _Key('⌫', _Kind.function),
  _Key('%', _Kind.function), _Key('÷', _Kind.operator),
  _Key('7', _Kind.number), _Key('8', _Kind.number),
  _Key('9', _Kind.number), _Key('×', _Kind.operator),
  _Key('4', _Kind.number), _Key('5', _Kind.number),
  _Key('6', _Kind.number), _Key('−', _Kind.operator),
  _Key('1', _Kind.number), _Key('2', _Kind.number),
  _Key('3', _Kind.number), _Key('+', _Kind.operator),
  _Key('±', _Kind.number), _Key('0', _Kind.number),
  _Key('.', _Kind.number), _Key('=', _Kind.equals),
];

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expr = '';
  String _result = '0';
  String _history = '';
  bool _justEvaluated = false;

  static const _ops = ['+', '−', '×', '÷'];

  bool _endsWithOp() => _expr.isNotEmpty && _ops.contains(_expr[_expr.length - 1]);

  /// Oxirgi sonni qaytaradi (tahrirlash uchun).
  String _lastNumber() {
    final m = RegExp(r'[0-9.%]*$').firstMatch(_expr);
    return m?.group(0) ?? '';
  }

  void _press(_Key k) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (k.label) {
        case 'AC':
          _expr = '';
          _result = '0';
          _history = '';
          _justEvaluated = false;
        case '⌫':
          if (_justEvaluated) {
            _expr = '';
            _justEvaluated = false;
          } else if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
          _preview();
        case '=':
          _equals();
        case '+' || '−' || '×' || '÷':
          _operator(k.label);
        case '%':
          if (_expr.isNotEmpty && !_endsWithOp() && !_expr.endsWith('%')) {
            _expr += '%';
            _justEvaluated = false;
          }
          _preview();
        case '±':
          _toggleSign();
        case '.':
          if (_justEvaluated) {
            _expr = '0.';
            _justEvaluated = false;
          } else if (!_lastNumber().contains('.')) {
            _expr += _lastNumber().isEmpty ? '0.' : '.';
          }
          _preview();
        default:
          if (_justEvaluated) {
            _expr = '';
            _justEvaluated = false;
          }
          if (_expr.length < 40) _expr += k.label;
          _preview();
      }
    });
  }

  void _operator(String op) {
    _justEvaluated = false;
    if (_expr.isEmpty) {
      if (op == '−') _expr = '−';
      return;
    }
    if (_expr == '−') return;
    if (_endsWithOp()) {
      _expr = _expr.substring(0, _expr.length - 1) + op;
    } else {
      _expr += op;
    }
  }

  void _toggleSign() {
    if (_justEvaluated) _justEvaluated = false;
    final num = _lastNumber();
    if (num.isEmpty) return;
    final idx = _expr.length - num.length;
    if (idx > 0 && _expr[idx - 1] == '−' && (idx == 1 || _ops.contains(_expr[idx - 2]))) {
      _expr = _expr.substring(0, idx - 1) + num;
    } else {
      _expr = '${_expr.substring(0, idx)}−$num';
    }
    _preview();
  }

  void _preview() {
    if (_expr.isEmpty) {
      _result = '0';
      return;
    }
    try {
      final e = _endsWithOp() ? _expr.substring(0, _expr.length - 1) : _expr;
      _result = CalculatorLogic.format(CalculatorLogic.evaluate(e));
    } on FormatException {
      // yarim yozilgan ifoda — oldingi natija qoladi
    }
  }

  void _equals() {
    if (_expr.isEmpty) return;
    final e = _endsWithOp() ? _expr.substring(0, _expr.length - 1) : _expr;
    try {
      final r = CalculatorLogic.format(CalculatorLogic.evaluate(e));
      _history = '$e =';
      _expr = r;
      _result = r;
      _justEvaluated = true;
    } on FormatException catch (err) {
      _result = err.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1D26), Color(0xFF0E0F13)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Expanded(child: _display()),
                  _keypad(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _display() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _history,
            style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.4)),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _expr.isEmpty ? '0' : _expr,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                _result,
                key: ValueKey(_result),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [for (final k in _keys) _CalcButton(k: k, onTap: () => _press(k))],
      ),
    );
  }
}

class _CalcButton extends StatefulWidget {
  const _CalcButton({required this.k, required this.onTap});
  final _Key k;
  final VoidCallback onTap;

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (Gradient? gradient, Color? color, Color fg) = switch (widget.k.kind) {
      _Kind.number => (null, const Color(0xFF23242D), Colors.white),
      _Kind.function => (null, const Color(0xFF2E3040), const Color(0xFF7DD3FC)),
      _Kind.operator => (null, const Color(0xFF2A2140), const Color(0xFFC4B5FD)),
      _Kind.equals => (
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
          null,
          Colors.white,
        ),
    };

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 80),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.k.label,
            style: TextStyle(
              fontSize: widget.k.kind == _Kind.number ? 30 : 28,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:calc/calculator_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operator priority', () {
    expect(CalculatorLogic.evaluate('2+3×4'), 14);
    expect(CalculatorLogic.evaluate('12÷4−1'), 2);
  });
  test('unary minus and percent', () {
    expect(CalculatorLogic.evaluate('−5+10'), 5);
    expect(CalculatorLogic.evaluate('50%'), 0.5);
  });
  test('division by zero throws', () {
    expect(() => CalculatorLogic.evaluate('1÷0'), throwsFormatException);
  });
  test('format', () {
    expect(CalculatorLogic.format(3.0), '3');
    expect(CalculatorLogic.format(0.1 + 0.2), '0.3');
  });
}

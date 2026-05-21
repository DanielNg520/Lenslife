import 'dart:math';

class WelfordState {
  final double mean;
  final double m2;
  final int count;

  const WelfordState({
    this.mean = 0.0,
    this.m2 = 0.0,
    this.count = 0,
  });

  WelfordState update(double x) {
    final n = count + 1;
    final delta = x - mean;
    final newMean = mean + delta / n;
    final newM2 = m2 + delta * (x - newMean);
    return WelfordState(mean: newMean, m2: newM2, count: n);
  }

  double get std => count < 2 ? 1.0 : sqrt(m2 / (count - 1));

  double zScore(double x) => (x - mean) / (std + 1e-9);

  Map<String, dynamic> toMap(String feature) => {
        'feature': feature,
        'mean': mean,
        'm2': m2,
        'count': count,
      };

  factory WelfordState.fromMap(Map<String, dynamic> m) => WelfordState(
        mean: (m['mean'] as num).toDouble(),
        m2: (m['m2'] as num).toDouble(),
        count: m['count'] as int,
      );
}

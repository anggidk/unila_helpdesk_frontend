double scoreToFive(double score) {
  return score.clamp(0, 5).toDouble();
}

String formatScoreFive(double? score, {int decimals = 2}) {
  if (score == null) {
    return '-';
  }
  return scoreToFive(score).toStringAsFixed(decimals);
}

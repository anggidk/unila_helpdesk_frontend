double scoreToFive(double score) {
  if (score <= 0) {
    return 0;
  }
  if (score <= 5) {
    return score;
  }
  return (score / 20).clamp(0, 5);
}

String formatScoreFive(double? score, {int decimals = 2}) {
  if (score == null) {
    return '-';
  }
  return scoreToFive(score).toStringAsFixed(decimals);
}

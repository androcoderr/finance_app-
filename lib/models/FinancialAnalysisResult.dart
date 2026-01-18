class FinancialAnalysisResult {
  final double recommendedMonthlySavings;
  final double completionProbability;
  final double riskLevel;
  final String? description; // Türkçe açıklama (opsiyonel)

  FinancialAnalysisResult({
    required this.recommendedMonthlySavings,
    required this.completionProbability,
    required this.riskLevel,
    this.description,
  });

  factory FinancialAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FinancialAnalysisResult(
      recommendedMonthlySavings: (json['aylik_tasarruf'] as num).toDouble(),
      completionProbability: (json['basari_olasiligi'] as num).toDouble(),
      riskLevel: (json['risk_seviyesi'] as num).toDouble(),
      description: json['aciklama'] as String?,
    );
  }
}

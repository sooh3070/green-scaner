import 'package:flutter/material.dart';

// 재질별 CO₂ 절감량 (kg/개) — EPA WARM Model 기반
// 출처: https://www.epa.gov/warm/documentation-chapters-greenhouse-gas-emission-and-energy-factors-used-waste-reduction-model-warm
const co2PerVerdict = {
  '플라스틱': 0.050,  // PET병 평균 25g × 2.0 kg CO₂/kg
  '종이류':   0.080,  // 종이류 평균 150g × 0.54 kg CO₂/kg
  '유리':     0.030,  // 유리병 평균 300g × 0.10 kg CO₂/kg
  '캔':       0.095,  // 알루미늄 캔 평균 15g × 6.3 kg CO₂/kg
  '비닐':     0.020,  // 비닐봉지 평균 40g × 0.50 kg CO₂/kg
  '스티로폼': 0.040,  // EPS 평균 80g × 0.50 kg CO₂/kg
};

class EcoGrade {
  final String emoji;
  final String name;
  final Color color;
  final int minScans;
  final int maxScans; // -1 = 최고 등급

  const EcoGrade({
    required this.emoji,
    required this.name,
    required this.color,
    required this.minScans,
    required this.maxScans,
  });
}

const ecoGrades = [
  EcoGrade(emoji: '🌰', name: '씨앗',        color: Color(0xFF8D6E63), minScans: 0,   maxScans: 4),
  EcoGrade(emoji: '🌱', name: '새싹',        color: Color(0xFF66BB6A), minScans: 5,   maxScans: 14),
  EcoGrade(emoji: '🍃', name: '나뭇잎',      color: Color(0xFF43A047), minScans: 15,  maxScans: 29),
  EcoGrade(emoji: '🌳', name: '나무',        color: Color(0xFF388E3C), minScans: 30,  maxScans: 59),
  EcoGrade(emoji: '🌲', name: '숲',          color: Color(0xFF2E7D32), minScans: 60,  maxScans: 99),
  EcoGrade(emoji: '🌍', name: '지구 수호자', color: Color(0xFF1B5E20), minScans: 100, maxScans: -1),
];

EcoGrade getEcoGrade(int total) {
  for (final g in ecoGrades.reversed) {
    if (total >= g.minScans) return g;
  }
  return ecoGrades.first;
}

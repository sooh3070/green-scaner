import 'package:flutter/material.dart';

const co2PerVerdict = {
  '플라스틱': 0.5,
  '종이류':   0.3,
  '유리':     0.4,
  '캔':       0.6,
  '비닐':     0.2,
  '스티로폼': 0.3,
  '음식물':   0.1,
  '일반쓰레기': 0.05,
  '특수폐기물': 0.8,
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

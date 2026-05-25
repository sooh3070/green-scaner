import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/eco_grade.dart';

class EcoGradeAvatar extends StatelessWidget {
  const EcoGradeAvatar({super.key, this.radius = 18});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.userStream,
      initialData: AuthService.currentUser,
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user == null) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFFEEEEEE),
            child: Icon(Icons.person_outline, size: radius, color: const Color(0xFFBDBDBD)),
          );
        }
        return StreamBuilder(
          stream: FirestoreService.myScansStream(),
          builder: (context, scanSnap) {
            final total = scanSnap.data?.docs.length ?? 0;
            final grade = getEcoGrade(total);
            return CircleAvatar(
              radius: radius,
              backgroundColor: grade.color.withValues(alpha: 0.15),
              child: Text(
                grade.emoji,
                style: TextStyle(fontSize: radius * 0.95),
              ),
            );
          },
        );
      },
    );
  }
}

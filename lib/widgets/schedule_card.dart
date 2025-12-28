import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final String room;
  final String lecturer;
  final Color color;
  final Color accentColor;

  const ScheduleCard({
    super.key,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.room,
    required this.lecturer,
    required this.color,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 140,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 25,
            bottom: 25,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const Spacer(),
                    const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.book_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text("|  $subtitle", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text("|  $room", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text("|  $lecturer", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
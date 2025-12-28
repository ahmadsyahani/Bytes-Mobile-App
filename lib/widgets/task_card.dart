import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String desc;
  final String startDate;
  final String endDate;
  final String status;
  final Color statusColor;
  final Color cardColor;

  const TaskCard({
    super.key,
    required this.title,
    required this.desc,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.statusColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(status == "Kerjakan" ? Icons.warning_amber_rounded : Icons.check_circle, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status, style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.file_copy_outlined, desc),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today_outlined, startDate),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.timer_outlined, endDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text("|  $text", style: const TextStyle(color: Colors.white, fontSize: 12))),
      ],
    );
  }
}
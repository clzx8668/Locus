import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text('日历日程模块正在规划中',
                style: TextStyle(fontSize: 16, color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

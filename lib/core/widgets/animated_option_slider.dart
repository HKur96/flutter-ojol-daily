// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:ojol_daily/core/config/enum.dart';

class AnimatedOptionSlider extends StatefulWidget {
  final ValueChanged<DailyType> onSelectionChanged;

  const AnimatedOptionSlider({super.key, required this.onSelectionChanged});

  @override
  State<AnimatedOptionSlider> createState() => _AnimatedOptionSliderState();
}

class _AnimatedOptionSliderState extends State<AnimatedOptionSlider> {
  DailyType _dailyType = DailyType.income;

  void _toggleSelection(DailyType dailyType) {
    if (_dailyType == dailyType) return;
    setState(() {
      _dailyType = dailyType;
    });
    widget.onSelectionChanged(_dailyType);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _dailyType == DailyType.income
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: _dailyType == DailyType.income
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_dailyType == DailyType.income
                                  ? Colors.green
                                  : Colors.red)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleSelection(DailyType.income),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dailyType == DailyType.income
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text('Pendapatan'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleSelection(DailyType.expense),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dailyType == DailyType.expense
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text('Pengeluaran'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

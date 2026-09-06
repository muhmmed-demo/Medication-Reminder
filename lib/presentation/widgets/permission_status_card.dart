import 'package:flutter/material.dart';
import '../../services/permission_service.dart';
import '../../core/di/injection_container.dart';

/// بطاقة عرض حالة الإذونات في الشاشة الرئيسية
/// تُظهر كل إذن بمؤشر أخضر/أحمر واضح لكبار السن
class PermissionStatusCard extends StatefulWidget {
  /// كولباك عند الضغط على "إصلاح" — لفتح شاشة الإعداد
  final VoidCallback onFixPressed;

  const PermissionStatusCard({
    super.key,
    required this.onFixPressed,
  });

  @override
  State<PermissionStatusCard> createState() => _PermissionStatusCardState();
}

class _PermissionStatusCardState extends State<PermissionStatusCard> {
  PermissionStatusModel? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final status = await sl<PermissionService>().checkAllPermissionsStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final status = _status!;

    // إذا كانت جميع الأذونات الحرجة مُفعَّلة، لا نعرض البطاقة
    if (status.criticalGranted) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 26),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'نظام التنبيهات يحتاج إعداد',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _refresh,
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280), size: 22),
                ),
              ],
            ),
          ),

          // قائمة الأذونات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _PermissionRow(
                  icon: Icons.notifications_rounded,
                  label: 'إشعارات الدواء',
                  granted: status.notifications,
                  description: 'تنبيهات الدواء على شاشة الهاتف',
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  icon: Icons.alarm_rounded,
                  label: 'منبه دقيق الموعد',
                  granted: status.exactAlarm,
                  description: 'ضروري لرنين المنبه في الوقت المحدد',
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'عدم إيقاف التطبيق',
                  granted: status.batteryOptimization,
                  description: 'يمنع الجهاز من إيقاف المنبه',
                ),
              ],
            ),
          ),

          // زر الإصلاح الكبير
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onFixPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.build_rounded, size: 22),
                label: const Text('إعداد التنبيهات الآن ⚙️'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// صف واحد يُمثل حالة إذن معين
class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool granted;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    final color = granted ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bgColor = granted
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 26,
          ),
        ],
      ),
    );
  }
}

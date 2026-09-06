import 'package:flutter/material.dart';
import '../../../core/di/injection_container.dart';
import '../../../services/permission_service.dart';
import '../../../services/notification_service.dart';

/// شاشة إعداد الإشعارات خطوة بخطوة — مُصمَّمة لكبار السن
/// تشرح كل إذن بلغة واضحة وأيقونات كبيرة ملونة
class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() => _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  int _currentStep = 0;
  bool _notifGranted = false;
  bool _exactAlarmGranted = false;
  bool _batteryGranted = false;
  bool _testSent = false;
  bool _loadingStep = false;

  final _permissionService = sl<PermissionService>();
  final _notificationService = sl<NotificationService>();

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    final status = await _permissionService.checkAllPermissionsStatus();
    if (mounted) {
      setState(() {
        _notifGranted = status.notifications;
        _exactAlarmGranted = status.exactAlarm;
        _batteryGranted = status.batteryOptimization;
        // إذا كانت بعض الأذونات ممنوحة مسبقاً، ننتقل للخطوة المناسبة
        if (_notifGranted && _exactAlarmGranted) {
          _currentStep = 2;
        } else if (_notifGranted) {
          _currentStep = 1;
        }
      });
    }
  }

  Future<void> _handleStepAction() async {
    setState(() => _loadingStep = true);

    switch (_currentStep) {
      case 0:
        // طلب إذن الإشعارات
        final granted = await _permissionService.requestNotificationPermission();
        setState(() {
          _notifGranted = granted;
          _loadingStep = false;
          if (granted) _currentStep = 1;
        });
        if (!granted && mounted) {
          _showDeniedDialog(
            'إذن الإشعارات مرفوض',
            'بدون هذا الإذن، لن يظهر أي تنبيه عند حلول موعد الدواء.\n\nيُرجى الذهاب للإعدادات وتفعيله.',
          );
        }
        break;

      case 1:
        // فتح إعدادات المنبه الدقيق
        await _permissionService.requestExactAlarmPermission();
        // نُعطي المستخدم وقتاً للعودة ثم نتحقق
        await Future.delayed(const Duration(milliseconds: 500));
        final exact = await _permissionService.isExactAlarmGranted();
        if (mounted) {
          setState(() {
            _exactAlarmGranted = exact;
            _loadingStep = false;
            if (exact) _currentStep = 2;
          });
        }
        break;

      case 2:
        // طلب إعفاء البطارية
        final granted = await _permissionService.requestBatteryOptimizationExemption();
        setState(() {
          _batteryGranted = granted;
          _loadingStep = false;
          _currentStep = 3; // ننتقل للخطوة الأخيرة دائماً
        });
        break;

      case 3:
        // اختبار المنبه
        await _notificationService.showTestNotification();
        setState(() {
          _testSent = true;
          _loadingStep = false;
        });
        break;
    }
  }

  Future<void> _recheckStep1() async {
    setState(() => _loadingStep = true);
    final exact = await _permissionService.isExactAlarmGranted();
    if (mounted) {
      setState(() {
        _exactAlarmGranted = exact;
        _loadingStep = false;
        if (exact) _currentStep = 2;
      });
    }
  }

  void _showDeniedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('إعداد التنبيهات'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep < 3
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'إغلاق',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            // Action Button at bottom
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 12,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDone
                      ? const Color(0xFF10B981)
                      : isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'الخطوة ${_currentStep + 1} من 4',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _StepCard(
          key: const ValueKey(0),
          icon: Icons.notifications_active_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFDBEAFE),
          stepNumber: '١',
          title: 'إذن الإشعارات',
          subtitle: 'لكي يُنبهك الهاتف عند حلول وقت الدواء',
          description:
              'هذا الإذن يُتيح للتطبيق إرسال تنبيه يظهر على شاشة هاتفك حتى لو كان مُقفلاً.\n\n'
              '👵 بدون هذا الإذن، لن يرن المنبه ولن تعرف أن موعد دوائك قد حان.',
          alreadyGranted: _notifGranted,
          grantedMessage: '✅ تم منح الإذن بنجاح',
        );

      case 1:
        return _StepCard(
          key: const ValueKey(1),
          icon: Icons.alarm_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
          stepNumber: '٢',
          title: 'إذن المنبه الدقيق',
          subtitle: 'لكي يرن المنبه في الوقت المحدد بالدقيقة',
          description:
              'ستفتح صفحة من إعدادات الهاتف.\n\n'
              '📌 ابحث عن اسم التطبيق "منبه الدواء" ثم اضغط عليه وفعِّل الخيار.\n\n'
              '⚠️ هذا الإذن ضروري جداً — بدونه قد يتأخر المنبه أو لا يرن أصلاً.',
          alreadyGranted: _exactAlarmGranted,
          grantedMessage: '✅ المنبه الدقيق مُفعَّل',
          extraWidget: _exactAlarmGranted
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: _loadingStep ? null : _recheckStep1,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تحقق من التفعيل بعد العودة'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        );

      case 2:
        return _StepCard(
          key: const ValueKey(2),
          icon: Icons.battery_charging_full_rounded,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFD1FAE5),
          stepNumber: '٣',
          title: 'منع إيقاف التطبيق',
          subtitle: 'لضمان أن المنبه يرن حتى لو أُغلق التطبيق',
          description:
              'بعض الهواتف (مثل Xiaomi وSamsung وHuawei) تُوقف التطبيقات في الخلفية لتوفير البطارية.\n\n'
              '🔋 هذا الإذن يُعطي التطبيق الأولوية لكي لا يُوقفه الجهاز عند حلول موعد الدواء.\n\n'
              '✨ هذا الخيار اختياري، لكن ننصح به بشدة.',
          alreadyGranted: _batteryGranted,
          grantedMessage: '✅ التطبيق محمي من الإيقاف',
        );

      case 3:
        return _SuccessStep(
          key: const ValueKey(3),
          notifGranted: _notifGranted,
          exactAlarmGranted: _exactAlarmGranted,
          batteryGranted: _batteryGranted,
          testSent: _testSent,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton() {
    if (_currentStep == 3) {
      // شاشة النجاح — زر إغلاق
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.home_rounded, size: 26),
          label: const Text('العودة للرئيسية 🏠'),
        ),
      );
    }

    String buttonLabel;
    IconData buttonIcon;
    Color buttonColor;

    if (_currentStep == 0) {
      buttonLabel = _notifGranted ? 'التالي ←' : 'السماح بالإشعارات 🔔';
      buttonIcon = _notifGranted ? Icons.arrow_forward_rounded : Icons.notifications_active_rounded;
      buttonColor = const Color(0xFF2563EB);
    } else if (_currentStep == 1) {
      buttonLabel = _exactAlarmGranted ? 'التالي ←' : 'فتح الإعدادات ⚙️';
      buttonIcon = _exactAlarmGranted ? Icons.arrow_forward_rounded : Icons.settings_rounded;
      buttonColor = const Color(0xFFF59E0B);
    } else {
      buttonLabel = _batteryGranted ? 'التالي ←' : 'تفعيل الحماية 🔋';
      buttonIcon = _batteryGranted
          ? Icons.arrow_forward_rounded
          : Icons.battery_charging_full_rounded;
      buttonColor = const Color(0xFF10B981);
    }

    // إذا كان الإذن ممنوحاً، يكفي الضغط للمتابعة فقط
    final bool alreadyGranted = (_currentStep == 0 && _notifGranted) ||
        (_currentStep == 1 && _exactAlarmGranted) ||
        (_currentStep == 2 && _batteryGranted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingStep
                  ? null
                  : alreadyGranted
                      ? () => setState(() => _currentStep++)
                      : _handleStepAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              icon: _loadingStep
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(buttonIcon, size: 24),
              label: Text(buttonLabel),
            ),
          ),
          // زر تخطي للخطوات غير الحرجة
          if (_currentStep == 2)
            TextButton(
              onPressed: () => setState(() => _currentStep = 3),
              child: const Text(
                'تخطي هذه الخطوة',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Widget مساعد: بطاقة الخطوة
// ═══════════════════════════════════════════════════════
class _StepCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String stepNumber;
  final String title;
  final String subtitle;
  final String description;
  final bool alreadyGranted;
  final String grantedMessage;
  final Widget? extraWidget;

  const _StepCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.alreadyGranted,
    required this.grantedMessage,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // أيقونة الخطوة الكبيرة
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 54, color: iconColor),
        ),
        const SizedBox(height: 16),
        // رقم الخطوة
        Text(
          'الخطوة $stepNumber',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: iconColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        // عنوان الخطوة
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),
        // بطاقة الوصف
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF374151),
              height: 1.7,
            ),
          ),
        ),
        // مؤشر النجاح إذا كان الإذن ممنوحاً
        if (alreadyGranted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 8),
                Text(
                  grantedMessage,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (extraWidget != null) extraWidget!,
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Widget مساعد: شاشة النجاح النهائية
// ═══════════════════════════════════════════════════════
class _SuccessStep extends StatelessWidget {
  final bool notifGranted;
  final bool exactAlarmGranted;
  final bool batteryGranted;
  final bool testSent;

  const _SuccessStep({
    super.key,
    required this.notifGranted,
    required this.exactAlarmGranted,
    required this.batteryGranted,
    required this.testSent,
  });

  @override
  Widget build(BuildContext context) {
    final allCritical = notifGranted && exactAlarmGranted;

    return Column(
      children: [
        const SizedBox(height: 24),
        // أيقونة النجاح
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: allCritical
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            allCritical ? Icons.celebration_rounded : Icons.warning_amber_rounded,
            size: 60,
            color: allCritical ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          allCritical ? '🎉 أنت جاهز تماماً!' : '⚠️ بعض الأذونات غير مُفعَّلة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: allCritical ? const Color(0xFF065F46) : const Color(0xFF92400E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          allCritical
              ? 'ستصلك تنبيهات الدواء في الوقت المحدد بشكل موثوق'
              : 'يُنصح بإعداد جميع الأذونات لضمان عمل المنبه',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.5),
        ),
        const SizedBox(height: 24),
        // ملخص الأذونات
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _SummaryRow(label: '🔔 الإشعارات', granted: notifGranted),
              const Divider(height: 16),
              _SummaryRow(label: '⏰ المنبه الدقيق', granted: exactAlarmGranted),
              const Divider(height: 16),
              _SummaryRow(label: '🔋 حماية البطارية', granted: batteryGranted),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // زر اختبار المنبه
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await sl<NotificationService>().showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 تم إرسال إشعار تجريبي — انتظر رنين المنبه!'),
                    backgroundColor: Color(0xFF2563EB),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.volume_up_rounded, size: 24),
            label: const Text('اختبر المنبه الآن 🔔'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final bool granted;

  const _SummaryRow({required this.label, required this.granted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: granted ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            granted ? 'مُفعَّل ✅' : 'غير مُفعَّل ❌',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: granted ? const Color(0xFF065F46) : const Color(0xFF991B1B),
            ),
          ),
        ),
      ],
    );
  }
}

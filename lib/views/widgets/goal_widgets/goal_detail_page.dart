// Hedef Detay Sayfası
import 'package:flutter/material.dart';
import 'package:test_borsa/utils/amount_parser.dart';
import 'package:easy_conffeti/easy_conffeti.dart';

import '../../../models/goal_model.dart';
import '../../../services/goal_service.dart';
import '../../../utils/error_handler.dart';
import '../../goal_page.dart';
import 'build_info_card.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  final VoidCallback onUpdate;

  const GoalDetailPage({super.key, required this.goal, required this.onUpdate});

  @override
  _GoalDetailPageState createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late Goal currentGoal;

  @override
  void initState() {
    super.initState();
    currentGoal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    final remainingAmount =
        currentGoal.targetAmount - currentGoal.currentAmount;
    final progressPercent = (currentGoal.progress * 100).clamp(0, 100);
    final isCompleted = currentGoal.progress >= 1.0;
    final isOverdue =
        currentGoal.targetDate != null &&
        currentGoal.targetDate!.isBefore(DateTime.now()) &&
        !isCompleted;

    int? daysLeft;
    if (currentGoal.targetDate != null && !isCompleted) {
      daysLeft = currentGoal.targetDate!.difference(DateTime.now()).inDays;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hedef Detayları'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: () => _editGoal()),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana kart
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentGoal.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Icon(Icons.check_circle, color: Colors.white, size: 32),
                    ],
                  ),
                  SizedBox(height: 20),

                  // İlerleme yüzdesi
                  Text(
                    '%${progressPercent.toInt()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'tamamlandı',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 20),

                  // İlerleme çubuğu
                  LinearProgressIndicator(
                    value: currentGoal.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Tutar bilgileri
            Row(
              children: [
                Expanded(
                  child: buildInfoCard(
                    'Mevcut Tutar',
                    '₺${_formatMoney(currentGoal.currentAmount)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: buildInfoCard(
                    'Hedef Tutar',
                    '₺${_formatMoney(currentGoal.targetAmount)}',
                    Icons.flag,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            if (!isCompleted)
              buildInfoCard(
                'Kalan Tutar',
                '₺${_formatMoney(remainingAmount)}',
                Icons.trending_up,
                Colors.orange,
              ),

            SizedBox(height: 24),

            // Tarih bilgileri
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarih Bilgileri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.grey[600], size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Oluşturulma Tarihi',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatDate(currentGoal.createdAt),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (currentGoal.targetDate != null) ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hedef Tarihi',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDate(currentGoal.targetDate!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: isOverdue ? Colors.red : Colors.black,
                                ),
                              ),
                              if (daysLeft != null)
                                Text(
                                  isCompleted
                                      ? 'Hedef tamamlandı'
                                      : isOverdue
                                      ? '${daysLeft.abs()} gün gecikti'
                                      : '$daysLeft gün kaldı',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? Colors.green
                                        : isOverdue
                                        ? Colors.red
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24),

            // İlerleme güncelleme butonu
            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showUpdateProgressDialog,
                  icon: Icon(Icons.add),
                  label: Text('İlerleme Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUpdateProgressDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('İlerleme Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mevcut tutar: ₺${_formatMoney(currentGoal.currentAmount)}'),
            Text('Hedef tutar: ₺${_formatMoney(currentGoal.targetAmount)}'),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Eklenecek tutar',
                prefixText: '₺',
                border: OutlineInputBorder(),
                helperText: 'Mevcut tutarın üzerine eklenir',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final added = parseAmount(amountController.text);
              if (added != null && added > 0) {
                final newAmount = currentGoal.currentAmount + added;
                try {
                  await GoalService.updateProgress(currentGoal.id, newAmount);
                  // ⚠️ DEĞİŞTİ: updatedGoal yerine manuel güncelleme
                  setState(() {
                    currentGoal = currentGoal.copyWith(
                      currentAmount: newAmount,
                    );
                  });
                  widget.onUpdate();
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (newAmount >= currentGoal.targetAmount) {
                    if (!mounted) return;
                    await ConfettiHelper.showConfettiDialog(
                      confettiType: ConfettiType.celebration,
                      confettiStyle: ConfettiStyle.star,
                      animationStyle: AnimationConfetti.fireworks,
                      colorTheme: ConfettiColorTheme.rainbow,
                      message: "Tebrikler! Hedefinize ulaştınız! 🎉",
                      durationInSeconds: 3, 
                      context: context,
                    );
                  }

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('İlerleme güncellendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ErrorHandler.showErrorSnackBar(context, e);
                }
              }
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _editGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Form kapandıktan sonra mesajlar bu sayfanın context'iyle gösterilsin
        builder: (_) => AddEditGoalPage(
          userId: currentGoal.userId,
          goal: currentGoal,
          onSave: (updatedGoal) async {
            try {
              await GoalService.updateGoal(updatedGoal);
              // ⚠️ DEĞİŞTİ: newGoal yerine manuel güncelleme
              setState(() => currentGoal = updatedGoal);
              widget.onUpdate();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hedef güncellendi!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ErrorHandler.showErrorSnackBar(context, e);
            }
          },
        ),
      ),
    );
  }
}

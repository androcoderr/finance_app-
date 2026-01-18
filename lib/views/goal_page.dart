import 'package:easy_conffeti/easy_conffeti.dart';
import 'package:flutter/material.dart';
import 'package:test_borsa/views/widgets/goal_widgets/goal_detail_page.dart';
import '../models/FinancialAnalysisResult.dart';
import '../models/goal_model.dart';
import '../services/Exceptions/token_expired_exception.dart';
import '../services/goal_service.dart';
import '../utils/error_handler.dart';

// Ana Hedefler Sayfası
class GoalsPage extends StatefulWidget {
  final String userId;

  const GoalsPage({super.key, required this.userId});

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  List<Goal> goals = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadGoals() async {
    try {
      setState(() => isLoading = true);
      final loadedGoals = await GoalService.getGoals(widget.userId, context);
      setState(() {
        goals = loadedGoals;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Load Goals Error: $e');
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  List<Goal> getActiveGoals() {
    return goals.where((goal) => goal.progress < 1.0).toList();
  }

  List<Goal> getCompletedGoals() {
    return goals.where((goal) => goal.progress >= 1.0).toList();
  }

  List<Goal> getOverdueGoals() {
    final now = DateTime.now();
    return goals
        .where(
          (goal) =>
              goal.targetDate != null &&
              goal.targetDate!.isBefore(now) &&
              goal.progress < 1.0,
        )
        .toList();
  }

  double getTotalTargetAmount() {
    return goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  double getTotalCurrentAmount() {
    return goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  double getAverageProgress() {
    if (goals.isEmpty) return 0.0;
    return goals.fold(0.0, (sum, goal) => sum + goal.progress) / goals.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Finansal Hedeflerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        //backgroundColor: Colors.white,
        //foregroundColor: Colors.black87,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: loadGoals)],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: 'Aktif (${getActiveGoals().length})'),
            Tab(text: 'Tamamlanan (${getCompletedGoals().length})'),
            Tab(text: 'Geciken (${getOverdueGoals().length})'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Özet İstatistikler
                // Tab İçeriği
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoalsList(getActiveGoals()),
                      _buildGoalsList(getCompletedGoals()),
                      _buildGoalsList(getOverdueGoals()),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(),
        icon: Icon(Icons.add),
        label: Text('Yeni Hedef'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goalsList) {
    if (goalsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'Henüz hedef yok',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yeni bir finansal hedef ekleyerek başlayın',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: goalsList.length,
      itemBuilder: (context, index) {
        final goal = goalsList[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final remainingAmount = goal.targetAmount - goal.currentAmount;
    final progressPercent = (goal.progress * 100).clamp(0, 100);
    final isCompleted = goal.progress >= 1.0;
    final isOverdue =
        goal.targetDate != null &&
        goal.targetDate!.isBefore(DateTime.now()) &&
        !isCompleted;

    int? daysLeft;
    if (goal.targetDate != null && !isCompleted) {
      daysLeft = goal.targetDate!.difference(DateTime.now()).inDays;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOverdue
            ? BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showGoalDetails(goal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve menü
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name, // DEĞİŞTİ: goal.title -> goal.name
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tamamlandı',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, size: 18),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'progress',
                        child: Row(
                          children: [
                            Icon(Icons.trending_up, size: 16),
                            SizedBox(width: 8),
                            Text('İlerleme Ekle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sil',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'progress':
                          _showUpdateProgressDialog(goal);
                          break;
                        case 'edit':
                          _showEditGoalDialog(goal);
                          break;
                        case 'delete':
                          _deleteGoal(goal.id);
                          break;
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Tutar bilgileri
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mevcut Tutar',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '₺${_formatMoney(goal.currentAmount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Hedef Tutar',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '₺${_formatMoney(goal.targetAmount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (!isCompleted) ...[
                SizedBox(height: 8),
                Text(
                  'Kalan: ₺${_formatMoney(remainingAmount)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              SizedBox(height: 16),

              // İlerleme çubuğu
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İlerleme: %${progressPercent.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (goal.targetDate != null)
                        Text(
                          isCompleted
                              ? 'Tamamlandı'
                              : isOverdue
                              ? '${daysLeft!.abs()} gün gecikti'
                              : '$daysLeft gün kaldı',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.green
                                : isOverdue
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goal.progress.clamp(0.0, 1.0),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? Colors.green
                          : isOverdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(
                      4,
                    ), // Köşeleri yuvarlatmak için
                  ),
                ],
              ),

              // Tarih bilgisi
              if (goal.targetDate != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Hedef: ${_formatDate(goal.targetDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],

              // Oluşturulma tarihi
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                  SizedBox(width: 4),
                  Text(
                    'Oluşturuldu: ${_formatDate(goal.createdAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
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

  void _showAddGoalDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditGoalPage(
          userId: widget.userId,
          onSave: (goal) async {
            String newGoalId;

            try {
              // 1. ADIM: Hedefi oluştur (GoalService'in de context aldığını varsayıyoruz)
              newGoalId = await GoalService.createGoal(goal, goal.targetDate!);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hedef eklendi! Şimdi analiz ediliyor...'),
                  backgroundColor: Colors.green,
                ),
              );

              // 2. ADIM: YENİ servisi kullanarak analizi tetikle
              // Token'ı düşünmüyoruz, servis hallediyor. Sadece context'i ver.
              final analysisResult = await GoalService.getFinanceAnalysis(
                newGoalId,
                context,
              );

              // 3. ADIM: Analiz sonucunu göster
              // Bu fonksiyonun bu sayfada tanımlı olduğunu varsayıyoruz
              _showAnalysisResultDialog(analysisResult);

              // 4. ADIM: Listeyi yenile
              loadGoals();
            } on TokenExpiredException {
              // Servisler hatayı yakalayıp login'e attı.
              // Burası sadece hatanın sayfaya yayılmasını engeller.
              print("Token expired, navigation handled by service.");
            } catch (e) {
              // Diğer tüm hatalar (hedef oluşturma, analiz vs.)
              ErrorHandler.showErrorSnackBar(context, e);
            }
          },
        ),
      ),
    );
  }

  // 4. ADIM: Sonuçları göstermek için YENİ bir dialog fonksiyonu
  // (Bu fonksiyonu _GoalsPageState sınıfınızın içine ekleyin)
  void _showAnalysisResultDialog(FinancialAnalysisResult result) {
    // Helper fonksiyon (Aynı kalabilir)
    String formatMoney(double amount) {
      if (amount >= 1000000) {
        return '${(amount / 1000000).toStringAsFixed(1)}M';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      } else {
        return amount.toStringAsFixed(0);
      }
    }

    // DÜZELTME: Değerleri doğrudan kullanın, bölmeyin veya yeniden hesaplamayın.
    final completionProb = result.completionProbability; // Örn: 87.0
    final risk =
        100 -
        result
            .completionProbability; // Örn: 13.0 (Backend'den gelen gerçek risk)

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📈 Finansal Analiz Sonucu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modelinize göre tavsiyeler:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.savings, color: Colors.green),
              title: Text('Aylık Tasarruf Önerisi'),
              subtitle: Text(
                '₺${formatMoney(result.recommendedMonthlySavings)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.blue),
              title: Text('Tamamlama Olasılığı'),
              // DÜZELTME: Doğrudan değişkeni yazdırın
              subtitle: Text(
                '%${completionProb.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Risk Seviyesi'),
              // DÜZELTME: Backend'den gelen riski yazdırın
              subtitle: Text(
                '%${risk.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // İsterseniz backend'den gelen açıklamayı da ekleyebilirsiniz
            if (result.description != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Text(
                  result.description!,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditGoalPage(
          userId: widget.userId,
          goal: goal,
          onSave: (updatedGoal) async {
            try {
              await GoalService.updateGoal(updatedGoal);
              loadGoals();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hedef güncellendi!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ErrorHandler.showErrorSnackBar(context, e);
            }
          },
        ),
      ),
    );
  }

  void _showUpdateProgressDialog(Goal goal) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('İlerleme Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mevcut tutar: ₺${_formatMoney(goal.currentAmount)}'),
            Text('Hedef tutar: ₺${_formatMoney(goal.targetAmount)}'),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yeni tutar',
                prefixText: '₺',
                border: OutlineInputBorder(),
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
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null && newAmount >= 0) {
                try {
                  await GoalService.updateProgress(goal.id, newAmount);
                  loadGoals();
                  Navigator.pop(dialogContext);
                  
                  if (newAmount >= goal.targetAmount) {
                    await ConfettiHelper.showConfettiDialog(
                      confettiType: ConfettiType.celebration,
                      confettiStyle: ConfettiStyle.star,
                      animationStyle: AnimationConfetti.fireworks,
                      colorTheme: ConfettiColorTheme.rainbow,
                      message: "Tebrikler! Hedefinize ulaştınız! 🎉",
                      durationInSeconds: 3, 
                      context: context, // Sayfa context'i
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('İlerleme güncellendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
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

  void _showGoalDetails(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailPage(goal: goal, onUpdate: loadGoals),
      ),
    );
  }

  Future<void> _deleteGoal(String goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hedefi Sil'),
        content: Text('Bu hedefi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GoalService.deleteGoal(goalId);
        loadGoals();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hedef silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }
}

// Hedef Ekleme/Düzenleme Sayfası
class AddEditGoalPage extends StatefulWidget {
  final String userId;
  final Goal? goal;
  final Function(Goal) onSave;

  const AddEditGoalPage({
    super.key,
    required this.userId,
    this.goal,
    required this.onSave,
  });

  @override
  _AddEditGoalPageState createState() => _AddEditGoalPageState();
}

class _AddEditGoalPageState extends State<AddEditGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController =
      TextEditingController(); // DEĞİŞTİ: _titleController -> _nameController
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();

  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text =
          widget.goal!.name; // DEĞİŞTİ: goal.title -> goal.name
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _targetDate = widget.goal!.targetDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Yeni Hedef' : 'Hedef Düzenle'),
        // backgroundColor: Colors.white,
        // foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Hedef Adı
            TextFormField(
              controller:
                  _nameController, // DEĞİŞTİ: _titleController -> _nameController
              decoration: InputDecoration(
                labelText:
                    'Hedef Adı', // DEĞİŞTİ: 'Hedef Başlığı' -> 'Hedef Adı'
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.flag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hedef adı gerekli';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Hedef tutar
            TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hedef Tutar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '₺',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hedef tutar gerekli';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Mevcut tutar
            TextFormField(
              controller: _currentAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Mevcut Tutar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.account_balance_wallet),
                prefixText: '₺',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Geçerli bir tutar girin';
                  }
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Hedef tarihi
            ListTile(
              title: Text('Hedef Tarihi (Opsiyonel)'),
              subtitle: Text(
                _targetDate != null
                    ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                    : 'Tarih seçilmedi',
              ),
              leading: Icon(Icons.calendar_today),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_targetDate != null)
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => setState(() => _targetDate = null),
                    ),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _targetDate ?? DateTime.now().add(Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365 * 10)),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),

            SizedBox(height: 32),

            // Kaydet butonu
            ElevatedButton(
              onPressed: _saveGoal,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.goal == null ? 'Hedef Oluştur' : 'Güncelle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        id: widget.goal?.id ?? '', // Backend UUID oluşturacak
        userId: widget.userId,
        name: _nameController.text, // DEĞİŞTİ: title -> name
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: double.tryParse(_currentAmountController.text) ?? 0.0,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
        targetDate: _targetDate,
      );

      widget.onSave(goal);
      Navigator.pop(context);
    }
  }
}

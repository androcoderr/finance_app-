import 'package:test_borsa/utils/amount_parser.dart';
import 'package:flutter/material.dart';
import 'widgets/ui/celebration.dart';
import 'package:intl/intl.dart';
import 'package:test_borsa/views/widgets/goal_widgets/goal_detail_page.dart';
import 'widgets/goal_widgets/goal_style.dart';
import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';
import '../models/goal_model.dart';
import '../services/Exceptions/token_expired_exception.dart';
import '../services/goal_service.dart';
import '../utils/error_handler.dart';

// Ana Hedefler Sayfası
class GoalsPage extends StatefulWidget {
  final String userId;

  const GoalsPage({super.key, required this.userId});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  List<Goal> goals = [];
  bool isLoading = true;
  String? _loadError; // Yüklenemediyse (çevrimdışı vb.) boş liste gösterilmez
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
        _loadError = null;
      });
    } catch (e) {
      debugPrint('❌ Load Goals Error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _loadError = ErrorHandler.getErrorMessage(e);
      });
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

  int _filter = 0; // 0: aktif, 1: tamamlanan, 2: geciken

  List<Goal> get _filteredGoals => switch (_filter) {
        1 => getCompletedGoals(),
        2 => getOverdueGoals(),
        _ => getActiveGoals(),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final completed = getCompletedGoals();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedeflerim'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              tooltip: 'Yeni hedef',
              style: IconButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.onInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              icon: const Icon(Icons.add),
              onPressed: _showAddGoalDialog,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null && goals.isEmpty
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Hedefler yüklenemedi',
              subtitle: _loadError,
              action: OutlinedButton.icon(
                onPressed: loadGoals,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadGoals,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.sm,
                  AppSpace.page,
                  AppSpace.xl,
                ),
                children: [
                  const Overline('Toplam birikim'),
                  const SizedBox(height: 6),
                  MoneyText(getTotalCurrentAmount(), fontSize: 36),
                  if (goals.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${goals.length} hedefin toplamı ${Money.format(getTotalTargetAmount())} · '
                      'ortalama ${Money.percent(getAverageProgress() * 100)}',
                      style: TextStyle(color: c.textMuted),
                    ),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.lg),
                    _CelebrationCard(goal: completed.first),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  _FilterChips(
                    selected: _filter,
                    counts: [
                      getActiveGoals().length,
                      completed.length,
                      getOverdueGoals().length,
                    ],
                    onChanged: (i) => setState(() => _filter = i),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _buildGoalsGrid(_filteredGoals),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalsGrid(List<Goal> list) {
    if (goals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.xl),
        child: EmptyState(
          icon: Icons.flag_outlined,
          title: 'Henüz hedefin yok',
          subtitle: 'Tatil, araba ya da acil durum fonu… Bir hedef koy, ilerlemeni takip et.',
          action: SizedBox(
            width: 200,
            child: AppButton(
              label: 'Hedef ekle',
              icon: Icons.add,
              onPressed: _showAddGoalDialog,
            ),
          ),
        ),
      );
    }
    final showNewTile = _filter == 0;
    final count = list.length + (showNewTile ? 1 : 0);
    if (count == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpace.xl),
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Bu listede hedef yok',
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      // Sabit yükseklik + yazı boyutuyla büyüyen kısım (büyük yazıda taşmasın)
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 100 + MediaQuery.textScalerOf(context).scale(110),
      ),
      itemBuilder: (context, i) {
        if (i == list.length) return _NewGoalTile(onTap: _showAddGoalDialog);
        return _buildGoalCard(list[i]);
      },
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final c = context.colors;
    final style = goalStyle(goal);
    final tone = context.tone(style.tone);
    final progress = goal.progress.clamp(0.0, 1.0);
    final isCompleted = goal.progress >= 1.0;
    final isOverdue = goal.targetDate != null &&
        goal.targetDate!.isBefore(DateTime.now()) &&
        !isCompleted;
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays;

    return Material(
      color: tone.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showGoalDetails(goal),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tone.foreground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(style.icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert, color: c.textMuted, size: 20),
                      onSelected: (v) {
                        switch (v) {
                          case 'progress':
                            _showUpdateProgressDialog(goal);
                          case 'edit':
                            _showEditGoalDialog(goal);
                          case 'delete':
                            _deleteGoal(goal.id);
                        }
                      },
                      itemBuilder: (_) => [
                        if (!isCompleted)
                          const PopupMenuItem(
                            value: 'progress',
                            child: Text('Birikim ekle'),
                          ),
                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Sil', style: TextStyle(color: c.expense)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                goal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Money.percent(progress * 100),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        color: tone.foreground,
                        backgroundColor: c.surface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${Money.format(goal.currentAmount)} / ${Money.format(goal.targetAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                    if (isOverdue)
                      Text(
                        'Süresi geçti',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.expense,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (daysLeft != null && !isCompleted)
                      Text(
                        '$daysLeft gün kaldı',
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Form kapandıktan sonra mesajlar bu sayfanın context'iyle gösterilsin
        builder: (_) => AddEditGoalPage(
          userId: widget.userId,
          onSave: (goal) async {
            try {
              await GoalService.createGoal(goal, goal.targetDate);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hedef eklendi!')),
              );
              loadGoals();
            } on TokenExpiredException {
              // Servisler hatayı yakalayıp login'e attı.
              // Burası sadece hatanın sayfaya yayılmasını engeller.
            } catch (e) {
              // Diğer tüm hatalar (hedef oluşturma, analiz vs.)
              if (!mounted) return;
              ErrorHandler.showErrorSnackBar(context, e);
            }
          },
        ),
      ),
    );
  }

  void _showEditGoalDialog(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Form kapandıktan sonra mesajlar bu sayfanın context'iyle gösterilsin
        builder: (_) => AddEditGoalPage(
          userId: widget.userId,
          goal: goal,
          onSave: (updatedGoal) async {
            try {
              await GoalService.updateGoal(updatedGoal);
              loadGoals();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hedef güncellendi!'),
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

  void _showUpdateProgressDialog(Goal goal) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Birikim ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biriken: ${Money.format(goal.currentAmount)}'),
            Text('Hedef: ${Money.format(goal.targetAmount)}'),
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
                final newAmount = goal.currentAmount + added;
                try {
                  await GoalService.updateProgress(goal.id, newAmount);
                  loadGoals();
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  
                  if (newAmount >= goal.targetAmount) {
                    if (!mounted) return;
                    await showGoalCelebration(context, goal.name);
                  }

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('İlerleme güncellendi!'),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hedef silindi'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
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
  State<AddEditGoalPage> createState() => _AddEditGoalPageState();
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
      final f = NumberFormat('#,##0.##', 'tr_TR');
      _targetAmountController.text = f.format(widget.goal!.targetAmount);
      _currentAmountController.text = f.format(widget.goal!.currentAmount);
      _targetDate = widget.goal!.targetDate;
    }
  }

  /// Hedef tarihine kadar her ay biriktirilmesi gereken tutar
  (double, int)? get _monthlyNeed {
    final target = parseAmount(_targetAmountController.text);
    final current = parseAmount(_currentAmountController.text) ?? 0;
    if (target == null || _targetDate == null || target <= current) return null;
    final now = DateTime.now();
    var months = (_targetDate!.year - now.year) * 12 + _targetDate!.month - now.month;
    if (months < 1) months = 1;
    return ((target - current) / months, months);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEdit = widget.goal != null;
    // Önizleme: ad yazıldıkça ikon güncellenir
    final preview = goalStyle(Goal(
      id: widget.goal?.id ?? 'yeni',
      userId: widget.userId,
      name: _nameController.text,
      targetAmount: 0,
      currentAmount: 0,
      createdAt: DateTime.now(),
    ));
    final tone = context.tone(preview.tone);
    final need = _monthlyNeed;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Hedefi düzenle' : 'Yeni hedef'),
        backgroundColor: tone.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: tone.background,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page, 0, AppSpace.page, AppSpace.xl),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tone.foreground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(preview.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: Text(
                      _nameController.text.trim().isEmpty
                          ? 'Hedefine bir ad ver'
                          : _nameController.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _nameController.text.trim().isEmpty
                                ? c.textFaint
                                : c.text,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.page),
                children: [
                  LabeledField(
                    label: 'Hedef adı',
                    child: TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Örn. Japonya tatili, Acil durum fonu',
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Hedef adı gerekli'
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Hedef tutar',
                          child: TextFormField(
                            controller: _targetAmountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixText: '₺ ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tutar gerekli';
                              }
                              final amount = parseAmount(value);
                              if (amount == null || amount <= 0) {
                                return 'Geçerli bir tutar gir';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: LabeledField(
                          label: 'Şu an biriken',
                          child: TextFormField(
                            controller: _currentAmountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixText: '₺ ',
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final amount = parseAmount(value);
                                if (amount == null || amount < 0) {
                                  return 'Geçerli bir tutar gir';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  LabeledField(
                    label: 'Son tarih (isteğe bağlı)',
                    child: Material(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _targetDate ??
                                DateTime.now().add(const Duration(days: 180)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) setState(() => _targetDate = date);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 18, color: c.textMuted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _targetDate == null
                                      ? 'Tarih seç'
                                      : DateFormat('d MMMM y', 'tr_TR')
                                          .format(_targetDate!),
                                  style: TextStyle(
                                    color: _targetDate == null ? c.textFaint : c.text,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_targetDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _targetDate = null),
                                  child: Icon(Icons.close, size: 18, color: c.textMuted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (need != null) ...[
                    const SizedBox(height: AppSpace.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      decoration: BoxDecoration(
                        color: c.ink,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hedefe ulaşmak için',
                            style: TextStyle(
                              color: c.onInk.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: Money.format(need.$1.ceilToDouble()),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ay · ${need.$2} ay',
                                  style: TextStyle(
                                    color: c.onInk.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(color: c.onInk),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.lg),
                child: AppButton(
                  label: isEdit ? 'Kaydet' : 'Hedefi oluştur',
                  icon: Icons.check,
                  onPressed: _saveGoal,
                ),
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
        targetAmount: parseAmount(_targetAmountController.text)!,
        currentAmount: parseAmount(_currentAmountController.text) ?? 0.0,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
        targetDate: _targetDate,
      );

      widget.onSave(goal);
      Navigator.pop(context);
    }
  }
}

class _FilterChips extends StatelessWidget {
  final int selected;
  final List<int> counts;
  final ValueChanged<int> onChanged;
  const _FilterChips({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const labels = ['Aktif', 'Tamamlanan', 'Geciken'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Material(
              color: selected == i ? c.ink : c.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    '${labels[i]} ${counts[i]}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected == i ? c.onInk : c.text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tamamlanan hedef için kutlama kartı
class _CelebrationCard extends StatelessWidget {
  final Goal goal;
  const _CelebrationCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: GridPattern(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.celebration_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'HEDEFE ULAŞILDI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Money.format(goal.targetAmount),
                      style: const TextStyle(color: Color(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewGoalTile extends StatelessWidget {
  final VoidCallback onTap;
  const _NewGoalTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: CustomPaint(
        painter: _DashedBorder(color: c.textFaint),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: c.textMuted, size: 28),
              const SizedBox(height: 6),
              Text(
                'Yeni hedef',
                style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  _DashedBorder({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppRadius.lg),
      ));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color;
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bill_model.dart';
import '../view_model/bill_view_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/user_view_model.dart';
import 'all_transactions_page.dart';
import 'analysis_screen.dart';
import 'bill_screen.dart';
import 'goal_page.dart';
import 'recurring_transaction_view.dart';
import 'widgets/home_widget/build_bottom_navigation_bar.dart';
import 'widgets/home_widget/build_drawer.dart';
import 'widgets/transaction_row.dart';
import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _billsRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Yaklaşan faturalar bölümü için faturaları bir kez yükle
    if (!_billsRequested) {
      final token = context.read<UserViewModel>().authToken;
      if (token != null) {
        _billsRequested = true;
        Future.microtask(() {
          if (mounted) context.read<BillsViewModel>().fetchBills(token);
        });
      }
    }
  }

  Future<void> _refresh(HomeViewModel vm) async {
    final token = context.read<UserViewModel>().authToken;
    await Future.wait([
      vm.refresh(),
      if (token != null) context.read<BillsViewModel>().fetchBills(token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewModel, UserViewModel>(
      builder: (context, vm, userVm, _) {
        if (!userVm.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const BrandSplash();
        }

        return Scaffold(
          endDrawer: DrawerWidget(viewModel: vm),
          bottomNavigationBar: buildBottomNavigationBar(context, vm),
          body: RefreshIndicator(
            onRefresh: () => _refresh(vm),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Durum çubuğu alanını mavi tut; kaydırınca içerik altından geçmesin
                const SliverAppBar(
                  pinned: true,
                  toolbarHeight: 0,
                  backgroundColor: AppColors.brandBlue,
                  surfaceTintColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                ),
                SliverToBoxAdapter(child: _Header(vm: vm)),
                SliverToBoxAdapter(child: _QuickActions(vm: vm)),
                if (vm.loadFailed)
                  SliverToBoxAdapter(
                    child: _OfflineCard(
                      stale: vm.hasData,
                      onRetry: () => _refresh(vm),
                    ),
                  ),
                const SliverToBoxAdapter(child: _UpcomingBills()),
                if (vm.hasData) ...[
                  SliverToBoxAdapter(child: _SpendingBreakdown(vm: vm)),
                  if (vm.hasGoals) SliverToBoxAdapter(child: _Goals(vm: vm)),
                  SliverToBoxAdapter(child: _RecentTransactions(vm: vm)),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xl)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Bağlantı yok uyarısı ────────────────────────────────────────────────────

class _OfflineCard extends StatefulWidget {
  /// true: eski veriler gösteriliyor (güncellenemedi); false: hiç yüklenemedi
  final bool stale;
  final Future<void> Function() onRetry;
  const _OfflineCard({required this.stale, required this.onRetry});

  @override
  State<_OfflineCard> createState() => _OfflineCardState();
}

class _OfflineCardState extends State<_OfflineCard> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.onRetry();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 0),
      child: AppCard(
        color: c.surfaceMuted,
        borderColor: Colors.transparent,
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: c.textMuted),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İnternet bağlantısı yok',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.stale
                        ? 'Gördüğün bilgiler güncel olmayabilir.'
                        : 'Bilgilerin yüklenemedi. Verilerin güvende; bağlanınca görünecek.',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _busy
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                : TextButton(onPressed: _retry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}

// ─── Üst mavi alan: karşılama, bakiye, bu ayın gelir/gideri ───────────────────

class _Header extends StatelessWidget {
  final HomeViewModel vm;
  const _Header({required this.vm});

  double _asset(String name) {
    for (final a in vm.assets) {
      if (a.name == name) return a.amount;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = vm.secretMoney;
    final income = vm.totalIncomeThisMonthPublic;
    final expense = vm.totalExpenseThisMonthPublic;
    final net = income - expense;
    // Çevrimdışı açılış: veri hiç gelmediyse ₺0 göstermek yanıltıcı olur
    final unknown = vm.loadFailed && !vm.hasData;
    const white70 = Color(0xB3FFFFFF);

    return GridPattern(
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, 8, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(
                    name: vm.currentUser?.name,
                    size: 42,
                    background: Colors.white,
                    foreground: AppColors.brandBlue,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Merhaba',
                          style: TextStyle(color: white70, fontSize: 13),
                        ),
                        Text(
                          vm.currentUser?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: hidden ? 'Tutarları göster' : 'Tutarları gizle',
                    color: Colors.white,
                    icon: Icon(
                      hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => vm.setSecretMoney(!hidden),
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Menü',
                      color: Colors.white,
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Overline('Toplam bakiye', color: white70),
              const SizedBox(height: 8),
              if (unknown)
                const Text(
                  '—',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                )
              else
                MoneyText(
                  _asset('Toplam Bakiye'),
                  fontSize: 42,
                  color: Colors.white,
                  hidden: hidden,
                ),
              const SizedBox(height: 12),
              if (income > 0 || expense > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        net >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hidden
                            ? 'Bu ay ${Money.hidden}'
                            : 'Bu ay ${Money.format(net, sign: true)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.south_west,
                        label: 'Bu ay gelir',
                        amount: income,
                        hidden: hidden,
                        unknown: unknown,
                      ),
                    ),
                    Container(width: 1, color: Colors.white.withValues(alpha: 0.18)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpace.lg),
                        child: _HeaderStat(
                          icon: Icons.north_east,
                          label: 'Bu ay gider',
                          amount: expense,
                          hidden: hidden,
                          unknown: unknown,
                        ),
                      ),
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
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final bool hidden;
  final bool unknown;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.hidden,
    this.unknown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xB3FFFFFF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FitLine(Text(
            unknown ? '—' : (hidden ? Money.hidden : Money.format(amount)),
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            )),
          ),
        ],
      ),
    );
  }
}

// ─── Hızlı erişim ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final HomeViewModel vm;
  const _QuickActions({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    void go(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    final userId = vm.userId ?? '';

    final items = [
      ('Hedefler', Icons.track_changes_outlined, Tone.purple,
          () => go(GoalsPage(userId: userId))),
      ('Faturalar', Icons.receipt_long_outlined, Tone.yellow,
          () => go(BillsPage())),
      ('Tekrarlayan', Icons.autorenew, Tone.teal,
          () => go(RecurringTransactionsPage(userId: userId))),
      ('Raporlar', Icons.bar_chart_outlined, Tone.orange,
          () => go(AnalysisScreen())),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg, horizontal: 8),
      child: Row(
        children: [
          for (final (label, icon, tone, onTap) in items)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      ToneIcon(icon: icon, tone: tone, size: 48),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FitLine(
                          alignment: Alignment.center,
                          Text(
                            label,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Yaklaşan faturalar (yatay kartlar) ───────────────────────────────────────

class _UpcomingBills extends StatelessWidget {
  const _UpcomingBills();

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillsViewModel>();
    final list = [...bills.overdueBills, ...bills.upcomingBills];
    if (list.isEmpty) return const SizedBox.shrink();
    final hidden = context.watch<HomeViewModel>().secretMoney;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Yaklaşan faturalar',
          actionLabel: 'Tümü',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BillsPage()),
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
            itemBuilder: (context, i) => _BillCard(bill: list[i], hidden: hidden),
          ),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final UpcomingBill bill;
  final bool hidden;
  const _BillCard({required this.bill, required this.hidden});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overdue = bill.status == 'Gecikti';
    final soon = !overdue && bill.daysDiff <= 3;
    final (pillText, fg, bg) = overdue
        ? ('${bill.daysDiff.abs()} GÜN GECİKTİ', c.expense, c.expenseSoft)
        : bill.daysDiff == 0
            ? ('BUGÜN', c.warning, c.warningSoft)
            : ('${bill.daysDiff} GÜN', soon ? c.warning : c.textMuted,
                soon ? c.warningSoft : c.surfaceMuted);

    return SizedBox(
      width: 168,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BillsPage()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ToneIcon.bill(bill.category, size: 34),
                const SizedBox(width: 8),
                Expanded(
                  child: FitLine(
                    alignment: AlignmentDirectional.centerEnd,
                    StatusPill(label: pillText, foreground: fg, background: bg),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              bill.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              hidden ? Money.hidden : Money.format(bill.amount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bu ayki harcama dağılımı ─────────────────────────────────────────────────

class _SpendingBreakdown extends StatelessWidget {
  final HomeViewModel vm;
  const _SpendingBreakdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = [...vm.expenseData]..sort((a, b) => b.amount.compareTo(a.amount));
    final total = data.fold<double>(0, (s, d) => s + d.amount);
    if (total <= 0) return const SizedBox.shrink();
    final top = data.take(4).toList();
    final hidden = vm.secretMoney;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Bu ay harcamaların'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: AppCard(
            child: Column(
              children: [
                // Kategori oranlarını gösteren tek parça çubuk
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        for (final d in data)
                          Expanded(
                            flex: (d.amount / total * 1000).round().clamp(1, 1000),
                            child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              color: CategoryStyle.of(d.categoryName)
                                  .tone
                                  .resolve(brightness)
                                  .foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                for (final d in top)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ToneIcon.category(d.categoryName, size: 34),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            d.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          Money.percent(d.amount / total * 100),
                          style: TextStyle(color: c.textFaint, fontSize: 13),
                        ),
                        const SizedBox(width: AppSpace.md),
                        SizedBox(
                          width: 96,
                          child: FitLine(
                            alignment: AlignmentDirectional.centerEnd,
                            Text(
                              hidden ? Money.hidden : Money.format(d.amount),
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hedefler ─────────────────────────────────────────────────────────────────

class _Goals extends StatelessWidget {
  final HomeViewModel vm;
  const _Goals({required this.vm});

  static const _tones = [Tone.teal, Tone.purple, Tone.orange, Tone.pink, Tone.blue];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final goals = vm.goals;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Hedeflerin',
          actionLabel: 'Tümü',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoalsPage(userId: vm.userId ?? ''),
            ),
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
            itemBuilder: (context, i) {
              final g = goals[i];
              final tone = _tones[i % _tones.length].resolve(brightness);
              final progress = g.targetAmount > 0
                  ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                  : 0.0;
              return SizedBox(
                width: 190,
                child: AppCard(
                  color: tone.background,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        Money.percent(progress * 100),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: tone.foreground,
                          backgroundColor: c.surface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Son işlemler ─────────────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final HomeViewModel vm;
  const _RecentTransactions({required this.vm});

  String _when(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Bugün $time';
    if (diff == 1) return 'Dün $time';
    return vm.formatDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = vm.recentTransactionsLimited;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Son işlemler',
          actionLabel: 'Tümü',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllTransactionsPage()),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            child: AppCard(
              child: EmptyState(
                icon: Icons.receipt_outlined,
                title: 'Henüz işlem yok',
                subtitle: 'Alttaki + butonuyla ilk gelir ya da giderini ekle.',
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(indent: 70, height: 1, color: c.border),
                    TransactionRow(
                      t: items[i],
                      categoryName:
                          vm.getCategoryById(items[i].categoryId)?.name,
                      subtitle: _when(items[i].date),
                      hidden: vm.secretMoney,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

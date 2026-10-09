import 'package:flutter/material.dart';

import '../models/shopping_list_item.dart';
import '../services/database_helper.dart';
import 'widgets/ui/ui.dart';

/// Cihazda tutulan basit alışveriş listesi
class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingListItem> _items = [];
  bool _isLoading = true;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _refreshItems() async {
    try {
      final data = await DatabaseHelper.instance.readAllItems();
      if (!mounted) return;
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste yüklenemedi')),
      );
    }
  }

  Future<void> _addItem() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    _controller.clear();
    await DatabaseHelper.instance.create(ShoppingListItem(name: name));
    await _refreshItems();
    _focus.requestFocus(); // Arka arkaya ürün eklenebilsin
  }

  Future<void> _toggle(ShoppingListItem item) async {
    item.isBought = !item.isBought;
    setState(() {});
    await DatabaseHelper.instance.update(item);
    await _refreshItems();
  }

  Future<void> _delete(ShoppingListItem item) async {
    await DatabaseHelper.instance.delete(item.id!);
    await _refreshItems();
  }

  Future<void> _clearBought() async {
    for (final item in _items.where((i) => i.isBought).toList()) {
      await DatabaseHelper.instance.delete(item.id!);
    }
    await _refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final toBuy = _items.where((i) => !i.isBought).toList();
    final bought = _items.where((i) => i.isBought).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Alışveriş listesi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addItem(),
                    decoration: const InputDecoration(
                      hintText: 'Ürün ekle (örn. süt)',
                      prefixIcon: Icon(Icons.add_shopping_cart_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                SizedBox(
                  width: 54,
                  height: 54,
                  child: IconButton.filled(
                    tooltip: 'Ekle',
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const EmptyState(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Listen boş',
                        subtitle: 'Almak istediklerini yukarıdan ekle; aldıkça işaretle.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
                        children: [
                          if (toBuy.isNotEmpty) ...[
                            Overline('Alınacak · ${toBuy.length}'),
                            const SizedBox(height: AppSpace.sm),
                            _Group(items: toBuy, onToggle: _toggle, onDelete: _delete),
                          ],
                          if (bought.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xl),
                            Row(
                              children: [
                                Overline('Alındı · ${bought.length}'),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _clearBought,
                                  child: Text(
                                    'Temizle',
                                    style: TextStyle(
                                      color: c.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.sm),
                            _Group(items: bought, onToggle: _toggle, onDelete: _delete),
                          ],
                          const SizedBox(height: AppSpace.lg),
                          Text(
                            'Silmek için ürünü sola kaydır. Liste yalnızca bu telefonda saklanır.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textFaint, fontSize: 12),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<ShoppingListItem> items;
  final ValueChanged<ShoppingListItem> onToggle;
  final ValueChanged<ShoppingListItem> onDelete;
  const _Group({required this.items, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: c.border),
            Dismissible(
              key: ValueKey(items[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: c.expense,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => onDelete(items[i]),
              child: InkWell(
                onTap: () => onToggle(items[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: items[i].isBought ? c.income : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: items[i].isBought ? c.income : c.textFaint,
                            width: 1.6,
                          ),
                        ),
                        child: items[i].isBought
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          items[i].name,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: items[i].isBought ? c.textFaint : c.text,
                            decoration:
                                items[i].isBought ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
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

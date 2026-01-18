import 'dart:ui';
import 'package:component_builder/component_builder.dart';
import 'package:flutter/material.dart';
import '../../../view_model/home_view_model.dart';

Widget buildAssetsSection(HomeViewModel viewModel, BuildContext context) {
  // HomeViewModel zaten verileri yüklemiş olmalı.
  // Burada sadece viewModel.assets ve viewModel.secretMoney'i kullanıyoruz.

  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final secretMoney = viewModel.secretMoney;

  // HomeViewModel assets[0]'a "Toplam Bakiye"yi koyuyor.
  // Eğer assets boşsa henüz yüklenmemiş veya veri yok demektir.
  final double totalAssets =
      viewModel.assets.isNotEmpty ? viewModel.assets[0].amount : 0.0;

  final gradientColors = isDark
      ? [Colors.blue.shade200, Colors.blue.shade600]
      : [Colors.green.shade400, Colors.green.shade400, Colors.red.shade600];

  ComponentBuilder cb = ComponentBuilder();

  final totalItems = cb
      .child(
        Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
      )
      .child(SizedBox(width: 8))
      .child(
        Text(
          'Toplam Varlıklarım',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
      .build(device: ComponentBuilderDevice.android);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [totalItems]),
        const SizedBox(height: 15),
        secretMoney
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Text(
                  viewModel.formatCurrency(totalAssets),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Text(
                viewModel.formatCurrency(totalAssets),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
        const SizedBox(height: 15),
        if (viewModel.assets.isEmpty)
          const Text(
            "Varlık bulunamadı",
            style: TextStyle(color: Colors.white70),
          )
        else
          Column(
            children: viewModel.assets.map((asset) {
              if (asset.name == 'Toplam Bakiye') return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          viewModel.formatCurrency(asset.amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    ),
  );
}


import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:flutter/material.dart';

/// On mobile, bulk Excel import (thousands of HARIAN rows) is handled on the
/// web app where file picking + preview is more reliable. This page explains
/// the format and points the user there.
class OrgImportPage extends StatelessWidget {
  const OrgImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrgScaffold(
      title: 'Import Excel',
      current: OrgNavItem.more,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.upload_file_rounded,
                color: AppColors.blue900, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Import Massal via Web',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import file Excel format HARIAN (ribuan transaksi) lebih andal '
            'dilakukan di aplikasi web Confindant. Buka Confindant di browser, '
            'masuk ke mode organisasi, lalu pilih menu Import Excel.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Format Sheet HARIAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _formatRow('A', 'Tanggal'),
                _formatRow('B', 'Uraian'),
                _formatRow('C', 'Pemasukan (Debit)'),
                _formatRow('D', 'Pengeluaran (Kredit)'),
                _formatRow('G', 'Kategori'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoStroke),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: AppColors.blue900),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Untuk input harian cepat, gunakan menu Jurnal di aplikasi ini.',
                    style: TextStyle(fontSize: 13, color: AppColors.blue900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatRow(String col, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              col,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

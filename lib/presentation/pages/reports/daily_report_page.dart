import 'package:flutter/material.dart';

class DailyReportPage extends StatelessWidget {
  const DailyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Rapor')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Günlük Rapor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bu özellik yakında ekleniyor...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Planlanan Özellikler:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('• Günlük puantaj özetleri'),
                    Text('• Günlük harcama raporları'),
                    Text('• Personel performans metrikleri'),
                    Text('• Grafik ve istatistikler'),
                    Text('• Karşılaştırmalı analizler'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/amende.dart';

/// Screen to scan QR codes and display amende details
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late MobileScannerController controller;
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (_screenOpened) return;
    if (barcodes.barcodes.isEmpty) return;

    final barcode = barcodes.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    _screenOpened = true;

    // Try to parse as JSON
    try {
      final jsonData = jsonDecode(rawValue);
      final amende = Amende.fromJson(jsonData as Map<String, dynamic>);
      
      if (!mounted) return;
      
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => _AmendeDetailsScreen(amende: amende),
      )).then((_) {
        _screenOpened = false;
      });
    } catch (e) {
      _screenOpened = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Amende QR Code'),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: _handleBarcode,
        errorBuilder: (context, error, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${error.errorCode}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Screen to display the scanned amende details
class _AmendeDetailsScreen extends StatelessWidget {
  final Amende amende;

  const _AmendeDetailsScreen({required this.amende});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Amende Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Simple text-based details
              _buildDetailRow('ID:', amende.id),
              const SizedBox(height: 16),
              _buildDetailRow('Type:', amende.getTypeLabel()),
              const SizedBox(height: 16),
              _buildDetailRow('Location:', amende.location),
              const SizedBox(height: 16),
              _buildDetailRow('Amount:', '${amende.amount} DT'),
              const SizedBox(height: 16),
              _buildDetailRow('Violator ID:', amende.userId),
              const SizedBox(height: 16),
              _buildDetailRow('Agent ID:', amende.agentId),

              // Photo if available
              if (amende.photoUrl != null && amende.photoUrl!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Photo:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    amende.photoUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('Photo not available'),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

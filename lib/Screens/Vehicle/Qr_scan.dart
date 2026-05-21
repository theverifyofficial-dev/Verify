import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VehicleQRScannerPage extends StatefulWidget {
  const VehicleQRScannerPage({super.key});

  @override
  State<VehicleQRScannerPage> createState() =>
      _VehicleQRScannerPageState();
}

class _VehicleQRScannerPageState extends State<VehicleQRScannerPage> {

  bool scanned = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      body: MobileScanner(

        onDetect: (capture) {

          if (scanned) return;

          final List<Barcode> barcodes =
              capture.barcodes;

          for (final barcode in barcodes) {

            final String? code = barcode.rawValue;

            if (code != null && code.isNotEmpty) {

              scanned = true;

              Navigator.pop(context, code);

              break;
            }
          }
        },
      ),
    );
  }
}
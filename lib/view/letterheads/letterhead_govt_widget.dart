import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings/company_profile_controller.dart';

/// A4 govt letterhead (794×1123) — green header matching TemplateGovt,
/// blank lined writing area, and authorized signatory footer.
class LetterheadGovtWidget extends StatelessWidget {
  const LetterheadGovtWidget({super.key});

  static const Color _green = Color(0xFF1A7A1A);
  static const Color _lineColor = Color(0xFFDDDDDD);
  static const double _pageWidth = 794;
  static const double _pageHeight = 1123;

  @override
  Widget build(BuildContext context) {
    final co = context.watch<CompanyProfileController>();
    return Container(
      width: _pageWidth,
      height: _pageHeight,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(co),
          Expanded(child: _buildBody()),
          _buildFooter(co),
        ],
      ),
    );
  }

  Widget _buildHeader(CompanyProfileController co) {
    return Container(
      color: _green,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Column(
        children: [
          Text(
            '${co.name}  ${co.tagline}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vendor Number: ${co.vendorNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Address: ${co.address}    Email: ${co.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          if (co.phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Phone: ${co.phone}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ref / Date row
          Row(
            children: [
              _fieldBox('Ref No:', 200),
              const Spacer(),
              _fieldBox('Date:', 180),
            ],
          ),
          const SizedBox(height: 16),
          _fullWidthFieldBox('To:'),
          const SizedBox(height: 10),
          _fullWidthFieldBox('Subject:'),
          const SizedBox(height: 20),
          // Lined writing area
          // Expanded(
          //   child: CustomPaint(
          //     size: const Size(double.infinity, double.infinity),
          //     painter: _LinedPaper(),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _fieldBox(String label, double width) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: width,
          height: 22,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _fullWidthFieldBox(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 22,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(CompanyProfileController co) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
      child: Column(
        children: [
          const Divider(color: _lineColor),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('Prepared By'),
              _signatureBlock('Checked By'),
              _signatureBlockWithSig(co),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureBlock(String label) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 48,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF999999), width: 1),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _signatureBlockWithSig(CompanyProfileController co) {
    final sigPath = co.signaturePath;
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 48,
          child: sigPath != null
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.file(
                    File(sigPath),
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                )
              : const SizedBox(),
        ),
        Container(width: 160, height: 1, color: const Color(0xFF999999)),
        const SizedBox(height: 4),
        const Text(
          'Authorized Signatory',
          style: TextStyle(fontSize: 10, color: Color(0xFF333333)),
        ),
      ],
    );
  }
}

// class _LinedPaper extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFFDDDDDD)
//       ..strokeWidth = 0.8;

//     const lineSpacing = 28.0;
//     double y = lineSpacing;
//     while (y < size.height) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
//       y += lineSpacing;
//     }
//   }

//   @override
//   bool shouldRepaint(_LinedPaper _) => false;
// }

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/activity_models.dart';

class TaxReceiptService {
  TaxReceiptService._();
  static final TaxReceiptService instance = TaxReceiptService._();

  static const _trustName = 'Marudamalai Devasthanam Trust';
  static const _trustPan = 'AAATM1234F';
  static const _trustReg = 'REG/TN/2003/0042';
  static const _ref80gPrefix = '80G/MRD';

  // ── Donation 80G PDF ───────────────────────────────────────────────────────

  Future<void> print80gReceipt(
      BuildContext context, DonationReceiptModel receipt) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfHeader(),
          pw.SizedBox(height: 16),
          _pdfTitle('80G Tax Exemption Receipt'),
          pw.SizedBox(height: 12),
          _pdfRow('Receipt No.', receipt.transactionId),
          _pdfRow('80G Reference', '$_ref80gPrefix/${receipt.transactionId}'),
          _pdfRow('Trust Name', _trustName),
          _pdfRow('Trust PAN', _trustPan),
          _pdfRow('Registration No.', _trustReg),
          _pdfRow('Donation Cause', receipt.cause),
          _pdfRow('Amount', '₹${receipt.amount}'),
          _pdfRow('Date', receipt.dateStr),
          pw.SizedBox(height: 20),
          pw.Text(
            'This receipt is valid for claiming 50% deduction under Section 80G '
            'of the Income Tax Act, 1961.',
            style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Authorised Signatory',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(_trustName,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '80G_${receipt.transactionId}.pdf',
    );
  }

  // ── Shuttle Boarding Pass PDF ──────────────────────────────────────────────

  Future<void> printBoardingPass(
      BuildContext context, ShuttleTicketModel ticket) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfHeader(),
          pw.SizedBox(height: 12),
          _pdfTitle('Shuttle Boarding Pass'),
          pw.SizedBox(height: 10),
          _pdfRow('Ticket ID', ticket.ticketId),
          _pdfRow('Date', ticket.date),
          _pdfRow('Departure', ticket.slot),
          _pdfRow('Route',
              '${ticket.pickupLocation} → ${ticket.dropLocation}'),
          _pdfRow('Seats', '${ticket.seatCount}'),
          _pdfRow('Fare', '₹${ticket.fare.toStringAsFixed(0)}'),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: ticket.qrPayload,
              width: 120,
              height: 120,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text('Scan at boarding point',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600)),
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'BoardingPass_${ticket.ticketId}.pdf',
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  pw.Widget _pdfHeader() => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#800000'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sannidhi',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(_trustName,
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 9)),
              ],
            ),
            pw.Text('🙏',
                style: const pw.TextStyle(
                    fontSize: 24, color: PdfColors.white)),
          ],
        ),
      );

  pw.Widget _pdfTitle(String title) => pw.Text(
        title,
        style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#800000')),
      );

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
            ),
            pw.Text(': ',
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700)),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      );
}

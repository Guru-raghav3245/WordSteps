import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

class QuizPDFGenerator {
  static Future<File> generateQuizPDF({
    required List<String> answeredQuestions,
    required List<String> userAnswers,
    required List<bool> answeredCorrectly,
    required int totalTime,
  }) async {
    final pdf = pw.Document();
    
    final correctAnswers = answeredCorrectly.where((correct) => correct).length;
    final wrongAnswers = answeredCorrectly.where((correct) => !correct).length;
    final totalQuestions = answeredQuestions.length;
    final score = totalQuestions > 0 
        ? ((correctAnswers / totalQuestions) * 100).toStringAsFixed(1) 
        : '0';
    final minutes = totalTime ~/ 60;
    final seconds = totalTime % 60;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Quiz Results',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.symmetric(vertical: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Quiz Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Time Taken', '$minutes:${seconds.toString().padLeft(2, '0')}'),
                    _buildSummaryItem('Score', '$score%'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Questions', totalQuestions.toString()),
                    _buildSummaryItem('Correct Answers', correctAnswers.toString()),
                    _buildSummaryItem('Wrong Answers', wrongAnswers.toString()),
                  ],
                ),
              ],
            ),
          ),
          pw.Header(
            level: 1,
            text: 'Detailed Questions & Answers',
            textStyle: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.ListView.builder(
            itemCount: answeredQuestions.length,
            itemBuilder: (context, index) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Q${index + 1}: ${answeredQuestions[index]}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    'Your Answer: ${userAnswers[index]}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: answeredCorrectly[index]
                          ? PdfColors.green
                          : PdfColors.red,  // Adjusted red color
                    ),
                  ),
                  pw.Divider(),
                ],
              );
            },
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/quiz_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value),
      ],
    );
  }
}

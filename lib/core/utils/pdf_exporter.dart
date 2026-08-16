import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  /// 导出外部AI提示词PDF
  static Future<File> exportExternalAIPdf({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (pageContext) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '生成时间：$dateStr',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              if (contactName != null)
                pw.Text(
                  '联系人：$contactName',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              pw.Divider(thickness: 1),
            ],
          ),
        ),
        footer: (pageContext) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            '第 ${pageContext.pageNumber} 页 / 共 ${pageContext.pagesCount} 页',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (pageContext) => [
          // 使用说明
          _buildSection(
            '📋 使用说明',
            [
              '1. 将此文档发送给 AI（千问、豆包等）',
              '2. 对 AI 说："按pdf要求执行"',
              '3. 等待 AI 返回分析结果',
              '4. 将 AI 的回复复制到 社交塔子 APP 中',
            ],
          ),
          pw.SizedBox(height: 20),
          
          // 背景上下文
          if (context != null) ...[
            _buildSection('📌 背景信息', [context]),
            pw.SizedBox(height: 20),
          ],
          
          // 主要提示词
          _buildSection('🎯 任务要求', [
            prompt,
          ]),
          
          // 附件说明
          if (attachments != null && attachments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection('📎 附件内容', attachments),
          ],
          
          // 结尾
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '💡 提示',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '请将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，'
                  'APP 将自动解析并保存结果。',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = '社交塔子_${title}_$timestamp.pdf';
    final filePath = '${dir.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  static pw.Widget _buildSection(String title, List<String> contents) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: contents.map((content) {
              if (content.startsWith('•') || content.startsWith('-') || content.startsWith('1') && content.contains('.')) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(
                    content,
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                  ),
                );
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(
                  content,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 分享PDF
  static Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  /// 打印PDF
  static Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await pdfFile.readAsBytes(),
    );
  }

  /// 下载图片到本地
  static Future<File?> downloadImage(String url, String fileName) async {
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      await dio.download(url, filePath);
      return File(filePath);
    } catch (e) {
      return null;
    }
  }
}

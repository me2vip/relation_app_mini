import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  static pw.Font? _cachedChineseFont;

  static Future<pw.Font?> _loadChineseFont() async {
    if (_cachedChineseFont != null) return _cachedChineseFont;

    final fontPaths = [
      '/system/fonts/DroidSansFallbackFull.ttf',
      '/system/fonts/DroidSansFallback.ttf',
      '/system/fonts/NotoSansCJK-Regular.ttc',
      '/system/fonts/NotoSansCJK.ttc',
      '/system/fonts/NotoSerifCJK-Regular.ttc',
      '/system/fonts/RobotoFallback-VF.ttf',
      '/system/fonts/NotoSansSC.ttf',
      '/system/fonts/NotoSerifSC.ttf',
      '/system/fonts/SourceHanSansCN-Regular.otf',
    ];

    for (final path in fontPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final font = pw.Font.ttf(bytes);
          _cachedChineseFont = font;
          return font;
        }
      } catch (_) {}
    }

    return null;
  }

  static pw.TextStyle _cnStyle({
    pw.Font? font,
    double? fontSize,
    pw.FontWeight? fontWeight,
    pw.Color? color,
    double? height,
  }) {
    return pw.TextStyle(
      font: font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static Future<File> exportExternalAIPdf({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    final chineseFont = await _loadChineseFont();

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    final buffer = StringBuffer();
    buffer.writeln('# $title');
    buffer.writeln('');
    buffer.writeln('> **生成时间：** $dateStr');
    if (contactName != null) {
      buffer.writeln('> **联系人：** $contactName');
    }
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');

    buffer.writeln('## 📋 使用说明');
    buffer.writeln('');
    buffer.writeln('1. 将此文档发送给 AI（千问、豆包等）');
    buffer.writeln('2. 对 AI 说：**"按pdf要求执行"**');
    buffer.writeln('3. 等待 AI 返回分析结果');
    buffer.writeln('4. 将 AI 的回复完整复制回 APP');
    buffer.writeln('');

    if (context != null && context.isNotEmpty) {
      buffer.writeln('## 📌 背景信息');
      buffer.writeln('');
      buffer.writeln(context);
      buffer.writeln('');
    }

    buffer.writeln('## 🎯 任务要求');
    buffer.writeln('');
    buffer.writeln(prompt);
    buffer.writeln('');

    if (attachments != null && attachments.isNotEmpty) {
      buffer.writeln('## 📎 附件内容');
      buffer.writeln('');
      for (final att in attachments) {
        buffer.writeln('- $att');
      }
      buffer.writeln('');
    }

    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('> **💡 提示：** 请将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，APP 将自动解析并保存结果。');

    final markdownText = buffer.toString();

    final baseStyle = pw.Style(
      textStyle: _cnStyle(font: chineseFont, fontSize: 11, height: 1.5),
      h1: _cnStyle(font: chineseFont, fontSize: 22, fontWeight: pw.FontWeight.bold, height: 1.3),
      h2: _cnStyle(font: chineseFont, fontSize: 16, fontWeight: pw.FontWeight.bold, height: 1.3),
      h3: _cnStyle(font: chineseFont, fontSize: 14, fontWeight: pw.FontWeight.bold),
      h4: _cnStyle(font: chineseFont, fontSize: 12, fontWeight: pw.FontWeight.bold),
      normal: _cnStyle(font: chineseFont, fontSize: 11, height: 1.5),
      em: _cnStyle(font: chineseFont, fontSize: 11, fontStyle: pw.FontStyle.italic),
      strong: _cnStyle(font: chineseFont, fontSize: 11, fontWeight: pw.FontWeight.bold),
      del: _cnStyle(font: chineseFont, fontSize: 11, decoration: pw.TextDecoration.lineThrough),
      link: _cnStyle(font: chineseFont, fontSize: 11, color: PdfColors.blue),
      hr: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
      tableHead: _cnStyle(font: chineseFont, fontSize: 11, fontWeight: pw.FontWeight.bold),
      tableHeaderDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      tableBodyDecoration: const pw.BoxDecoration(color: PdfColors.white),
      code: pw.TextStyle(
        font: pw.Font.courier(),
        fontSize: 10,
        background: const pw.BoxDecoration(color: PdfColors.grey100),
      ),
      codeBlockDecoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      blockQuoteDecoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: PdfColors.indigo400, width: 3)),
      ),
      blockPadding: const pw.EdgeInsets.all(8),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (pageContext) {
          if (pageContext.pageNumber == 1) return const pw.SizedBox.shrink();
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              '$title · ${DateFormat('yyyy年MM月dd日').format(now)}',
              style: _cnStyle(
                font: chineseFont,
                fontSize: 9,
                color: PdfColors.grey500,
              ),
            ),
          );
        },
        footer: (pageContext) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            '第 ${pageContext.pageNumber} 页 / 共 ${pageContext.pagesCount} 页',
            style: _cnStyle(
              font: chineseFont,
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ),
        build: (context) => [
          pw.Markdown(
            data: markdownText,
            style: baseStyle,
            onReply: () {},
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '社交塔子_${safeTitle}_$timestamp.pdf';
    final filePath = '${dir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  static Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await pdfFile.readAsBytes(),
    );
  }

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

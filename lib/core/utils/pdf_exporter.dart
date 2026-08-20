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
          if (bytes.isEmpty) continue;
          final font = pw.Font.ttf(bytes.buffer.asByteData());
          _cachedChineseFont = font;
          return font;
        }
      } catch (_) {}
    }

    return null;
  }

  static pw.TextStyle _style({
    pw.Font? font,
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
    double? height,
    pw.FontStyle? fontStyle,
    pw.TextDecoration? decoration,
  }) {
    if (font != null) {
      return pw.TextStyle(
        font: font,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
      );
    }
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
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

    final style = _style(font: chineseFont, fontSize: 11, height: 1.5);
    final h1Style = _style(
      font: chineseFont,
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      height: 1.3,
    );
    final h2Style = _style(
      font: chineseFont,
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      height: 1.3,
    );
    final captionStyle = _style(
      font: chineseFont,
      fontSize: 10,
      color: PdfColors.grey500,
    );
    final quoteStyle = _style(
      font: chineseFont,
      fontSize: 11,
      fontStyle: pw.FontStyle.italic,
      color: PdfColors.grey700,
    );

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);
    final dateForHeader = DateFormat('yyyy年MM月dd日').format(now);

    final widgets = <pw.Widget>[];

    widgets.add(pw.Text(title, style: h1Style));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(pw.Text('生成时间：$dateStr', style: captionStyle));
    if (contactName != null) {
      widgets.add(pw.Text('联系人：$contactName', style: captionStyle));
    }
    widgets.add(pw.SizedBox(height: 12));
    widgets.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
    widgets.add(pw.SizedBox(height: 16));

    widgets.add(pw.Text('📋 使用说明', style: h2Style));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(pw.Text('1. 将此PDF文档发送给 AI（千问、豆包、GPT等）', style: style));
    widgets.add(pw.Text('2. 对 AI 说："请按照此PDF文档的要求执行任务"', style: style));
    widgets.add(pw.Text('3. 等待 AI 返回分析结果', style: style));
    widgets.add(pw.Text('4. 将 AI 的回复完整复制回 APP', style: style));
    widgets.add(pw.SizedBox(height: 16));

    if (context != null && context.isNotEmpty) {
      widgets.add(pw.Text('📌 背景信息 / 素材', style: h2Style));
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: PdfColors.indigo400, width: 3)),
            color: PdfColors.indigo50,
          ),
          child: pw.Text(context, style: quoteStyle),
        ),
      );
      widgets.add(pw.SizedBox(height: 16));
    }

    widgets.add(pw.Text('🎯 AI 任务指令', style: h2Style));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(prompt, style: style),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    if (attachments != null && attachments.isNotEmpty) {
      widgets.add(pw.Text('📎 附件/素材列表', style: h2Style));
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(pw.Text('以下素材已通过APP附加，请AI分析时结合考虑：', style: quoteStyle.copyWith(color: PdfColors.grey600)));
      widgets.add(pw.SizedBox(height: 8));
      for (final att in attachments) {
        widgets.add(pw.Text('• $att', style: style));
      }
      widgets.add(pw.SizedBox(height: 16));
    }

    widgets.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
    widgets.add(pw.SizedBox(height: 12));
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '💡 重要提示：',
              style: _style(
                font: chineseFont,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，APP 将自动解析 JSON 并保存为任务。',
              style: quoteStyle.copyWith(color: PdfColors.amber700),
            ),
          ],
        ),
      ),
    );

    try {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pageContext) {
            if (pageContext.pageNumber == 1) {
              return pw.SizedBox.shrink();
            }
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text(
                '$title · $dateForHeader',
                style: captionStyle,
              ),
            );
          },
          footer: (pageContext) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              '第 ${pageContext.pageNumber} 页 / 共 ${pageContext.pagesCount} 页',
              style: captionStyle,
            ),
          ),
          build: (context) => widgets,
        ),
      );
    } catch (e) {
      rethrow;
    }

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

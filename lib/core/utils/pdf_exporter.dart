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
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        try {
          final byteData = bytes.buffer.asByteData();
          if (byteData.lengthInBytes < 12) continue;
          final font = pw.Font.ttf(byteData);
          _cachedChineseFont = font;
          return font;
        } catch (_) {
          // 字体格式不支持，继续尝试下一个
        }
      } catch (_) {}
    }

    return null;
  }

  /// 极简安全 TextStyle：只有明确有字体时才传 font，
  /// 不设置任何可能触发 pdf 库内部组合断言的扩展样式。
  static pw.TextStyle _plainStyle(pw.Font? font, double size, {PdfColor? color, double? height}) {
    if (font != null) {
      return pw.TextStyle(font: font, fontSize: size, color: color, height: height);
    }
    return pw.TextStyle(fontSize: size, color: color, height: height);
  }

  /// 将可能包含 emoji 或控制字符的文本进行安全处理，
  /// 避免 pdf 库遇到不支持的 Unicode 时内部崩溃。
  static String _sanitizeText(String? text) {
    if (text == null) return '';
    var s = text;
    // 移除一些 PDF 字体可能不支持的 emoji 区间
    s = s.replaceAllMapped(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F02F}]',
        unicode: true,
      ),
      (m) => '□',
    );
    // 去掉 ASCII 控制字符 (0x00-0x1F 除了 \n\r\t)
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return s;
  }

  static pw.Widget _safeText(String? raw, pw.Font? font, double size,
      {PdfColor? color, double? height, pw.TextAlign? align}) {
    final text = _sanitizeText(raw);
    final style = _plainStyle(font, size, color: color, height: height);
    try {
      return pw.Text(text, style: style, textAlign: align ?? pw.TextAlign.left);
    } catch (_) {
      // 如果连 pw.Text 都抛错（极端情况），退回使用系统默认字体
      try {
        return pw.Text(text, style: pw.TextStyle(fontSize: size), textAlign: align ?? pw.TextAlign.left);
      } catch (__) {
        return pw.SizedBox.shrink();
      }
    }
  }

  static Future<File> exportExternalAIPdf({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    pw.Font? chineseFont;
    try {
      chineseFont = await _loadChineseFont();
    } catch (_) {
      chineseFont = null;
    }

    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    final children = <pw.Widget>[];

    // 标题（用较大字号代替 bold，避免 pdf 库组合字体的空断言）
    children.add(_safeText(title, chineseFont, 22, height: 1.3));
    children.add(pw.SizedBox(height: 6));
    children.add(_safeText('生成时间：$dateStr', chineseFont, 10, color: PdfColors.grey500));
    if (contactName != null && contactName.isNotEmpty) {
      children.add(pw.SizedBox(height: 2));
      children.add(_safeText('联系人：$contactName', chineseFont, 10, color: PdfColors.grey500));
    }
    children.add(pw.SizedBox(height: 14));
    children.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
    children.add(pw.SizedBox(height: 14));

    // 使用说明
    children.add(_safeText('使用说明', chineseFont, 16, height: 1.3));
    children.add(pw.SizedBox(height: 8));
    children.add(_safeText('1. 将此PDF文档发送给 AI（千问、豆包、GPT等）', chineseFont, 11, height: 1.5));
    children.add(_safeText('2. 对 AI 说：请按照此PDF文档的要求执行任务', chineseFont, 11, height: 1.5));
    children.add(_safeText('3. 等待 AI 返回分析结果', chineseFont, 11, height: 1.5));
    children.add(_safeText('4. 将 AI 的回复完整复制回 APP', chineseFont, 11, height: 1.5));
    children.add(pw.SizedBox(height: 16));

    // 背景信息
    if (context != null && context.isNotEmpty) {
      children.add(_safeText('背景信息 / 素材', chineseFont, 16, height: 1.3));
      children.add(pw.SizedBox(height: 8));
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: PdfColors.indigo400, width: 3)),
            color: PdfColors.indigo50,
          ),
          child: _safeText(context, chineseFont, 11, color: PdfColors.grey700, height: 1.5),
        ),
      );
      children.add(pw.SizedBox(height: 16));
    }

    // AI 任务指令
    children.add(_safeText('AI 任务指令', chineseFont, 16, height: 1.3));
    children.add(pw.SizedBox(height: 8));
    children.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: _safeText(prompt, chineseFont, 11, height: 1.5),
      ),
    );
    children.add(pw.SizedBox(height: 16));

    // 附件列表
    if (attachments != null && attachments.isNotEmpty) {
      children.add(_safeText('附件/素材列表', chineseFont, 16, height: 1.3));
      children.add(pw.SizedBox(height: 8));
      children.add(_safeText(
        '以下素材已通过APP附加，请AI分析时结合考虑：',
        chineseFont,
        11,
        color: PdfColors.grey600,
      ));
      children.add(pw.SizedBox(height: 8));
      for (final att in attachments) {
        children.add(_safeText('- $att', chineseFont, 11, height: 1.5));
      }
      children.add(pw.SizedBox(height: 16));
    }

    children.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
    children.add(pw.SizedBox(height: 12));

    // 重要提示
    children.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _safeText('重要提示：', chineseFont, 12, color: PdfColors.amber800),
            pw.SizedBox(height: 6),
            _safeText(
              '将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，APP 将自动解析 JSON 并保存为任务。',
              chineseFont,
              11,
              color: PdfColors.amber700,
              height: 1.5,
            ),
          ],
        ),
      ),
    );

    final pdf = pw.Document();

    // 极端保守：只用 pw.Page，完全不使用 MultiPage / header / footer 回调
    // （MultiPage 的 pagesCount/pageNumber 闭包在部分 pdf 版本内部存在 ! 断言）
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pageContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          );
        },
      ),
    );

    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '社交塔子_${safeTitle}_$timestamp.pdf';
    final filePath = '${dir.path}/$fileName';

    List<int> bytes;
    try {
      bytes = await pdf.save();
    } catch (e) {
      // 如果内容渲染导致 save 失败，退回到最小内容 PDF
      final fallback = pw.Document();
      fallback.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_sanitizeText(title), style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 12),
              pw.Text(_sanitizeText('生成时间：$dateStr')),
              pw.SizedBox(height: 20),
              pw.Text(_sanitizeText('AI 任务指令'), style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Text(_sanitizeText(prompt)),
            ],
          ),
        ),
      );
      // ignore: avoid_print
      print('[PdfExporter] 主PDF渲染失败，使用降级内容: $e');
      bytes = await fallback.save();
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<void> sharePdf(File pdfFile) async {
    try {
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: pdfFile.path.split('/').last,
      );
    } catch (_) {}
  }

  static Future<void> printPdf(File pdfFile) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => await pdfFile.readAsBytes(),
      );
    } catch (_) {}
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

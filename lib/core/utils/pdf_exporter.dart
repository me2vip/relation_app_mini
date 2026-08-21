import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  /// 已加载的中文字体列表（按优先级排序），fontResolver 会
  /// 在第一个字体缺少字形时依次尝试后续字体。
  static final List<pw.Font> _chineseFonts = [];
  static bool _scanned = false;

  /// 关键词优先顺序：越靠前越先尝试加载
  static const List<String> _fontKeywords = [
    'NotoSansCJK',
    'NotoSerifCJK',
    'NotoSansSC',
    'NotoSerifSC',
    'SourceHanSans',
    'SourceHanSerif',
    'DroidSansFallback',
    'RobotoFallback',
    'Miui-Bold',
    'Miui-Regular',
    'HanSans',
    'PingFang',
    'HarmonyOS',
    'Sans',
  ];

  static Future<void> _scanAndLoadFonts() async {
    if (_scanned) return;
    _scanned = true;

    final candidates = <String>[];
    try {
      const fontDirs = [
        '/system/fonts',
        '/system/font',
        '/data/fonts',
        '/product/fonts',
        '/vendor/fonts',
      ];
      for (final dir in fontDirs) {
        try {
          final d = Directory(dir);
          if (!await d.exists()) continue;
          await for (final f in d.list(recursive: false, followLinks: false)) {
            if (f is! File) continue;
            final lower = f.path.toLowerCase();
            if (lower.endsWith('.ttf') ||
                lower.endsWith('.otf') ||
                lower.endsWith('.ttc')) {
              candidates.add(f.path);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // 按关键词优先级排序
    String score(String path) {
      final lower = path.toLowerCase();
      for (var i = 0; i < _fontKeywords.length; i++) {
        if (lower.contains(_fontKeywords[i].toLowerCase())) {
          return '0$i${lower.split('/').last}';
        }
      }
      return '9z${lower.split('/').last}';
    }
    candidates.sort((a, b) => score(a).compareTo(score(b)));

    for (final path in candidates) {
      if (_chineseFonts.length >= 6) break; // 最多加载6个字体供 fallback 使用
      try {
        final file = File(path);
        final bytes = await file.readAsBytes();
        if (bytes.length < 1024) continue;
        try {
          final font = pw.Font.ttf(bytes.buffer.asByteData());
          _chineseFonts.add(font);
        } catch (_) {
          // ttc/otf 解析失败就继续下一个
        }
      } catch (_) {}
    }
  }

  /// 生成 PdfThemeData：当主字体缺字时，fontResolver 依次在 fallback 字体中查找字形
  static pw.ThemeData _buildTheme(pw.Font? primary) {
    final fallback = <pw.Font>[];
    for (final f in _chineseFonts) {
      if (primary != null && f == primary) continue;
      fallback.add(f);
    }

    pw.Font? base;
    pw.Font? fontBold;
    pw.Font? fontItalic;
    pw.Font? fontBoldItalic;
    if (primary != null) {
      base = primary;
      // 有中文字体时，bold/italic 也用同一份 ttf，避免 pdf 库内部合成时报空断言
      fontBold = primary;
      fontItalic = primary;
      fontBoldItalic = primary;
    }

    final fontResolver = fallback.isEmpty
        ? null
        : (pw.FontStyle style, int? unicode) {
            for (final font in fallback) {
              try {
                // 只要 font 本身支持该字形，pdf 库就会用它
                // 这里我们不需要显式判断是否包含 glyph，fontResolver 只要返回一个
                // 非空字体 pdf 库就会用它重新布局
                return font;
              } catch (_) {}
            }
            return null;
          };

    return pw.ThemeData.withFont(
      base: base,
      bold: fontBold,
      italic: fontItalic,
      boldItalic: fontBoldItalic,
      fontResolver: fontResolver,
      icons: null,
      iconResolver: null,
    );
  }

  /// 过滤 emoji/控制字符
  static String _sanitizeText(String? text) {
    if (text == null) return '';
    var s = text;
    try {
      s = s.replaceAllMapped(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F02F}]',
            unicode: true),
        (m) => '',
      );
    } catch (_) {}
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return s;
  }

  static pw.Widget _safeText(String? raw, double size,
      {PdfColor? color, double? height, pw.TextAlign? align}) {
    final text = _sanitizeText(raw);
    try {
      return pw.Text(
        text,
        style: pw.TextStyle(fontSize: size, color: color, height: height),
        textAlign: align ?? pw.TextAlign.left,
      );
    } catch (_) {
      return pw.SizedBox.shrink();
    }
  }

  static Future<File> exportExternalAIPdf({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    await _scanAndLoadFonts();
    final primaryFont = _chineseFonts.isNotEmpty ? _chineseFonts.first : null;
    final theme = _buildTheme(primaryFont);

    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    // 所有文本通过 Theme.of(context).defaultTextStyle 继承字体解析器：
    // 所以必须用 pw.Theme(child: ...) 包裹内容，否则 fontResolver 不生效！
    pw.Widget wrapBody(pw.Widget child) =>
        pw.Theme(data: theme, child: child);

    pw.Document makeDoc(List<pw.Widget> children) {
      final pdf = pw.Document(theme: theme);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: theme,
          build: (_) => wrapBody(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      );
      return pdf;
    }

    final children = <pw.Widget>[];

    children.add(_safeText(title, 22, height: 1.3));
    children.add(pw.SizedBox(height: 6));
    children.add(_safeText('生成时间：$dateStr', 10, color: PdfColors.grey500));
    if (contactName != null && contactName.isNotEmpty) {
      children.add(pw.SizedBox(height: 2));
      children.add(_safeText('联系人：$contactName', 10, color: PdfColors.grey500));
    }
    children.add(pw.SizedBox(height: 14));
    children.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
    children.add(pw.SizedBox(height: 14));

    children.add(_safeText('使用说明', 16, height: 1.3));
    children.add(pw.SizedBox(height: 8));
    children.add(_safeText('1. 将此PDF文档发送给 AI（千问、豆包、GPT等）', 11, height: 1.5));
    children.add(_safeText('2. 对 AI 说：请按照此PDF文档的要求执行任务', 11, height: 1.5));
    children.add(_safeText('3. 等待 AI 返回分析结果', 11, height: 1.5));
    children.add(_safeText('4. 将 AI 的回复完整复制回 APP', 11, height: 1.5));
    children.add(pw.SizedBox(height: 16));

    if (context != null && context.isNotEmpty) {
      children.add(_safeText('背景信息 / 素材', 16, height: 1.3));
      children.add(pw.SizedBox(height: 8));
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: PdfColors.indigo400, width: 3)),
            color: PdfColors.indigo50,
          ),
          child: _safeText(context, 11, color: PdfColors.grey700, height: 1.5),
        ),
      );
      children.add(pw.SizedBox(height: 16));
    }

    children.add(_safeText('AI 任务指令', 16, height: 1.3));
    children.add(pw.SizedBox(height: 8));
    children.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: _safeText(prompt, 11, height: 1.5),
      ),
    );
    children.add(pw.SizedBox(height: 16));

    if (attachments != null && attachments.isNotEmpty) {
      children.add(_safeText('附件/素材列表', 16, height: 1.3));
      children.add(pw.SizedBox(height: 8));
      children.add(_safeText(
        '以下素材已通过APP附加，请AI分析时结合考虑：',
        11,
        color: PdfColors.grey600,
      ));
      children.add(pw.SizedBox(height: 8));
      for (final att in attachments) {
        children.add(_safeText('- $att', 11, height: 1.5));
      }
      children.add(pw.SizedBox(height: 16));
    }

    children.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
    children.add(pw.SizedBox(height: 12));

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
            _safeText('重要提示：', 12, color: PdfColors.amber800),
            pw.SizedBox(height: 6),
            _safeText(
              '将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，APP 将自动解析 JSON 并保存为任务。',
              11,
              color: PdfColors.amber700,
              height: 1.5,
            ),
          ],
        ),
      ),
    );

    final pdf = makeDoc(children);

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
      // ignore: avoid_print
      print('[PdfExporter] save失败，退回最小PDF: $e');
      final fb = makeDoc(<pw.Widget>[
        _safeText(title, 20),
        pw.SizedBox(height: 12),
        _safeText('生成时间：$dateStr', 11),
        pw.SizedBox(height: 20),
        _safeText('AI 任务指令', 16),
        pw.SizedBox(height: 8),
        _safeText(prompt, 11, height: 1.5),
      ]);
      bytes = await fb.save();
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

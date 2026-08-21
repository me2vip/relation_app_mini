import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  /// 扫描到的首个 CJK 字体实例；找不到就是 null，退回 print/PDF 默认字体
  static pw.Font? _chineseFont;
  static bool _scanned = false;

  /// 关键词优先级顺序：越靠前越先尝试
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
          return '${i.toString().padLeft(2, '0')}_${lower.split('/').last}';
        }
      }
      return '99_${lower.split('/').last}';
    }
    candidates.sort((a, b) => score(a).compareTo(score(b)));

    for (final path in candidates) {
      try {
        final file = File(path);
        final bytes = await file.readAsBytes();
        if (bytes.length < 1024) continue;
        try {
          final font = pw.Font.ttf(bytes.buffer.asByteData());
          _chineseFont = font;
          // ignore: avoid_print
          print('[PdfExporter] 扫描${candidates.length}个字体，已加载CJK字体: ${path.split('/').last}');
          return;
        } catch (_) {
          // ttc/otf 解析失败继续下一个
        }
      } catch (_) {}
    }

    // ignore: avoid_print
    print('[PdfExporter] 扫描${candidates.length}个字体，未找到可加载的中文字体，使用系统默认字体');
  }

  /// 构造 ThemeData：
  /// - 如果找到中文字体，就把 base/bold/italic/boldItalic 全部指向同一个字体实例
  ///   （避免 pdf 库内部因缺少 bold/italic 子集走合成分支引发 ! 断言）
  /// - 否则直接用 ThemeData.withFont() 全部为 null，退回 pdf 默认 Helvetica
  static pw.ThemeData _buildTheme() {
    final f = _chineseFont;
    if (f == null) return pw.ThemeData.withFont();
    return pw.ThemeData.withFont(
      base: f,
      bold: f,
      italic: f,
      boldItalic: f,
    );
  }

  /// 构造标准 Markdown 文本，交给 print/pdf 的 pw.MarkdownParser 渲染。
  /// MarkdownParser 是 pdf 包官方提供并经过大量测试的，
  /// 不容易触发 Null check 内部断言，同时天然支持标题/列表/代码块/分割线。
  static String _buildMarkdown({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
    required String dateStr,
  }) {
    final md = StringBuffer();

    md.writeln('# $title');
    md.writeln();
    md.writeln('> 生成时间：$dateStr');
    if (contactName != null && contactName.isNotEmpty) {
      md.writeln('> 联系人：$contactName');
    }
    md.writeln();
    md.writeln('---');
    md.writeln();

    md.writeln('## 使用说明');
    md.writeln();
    md.writeln('1. 将此PDF文档发送给 AI（千问、豆包、GPT等）');
    md.writeln('2. 对 AI 说：请按照此PDF文档的要求执行任务');
    md.writeln('3. 等待 AI 返回分析结果');
    md.writeln('4. 将 AI 的回复完整复制回 APP');
    md.writeln();

    if (context != null && context.isNotEmpty) {
      md.writeln('## 背景信息 / 素材');
      md.writeln();
      md.writeln('> ${context.replaceAll('\n', '\n> ')}');
      md.writeln();
    }

    md.writeln('## AI 任务指令');
    md.writeln();
    // 指令中可能包含 ```json``` 代码块，直接保留原始 markdown 内容
    md.writeln(prompt);
    md.writeln();

    if (attachments != null && attachments.isNotEmpty) {
      md.writeln('## 附件 / 素材列表');
      md.writeln();
      md.writeln('以下素材已通过APP附加，请AI分析时结合考虑：');
      md.writeln();
      for (final att in attachments) {
        md.writeln('- $att');
      }
      md.writeln();
    }

    md.writeln('---');
    md.writeln();
    md.writeln('### ⚠️ 重要提示');
    md.writeln();
    md.writeln(
      '将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，'
      'APP 将自动解析 JSON 并保存为任务。',
    );

    return md.toString();
  }

  static Future<File> exportExternalAIPdf({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    // 1. 字体准备（失败不阻塞，退回默认字体）
    try {
      await _scanAndLoadFonts();
    } catch (_) {}

    final theme = _buildTheme();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    // 2. 构造 markdown 字符串
    final markdown = _buildMarkdown(
      title: title,
      prompt: prompt,
      contactName: contactName,
      context: context,
      attachments: attachments,
      dateStr: dateStr,
    );

    // 3. 保存 PDF：优先走 pw.MarkdownParser；失败则退回极简文本渲染
    List<int> bytes;
    try {
      final pdf = pw.Document(theme: theme);
      final mdParser = pw.MarkdownParser(
        styleSheet: _mdStyleSheet(theme),
        imageDelegate: null,
      );
      final mdWidgets = mdParser.parse(markdown);
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) => mdWidgets,
        ),
      );
      bytes = await pdf.save();
    } catch (e, st) {
      // ignore: avoid_print
      print('[PdfExporter] Markdown渲染失败，退回纯文本PDF: $e\n$st');
      bytes = await _renderPlainTextFallback(
        title,
        prompt,
        contactName,
        context,
        attachments,
        dateStr,
        theme,
      );
    }

    // 4. 写文件
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

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// MarkdownParser 的样式：只改字号/颜色，不碰 fontWeight/fontStyle，
  /// 避免 pdf 库内部组合字体的 ! 断言。
  static pw.MarkdownStyleSheet _mdStyleSheet(pw.ThemeData theme) {
    final f = _chineseFont;
    pw.TextStyle t(double size, {PdfColor? color, double? height}) {
      if (f != null) {
        return pw.TextStyle(
          font: f,
          fontSize: size,
          color: color,
          height: height,
        );
      }
      return pw.TextStyle(fontSize: size, color: color, height: height);
    }

    return pw.MarkdownStyleSheet(
      a: t(11),
      p: t(11, height: 1.5),
      h1: t(22, height: 1.3),
      h2: t(16, height: 1.3),
      h3: t(13),
      h4: t(12),
      h5: t(11),
      h6: t(11),
      em: t(11),
      strong: t(11),
      blockquote: t(11, color: PdfColors.grey700),
      code: t(10.5),
      tableHead: t(11),
      tableBody: t(11),
      listBullet: t(11),
      horizontalRuleColor: PdfColors.grey300,
      horizontalRuleHeight: 1,
      blockquoteDecoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: PdfColors.indigo400, width: 3)),
        color: PdfColors.indigo50,
      ),
      codeblockDecoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
    );
  }

  /// Markdown 路径失败时的终极兜底：完全不使用 MarkdownParser 与 MultiPage，
  /// 只通过最简单的 pw.Page + pw.Column + pw.Text 组合，确保能出 PDF 文件。
  static Future<List<int>> _renderPlainTextFallback(
    String title,
    String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
    String dateStr,
    pw.ThemeData theme,
  ) async {
    final f = _chineseFont;
    pw.TextStyle ts(double size, {PdfColor? color, double? height}) =>
        f != null
            ? pw.TextStyle(font: f, fontSize: size, color: color, height: height)
            : pw.TextStyle(fontSize: size, color: color, height: height);
    pw.Widget txt(String? raw, double size,
            {PdfColor? color, double? height}) =>
        pw.Text(
          (raw ?? '').replaceAllMapped(
            RegExp(
                r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F02F}]',
                unicode: true),
            (m) => ''),
          style: ts(size, color: color, height: height),
        );

    final children = <pw.Widget>[
      txt(title, 22, height: 1.3),
      pw.SizedBox(height: 6),
      txt('生成时间：$dateStr', 10, color: PdfColors.grey500),
      if (contactName != null && contactName.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        txt('联系人：$contactName', 10, color: PdfColors.grey500),
      ],
      pw.SizedBox(height: 14),
      pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 14),
      txt('使用说明', 16, height: 1.3),
      pw.SizedBox(height: 8),
      txt('1. 将此PDF文档发送给 AI（千问、豆包、GPT等）', 11, height: 1.5),
      txt('2. 对 AI 说：请按照此PDF文档的要求执行任务', 11, height: 1.5),
      txt('3. 等待 AI 返回分析结果', 11, height: 1.5),
      txt('4. 将 AI 的回复完整复制回 APP', 11, height: 1.5),
      pw.SizedBox(height: 16),
    ];

    if (context != null && context.isNotEmpty) {
      children.addAll(<pw.Widget>[
        txt('背景信息 / 素材', 16, height: 1.3),
        pw.SizedBox(height: 8),
        txt(context, 11, color: PdfColors.grey700, height: 1.5),
        pw.SizedBox(height: 16),
      ]);
    }

    children.addAll(<pw.Widget>[
      txt('AI 任务指令', 16, height: 1.3),
      pw.SizedBox(height: 8),
      txt(prompt, 11, height: 1.5),
      pw.SizedBox(height: 16),
    ]);

    if (attachments != null && attachments.isNotEmpty) {
      children.add(txt('附件 / 素材列表', 16, height: 1.3));
      children.add(pw.SizedBox(height: 8));
      children.add(txt('以下素材已通过APP附加，请AI分析时结合考虑：', 11,
          color: PdfColors.grey600));
      children.add(pw.SizedBox(height: 8));
      for (final att in attachments) {
        children.add(txt('- $att', 11, height: 1.5));
      }
      children.add(pw.SizedBox(height: 16));
    }

    children.addAll(<pw.Widget>[
      pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 12),
      txt('重要提示：', 12, color: PdfColors.amber800),
      pw.SizedBox(height: 6),
      txt(
        '将 AI 的完整回复（包括思考过程和分析结果）复制回 APP，APP 将自动解析 JSON 并保存为任务。',
        11,
        color: PdfColors.amber700,
        height: 1.5,
      ),
    ]);

    final pdf = pw.Document(theme: theme);
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
    return pdf.save();
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

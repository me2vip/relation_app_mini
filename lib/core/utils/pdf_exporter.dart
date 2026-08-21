import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  /// 扫描到的首个 CJK 字体实例；找不到就是 null，退回 pdf 默认字体
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
        } catch (_) {}
      } catch (_) {}
    }

    // ignore: avoid_print
    print('[PdfExporter] 扫描${candidates.length}个字体，未找到可加载的中文字体，使用系统默认字体');
  }

  /// 构造 ThemeData：
  /// - 找到中文字体：base/bold/italic/boldItalic 全部指向同一个实例，
  ///   避免 pdf 库内部合成 bold/italic 子集时触发 ! 断言。
  /// - 否则退回 ThemeData.withFont() 全空，pdf 使用内置 Helvetica。
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

  // ==================================================================
  // Markdown -> List<pw.Widget> 自渲染（无需依赖 pdf 包内置 markdown parser，
  // 该 parser 在 3.13+ 已被移除/更名）。
  // 支持语法：ATX 标题(#~######)、有序列表、无序列表(-/*)、> blockquote、
  // ``` fenced 代码块、--- 分割线、普通段落。
  // ==================================================================

  static pw.TextStyle _ts(double size, {PdfColor? color, double? height}) {
    final f = _chineseFont;
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

  static String _strip(String s) {
    // 去掉 emoji & 控制字符
    var r = s;
    try {
      r = r.replaceAllMapped(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F02F}]',
            unicode: true),
        (m) => '',
      );
    } catch (_) {}
    r = r.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return r;
  }

  static pw.Widget _txt(String raw, double size,
      {PdfColor? color, double? height, pw.TextAlign? align}) {
    return pw.Text(
      _strip(raw),
      style: _ts(size, color: color, height: height),
      textAlign: align ?? pw.TextAlign.left,
    );
  }

  /// 将 Markdown 文本解析为 widget 列表（不支持嵌套块，仅顶层结构）
  static List<pw.Widget> _renderMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final out = <pw.Widget>[];
    final paraBuffer = StringBuffer();
    bool inFence = false;
    final fenceBuffer = StringBuffer();
    int? listLevel;   // 1 = ordered, 2 = unordered
    final listBuffer = <String>[];

    void flushPara() {
      if (paraBuffer.isEmpty) return;
      out.add(_txt(paraBuffer.toString().trimRight(), 11, height: 1.5));
      out.add(pw.SizedBox(height: 8));
      paraBuffer.clear();
    }

    void flushList() {
      final lv = listLevel;
      if (listBuffer.isEmpty || lv == null) return;
      final children = <pw.Widget>[];
      for (var i = 0; i < listBuffer.length; i++) {
        final bullet = lv == 1 ? '${i + 1}. ' : '• ';
        children.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 16, child: _txt(bullet, 11)),
              pw.Expanded(child: _txt(listBuffer[i], 11, height: 1.5)),
            ],
          ),
        );
        if (i != listBuffer.length - 1) {
          children.add(pw.SizedBox(height: 4));
        }
      }
      out.add(pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ));
      out.add(pw.SizedBox(height: 10));
      listBuffer.clear();
      listLevel = null;
    }

    void flushFence() {
      if (fenceBuffer.isEmpty) {
        inFence = false;
        return;
      }
      out.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: _txt(fenceBuffer.toString().trimRight(), 10.5, height: 1.4),
        ),
      );
      out.add(pw.SizedBox(height: 12));
      fenceBuffer.clear();
      inFence = false;
    }

    final ordered = RegExp(r'^\s*\d+\.\s+(.*)$');
    final unordered = RegExp(r'^\s*[-*+]\s+(.*)$');
    final quote = RegExp(r'^>\s?(.*)$');
    final fence = RegExp(r'^\s*```');
    final atx = RegExp(r'^(#{1,6})\s+(.*)$');
    final hr = RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (inFence) {
        if (fence.hasMatch(line)) {
          flushFence();
        } else {
          if (fenceBuffer.isNotEmpty) fenceBuffer.writeln();
          fenceBuffer.write(line);
        }
        continue;
      }

      if (fence.hasMatch(line)) {
        flushPara();
        flushList();
        inFence = true;
        continue;
      }

      if (hr.hasMatch(line)) {
        flushPara();
        flushList();
        out.add(pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300));
        out.add(pw.SizedBox(height: 10));
        continue;
      }

      final atxMatch = atx.firstMatch(line);
      if (atxMatch != null) {
        flushPara();
        flushList();
        final g1 = atxMatch.group(1);
        final g2 = atxMatch.group(2);
        if (g1 == null || g2 == null) {
          // 当做普通段落
          if (paraBuffer.isNotEmpty) paraBuffer.write(' ');
          paraBuffer.write(line.trim());
          continue;
        }
        final level = g1.length;
        final text = g2.trim();
        late double size;
        double height = 1.3;
        switch (level) {
          case 1:
            size = 22;
            break;
          case 2:
            size = 16;
            break;
          case 3:
            size = 14;
            break;
          case 4:
            size = 13;
            break;
          case 5:
          case 6:
          default:
            size = 12;
        }
        out.add(_txt(text, size, height: height));
        out.add(pw.SizedBox(height: level == 1 ? 10 : 8));
        continue;
      }

      final ord = ordered.firstMatch(line);
      if (ord != null) {
        flushPara();
        final g = ord.group(1);
        if (g != null) {
          if (listLevel != 1) flushList();
          listLevel = 1;
          listBuffer.add(g.trim());
        }
        continue;
      }

      final unord = unordered.firstMatch(line);
      if (unord != null) {
        flushPara();
        final g = unord.group(1);
        if (g != null) {
          if (listLevel != 2) flushList();
          listLevel = 2;
          listBuffer.add(g.trim());
        }
        continue;
      }

      final q = quote.firstMatch(line);
      if (q != null) {
        flushPara();
        flushList();
        final first = q.group(1) ?? '';
        final content = StringBuffer(first);
        while (i + 1 < lines.length) {
          final next = lines[i + 1];
          final nq = quote.firstMatch(next);
          if (nq == null) break;
          i++;
          content.writeln();
          content.write(nq.group(1) ?? '');
        }
        out.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.indigo400, width: 3)),
              color: PdfColors.indigo50,
            ),
            child: _txt(content.toString().trimRight(), 11,
                color: PdfColors.grey700, height: 1.5),
          ),
        );
        out.add(pw.SizedBox(height: 12));
        continue;
      }

      if (line.trim().isEmpty) {
        flushPara();
        flushList();
        continue;
      }

      // 普通段落
      if (paraBuffer.isNotEmpty) paraBuffer.write(' ');
      paraBuffer.write(line.trim());
    }

    flushPara();
    flushList();
    if (inFence) flushFence();
    return out;
  }

  /// 构造标准 Markdown 字符串
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
      for (final l in context.split('\n')) {
        md.writeln('> ${l.trimRight()}');
      }
      md.writeln();
    }

    md.writeln('## AI 任务指令');
    md.writeln();
    // 指令中可能包含 ```json``` 代码块，直接保留原始内容
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
    md.writeln('### 重要提示');
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
    // 1. 字体准备（失败不阻塞）
    try {
      await _scanAndLoadFonts();
    } catch (_) {}

    final theme = _buildTheme();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    // 2. Markdown 字符串 -> Widget 列表
    final markdown = _buildMarkdown(
      title: title,
      prompt: prompt,
      contactName: contactName,
      context: context,
      attachments: attachments,
      dateStr: dateStr,
    );

    // 3. 保存 PDF：优先自建 Markdown 渲染器 + 多个 pw.Page 分页；
    //    完全不使用 pw.MultiPage（其内部 pageContext.pagesCount 在 pdf 3.13
    //    使用了 ! 断言）和 MarkdownParser/MarkdownStyleSheet（3.13 已移除）。
    List<int> bytes;
    try {
      final widgets = _renderMarkdown(markdown);
      final pdf = pw.Document(theme: theme);

      // 粗略分页：每 60 个 widget 一页（仅避免单页过高，不需要精确）
      const chunkSize = 60;
      final chunks = <List<pw.Widget>>[];
      for (var i = 0; i < widgets.length; i += chunkSize) {
        chunks.add(widgets.sublist(
            i, i + chunkSize > widgets.length ? widgets.length : i + chunkSize));
      }
      // 至少一页
      if (chunks.isEmpty) chunks.add([pw.SizedBox.shrink()]);

      for (final chunk in chunks) {
        pdf.addPage(
          pw.Page(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: chunk,
            ),
          ),
        );
      }
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

  /// Markdown 路径失败时的终极兜底：极简 widget 树，尽量不依赖 pdf 高级 API
  static Future<List<int>> _renderPlainTextFallback(
    String title,
    String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
    String dateStr,
    pw.ThemeData theme,
  ) async {
    final children = <pw.Widget>[
      _txt(title, 22, height: 1.3),
      pw.SizedBox(height: 6),
      _txt('生成时间：$dateStr', 10, color: PdfColors.grey500),
      if (contactName != null && contactName.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        _txt('联系人：$contactName', 10, color: PdfColors.grey500),
      ],
      pw.SizedBox(height: 14),
      pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 14),
      _txt('使用说明', 16, height: 1.3),
      pw.SizedBox(height: 8),
      _txt('1. 将此PDF文档发送给 AI（千问、豆包、GPT等）', 11, height: 1.5),
      _txt('2. 对 AI 说：请按照此PDF文档的要求执行任务', 11, height: 1.5),
      _txt('3. 等待 AI 返回分析结果', 11, height: 1.5),
      _txt('4. 将 AI 的回复完整复制回 APP', 11, height: 1.5),
      pw.SizedBox(height: 16),
    ];

    if (context != null && context.isNotEmpty) {
      children.addAll(<pw.Widget>[
        _txt('背景信息 / 素材', 16, height: 1.3),
        pw.SizedBox(height: 8),
        _txt(context, 11, color: PdfColors.grey700, height: 1.5),
        pw.SizedBox(height: 16),
      ]);
    }

    children.addAll(<pw.Widget>[
      _txt('AI 任务指令', 16, height: 1.3),
      pw.SizedBox(height: 8),
      _txt(prompt, 11, height: 1.5),
      pw.SizedBox(height: 16),
    ]);

    if (attachments != null && attachments.isNotEmpty) {
      children.add(_txt('附件 / 素材列表', 16, height: 1.3));
      children.add(pw.SizedBox(height: 8));
      children.add(_txt('以下素材已通过APP附加，请AI分析时结合考虑：', 11,
          color: PdfColors.grey600));
      children.add(pw.SizedBox(height: 8));
      for (final att in attachments) {
        children.add(_txt('- $att', 11, height: 1.5));
      }
      children.add(pw.SizedBox(height: 16));
    }

    children.addAll(<pw.Widget>[
      pw.Divider(height: 1, thickness: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 12),
      _txt('重要提示：', 12, color: PdfColors.amber800),
      pw.SizedBox(height: 6),
      _txt(
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

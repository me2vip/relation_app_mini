import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdf_export/flutter_pdf_export.dart';

class PdfExporter {
  static pw.Font? _chineseFont;
  static bool _scanned = false;
  static String? _loadedFontPath;

  static const List<String> _chineseFontKeywords = [
    'notosanscjktc', 'notosanssc', 'notosanssc-regular',
    'notoserifsc', 'notoserifcjk', 'sourcehansans', 'sourcehanserif',
    'droidsansfallback', 'droidsansfallbackfull', 'droidsans',
    'robotofallback', 'robotofallback-regular',
    'miui', 'miui-regular', 'miui-bold', 'miuiui',
    'hansans', 'hansanscn', 'hansanshans',
    'pingfang', 'pingfangsc',
    'harmonyos', 'harmonyossans', 'harmonyos-sans',
    'gbcsans', 'gbc',
    'heiti', 'songti', 'kaiti',
    'fangzheng', 'wenquanyi', 'wenquanyimicro',
    'google', 'googlesans', 'googlesanssc',
    'arphic', 'arphicgothic', 'arphicming',
    'notosans-regular', 'notoserif-regular',
    'sans', 'serif',
  ];

  static const List<String> _systemFontDirs = [
    '/system/fonts',
    '/system/font',
    '/system/fonts/hwfonts',
    '/system/fonts/oppo',
    '/system/fonts/vivo',
    '/system/fonts/miui',
    '/product/fonts',
    '/product/fonts/fonts',
    '/vendor/fonts',
    '/vendor/fonts/fonts',
    '/data/fonts',
    '/data/local/fonts',
    '/mnt/system/fonts',
    '/mnt/vendor/fonts',
    '/system_ext/fonts',
    '/odm/fonts',
    '/system/system_ext/fonts',
  ];

  static const List<String> _hardCodedFontPaths = [
    '/system/fonts/DroidSansFallback.ttf',
    '/system/fonts/DroidSans.ttf',
    '/system/fonts/DroidSansFallbackFull.ttf',
    '/system/fonts/RobotoFallback-Regular.ttf',
    '/system/fonts/RobotoFallback.ttf',
    '/system/fonts/RobotoFallback-Bold.ttf',
    '/system/fonts/NotoSans-Regular.ttf',
    '/system/fonts/NotoSerif-Regular.ttf',
    '/system/fonts/NotoSansCJK-Regular.ttc',
    '/system/fonts/NotoSansCJK-Regular.ttf',
    '/system/fonts/NotoSansSC-Regular.ttf',
    '/system/fonts/NotoSerifCJK-Regular.ttc',
    '/system/fonts/SourceHanSans-Regular.otf',
    '/system/fonts/SourceHanSC-Regular.otf',
    '/system/fonts/DejaVuSans.ttf',
    '/system/fonts/DejaVuSans.ttc',
    '/system/fonts/GoogleSans-Regular.ttf',
    '/system/fonts/GoogleSansSC-Regular.ttf',
    '/system/fonts/HanSans-Regular.ttf',
    '/system/fonts/HanSansCN-Regular.ttf',
    '/system/fonts/Miui-Regular.ttf',
    '/system/fonts/Miui-Bold.ttf',
    '/system/fonts/PingFangSC-Regular.ttf',
    '/system/fonts/HarmonyOS-Sans-Regular.ttf',
    '/system/fonts/HarmonyOSSans-Regular.ttf',
    '/system/fonts/DroidSansFallbackHuaWei.ttf',
    '/system/fonts/DroidSansFallbackMT.ttf',
    '/system/fonts/HwHuaWeiSans.ttf',
    '/system/fonts/HwSansCN.ttf',
    '/system/fonts/HeitiSC.ttf',
    '/system/fonts/Songti.ttc',
    '/system/fonts/Kaiti.ttf',
    '/system/fonts/FangZhengSan.ttf',
    '/system/fonts/WenQuanYiMicroHei.ttf',
    '/system/fonts/ARPL-UMing.ttf',
    '/system/fonts/GBCSans.ttf',
  ];

  static Future<void> _scanAndLoadFonts() async {
    if (_scanned) return;
    _scanned = true;

    final candidates = <String>[..._hardCodedFontPaths];

    for (final dir in _systemFontDirs) {
      try {
        final d = Directory(dir);
        if (!await d.exists()) continue;
        await for (final f in d.list(recursive: true, followLinks: false)) {
          if (f is! File) continue;
          final lower = f.path.toLowerCase();
          if (_isFontFile(lower)) {
            candidates.add(f.path);
          }
        }
      } catch (_) {}
    }

    final seen = <String>{};
    candidates.removeWhere((p) => !seen.add(p));
    candidates.sort((a, b) => _fontScore(a).compareTo(_fontScore(b)));

    for (final path in candidates) {
      final font = await _tryLoadFont(path);
      if (font != null) {
        _chineseFont = font;
        _loadedFontPath = path;
        return;
      }
    }

    _chineseFont = await _loadFallbackFont();
  }

  static bool _isFontFile(String path) {
    return path.endsWith('.ttf') ||
        path.endsWith('.otf') ||
        path.endsWith('.ttc') ||
        path.endsWith('.dfont');
  }

  static String _fontScore(String path) {
    final lower = path.toLowerCase();
    for (var i = 0; i < _hardCodedFontPaths.length; i++) {
      if (path == _hardCodedFontPaths[i]) return '00_$i';
    }
    for (var i = 0; i < _chineseFontKeywords.length; i++) {
      if (lower.contains(_chineseFontKeywords[i])) {
        return '${(i + 1).toString().padLeft(3, '0')}_${lower.split('/').last}';
      }
    }
    if (lower.endsWith('.ttf')) return '050_${lower.split('/').last}';
    if (lower.endsWith('.otf')) return '060_${lower.split('/').last}';
    if (lower.endsWith('.ttc')) return '070_${lower.split('/').last}';
    return '099_${lower.split('/').last}';
  }

  static Future<pw.Font?> _tryLoadFont(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.length < 2048) return null;

      final font = pw.Font.ttf(Uint8List.fromList(bytes).buffer.asByteData());
      if (_validateFont(font)) {
        return font;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static bool _validateFont(pw.Font font) {
    try {
      final testStyle = pw.TextStyle(font: font, fontSize: 12);
      return testStyle.fontSize == 12;
    } catch (e) {
      return false;
    }
  }

  static Future<pw.Font?> _loadFallbackFont() async {
    const fallbackPaths = [
      '/system/fonts/DroidSansFallback.ttf',
      '/system/fonts/DroidSansFallbackFull.ttf',
      '/system/fonts/NotoSans-Regular.ttf',
      '/system/fonts/DejaVuSans.ttf',
    ];

    for (final path in fallbackPaths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.length < 2048) continue;
        final font = pw.Font.ttf(Uint8List.fromList(bytes).buffer.asByteData());
        if (_validateFont(font)) {
          return font;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> initializeFonts({bool forceRescan = false}) async {
    if (forceRescan) {
      _scanned = false;
      _chineseFont = null;
      _loadedFontPath = null;
    }
    await _scanAndLoadFonts();
  }

  static bool get hasChineseFont => _chineseFont != null;

  static String? get loadedFontPath => _loadedFontPath;

  static Future<bool> loadFontFromPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      if (bytes.length < 2048) return false;

      final font = pw.Font.ttf(Uint8List.fromList(bytes).buffer.asByteData());
      if (_validateFont(font)) {
        _chineseFont = font;
        _loadedFontPath = path;
        _scanned = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> scanAvailableFonts() async {
    final fonts = <String>[];

    for (final dir in _systemFontDirs) {
      try {
        final d = Directory(dir);
        if (!await d.exists()) continue;
        await for (final f in d.list(recursive: true, followLinks: false)) {
          if (f is! File) continue;
          final lower = f.path.toLowerCase();
          if (_isFontFile(lower)) {
            try {
              final bytes = await f.readAsBytes();
              if (bytes.length >= 2048) {
                fonts.add(f.path);
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    fonts.sort((a, b) => _fontScore(a).compareTo(_fontScore(b)));
    return fonts;
  }

  static pw.ThemeData _buildTheme() {
    return pw.ThemeData.withFont();
  }

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

  static List<pw.Widget> _renderMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final out = <pw.Widget>[];
    final paraBuffer = StringBuffer();
    bool inFence = false;
    final fenceBuffer = StringBuffer();
    int? listLevel;
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
    final imageLine = RegExp(r'^\s*!\[([^\]]*)\]\((.+)\)\s*$');

    pw.Widget? _tryLoadImage(String path, String alt) {
      try {
        final f = File(path);
        if (!f.existsSync()) return null;
        final bytes = f.readAsBytesSync();
        if (bytes.isEmpty) return null;
        final mem = pw.MemoryImage(bytes);
        return pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(mem,
              width: 515,
              height: 360,
              fit: pw.BoxFit.contain,
              alignment: pw.Alignment.center),
        );
      } catch (e) {
        return null;
      }
    }

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

      final img = imageLine.firstMatch(line);
      if (img != null) {
        flushPara();
        flushList();
        final alt = img.group(1) ?? '';
        final path = (img.group(2) ?? '').trim();
        if (path.isNotEmpty) {
          final w = _tryLoadImage(path, alt);
          if (w != null) {
            if (alt.isNotEmpty) {
              out.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 6),
                  w,
                  pw.SizedBox(height: 4),
                  _txt(alt, 10, color: PdfColors.grey600),
                  pw.SizedBox(height: 14),
                ],
              ));
            } else {
              out.add(pw.Column(children: [
                pw.SizedBox(height: 6),
                w,
                pw.SizedBox(height: 14),
              ]));
            }
            continue;
          }
          out.add(_txt('[图片：$alt] (${path.split('/').last} 加载失败)',
              11, color: PdfColors.red600));
          out.add(pw.SizedBox(height: 10));
          continue;
        }
      }

      final atxMatch = atx.firstMatch(line);
      if (atxMatch != null) {
        flushPara();
        flushList();
        final g1 = atxMatch.group(1);
        final g2 = atxMatch.group(2);
        if (g1 == null || g2 == null) {
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
          final innerImg = imageLine.firstMatch(g.trim());
          if (innerImg != null) {
            flushList();
            final alt = innerImg.group(1) ?? '';
            final path = (innerImg.group(2) ?? '').trim();
            if (path.isNotEmpty) {
              final w = _tryLoadImage(path, alt);
              if (w != null) {
                out.add(pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _txt('${(listBuffer.length + 1)}.', 11),
                    pw.SizedBox(height: 4),
                    w,
                    if (alt.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      _txt(alt, 10, color: PdfColors.grey600),
                    ],
                    pw.SizedBox(height: 14),
                  ],
                ));
                continue;
              }
            }
          }
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
          final innerImg = imageLine.firstMatch(g.trim());
          if (innerImg != null) {
            flushList();
            final alt = innerImg.group(1) ?? '';
            final path = (innerImg.group(2) ?? '').trim();
            if (path.isNotEmpty) {
              final w = _tryLoadImage(path, alt);
              if (w != null) {
                out.add(pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _txt('•', 11),
                    pw.SizedBox(height: 4),
                    w,
                    if (alt.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      _txt(alt, 10, color: PdfColors.grey600),
                    ],
                    pw.SizedBox(height: 14),
                  ],
                ));
                continue;
              }
            }
          }
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

      if (paraBuffer.isNotEmpty) paraBuffer.write(' ');
      paraBuffer.write(line.trim());
    }

    flushPara();
    flushList();
    if (inFence) flushFence();
    return out;
  }

  static String buildMarkdown({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
    required String dateStr,
  }) {
    return _buildMarkdown(
      title: title,
      prompt: prompt,
      contactName: contactName,
      context: context,
      attachments: attachments,
      dateStr: dateStr,
    );
  }

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
    md.writeln(prompt);
    md.writeln();

    if (attachments != null && attachments.isNotEmpty) {
      md.writeln('## 附件 / 素材列表');
      md.writeln();
      md.writeln('以下素材已通过APP附加，请AI分析时结合考虑：');
      md.writeln();
      for (final att in attachments) {
        if (att.startsWith('![') && att.contains('](')) {
          md.writeln(att);
        } else {
          md.writeln('- $att');
        }
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

  static String _formatError(String phase, Object e, StackTrace st) {
    final msg = e.toString().replaceAll('\n', ' ');
    final head = '[$phase] $msg';
    final lines = st.toString().split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return head;
    final top = lines.take(2).map((l) => l.trim()).join(' | ');
    return '$head  Stack: $top';
  }

  static Future<({File file, String level, String fallbackReport})> exportExternalAIPdfEx({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

      final markdown = _buildMarkdown(
        title: title,
        prompt: prompt,
        contactName: contactName,
        context: context,
        attachments: attachments,
        dateStr: dateStr,
      );

      final errors = <String>[];

      // L0: 使用 flutter_pdf_export (支持中文，使用 Noto Sans SC 字体)
      try {
        final phase = 'L0_flutter_pdf_export';
        final file = await _exportWithFlutterPdfExport(title, markdown, now);
        return (
          file: file,
          level: phase,
          fallbackReport: errors.join('\n'),
        );
      } catch (e, st) {
        final line = _formatError('L0_flutter_pdf_export', e, st);
        errors.add(line);
      }

      // L1: 降级到自建渲染器 (使用系统中文字体)
      try {
        final phase = 'L1_fallback';
        await _scanAndLoadFonts();
        final theme = _buildTheme();
        final widgets = _renderMarkdown(markdown);
        final f = await _saveWidgetsToPdf(title, now, widgets, theme);
        return (
          file: f,
          level: phase,
          fallbackReport: errors.join('\n'),
        );
      } catch (e, st) {
        final line = _formatError('L1_fallback', e, st);
        errors.add(line);
      }

      // L2: 最终兜底
      try {
        final phase = 'L2_final';
        final theme = _buildTheme();
        _chineseFont = null;
        final bytes = await _renderPlainTextFallback(
          title, prompt, contactName, context, attachments, dateStr, theme,
        );
        final f = await _writePdfFile(title, now, bytes);
        return (
          file: f,
          level: phase,
          fallbackReport: errors.join('\n'),
        );
      } catch (e, st) {
        final line = _formatError('L2_final', e, st);
        errors.add(line);
      }

      throw StateError('PDF导出失败\n${errors.join('\n')}');
    } catch (e, st) {
      if (e is StateError && (e.message ?? '').startsWith('PDF导出失败')) {
        rethrow;
      }
      final extra = _formatError('GLOBAL', e, st);
      throw StateError('PDF导出失败(global)\n$extra');
    }
  }

  static Future<File> _exportWithFlutterPdfExport(
      String title, String markdown, DateTime now) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '社交塔子_${safeTitle}_$timestamp.pdf';
    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/$fileName';

    final file = await PdfBuilder.generate(
      PdfDocumentData.fromMarkdown(
        title: title,
        markdown: markdown,
        style: PdfStyle.light.copyWith(
          accentColor: PdfColor.fromInt(0xFF0066CC),
          footerLeftText: '社交塔子 AI任务中心',
          footerCenterText: 'AI 任务生成素材',
          showPageNumbers: true,
          bodyFontSize: 13,
        ),
      ),
    );

    if (file.path != outputPath) {
      final savedFile = await file.copy(outputPath);
      return savedFile;
    }

    return file;
  }

  static Future<File> exportExternalAIPdf({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    final r = await exportExternalAIPdfEx(
      title: title,
      prompt: prompt,
      contactName: contactName,
      context: context,
      attachments: attachments,
    );
    return r.file;
  }

  static Future<File> _saveWidgetsToPdf(
    String title,
    DateTime now,
    List<pw.Widget> widgets,
    pw.ThemeData theme,
  ) async {
    final pdf = pw.Document(theme: theme);
    const chunkSize = 60;
    final chunks = <List<pw.Widget>>[];
    if (widgets.isEmpty) {
      chunks.add([pw.SizedBox.shrink()]);
    } else {
      for (var i = 0; i < widgets.length; i += chunkSize) {
        final end = i + chunkSize;
        chunks.add(widgets.sublist(i, end > widgets.length ? widgets.length : end));
      }
    }

    for (final chunk in chunks) {
      try {
        pdf.addPage(
          pw.Page(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (_) {
              try {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: chunk,
                );
              } catch (_) {
                return pw.Column(children: [pw.SizedBox.shrink()]);
              }
            },
          ),
        );
      } catch (_) {}
    }

    final bytes = await pdf.save();
    return _writePdfFile(title, now, bytes);
  }

  static Future<File> _writePdfFile(
    String title,
    DateTime now,
    List<int> bytes,
  ) async {
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
    await file.writeBytes(bytes);
    return file;
  }

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
    try {
      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) {
            try {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: children,
              );
            } catch (_) {
              return pw.Column(
                children: [pw.Text('(此页渲染失败，请查看APP原始文本提示词)')],
              );
            }
          },
        ),
      );
    } catch (_) {}
    return pdf.save();
  }

  static Future<File> writeMarkdownSidecar(String title, String markdown) async {
    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '社交塔子_${safeTitle}_$timestamp.md';
    final filePath = '${dir.path}/$fileName';
    final f = File(filePath);
    await f.writeAsString(markdown);
    return f;
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

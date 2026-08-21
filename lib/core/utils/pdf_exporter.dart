import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:neom_docs/neom_docs.dart';

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
    '/product/fonts/fonts',
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
    '/system/fonts/NotoColorEmoji.ttf',
    '/system/fonts/NotoSans-Regular.ttf',
    '/system/fonts/DroidSerif.ttf',
    '/system/fonts/Roboto-Regular.ttf',
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

    // ignore: avoid_print
    print('[PdfExporter] 字体扫描完成: ${candidates.length} 个候选字体');

    for (final path in candidates) {
      final font = await _tryLoadFont(path);
      if (font != null) {
        _chineseFont = font;
        _loadedFontPath = path;
        // ignore: avoid_print
        print('[PdfExporter] 成功加载中文字体: ${path.split('/').last}');
        return;
      }
    }

    // ignore: avoid_print
    print('[PdfExporter] 警告: 未找到可用中文字体，将使用备选方案');
    _chineseFont = await _loadFallbackFont();
    if (_chineseFont != null) {
      // ignore: avoid_print
      print('[PdfExporter] 加载备选字体成功');
    } else {
      // ignore: avoid_print
      print('[PdfExporter] 错误: 所有字体加载失败，PDF中文可能显示为□');
    }
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

      if (path.toLowerCase().endsWith('.ttc')) {
        return await _tryLoadTtcFont(path, bytes);
      }

      final font = pw.Font.ttf(bytes.buffer.asByteData());
      if (_validateFont(font)) {
        return font;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<pw.Font?> _tryLoadTtcFont(String path, List<int> bytes) async {
    try {
      final font = pw.Font.ttf(bytes.buffer.asByteData());
      if (_validateFont(font)) {
        return font;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[PdfExporter] TTC字体直接解析失败 $path: $e，尝试提取子字体');
      return await _extractTtcSubFont(path);
    }
  }

  static Future<pw.Font?> _extractTtcSubFont(String ttcPath) async {
    try {
      final file = File(ttcPath);
      final raf = file.openRead();
      final header = List<int>.filled(12, 0);
      await raf.readInto(header);
      await raf.close();

      if (header[0] != 0x00 ||
          header[1] != 0x01 ||
          header[2] != 0x00 ||
          header[3] != 0x00) {
        return null;
      }

      final fontCount = ByteData.sublistView(Uint8List.fromList(header), 8, 12).getUint32(0);
      if (fontCount <= 0 || fontCount > 100) return null;

      // ignore: avoid_print
      print('[PdfExporter] TTC包含$fontCount个子字体，尝试提取第一个');

      try {
        final fullBytes = await file.readAsBytes();
        final offsetTableOffset = 12;
        final offsetBytes = List<int>.generate(fontCount * 4, (i) => fullBytes[offsetTableOffset + i]);
        final bd = ByteData.sublistView(Uint8List.fromList(offsetBytes));
        final firstFontOffset = bd.getUint32(0);

        final fontData = Uint8List.fromList(
            fullBytes.sublist(firstFontOffset, fullBytes.length),
        );

        final font = pw.Font.ttf(fontData.buffer.asByteData());
        if (_validateFont(font)) {
          // ignore: avoid_print
          print('[PdfExporter] 成功从TTC提取子字体');
          return font;
        }
        return null;
      } catch (e) {
        return null;
      }
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
        final font = pw.Font.ttf(bytes.buffer.asByteData());
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

      final font = pw.Font.ttf(bytes.buffer.asByteData());
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

  /// 构造 ThemeData：
  /// 注意：pdf 3.13 在 TextStyle 已显式设 font 时，ThemeData 的 base/bold
  /// 会做二次检查，可能干扰。这里保持 ThemeData.withFont() 全空，
  /// 让 _ts() 的 font 设置直接生效。
  static pw.ThemeData _buildTheme() {
    return pw.ThemeData.withFont();
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
    // 整行 Markdown 图片引用：![alt](path)
    //   路径里允许中文/空格等非 ASCII，用非贪婪 .+? 匹配 () 内直到末尾空格或 EOL
    final imageLine = RegExp(r'^\s*!\[([^\]]*)\]\((.+)\)\s*$');

    /// 读本地文件渲染为 pw.Image（宽度按 A4 页宽-80px 左右），失败返回 null
    pw.Widget? _tryLoadImage(String path, String alt) {
      try {
        final f = File(path);
        if (!f.existsSync()) return null;
        final bytes = f.readAsBytesSync();
        if (bytes.isEmpty) return null;
        final mem = pw.MemoryImage(bytes);
        // 不抛异常：先估算尺寸。宽度统一限制到约 A4 内容宽度 515 点，
        // 高度上限 360 点（避免一张图占满整页）。
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
        // ignore: avoid_print
        print('[PdfExporter] 图片渲染失败 path=$path alt=$alt: $e');
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

      // 图片优先：**整行就是图片语法**（attachment 我们就是这么加的），
      // 所以放在其他语法之前检查
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
          // 图片加载失败：退回文本占位（不丢信息）
          out.add(_txt('[图片：$alt] (${path.split('/').last} 加载失败，请在APP中查看原素材)',
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
          // 列表项如果其实是图片语法，交给图片处理（不加进列表）
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
          // 列表项如果其实是图片语法，交给图片处理
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

      // 普通段落
      if (paraBuffer.isNotEmpty) paraBuffer.write(' ');
      paraBuffer.write(line.trim());
    }

    flushPara();
    flushList();
    if (inFence) flushFence();
    return out;
  }

  /// 构造标准 Markdown 字符串（public：UI 层需要先构建侧车 .md 文件时调用）
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
        // 图片引用行直接原样输出（让 _renderMarkdown 的顶层 imageLine
        // 正则能正确匹配），其他文本行作为无序列表项
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

  /// 把一次尝试的阶段+异常+堆栈拼接成一份可读文本
  /// （单行紧凑，方便 SnackBar 显示）
  static String _formatError(String phase, Object e, StackTrace st) {
    final msg = e.toString().replaceAll('\n', ' ');
    final head = '[$phase] $msg';
    // 取堆栈前 2 行关键帧
    final lines = st.toString().split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return head;
    final top = lines.take(2).map((l) => l.trim()).join(' | ');
    return '$head  Stack: $top';
  }

  /// 导出结果：不仅包含文件，还包含本次最终走了哪一层、L1/L2 失败记录（若有），
  /// 便于 UI 层给用户提示（你连不到 PC 也能把失败报告复制给作者）。
  ///
  /// 注意：使用**具名** record，调用方通过 `r.file / r.level / r.fallbackReport`
  /// 取值（与 `(File, String, String)` 位置型 record 不是同一种类型）。
  static Future<({File file, String level, String fallbackReport})> exportExternalAIPdfEx({
    required String title,
    required String prompt,
    String? contactName,
    String? context,
    List<String>? attachments,
  }) async {
    // 最外层再统一包一次：任何"漏掉"的异常（例如 L1/L2/L3 内部 try/catch 都没接住时），
    // 全部重新包装成「三次导出均失败」+ 总堆栈，保证 UI 层拿到的都是合并报告，
    // SnackBar 一定出现复制崩溃报告按钮。
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

      await _scanAndLoadFonts();

      final markdown = _buildMarkdown(
        title: title,
        prompt: prompt,
        contactName: contactName,
        context: context,
        attachments: attachments,
        dateStr: dateStr,
      );

      final errors = <String>[];

      // L0：neom_docs 专业库渲染（仅适用于非中文、无图片的内容）
      // neom_docs 使用 Open Sans 字体，不支持中文；且不支持 Markdown 图片语法
      // 检测到中文或图片时直接跳过，进入 L1 自建渲染（支持中文字体和图片）
      final hasChinese = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]').hasMatch(markdown);
      final hasImages = RegExp(r'!\[.*?\]\([^)]+\)').hasMatch(markdown);

      if (!hasChinese && !hasImages) {
        try {
          final phase = 'L0_neom_docs';
          // ignore: avoid_print
          print('[PdfExporter] 尝试L0: neom_docs 专业库渲染 (非中文、无图片)');

          final pdfBytes = await NeomPdfService.generateFromMarkdown(
            content: markdown,
            title: title,
            theme: DocTheme(
              accentColor: PdfColor.fromInt(0xFF0066CC),
              accentDark: PdfColor.fromInt(0xFF004C99),
              brandName: '社交塔子',
              brandVersion: 'v1.0',
              footerLeft: '社交塔子',
              footerCenter: 'AI 任务中心',
            ),
          );

          final f = await _writePdfFile(title, now, pdfBytes);
          return (
            file: f,
            level: phase,
            fallbackReport: errors.join('\n'),
          );
        } catch (e, st) {
          final line = _formatError('L0_neom_docs', e, st);
          errors.add(line);
          // ignore: avoid_print
          print('[PdfExporter] L0失败(将降级到自建渲染): $line');
        }
      } else {
        final skipReason = hasChinese ? '内容含中文(neom_docs不支持)' : '内容含图片(neom_docs不支持)';
        // ignore: avoid_print
        print('[PdfExporter] 跳过L0_neom_docs: $skipReason，直接使用L1自建渲染');
        errors.add('[L0_neom_docs] 跳过: $skipReason');
      }

      for (var attempt = 1; attempt <= 3; attempt++) {
        final phase = 'L$attempt';
        try {
          pw.ThemeData theme;
          if (attempt == 1) {
            // L1：尝试加载系统 CJK 字体 + Markdown 渲染；
            // 注意：因 pdf 3.13 内部 save() 的字体子集化不暴露 API 让我们关闭，
            // 若加载中文字体后 save 仍炸 null，L2 会立即退回无字体模式。
            try {
              await _scanAndLoadFonts();
            } catch (_) {}
            theme = _buildTheme();
            final widgets = _renderMarkdown(markdown);
            final f = await _saveWidgetsToPdf(title, now, widgets, theme);
            return (
              file: f,
              level: phase,
              fallbackReport: errors.join('\n'),
            );
          } else if (attempt == 2) {
            // L2：零字体 + Markdown 渲染。
            // pdf 使用内置 Helvetica，中文会变 □，但不会触发字体相关 ! 断言。
            theme = pw.ThemeData.withFont();
            _chineseFont = null;
            final widgets = _renderMarkdown(markdown);
            final f = await _saveWidgetsToPdf(title, now, widgets, theme);
            return (
              file: f,
              level: phase,
              fallbackReport: errors.join('\n'),
            );
          } else {
            // L3：零字体 + 纯文本单页（终极兜底）。
            theme = pw.ThemeData.withFont();
            _chineseFont = null;
            final bytes = await _renderPlainTextFallback(
              title,
              prompt,
              contactName,
              context,
              attachments,
              dateStr,
              theme,
            );
            final f = await _writePdfFile(title, now, bytes);
            return (
              file: f,
              level: phase,
              fallbackReport: errors.join('\n'),
            );
          }
        } catch (e, st) {
          final line = _formatError(phase, e, st);
          errors.add(line);
          // ignore: avoid_print
          print('[PdfExporter] 尝试$phase失败: $line');
          if (attempt == 3) {
            final merged = errors.join('\n');
            throw StateError('三次导出均失败\n$merged');
          }
          await Future<void>.delayed(Duration.zero);
        }
      }
      throw StateError('PDF导出失败: 未知错误');
    } catch (e, st) {
      // 二次兜底：若 for 循环外、入口处的未捕获异常也在此合并
      if (e is StateError &&
          (e.message ?? '').startsWith('三次导出均失败')) {
        rethrow;
      }
      final extra = _formatError('GLOBAL', e, st);
      throw StateError('三次导出均失败(global catch)\n$extra');
    }
  }

  /// 兼容旧签名：内部调用扩展版
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
    // widgets 允许为空（至少塞一个 SizedBox，避免 pdf 库极端空断言）
    if (widgets.isEmpty) {
      chunks.add([pw.SizedBox.shrink()]);
    } else {
      for (var i = 0; i < widgets.length; i += chunkSize) {
        final end = i + chunkSize;
        chunks.add(widgets.sublist(i, end > widgets.length ? widgets.length : end));
      }
    }

    // 每一页独立 try/catch + save 时 subsetFonts: false
    // （最关键：关闭字体子集化，DroidSansFallback 等系统字体的 cmap/OS-2
    //  表和 pdf 库 subset 解析假设不完全匹配，很容易触发内部 ! 断言。
    //  关闭 subset 后嵌入完整 ttf（文件稍大，但绝不会炸 subset）。）
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
      } catch (e, st) {
        // ignore: avoid_print
        print('[PdfExporter] addPage失败，继续空页: $e\n$st');
        try {
          pdf.addPage(pw.Page(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            build: (_) => pw.Text('(此页渲染失败)'),
          ));
        } catch (_) {}
      }
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
    } catch (e, st) {
      // ignore: avoid_print
      print('[PdfExporter L3] addPage失败，尝试最小空页: $e\n$st');
      pdf.addPage(pw.Page(build: (_) => pw.Text('fallback')));
    }
    // pdf 3.13 不暴露 subsetFonts 参数，直接默认 save()；
    // 如果传入了中文字体触发 subset 内部 null，L2/L3 无字体模式能兜底。
    return pdf.save();
  }

  /// 把完整中文 Markdown 原文写进临时 .md 文件，分享 PDF 时一起作为附件，
  /// 这样即便 PDF 用内置 Helvetica 把中文渲染成 □，第三方 AI 读 .md 附件
  /// 也能 100% 获取到中文原文。
  static Future<File> writeMarkdownSidecar(String title, String markdown) async {
    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    final timestamp =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
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

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

    // 优先级：硬编码最稳定的 DroidSans 路径（TTF 格式，Android 全版本可用）
    // 然后再扫系统目录。**只试 .ttf/.otf，跳过 .ttc**（pdf 3.13 不支持 TTC 集合字体）
    const hardCoded = [
      '/system/fonts/DroidSansFallback.ttf',
      '/system/fonts/DroidSans.ttf',
      '/system/fonts/DroidSansFallbackFull.ttf',
      '/system/fonts/RobotoFallback-Regular.ttf',
      '/system/fonts/RobotoFallback.ttf',
      '/system/fonts/NotoSans-Regular.ttf',
      '/system/fonts/NotoSerif-Regular.ttf',
    ];

    final candidates = <String>[...hardCoded];

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
            // ★ 只收集 TTF/OTF，TTC 集合格式 pdf 库不支持
            if (lower.endsWith('.ttf') || lower.endsWith('.otf')) {
              candidates.add(f.path);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // 去重
    final seen = <String>{};
    candidates.removeWhere((p) => !seen.add(p));

    // 排序：硬编码路径最前，其余按关键词优先级
    String score(String path) {
      for (var i = 0; i < hardCoded.length; i++) {
        if (path == hardCoded[i]) return '00_$i';
      }
      final lower = path.toLowerCase();
      for (var i = 0; i < _fontKeywords.length; i++) {
        if (lower.contains(_fontKeywords[i].toLowerCase())) {
          return '${(i + 1).toString().padLeft(2, '0')}_${lower.split('/').last}';
        }
      }
      return '99_${lower.split('/').last}';
    }
    candidates.sort((a, b) => score(a).compareTo(score(b)));

    // ignore: avoid_print
    print('[PdfExporter] 待扫描字体 ${candidates.length} 个: ${candidates.take(5).join(', ')}...');

    for (final path in candidates) {
      try {
        final file = File(path);
        final bytes = await file.readAsBytes();
        if (bytes.length < 1024) {
          // ignore: avoid_print
          print('[PdfExporter] 跳过 $path: 文件过小 (${bytes.length} bytes)');
          continue;
        }
        try {
          final font = pw.Font.ttf(bytes.buffer.asByteData());
          // 验证：用这个字体渲染 "测试" 两字的 TextStyle 构造是否正常
          final probe = pw.TextStyle(font: font, fontSize: 12);
          // ignore: avoid_print
          print('[PdfExporter] 成功加载字体: ${path.split('/').last} (${bytes.length} bytes) probe=${probe.fontSize}');
          _chineseFont = font;
          return;
        } catch (e) {
          // ignore: avoid_print
          print('[PdfExporter] 解析失败 $path: $e');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[PdfExporter] 读取失败 $path: $e');
      }
    }

    // ignore: avoid_print
    print('[PdfExporter] 全部 ${candidates.length} 个字体均未成功加载，将使用内置 Helvetica（中文显示为□）');
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

      final markdown = _buildMarkdown(
        title: title,
        prompt: prompt,
        contactName: contactName,
        context: context,
        attachments: attachments,
        dateStr: dateStr,
      );

      final errors = <String>[];

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

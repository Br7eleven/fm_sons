import 'dart:io';

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  ZAIQA SAMOSA INVOICE — v5, rebuilt against the CURRENT docx
//
//  Why this version exists: the previous file (v3/v4) was built
//  against an OLDER copy of ZAIQA_OK.docx. The doc has since been
//  edited and the header structure changed completely. Verified
//  fresh by unzipping ZAIQA_OK.docx and reading the raw XML
//  (unpacked/word/header2.xml, document.xml, fontTable.xml) —
//  not eyeballed from a screenshot, not assumed from the old file.
//
//  WHAT ACTUALLY CHANGED vs the old file:
//
//   1. THE "ZAIQA samosa" WORDMARK IS REAL TEXT, NOT AN IMAGE.
//      header2.xml proves it:
//        <w:rFonts w:ascii="Inertia" .../><w:t>ZAIQA</w:t>           sz 72 (36pt)
//        <w:rFonts w:ascii="Trakya-Sans-Alt-900-Bold" .../><w:t>samosa</w:t>  sz 48 (24pt)
//      Both colored FFFF00 (pure yellow — NOT the FFD700 gold used
//      elsewhere). The old file baked these into a PNG and used
//      Arial Black as a fallback because someone screenshotted an
//      earlier render where the fonts weren't installed and the
//      text rendered as a placeholder image. There is only ONE
//      real image in the doc: the small round chicken-vegetable-
//      samosa badge (rId1 -> media/image1.png, 94x96px).
//
//   2. HEADER BAND COLOR IS #EC1719, NOT #EE1B24.
//      <w:shd w:val="clear" w:color="auto" w:fill="EC1719"/>
//      Sampled directly from every shaded header cell. Off by a
//      few RGB points from the old constant — easy to miss
//      eyeballing a screenshot, obvious in the XML.
//
//   3. HEADER GRID IS 6073 / 5884 DXA, NOT 10742 / 6178.
//      <w:gridCol w:w="6073"/><w:gridCol w:w="5884"/>
//      The old file's ratio was from a previous revision of the
//      header table (it even used a different tblInd). Confirmed
//      from THIS doc's <w:tblGrid> — this is what was actually
//      causing things to land in the wrong place horizontally.
//
//   4. "MAIN OFFICE" block indent is 144 dxa (~10px), not 3744
//      dxa (~250px). The real run has <w:ind w:left="144"/>. The
//      old file's huge indent would shove that text far to the
//      right of where Word actually puts it (hard up against the
//      left edge, just inside the cell margin).
//
//   5. dotted item-row borders only painted the BOTTOM line.
//      document.xml gives every item/blank cell an explicit
//      <w:left w:val="single" w:sz="6" .../> in CC0000 too (and
//      the last column also gets a right border). Without it the
//      vertical red column dividers in the item table are simply
//      missing. Fixed below — see _CellEdges.
//
//   6. TOTAL/ADVANCE/BALANCE row pink is #FFE8E8, not #F2DCDB,
//      and the labels themselves were missing their color
//      (<w:color w:val="CC0000"/> on TOTAL/ADVANCE/BALANCE — the
//      old file rendered them in default black).
//
//   7. Real row heights, read from <w:trHeight>: header row 1 =
//      1133 dxa (~75px, content can grow past this — it's
//      "atLeast", not exact), header row 2 = 1287 dxa (~86px —
//      the old file used a guessed 453 dxa, way off), item/blank
//      rows = 607 dxa exact (this one was already right),
//      TOTAL/ADVANCE = 607 dxa exact (old file guessed 450),
//      BALANCE/Signature row = 569 dxa exact.
//
//   8. THE GRIDSPAN MERGE — handled differently and more robustly
//      this time. Word merges QTY+DESCRIPTION (935+6234=7169 dxa)
//      into one real cell on the TOTAL/ADVANCE/BALANCE rows.
//      Flutter's Table has no colspan. Instead of faking it inside
//      the Table (which is what caused the old misalignment bugs),
//      these 3 rows are built as a separate Row of fixed-width
//      SizedBoxes — 7169 / 1619 / 1619 dxa, pixel-identical to the
//      Table's own column math above them — placed directly under
//      the Table. Same total width, same per-segment width, so
//      they line up exactly without ever touching Table's column
//      model. This is the actual fix for the bug the old file's
//      comments kept describing.
//
//  WHAT'S UNCHANGED / kept from the old file because it was right:
//   - Table: real column widths 935/6234/1619/1619 dxa
//   - Page: A4, 11906 x 16838 dxa, 1440 dxa margins
//   - Footer: pBdr top rule CC0000, "BR7 Technologies & Co." in
//     D0CECE — both verified again against footer2.xml
//   - amount is always computed (qty * rate), never stored
//
//  FONTS YOU STILL NEED TO ADD (the doc references them, Flutter
//  doesn't ship them — get the .ttf/.otf files from wherever you
//  installed them for Word, e.g. C:\Windows\Fonts):
//
//    pubspec.yaml:
//      flutter:
//        fonts:
//          - family: Inertia
//            fonts:
//              - asset: assets/fonts/Inertia.ttf
//          - family: TrakyaSansAlt900Bold
//            fonts:
//              - asset: assets/fonts/Trakya-Sans-Alt-900-Bold.ttf
//                weight: 900
//        assets:
//          - assets/images/samosa_logo.png
//
//    If a font file is missing, Flutter silently falls back to the
//    default sans — it won't crash, "ZAIQA"/"samosa" will just look
//    like generic text until you drop the real files in.
//
//  The real logo (extracted straight from the docx, 94x96px) ships
//  alongside this file as assets/images/samosa_logo.png. It's small
//  — fine on screen at the size used here, but if you have a higher
//  resolution master logo, swap it in for sharper print/PDF export.
// ═══════════════════════════════════════════════════════════════

void main() => runApp(const _PreviewApp());

/// One line item: qty × description × rate. Amount is always
/// computed (qty * rate), never stored, so it can't drift out of
/// sync with its inputs.
class ZaiqaLineItem {
  final num qty;
  final String description;
  final num rate;
  const ZaiqaLineItem({
    required this.qty,
    required this.description,
    required this.rate,
  });
  num get amount => qty * rate;
}

// ─── Verified brand colors (sampled from the actual XML) ───
const Color kHeaderBandRed = Color(0xFFEC1719); // header band fill
const Color kBorderRed = Color(
  0xFFCC0000,
); // table borders, dotted rules, footer rule, summary labels
const Color kGold = Color(0xFFFFD700); // HALAL CERTIFIED, MAIN OFFICE
const Color kWordmarkYellow = Color(0xFFFFFF00); // ZAIQA / samosa text only
const Color kGreenBadge = Color(0xFF70AD47); // "A Project of FM SONS" pill
const Color kTotalRowBg = Color(
  0xFFFFE8E8,
); // TOTAL/ADVANCE/BALANCE label shading
const Color kDivider = Colors.black; // the thin "auto" colored merge divider
const Color kSignatureGrey = Color(0xFF666666);

// DXA → logical px @96dpi (1440 dxa = 1 inch)
double dxa(num v) => v / 1440 * 96;
// half-points (font w:sz) → logical px @96dpi
double hpt(num v) => v * 96 / 144;
// eighths-of-a-point (border w:sz) → logical px @96dpi
double bpt(num v) => v / 6;
// EMU (image w:extent units) → logical px @96dpi (914400 EMU = 1in = 96px)
double emuToPx(num emu) => emu / 9525;

// Real column widths (DXA) from the item table's <w:gridCol>
const double _colNum = 500;
const double _colQty = 935;
const double _colDesc = 6234;
const double _colRate = 1619;
const double _colAmount = 1619;
const double _mergedQtyDesc =
    _colNum + _colQty + _colDesc; // GRIDSPAN width with # column

/// Full A4 page width at 96dpi. Wrap [ZaiqaInvoiceWidget] in a
/// SizedBox of this width (see the demo at the bottom) — the body
/// tables are centered at fixed real-document widths, so they need
/// a parent at least this wide to land correctly.
const double kZaiqaInvoicePageWidth = 11906 / 1440 * 96; // 793.73

class ZaiqaInvoiceWidget extends StatelessWidget {
  final String customerName;
  final String invoiceNumber;
  final DateTime date;
  final List<ZaiqaLineItem> items;
  final num advance;
  final String? signaturePath;

  static const int itemsPerPage = 16;

  const ZaiqaInvoiceWidget({
    super.key,
    required this.customerName,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    this.advance = 0,
    this.signaturePath,
  });

  num get total => items.fold<num>(0, (sum, item) => sum + item.amount);
  num get balance => total - advance;

  List<List<ZaiqaLineItem>> get pageItemChunks {
    final n = items.length;
    if (n == 0) return [[]];
    if (n <= itemsPerPage) return [items];
    final chunks = <List<ZaiqaLineItem>>[];
    chunks.add(items.sublist(0, itemsPerPage));
    for (var i = itemsPerPage; i < n; i += itemsPerPage) {
      final end = (i + itemsPerPage > n) ? n : i + itemsPerPage;
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }

  Widget _buildPage(BuildContext context, int pageIndex) {
    final chunks = pageItemChunks;
    final pageItems = chunks[pageIndex];
    final startIndex = chunks.take(pageIndex).fold<int>(0, (s, c) => s + c.length);
    final isLastPage = pageIndex == chunks.length - 1;
    final isFirstPage = pageIndex == 0;

    return Container(
      width: kZaiqaInvoicePageWidth,
      height: 1123,
      color: Colors.white,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderBanner(),
              if (isFirstPage) ...[
                SizedBox(height: dxa(200)),
                Center(
                  child: _ToInvoiceRow(
                    customerName: customerName,
                    invoiceNumber: invoiceNumber,
                    date: date,
                  ),
                ),
              ],
              SizedBox(height: dxa(160)),
              Center(
                child: _ItemsTable(
                  items: pageItems,
                  startIndex: startIndex,
                  isLastPage: isLastPage,
                ),
              ),
              if (isLastPage)
                Center(
                  child: _SummarySection(
                    total: total,
                    advance: advance,
                    balance: balance,
                    signaturePath: signaturePath,
                  ),
                ),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: const _Footer()),
        ],
      ),
    );
  }

  List<Widget> buildPages(BuildContext context) {
    return List.generate(pageItemChunks.length, (i) => _buildPage(context, i));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: buildPages(context),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER BANNER — replica of header2.xml's 2-row, 2-col table.
//  Full-bleed red background (the real table is indented past the
//  page margin via tblInd=-1522, landing it almost exactly edge to
//  edge — close enough that "fill the parent width" is correct).
// ════════════════════════════════════════════════════════════
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1 — logo + ZAIQA/samosa wordmark (left, flex 6073),
        // badge + HALAL block (right, flex 5884). Top-aligned, like
        // the original — the logo and "ZAIQA" start flush with the
        // top of the band, "samosa" cascades down-right under it.
        Container(
          color: kHeaderBandRed,
          constraints: BoxConstraints(minHeight: dxa(1133)),
          padding: EdgeInsets.fromLTRB(dxa(150), dxa(150), dxa(150), dxa(120)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6073, child: _LogoAndWordmark()),
                Expanded(flex: 5884, child: _BadgeAndHalalBlock()),
              ],
            ),
          ),
        ),
        // Row 2 — MAIN OFFICE / address (left), Contact / Email
        // (right). Real run has several leading blank paragraphs
        // that push the text toward the bottom of the row — modeled
        // here with bottom alignment instead of fragile blank-line
        // math, same visual result.
        Container(
          color: kHeaderBandRed,
          constraints: BoxConstraints(minHeight: dxa(1287)),
          padding: EdgeInsets.fromLTRB(dxa(150), dxa(60), dxa(150), dxa(100)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 6073,
                child: Padding(
                  padding: EdgeInsets.only(left: dxa(144)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MAIN OFFICE',
                        style: TextStyle(
                          color: kGold,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                          fontSize: hpt(22),
                        ),
                      ),
                      Text(
                        'PHQ Hospital Road –Modern Glass Aluminium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                          fontSize: hpt(18),
                        ),
                      ),
                      Text(
                        'Decoration Center Gilgit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                          fontSize: hpt(18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5884,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contact: 03455050012',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Arial',
                        fontSize: hpt(18),
                      ),
                    ),
                    Text(
                      'Email: zaiqa.samosa@gmail.com',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Arial',
                        fontSize: hpt(18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Logo (real image, 94x96) + "ZAIQA" (Inertia, 36pt) on the first
// line, "samosa" (Trakya-Sans-Alt-900-Bold, 24pt) cascading below
// and to the right of it — both pure yellow (FFFF00).
//
// The docx achieves this with a floating/anchored image plus manual
// leading-space hacks to reserve room for it (the classic Word
// trick before it had real layout). None of that math survives
// translation cleanly, and it doesn't need to: now that the
// wordmark is real text instead of a baked PNG, a plain Row +
// Column reproduces the same look, more robustly, with way less
// code than the old EMU-offset Stack approach.
class _LogoAndWordmark extends StatelessWidget {
  const _LogoAndWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/samosa_logo.png',
          width: emuToPx(819150),
          height: emuToPx(835660),
          errorBuilder: (_, _, _) => Container(
            width: 86,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: const Text('LOGO', style: TextStyle(fontSize: 9)),
          ),
        ),
        // 1. Increase this width if you want more space between the logo and the text block
        SizedBox(width: dxa(120)),
        Padding(
          // 2. This padding pushes the entire text block (ZAIQA + samosa) together to the right
          padding: EdgeInsets.only(
            left: dxa(200),
          ), // Adjust this value to drag it right
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .center, // 3. Centers both texts relative to each other
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ZAIQA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inertia',
                  color: kWordmarkYellow,
                  fontSize: hpt(72),
                  height: 1.0,
                ),
              ),
              Text(
                'samosa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TrakyaSansAlt900Bold',
                  color: kWordmarkYellow,
                  fontSize: hpt(48),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// "A Project of FM SONS" green pill (top-right corner) + HALAL
// CERTIFIED block (centered under it, inset from the right by the
// docx's 864-dxa right indent).
class _BadgeAndHalalBlock extends StatelessWidget {
  const _BadgeAndHalalBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: kGreenBadge,
          padding: EdgeInsets.symmetric(horizontal: dxa(80), vertical: dxa(20)),
          child: Text(
            'A Project of FM SONS',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Arial',
              fontSize: hpt(22),
            ),
          ),
        ),
        SizedBox(height: dxa(120)),
        Padding(
          padding: EdgeInsets.only(right: dxa(864)),
          child: Column(
            // These 3 lines must share ONE common width before
            // textAlign.center means anything. With the outer
            // Column's crossAxisAlignment.end, each line was being
            // sized to its own text width first, then right-aligned
            // — which only looks centered for "HALAL CERTIFIED"
            // because it happens to be close to the full width.
            // Stretching here gives all 3 lines the same width
            // (the cell width minus the 864-dxa right indent above),
            // matching the docx's jc="center" paragraph behavior.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HALAL CERTIFIED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kGold,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                  fontSize: hpt(28),
                ),
              ),
              Text(
                'Special Chicken Vegetable Samosa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Arial',
                  fontSize: hpt(22),
                ),
              ),
              Text(
                '"Zaiqa Hamari Pehchan!"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Arial',
                  fontSize: hpt(22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TO: ____   Invoice No: ____  Date: ____
//  Real 2-col table, width 10484 dxa, columns 5206/5278.
// ════════════════════════════════════════════════════════════
class _ToInvoiceRow extends StatelessWidget {
  final String customerName;
  final String invoiceNumber;
  final DateTime date;

  const _ToInvoiceRow({
    required this.customerName,
    required this.invoiceNumber,
    required this.date,
  });

  String get _formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'Arial',
      fontSize: 13.3,
      color: Colors.black,
    );
    return SizedBox(
      width: dxa(5206 + 5278),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5206,
            child: Text(
              customerName.isEmpty
                  ? 'To: _______________________________'
                  : 'To: $customerName',
              style: textStyle,
            ),
          ),
          Expanded(
            flex: 5278,
            child: Text(
              'Invoice No: $invoiceNumber   Date: $_formattedDate',
              textAlign: TextAlign.right,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ITEMS TABLE — true 4-column Table (no merge needed here).
//  Header row: solid red fill, no border math needed (border color
//  == fill color in the source doc, so it's invisible either way).
//  Item/blank rows: solid red left border on every column, solid
//  red right border on the last column only, dotted red bottom on
//  every row. That's exactly what document.xml specifies per cell.
// ════════════════════════════════════════════════════════════
class _ItemsTable extends StatelessWidget {
  final List<ZaiqaLineItem> items;
  final int startIndex;
  final bool isLastPage;

  const _ItemsTable({required this.items, required this.startIndex, required this.isLastPage});

  static const int minRows = 12;
  static String _fmt(num v) {
    final formatted = v.toStringAsFixed(2);
    return 'Rs. $formatted';
  }

  static String _fmtQty(num v) {
    final asDouble = v.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toStringAsFixed(0);
    }
    return asDouble.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    // Pad to minimum 12 visible rows only on the last page
    final blankRowsNeeded = isLastPage
        ? (minRows - items.length).clamp(0, minRows)
        : 0;

    return SizedBox(
      width: dxa(_colNum + _colQty + _colDesc + _colRate + _colAmount),
      child: Table(
        columnWidths: {
          0: FixedColumnWidth(dxa(_colNum)),
          1: FixedColumnWidth(dxa(_colQty)),
          2: FixedColumnWidth(dxa(_colDesc)),
          3: FixedColumnWidth(dxa(_colRate)),
          4: FixedColumnWidth(dxa(_colAmount)),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: kBorderRed),
            children: [
              _headerCell('#'),
              _headerCell('QTY'),
              _headerCell('DESCRIPTION'),
              _headerCell('RATE'),
              _headerCell('AMOUNT'),
            ],
          ),
          for (int i = 0; i < items.length; i++) _itemRow(i, items[i]),
          for (int i = 0; i < blankRowsNeeded; i++) _blankRow(),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => TableCell(
    child: Container(
      height: dxa(291),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
          fontSize: 12,
        ),
      ),
    ),
  );

  TableRow _itemRow(int index, ZaiqaLineItem item) {
    const textStyle = TextStyle(fontFamily: 'Arial', fontSize: 13.3);
    return TableRow(
      children: [
        _ruledCell(
          child: Center(child: Text('${startIndex + index + 1}', style: textStyle)),
        ),
        _ruledCell(
          child: Center(child: Text(_fmtQty(item.qty), style: textStyle)),
        ),
        _ruledCell(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dxa(100)),
              child: Text(item.description, style: textStyle),
            ),
          ),
        ),
        _ruledCell(
          child: Center(child: Text(_fmt(item.rate), style: textStyle)),
        ),
        _ruledCell(
          isLastColumn: true,
          child: Center(child: Text(_fmt(item.amount), style: textStyle)),
        ),
      ],
    );
  }

  TableRow _blankRow() {
    return TableRow(
      children: [
        _ruledCell(),
        _ruledCell(),
        _ruledCell(),
        _ruledCell(),
        _ruledCell(isLastColumn: true),
      ],
    );
  }

  Widget _ruledCell({Widget? child, bool isLastColumn = false}) {
    return TableCell(
      child: _CellEdges(
        isLastColumn: isLastColumn,
        child: SizedBox(height: dxa(607), width: double.infinity, child: child),
      ),
    );
  }
}

/// Paints exactly what document.xml specifies per item/blank cell:
/// a solid red left border (always), a dotted red bottom border
/// (always), and a solid red right border (only on the last
/// column — that's the table's own right edge).
class _CellEdges extends StatelessWidget {
  final Widget child;
  final bool isLastColumn;
  const _CellEdges({required this.child, this.isLastColumn = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CellEdgesPainter(isLastColumn: isLastColumn),
      child: child,
    );
  }
}

class _CellEdgesPainter extends CustomPainter {
  final bool isLastColumn;
  _CellEdgesPainter({required this.isLastColumn});

  @override
  void paint(Canvas canvas, Size size) {
    final solid = Paint()
      ..color = kBorderRed
      ..strokeWidth = bpt(6); // sz=6 -> ~1px

    // Left border — every cell has one (it's the doc's own choice,
    // not just a table-outline default).
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), solid);

    if (isLastColumn) {
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        solid,
      );
    }

    // Dotted bottom border.
    final dotted = Paint()
      ..color = kBorderRed
      ..strokeWidth = bpt(6);
    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;
    final y = size.height;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), dotted);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════
//  TOTAL / ADVANCE / BALANCE — NOT part of the Table above.
//
//  The real doc merges QTY+DESCRIPTION (gridSpan=2, 7169 dxa) into
//  one cell on these 3 rows. Flutter's Table has no colspan, and
//  faking it inside a Table (a wide cell in column 0 + an empty
//  cell in column 1) is exactly what caused the old file's
//  misalignment bugs — Table sizes every column strictly from
//  columnWidths regardless of child width, so a "wide" cell just
//  silently overflows into the next column's space.
//
//  Fix: these 3 rows are a plain Row of fixed-width SizedBoxes —
//  7169 / 1619 / 1619 dxa — placed directly below the Table, at
//  the exact same total width (10407 dxa) and centered the exact
//  same way. Same pixel math, zero colspan trickery, can't drift.
// ════════════════════════════════════════════════════════════
class _SummarySection extends StatelessWidget {
  final num total;
  final num advance;
  final num balance;
  final String? signaturePath;

  const _SummarySection({
    required this.total,
    required this.advance,
    required this.balance,
    this.signaturePath,
  });

  static String _fmt(num v) {
    final formatted = v.toStringAsFixed(2);
    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: dxa(_mergedQtyDesc + _colRate + _colAmount),
      child: Column(
        children: [
          _summaryRow(label: 'TOTAL', value: _fmt(total)),
          _summaryRow(label: 'ADVANCE', value: _fmt(advance)),
          _signatureBalanceRow(value: _fmt(balance)),
        ],
      ),
    );
  }

  Widget _summaryRow({required String label, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The merged QTY+DESCRIPTION area — blank, white, just a
        // thin dark divider on its right edge (matches the doc's
        // sz=4 "auto" colored border, not the red table border).
        Container(
          width: dxa(_mergedQtyDesc),
          height: dxa(607),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: kDivider, width: bpt(4)),
            ),
          ),
        ),
        Container(
          width: dxa(_colRate),
          height: dxa(607),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kTotalRowBg,
            border: Border.all(color: kBorderRed, width: bpt(6)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kBorderRed,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
              fontSize: 12.0,
            ),
          ),
        ),
        Container(
          width: dxa(_colAmount),
          height: dxa(607),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorderRed, width: bpt(6)),
          ),
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Arial', fontSize: 13.3),
          ),
        ),
      ],
    );
  }

  Widget _signatureBalanceRow({required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dxa(_mergedQtyDesc),
          height: dxa(569),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: kDivider, width: bpt(4)),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: dxa(150),
                right: dxa(2000),
                bottom: dxa(115),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Signature:',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 12.0,
                        color: kSignatureGrey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(height: 1, color: kSignatureGrey),
                    ),
                  ],
                ),
              ),
              if (signaturePath != null)
                Positioned(
                  left: dxa(1850),
                  bottom: dxa(135),
                  child: Image.file(
                    File(signaturePath!),
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: dxa(_colRate),
          height: dxa(569),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kTotalRowBg,
            border: Border.all(color: kBorderRed, width: bpt(6)),
          ),
          child: const Text(
            'BALANCE',
            style: TextStyle(
              color: kBorderRed,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
              fontSize: 12.0,
            ),
          ),
        ),
        Container(
          width: dxa(_colAmount),
          height: dxa(569),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorderRed, width: bpt(6)),
          ),
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Arial', fontSize: 13.3),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FOOTER — pBdr top rule (#CC0000), brand line (8pt/#CC0000),
//  "BR7 Technologies & Co." (9pt, D0CECE). Unchanged from before —
//  this part of the old file was already correct against footer2.xml.
//  Uses the real standard page margin (1440 dxa), since the footer
//  is normal in-flow text, not a floating/bled table like the
//  header and item table are.
// ════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dxa(1440)),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorderRed, width: 0.75)),
            ),
            padding: EdgeInsets.only(top: dxa(200)),
            width: double.infinity,
            child: const Text(
              'ZAIQA SAMOSA | FM SONS | 03455050012 | zaiqa.samosa@gmail.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kBorderRed,
                fontFamily: 'Arial',
                fontSize: 10.7, // sz=16 half-pt -> 8pt -> 10.7px
              ),
            ),
          ),
          const Text(
            'BR7 Technologies & Co.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD0CECE),
              fontSize: 12.0, // sz=18 half-pt -> 9pt -> 12px
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Standalone preview only — delete this section once you've
// wired ZaiqaInvoiceWidget into your real app/history/edit screen ───
class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFE9E9E9),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Material(
                elevation: 2,
                child: SizedBox(
                  width: kZaiqaInvoicePageWidth,
                  child: ZaiqaInvoiceWidget(
                    customerName: 'gb',
                    invoiceNumber: 'INV-0002',
                    date: DateTime(2026, 6, 21),
                    items: const [
                      ZaiqaLineItem(
                        qty: 10,
                        description: 'chicken samosa',
                        rate: 41.00,
                      ),
                    ],
                    advance: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

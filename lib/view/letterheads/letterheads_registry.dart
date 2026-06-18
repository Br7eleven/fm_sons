class Letterhead {
  final String id;
  final String name;
  final String subtitle;
  // null = coded Flutter widget letterhead; non-null = PDF asset path
  final String? assetPath;

  const Letterhead({
    required this.id,
    required this.name,
    required this.subtitle,
    this.assetPath,
  });
}

const List<Letterhead> kLetterheads = [
  Letterhead(
    id: 'govt',
    name: 'FM Sons',
    subtitle: 'Government Contractor General Order Supplier',
    // no assetPath = coded letterhead
  ),
  Letterhead(
    id: 'abbas',
    name: 'ABBAS',
    subtitle: 'Government Contractor & General Order Supplier',
    assetPath: 'assets/letterheads/abbas_letterhead.pdf',
  ),
  Letterhead(
    id: 'ijlal',
    name: 'Ijlal',
    subtitle: 'Government Contractor',
    assetPath: 'assets/letterheads/Ijlal_letterhead.pdf',
  ),
  Letterhead(
    id: 'al_murtaza',
    name: 'Al-Murtaza',
    subtitle: 'Government Contractor',
    assetPath: 'assets/letterheads/Al-murtaza_letterhead.pdf',
  ),
  Letterhead(
    id: 'fazal',
    name: 'Fazal',
    subtitle: 'Government Contractor',
    assetPath: 'assets/letterheads/fazal_letterhead.pdf',
  ),
  Letterhead(
    id: 'ms_auto',
    name: 'MS Auto',
    subtitle: 'Government Contractor',
    assetPath: 'assets/letterheads/ms-auto_letterhead.pdf',
  ),
  Letterhead(
    id: 'siraj',
    name: 'Siraj',
    subtitle: 'Government Contractor',
    assetPath: 'assets/letterheads/siraj_letterhead.pdf',
  ),
];

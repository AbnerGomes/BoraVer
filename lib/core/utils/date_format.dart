const _monthsLong = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 05/03/2026
String formatDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';

/// 5 de março de 2026
String formatDateLong(DateTime date) =>
    '${date.day} de ${_monthsLong[date.month - 1]} de ${date.year}';

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Bom dia!';
  if (h >= 12 && h < 18) return 'Boa tarde!';
  return 'Boa noite!';
}

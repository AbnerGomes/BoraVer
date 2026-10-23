import '../../core/utils/text_normalize.dart';

/// País identificado pelo código ISO 3166-1 alfa-2 (o valor persistido).
class Country {
  const Country(this.code, this.name);

  final String code;
  final String name;

  /// Bandeira em emoji, formada pelos indicadores regionais do código ISO.
  String get flag => flagFor(code);

  static String flagFor(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2 || _historicalCodes.contains(upper)) return '';
    const base = 0x1F1E6 - 0x41; // 'A' -> indicador regional A
    return String.fromCharCodes([
      base + upper.codeUnitAt(0),
      base + upper.codeUnitAt(1),
    ]);
  }

  /// Nome em português; para códigos desconhecidos (ex.: vindos do TMDB),
  /// devolve o próprio código, sem inventar um nome.
  static String nameFor(String code) =>
      countriesByCode[code.toUpperCase()]?.name ?? code.toUpperCase();

  static List<Country> search(String query) {
    final q = normalizeText(query);
    if (q.isEmpty) return allCountries;
    return allCountries
        .where(
          (c) => normalizeText(c.name).contains(q) || c.code.toLowerCase() == q,
        )
        .toList();
  }
}

/// Lista padronizada de países (nomes em português do Brasil), em ordem alfabética.
final List<Country> allCountries = [
  for (final entry in _countryNames.entries) Country(entry.key, entry.value),
]..sort((a, b) => compareText(a.name, b.name));

final Map<String, Country> countriesByCode = {
  for (final c in allCountries) c.code: c,
};

/// Códigos sem bandeira em emoji (países que não existem mais).
const _historicalCodes = {'SU', 'XC', 'YU', 'XG'};

const _countryNames = <String, String>{
  'AF': 'Afeganistão', 'ZA': 'África do Sul', 'AL': 'Albânia',
  'DE': 'Alemanha', 'AD': 'Andorra', 'AO': 'Angola',
  'SA': 'Arábia Saudita', 'DZ': 'Argélia', 'AR': 'Argentina',
  'AM': 'Armênia', 'AU': 'Austrália', 'AT': 'Áustria',
  'AZ': 'Azerbaijão', 'BS': 'Bahamas', 'BD': 'Bangladesh',
  'BB': 'Barbados', 'BH': 'Bahrein', 'BE': 'Bélgica', 'BZ': 'Belize',
  'BJ': 'Benin', 'BY': 'Bielorrússia', 'BO': 'Bolívia',
  'BA': 'Bósnia e Herzegovina', 'BW': 'Botsuana', 'BR': 'Brasil',
  'BG': 'Bulgária', 'BF': 'Burkina Faso', 'BT': 'Butão',
  'CV': 'Cabo Verde', 'CM': 'Camarões', 'KH': 'Camboja',
  'CA': 'Canadá', 'QA': 'Catar', 'KZ': 'Cazaquistão', 'TD': 'Chade',
  'CL': 'Chile', 'CN': 'China', 'CY': 'Chipre', 'CO': 'Colômbia',
  'KP': 'Coreia do Norte', 'KR': 'Coreia do Sul',
  'CI': 'Costa do Marfim', 'CR': 'Costa Rica', 'HR': 'Croácia',
  'CU': 'Cuba', 'DK': 'Dinamarca', 'EG': 'Egito',
  'SV': 'El Salvador', 'AE': 'Emirados Árabes Unidos',
  'EC': 'Equador', 'SK': 'Eslováquia', 'SI': 'Eslovênia',
  'ES': 'Espanha', 'US': 'Estados Unidos', 'EE': 'Estônia',
  'ET': 'Etiópia', 'PH': 'Filipinas', 'FI': 'Finlândia',
  'FR': 'França', 'GA': 'Gabão', 'GH': 'Gana', 'GE': 'Geórgia',
  'GR': 'Grécia', 'GT': 'Guatemala', 'GN': 'Guiné',
  'GW': 'Guiné-Bissau', 'HT': 'Haiti', 'NL': 'Holanda (Países Baixos)',
  'HN': 'Honduras', 'HK': 'Hong Kong', 'HU': 'Hungria',
  'IN': 'Índia', 'ID': 'Indonésia', 'IQ': 'Iraque', 'IR': 'Irã',
  'IE': 'Irlanda', 'IS': 'Islândia', 'IL': 'Israel', 'IT': 'Itália',
  'JM': 'Jamaica', 'JP': 'Japão', 'JO': 'Jordânia', 'KW': 'Kuwait',
  'LA': 'Laos', 'LV': 'Letônia', 'LB': 'Líbano', 'LY': 'Líbia',
  'LI': 'Liechtenstein', 'LT': 'Lituânia', 'LU': 'Luxemburgo',
  'MO': 'Macau', 'MK': 'Macedônia do Norte', 'MG': 'Madagascar',
  'MY': 'Malásia', 'ML': 'Mali', 'MT': 'Malta', 'MA': 'Marrocos',
  'MR': 'Mauritânia', 'MX': 'México', 'MZ': 'Moçambique',
  'MD': 'Moldávia', 'MC': 'Mônaco', 'MN': 'Mongólia',
  'ME': 'Montenegro', 'MM': 'Myanmar', 'NA': 'Namíbia', 'NP': 'Nepal',
  'NI': 'Nicarágua', 'NE': 'Níger', 'NG': 'Nigéria', 'NO': 'Noruega',
  'NZ': 'Nova Zelândia', 'OM': 'Omã', 'PS': 'Palestina',
  'PA': 'Panamá', 'PK': 'Paquistão', 'PY': 'Paraguai', 'PE': 'Peru',
  'PL': 'Polônia', 'PR': 'Porto Rico', 'PT': 'Portugal',
  'KE': 'Quênia', 'KG': 'Quirguistão', 'GB': 'Reino Unido',
  'CF': 'República Centro-Africana', 'CZ': 'República Tcheca',
  'CD': 'República Democrática do Congo', 'CG': 'República do Congo',
  'DO': 'República Dominicana', 'RO': 'Romênia', 'RW': 'Ruanda',
  'RU': 'Rússia', 'SN': 'Senegal', 'RS': 'Sérvia', 'SG': 'Singapura',
  'SY': 'Síria', 'SO': 'Somália', 'LK': 'Sri Lanka', 'SD': 'Sudão',
  'SE': 'Suécia', 'CH': 'Suíça', 'SR': 'Suriname', 'TH': 'Tailândia',
  'TW': 'Taiwan', 'TJ': 'Tajiquistão', 'TZ': 'Tanzânia',
  'TL': 'Timor-Leste', 'TG': 'Togo', 'TT': 'Trinidad e Tobago',
  'TN': 'Tunísia', 'TM': 'Turcomenistão', 'TR': 'Turquia',
  'UA': 'Ucrânia', 'UG': 'Uganda', 'UY': 'Uruguai',
  'UZ': 'Uzbequistão', 'VE': 'Venezuela', 'VN': 'Vietnã',
  'YE': 'Iêmen', 'ZM': 'Zâmbia', 'ZW': 'Zimbábue',
  // Países históricos que aparecem com frequência em filmografias.
  'SU': 'União Soviética', 'XC': 'Tchecoslováquia', 'YU': 'Iugoslávia',
  'XG': 'Alemanha Oriental',
};

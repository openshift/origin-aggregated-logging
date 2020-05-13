module.exports = [
  {
    id: 'be-nl',
    name: 'belgium-dutch (be-nl)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: ' mln',
        billion: ' mld',
        trillion: ' bln'
      },
      ordinal: function(number) {
        var remainder = number % 100;
        return (number !== 0 && remainder <= 1) || remainder === 8 || remainder >= 20 ? 'ste' : 'de';
      },
      currency: {
        symbol: '€ '
      }
    }
  },
  {
    id: 'chs',
    name: 'simplified chinese',
    lang: {
      delimiters: {
        thousands: ',',
        decimal: '.'
      },
      abbreviations: {
        thousand: '千',
        million: '百万',
        billion: '十亿',
        trillion: '兆'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: '¥'
      }
    }
  },
  {
    id: 'cs',
    name: 'czech (cs)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'tis.',
        million: 'mil.',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function() {
        return '.';
      },
      currency: {
        symbol: 'Kč'
      }
    }
  },
  {
    id: 'da-dk',
    name: 'danish denmark (dk)',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'mio',
        billion: 'mia',
        trillion: 'b'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: 'DKK'
      }
    }
  },
  {
    id: 'de-ch',
    name: 'German in Switzerland (de-ch)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: 'CHF'
      }
    }
  },
  {
    id: 'de',
    name: 'German (de) – generally useful in Germany, Austria, Luxembourg, Belgium',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'en-gb',
    name: 'english united kingdom (uk)',
    lang: {
      delimiters: {
        thousands: ',',
        decimal: '.'
      },
      abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        var b = number % 10;
        return ~~((number % 100) / 10) === 1 ? 'th' : b === 1 ? 'st' : b === 2 ? 'nd' : b === 3 ? 'rd' : 'th';
      },
      currency: {
        symbol: '£'
      }
    }
  },
  {
    id: 'es-ES',
    name: 'spanish Spain',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'mm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        var b = number % 10;
        return b === 1 || b === 3
          ? 'er'
          : b === 2 ? 'do' : b === 7 || b === 0 ? 'mo' : b === 8 ? 'vo' : b === 9 ? 'no' : 'to';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'es',
    name: 'spanish',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'mm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        var b = number % 10;
        return b === 1 || b === 3
          ? 'er'
          : b === 2 ? 'do' : b === 7 || b === 0 ? 'mo' : b === 8 ? 'vo' : b === 9 ? 'no' : 'to';
      },
      currency: {
        symbol: '$'
      }
    }
  },
  {
    id: 'et',
    name: 'Estonian',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: ' tuh',
        million: ' mln',
        billion: ' mld',
        trillion: ' trl'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'fi',
    name: 'Finnish',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'M',
        billion: 'G',
        trillion: 'T'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'fr-CA',
    name: 'french (Canada) (fr-CA)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'M',
        billion: 'G',
        trillion: 'T'
      },
      ordinal: function(number) {
        return number === 1 ? 'er' : 'e';
      },
      currency: {
        symbol: '$'
      }
    }
  },
  {
    id: 'fr-ch',
    name: 'french (fr-ch)',
    lang: {
      delimiters: {
        thousands: "'",
        decimal: '.'
      },
      abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return number === 1 ? 'er' : 'e';
      },
      currency: {
        symbol: 'CHF'
      }
    }
  },
  {
    id: 'fr',
    name: 'french (fr)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return number === 1 ? 'er' : 'e';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'hu',
    name: 'Hungarian (hu)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'E', // ezer
        million: 'M', // millió
        billion: 'Mrd', // milliárd
        trillion: 'T' // trillió
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: ' Ft'
      }
    }
  },
  {
    id: 'it',
    name: 'italian Italy (it)',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'mila',
        million: 'mil',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return 'º';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'ja',
    name: 'japanese',
    lang: {
      delimiters: {
        thousands: ',',
        decimal: '.'
      },
      abbreviations: {
        thousand: '千',
        million: '百万',
        billion: '十億',
        trillion: '兆'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: '¥'
      }
    }
  },
  {
    id: 'nl-nl',
    name: 'netherlands-dutch (nl-nl)',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'mln',
        billion: 'mrd',
        trillion: 'bln'
      },
      ordinal: function(number) {
        var remainder = number % 100;
        return (number !== 0 && remainder <= 1) || remainder === 8 || remainder >= 20 ? 'ste' : 'de';
      },
      currency: {
        symbol: '€ '
      }
    }
  },
  {
    id: 'pl',
    name: 'polish (pl)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'tys.',
        million: 'mln',
        billion: 'mld',
        trillion: 'bln'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: 'PLN'
      }
    }
  },
  {
    id: 'pt-br',
    name: 'portuguese brazil (pt-br)',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'mil',
        million: 'milhões',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return 'º';
      },
      currency: {
        symbol: 'R$'
      }
    }
  },
  {
    id: 'pt-pt',
    name: 'portuguese (pt-pt)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function(number) {
        return 'º';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'ru-UA',
    name: 'Russian for the Ukraine (ru-UA)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'тыс.',
        million: 'млн',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function() {
        // not ideal, but since in Russian it can taken on
        // different forms (masculine, feminine, neuter)
        // this is all we can do
        return '.';
      },
      currency: {
        symbol: '\u20B4'
      }
    }
  },
  {
    id: 'ru',
    name: 'russian (ru)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'тыс.',
        million: 'млн',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function() {
        // not ideal, but since in Russian it can taken on
        // different forms (masculine, feminine, neuter)
        // this is all we can do
        return '.';
      },
      currency: {
        symbol: 'руб.'
      }
    }
  },
  {
    id: 'sk',
    name: 'slovak (sk)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'tis.',
        million: 'mil.',
        billion: 'b',
        trillion: 't'
      },
      ordinal: function() {
        return '.';
      },
      currency: {
        symbol: '€'
      }
    }
  },
  {
    id: 'th',
    name: 'thai (th)',
    lang: {
      delimiters: {
        thousands: ',',
        decimal: '.'
      },
      abbreviations: {
        thousand: 'พัน',
        million: 'ล้าน',
        billion: 'พันล้าน',
        trillion: 'ล้านล้าน'
      },
      ordinal: function(number) {
        return '.';
      },
      currency: {
        symbol: '฿'
      }
    }
  },
  {
    id: 'tr',
    name: 'turkish (tr)',
    lang: {
      delimiters: {
        thousands: '.',
        decimal: ','
      },
      abbreviations: {
        thousand: 'bin',
        million: 'milyon',
        billion: 'milyar',
        trillion: 'trilyon'
      },
      ordinal: (function() {
        var suffixes = {
          1: "'inci",
          5: "'inci",
          8: "'inci",
          70: "'inci",
          80: "'inci",

          2: "'nci",
          7: "'nci",
          20: "'nci",
          50: "'nci",

          3: "'üncü",
          4: "'üncü",
          100: "'üncü",

          6: "'ncı",

          9: "'uncu",
          10: "'uncu",
          30: "'uncu",

          60: "'ıncı",
          90: "'ıncı"
        };

        return function(number) {
          if (number === 0) {
            // special case for zero
            return "'ıncı";
          }

          var a = number % 10,
            b = number % 100 - a,
            c = number >= 100 ? 100 : null;

          return suffixes[a] || suffixes[b] || suffixes[c];
        };
      })(),
      currency: {
        symbol: '\u20BA'
      }
    }
  },
  {
    id: 'uk-UA',
    name: 'Ukrainian for the Ukraine (uk-UA)',
    lang: {
      delimiters: {
        thousands: ' ',
        decimal: ','
      },
      abbreviations: {
        thousand: 'тис.',
        million: 'млн',
        billion: 'млрд',
        trillion: 'блн'
      },
      ordinal: function() {
        // not ideal, but since in Ukrainian it can taken on
        // different forms (masculine, feminine, neuter)
        // this is all we can do
        return '';
      },
      currency: {
        symbol: '\u20B4'
      }
    }
  }
];

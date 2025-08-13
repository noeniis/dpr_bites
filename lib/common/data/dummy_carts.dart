// Original mutable sample carts (may be mutated at runtime by some pages)
final dummyCarts = [
  {
    'restaurantName': 'Waroeng Kenyank 88',
    'estimate': '30 Menit',
    'image': 'lib/assets/images/pecel.jpeg',
    'menus': [
      {
        'name': 'Nasi Pecel',
        'image': 'lib/assets/images/pecel.jpeg',
        'desc': 'Nasi dengan sayur dan sambal kacang khas Jawa Timur.',
        'addon': ['Telur Dadar'],
        'addonPrice': 3000,
        'addonOptions': [
          {'label': 'Telur Dadar', 'price': 3000},
          {'label': 'Tempe Goreng', 'price': 2000},
          {'label': 'Tahu Goreng', 'price': 2000},
          {'label': 'Sambal', 'price': 0},
          {'label': 'Kerupuk', 'price': 2000},
        ],
        'note': 'Pedas',
        'price': 15000,
        'qty': 1,
      },
      {
        'name': 'Es Teh Manis',
        'image': 'lib/assets/images/pecel_lele.jpeg',
        'desc': 'Minuman teh manis segar dengan es batu.',
        'addon': ['Tawar'],
        'addonPrice': 0,
        'addonOptions': [
          {'label': 'Lemon', 'price': 2000},
          {'label': 'Gula Batu', 'price': 1000},
          {'label': 'Less Sugar', 'price': 0},
          {'label': 'Tawar', 'price': 0},
        ],
        'note': '',
        'price': 5000,
        'qty': 2,
      },
    ],
  },
  {
    'restaurantName': 'Kantin Oma Sum',
    'estimate': '40 Menit',
    'image': 'lib/assets/images/kantinmakmur.jpeg',
    'menus': [
      {
        'name': 'Ayam Geprek',
        'image': 'lib/assets/images/pecel_lele.jpeg',
        'desc': 'Ayam goreng tepung dengan sambal geprek dan nasi.',
        'addon': ['Keju'],
        'addonPrice': 4000,
        'addonOptions': [
          {'label': 'Keju', 'price': 4000},
          {'label': 'Telur Mata Sapi', 'price': 3000},
          {'label': 'Sambal Bawang', 'price': 0},
        ],
        'note': 'Tidak pedas',
        'price': 18000,
        'qty': 1,
      },
      {
        'name': 'Jus Alpukat',
        'image': 'lib/assets/images/nasi_goreng.jpeg',
        'desc': 'Jus alpukat segar dengan susu coklat.',
        'addon': [],
        'addonPrice': 0,
        'addonOptions': [
          {'label': 'Susu Kental Manis', 'price': 2000},
          {'label': 'Coklat', 'price': 1500},
          {'label': 'Tanpa Gula', 'price': 0},
        ],
        'note': '',
        'price': 10000,
        'qty': 1,
      },
    ],
  },
  {
    'restaurantName': 'Ricebowl 101',
    'estimate': '20 Menit',
    'image': 'lib/assets/images/ricebowl.jpeg',
    'menus': [
      {
        'name': 'Ricebowl Chicken',
        'image': 'lib/assets/images/ricebowl.jpeg',
        'desc': 'Ricebowl ayam crispy dengan saus spesial.',
        'addon': ['Extra Saus'],
        'addonPrice': 2000,
        'addonOptions': [
          {'label': 'Extra Saus', 'price': 2000},
          {'label': 'Telur Dadar', 'price': 3000},
          {'label': 'Mayonaise', 'price': 0},
        ],
        'note': '',
        'price': 20000,
        'qty': 1,
      },
    ],
  },
];

// Always return a fresh deep copy of the dummy carts so mutations won't leak
List<Map<String, dynamic>> freshDummyCarts() {
  return [
    {
      'restaurantName': 'Waroeng Kenyank 88',
      'estimate': '30 Menit',
      'image': 'lib/assets/images/pecel.jpeg',
      'menus': [
        {
          'name': 'Nasi Pecel',
          'image': 'lib/assets/images/pecel.jpeg',
          'desc': 'Nasi dengan sayur dan sambal kacang khas Jawa Timur.',
          'addon': ['Telur Dadar'],
          'addonPrice': 3000,
          'addonOptions': [
            {'label': 'Telur Dadar', 'price': 3000},
            {'label': 'Tempe Goreng', 'price': 2000},
            {'label': 'Tahu Goreng', 'price': 2000},
            {'label': 'Sambal', 'price': 0},
            {'label': 'Kerupuk', 'price': 2000},
          ],
          'note': 'Pedas',
          'price': 15000,
          'qty': 1,
        },
        {
          'name': 'Es Teh Manis',
          'image': 'lib/assets/images/pecel_lele.jpeg',
          'desc': 'Minuman teh manis segar dengan es batu.',
          'addon': ['Tawar'],
          'addonPrice': 0,
          'addonOptions': [
            {'label': 'Lemon', 'price': 2000},
            {'label': 'Gula Batu', 'price': 1000},
            {'label': 'Less Sugar', 'price': 0},
            {'label': 'Tawar', 'price': 0},
          ],
          'note': '',
          'price': 5000,
          'qty': 2,
        },
      ],
    },
    {
      'restaurantName': 'Kantin Oma Sum',
      'estimate': '40 Menit',
      'image': 'lib/assets/images/kantinmakmur.jpeg',
      'menus': [
        {
          'name': 'Ayam Geprek',
          'image': 'lib/assets/images/pecel_lele.jpeg',
          'desc': 'Ayam goreng tepung dengan sambal geprek dan nasi.',
          'addon': ['Keju'],
          'addonPrice': 4000,
          'addonOptions': [
            {'label': 'Keju', 'price': 4000},
            {'label': 'Telur Mata Sapi', 'price': 3000},
            {'label': 'Sambal Bawang', 'price': 0},
          ],
          'note': 'Tidak pedas',
          'price': 18000,
          'qty': 1,
        },
        {
          'name': 'Jus Alpukat',
          'image': 'lib/assets/images/nasi_goreng.jpeg',
          'desc': 'Jus alpukat segar dengan susu coklat.',
          'addon': [],
          'addonPrice': 0,
          'addonOptions': [
            {'label': 'Susu Kental Manis', 'price': 2000},
            {'label': 'Coklat', 'price': 1500},
            {'label': 'Tanpa Gula', 'price': 0},
          ],
          'note': '',
          'price': 10000,
          'qty': 1,
        },
      ],
    },
    {
      'restaurantName': 'Ricebowl 101',
      'estimate': '20 Menit',
      'image': 'lib/assets/images/ricebowl.jpeg',
      'menus': [
        {
          'name': 'Ricebowl Chicken',
          'image': 'lib/assets/images/ricebowl.jpeg',
          'desc': 'Ricebowl ayam crispy dengan saus spesial.',
          'addon': ['Extra Saus'],
          'addonPrice': 2000,
          'addonOptions': [
            {'label': 'Extra Saus', 'price': 2000},
            {'label': 'Telur Dadar', 'price': 3000},
            {'label': 'Mayonaise', 'price': 0},
          ],
          'note': '',
          'price': 20000,
          'qty': 1,
        },
      ],
    },
  ];
}

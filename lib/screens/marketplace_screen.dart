import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/tr.dart';
import '../services/auth_service.dart';
import 'farm_registration_screen.dart';

const String _sellerPhone = '03002678621';
const String _sellerName  = 'Rahim';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All';
  final ImagePicker _picker = ImagePicker();
  String _searchQuery  = '';
  String _selectedUnit = 'kg';

  final List<String> _categories = [
    'All','Fruits','Vegetables','Grains','Pulses','Spices','Oilseeds','Crops','Fish','Seafood',
  ];
  final List<String> _units = ['kg', 'pounds', 'tons'];

  final List<Map<String, dynamic>> _products = [
    {'id':1,  'title':'Sindhi Rasoli Mango',   'urdu':'سندھی راسولی آم',   'location':'Mirpur Khas, Sindh',  'price':280,  'unit':'per kg','min_order':5,   'stock':500,  'category':'Fruits',    'color':const Color(0xFFFF9800),'emoji':'🥭','imageUrl':'https://images.unsplash.com/photo-1618897996318-5a901fa696ca?w=400&q=80'},
    {'id':2,  'title':'Chaunsa Mango',          'urdu':'چونسہ آم',          'location':'Rahim Yar Khan',      'price':320,  'unit':'per kg','min_order':5,   'stock':300,  'category':'Fruits',    'color':const Color(0xFFFF9800),'emoji':'🥭','imageUrl':'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400&q=80'},
    {'id':3,  'title':'Anwar Ratol Mango',      'urdu':'انور رٹول آم',      'location':'Multan, Punjab',      'price':350,  'unit':'per kg','min_order':3,   'stock':200,  'category':'Fruits',    'color':const Color(0xFFFF9800),'emoji':'🥭','imageUrl':'https://images.unsplash.com/photo-1605027990121-cbae9e0642df?w=400&q=80'},
    {'id':4,  'title':'Langra Mango',           'urdu':'لنگڑا آم',          'location':'Bahawalpur, Punjab',  'price':260,  'unit':'per kg','min_order':5,   'stock':400,  'category':'Fruits',    'color':const Color(0xFFFF9800),'emoji':'🥭','imageUrl':'https://images.unsplash.com/photo-1601493700631-2b16ec4b4716?w=400&q=80'},
    {'id':5,  'title':'Red Chilli',             'urdu':'لال مرچ',           'location':'Kunri, Sindh',        'price':180,  'unit':'per kg','min_order':10,  'stock':800,  'category':'Spices',    'color':const Color(0xFFF44336),'emoji':'🌶️','imageUrl':'https://images.unsplash.com/photo-1583119022894-919a68a3d0e3?w=400&q=80'},
    {'id':6,  'title':'Green Chilli',           'urdu':'ہری مرچ',           'location':'Badin, Sindh',        'price':120,  'unit':'per kg','min_order':5,   'stock':500,  'category':'Vegetables','color':const Color(0xFF4CAF50),'emoji':'🌿','imageUrl':'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400&q=80'},
    {'id':7,  'title':'Tomato (Tamatar)',        'urdu':'ٹماٹر',             'location':'Peshawar, KPK',       'price':80,   'unit':'per kg','min_order':20,  'stock':1000, 'category':'Vegetables','color':const Color(0xFFF44336),'emoji':'🍅','imageUrl':'https://images.unsplash.com/photo-1546470427-e212a8353c22?w=400&q=80'},
    {'id':8,  'title':'Onion (Pyaz)',            'urdu':'پیاز',              'location':'Hyderabad, Sindh',    'price':60,   'unit':'per kg','min_order':50,  'stock':2000, 'category':'Vegetables','color':const Color(0xFF9C27B0),'emoji':'🧅','imageUrl':'https://images.unsplash.com/photo-1518977956812-cd3dbadaaf31?w=400&q=80'},
    {'id':9,  'title':'Cucumber (Kheera)',       'urdu':'کھیرا',             'location':'Multan, Punjab',      'price':50,   'unit':'per kg','min_order':10,  'stock':600,  'category':'Vegetables','color':const Color(0xFF4CAF50),'emoji':'🥒','imageUrl':'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&q=80'},
    {'id':10, 'title':'Watermelon (Tarbooz)',    'urdu':'تربوز',             'location':'Rahim Yar Khan',      'price':30,   'unit':'per kg','min_order':100, 'stock':3000, 'category':'Fruits',    'color':const Color(0xFF4CAF50),'emoji':'🍉','imageUrl':'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80'},
    {'id':11, 'title':'Wheat (Gandum)',          'urdu':'گندم',              'location':'Sahiwal, Punjab',     'price':95,   'unit':'per kg','min_order':100, 'stock':5000, 'category':'Grains',    'color':const Color(0xFFF9A825),'emoji':'🌾','imageUrl':'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&q=80'},
    {'id':12, 'title':'Basmati Rice',            'urdu':'باسمتی چاول',       'location':'Gujranwala, Punjab',  'price':130,  'unit':'per kg','min_order':50,  'stock':2000, 'category':'Grains',    'color':const Color(0xFF1565C0),'emoji':'🍚','imageUrl':'https://images.unsplash.com/photo-1536304993881-ff86e0c9b592?w=400&q=80'},
    {'id':13, 'title':'Potato (Aloo)',           'urdu':'آلو',               'location':'Okara, Punjab',       'price':55,   'unit':'per kg','min_order':50,  'stock':3000, 'category':'Vegetables','color':const Color(0xFFFF9800),'emoji':'🥔','imageUrl':'https://images.unsplash.com/photo-1518977676405-d4a5e0a2a4c7?w=400&q=80'},
    {'id':14, 'title':'Garlic (Lehsan)',         'urdu':'لہسن',              'location':'Kasur, Punjab',       'price':220,  'unit':'per kg','min_order':10,  'stock':500,  'category':'Vegetables','color':const Color(0xFF9C27B0),'emoji':'🧄','imageUrl':'https://images.unsplash.com/photo-1501200291289-c5a76c232e5f?w=400&q=80'},
    {'id':15, 'title':'Kinnow Orange',           'urdu':'کنو',               'location':'Sargodha, Punjab',    'price':70,   'unit':'per kg','min_order':20,  'stock':1500, 'category':'Fruits',    'color':const Color(0xFFFF9800),'emoji':'🍊','imageUrl':'https://images.unsplash.com/photo-1547514701-42782101795e?w=400&q=80'},
    {'id':16, 'title':'Banana (Kela)',           'urdu':'کیلا',              'location':'Turbat, Balochistan', 'price':70,   'unit':'per kg','min_order':20,  'stock':1000, 'category':'Fruits',    'color':const Color(0xFFFFC107),'emoji':'🍌','imageUrl':'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80'},
    {'id':17, 'title':'Apple — Swat',            'urdu':'سیب سوات',          'location':'Swat, KPK',           'price':150,  'unit':'per kg','min_order':10,  'stock':800,  'category':'Fruits',    'color':const Color(0xFFF44336),'emoji':'🍎','imageUrl':'https://images.unsplash.com/photo-1569870499705-504209102861?w=400&q=80'},
    {'id':18, 'title':'Pomegranate (Anar)',      'urdu':'انار',              'location':'Peshawar, KPK',       'price':180,  'unit':'per kg','min_order':10,  'stock':600,  'category':'Fruits',    'color':const Color(0xFFF44336),'emoji':'🍎','imageUrl':'https://images.unsplash.com/photo-1513828583688-c52646db42da?w=400&q=80'},
    {'id':19, 'title':'Guava (Amrood)',          'urdu':'امرود',             'location':'Karachi, Sindh',      'price':90,   'unit':'per kg','min_order':10,  'stock':700,  'category':'Fruits',    'color':const Color(0xFF4CAF50),'emoji':'🍈','imageUrl':'https://images.unsplash.com/photo-1536511132770-e5058c7e8c46?w=400&q=80'},
    {'id':20, 'title':'Grapes (Angoor)',         'urdu':'انگور',             'location':'Quetta, Balochistan', 'price':180,  'unit':'per kg','min_order':5,   'stock':400,  'category':'Fruits',    'color':const Color(0xFF9C27B0),'emoji':'🍇','imageUrl':'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=400&q=80'},
    {'id':21, 'title':'Dates (Khajoor)',         'urdu':'کھجور',             'location':'Khairpur, Sindh',     'price':400,  'unit':'per kg','min_order':5,   'stock':300,  'category':'Fruits',    'color':const Color(0xFF795548),'emoji':'🌴','imageUrl':'https://images.unsplash.com/photo-1604085572504-a392ddf0d86a?w=400&q=80'},
    {'id':22, 'title':'Melon (Kharbooza)',       'urdu':'خربوزہ',            'location':'Sukkur, Sindh',       'price':40,   'unit':'per kg','min_order':50,  'stock':1500, 'category':'Fruits',    'color':const Color(0xFFFFC107),'emoji':'🍈','imageUrl':'https://images.unsplash.com/photo-1571575173700-afb9492437af?w=400&q=80'},
    {'id':23, 'title':'IRRI Rice',               'urdu':'آئی آر آر آئی',    'location':'Larkana, Sindh',      'price':80,   'unit':'per kg','min_order':100, 'stock':3000, 'category':'Grains',    'color':const Color(0xFF1565C0),'emoji':'🍚','imageUrl':'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=400&q=80'},
    {'id':24, 'title':'Maize (Makai)',           'urdu':'مکئی',              'location':'Nowshera, KPK',       'price':70,   'unit':'per kg','min_order':100, 'stock':4000, 'category':'Grains',    'color':const Color(0xFFFFC107),'emoji':'🌽','imageUrl':'https://images.unsplash.com/photo-1601593768938-fa742bd6b8a8?w=400&q=80'},
    {'id':25, 'title':'Masoor Daal',             'urdu':'مسور دال',          'location':'Rawalpindi',          'price':180,  'unit':'per kg','min_order':10,  'stock':500,  'category':'Pulses',    'color':const Color(0xFFFF5722),'emoji':'🫘','imageUrl':'https://images.unsplash.com/photo-1585996852602-1d6c6dfbcc89?w=400&q=80'},
    {'id':26, 'title':'Mung Daal',               'urdu':'مونگ دال',          'location':'Bahawalpur',          'price':200,  'unit':'per kg','min_order':10,  'stock':400,  'category':'Pulses',    'color':const Color(0xFF4CAF50),'emoji':'🫘','imageUrl':'https://images.unsplash.com/photo-1515543904379-3d757fe72b3a?w=400&q=80'},
    {'id':27, 'title':'Chickpea (Chana)',        'urdu':'چنا',               'location':'Bhakkar, Punjab',     'price':160,  'unit':'per kg','min_order':20,  'stock':600,  'category':'Pulses',    'color':const Color(0xFFFF9800),'emoji':'🫘','imageUrl':'https://images.unsplash.com/photo-1515543904379-3d757fe72b3a?w=400&q=80'},
    {'id':28, 'title':'Spinach (Palak)',         'urdu':'پالک',              'location':'Lahore, Punjab',      'price':40,   'unit':'per kg','min_order':10,  'stock':500,  'category':'Vegetables','color':const Color(0xFF4CAF50),'emoji':'🥬','imageUrl':'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&q=80'},
    {'id':29, 'title':'Carrot (Gajar)',          'urdu':'گاجر',              'location':'Peshawar, KPK',       'price':60,   'unit':'per kg','min_order':20,  'stock':800,  'category':'Vegetables','color':const Color(0xFFFF5722),'emoji':'🥕','imageUrl':'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&q=80'},
    {'id':30, 'title':'Cauliflower (Gobhi)',     'urdu':'گوبھی',             'location':'Gujranwala',          'price':50,   'unit':'per kg','min_order':20,  'stock':600,  'category':'Vegetables','color':const Color(0xFF607D8B),'emoji':'🥦','imageUrl':'https://images.unsplash.com/photo-1566842600175-97dca489844f?w=400&q=80'},
    {'id':31, 'title':'Cabbage (Bandgobhi)',     'urdu':'بند گوبھی',         'location':'Faisalabad',          'price':40,   'unit':'per kg','min_order':20,  'stock':700,  'category':'Vegetables','color':const Color(0xFF4CAF50),'emoji':'🥬','imageUrl':'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=400&q=80'},
    {'id':32, 'title':'Green Peas (Matar)',      'urdu':'مٹر',               'location':'Sialkot, Punjab',     'price':100,  'unit':'per kg','min_order':10,  'stock':400,  'category':'Vegetables','color':const Color(0xFF4CAF50),'emoji':'🟢','imageUrl':'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80'},
    {'id':33, 'title':'Brinjal (Baingan)',       'urdu':'بینگن',             'location':'Hyderabad, Sindh',    'price':60,   'unit':'per kg','min_order':10,  'stock':500,  'category':'Vegetables','color':const Color(0xFF9C27B0),'emoji':'🍆','imageUrl':'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80'},
    {'id':34, 'title':'Okra (Bhindi)',           'urdu':'بھنڈی',             'location':'Nawabshah, Sindh',    'price':80,   'unit':'per kg','min_order':10,  'stock':400,  'category':'Vegetables','color':const Color(0xFF4CAF50),'emoji':'🌿','imageUrl':'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=400&q=80'},
    {'id':35, 'title':'Capsicum (Shimla Mirch)', 'urdu':'شملہ مرچ',          'location':'Islamabad',           'price':120,  'unit':'per kg','min_order':5,   'stock':300,  'category':'Vegetables','color':const Color(0xFFF44336),'emoji':'🫑','imageUrl':'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400&q=80'},
    {'id':36, 'title':'Cherry Tomato',           'urdu':'چھوٹا ٹماٹر',       'location':'Islamabad',           'price':150,  'unit':'per kg','min_order':5,   'stock':200,  'category':'Vegetables','color':const Color(0xFFF44336),'emoji':'🍅','imageUrl':'https://images.unsplash.com/photo-1561136594-7f68413baa99?w=400&q=80'},
    {'id':37, 'title':'Turmeric (Haldi)',        'urdu':'ہلدی',              'location':'Mirpur Khas, Sindh',  'price':300,  'unit':'per kg','min_order':5,   'stock':300,  'category':'Spices',    'color':const Color(0xFFFFC107),'emoji':'🟡','imageUrl':'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=400&q=80'},
    {'id':38, 'title':'Ginger (Adrak)',          'urdu':'ادرک',              'location':'Swat, KPK',           'price':250,  'unit':'per kg','min_order':5,   'stock':400,  'category':'Spices',    'color':const Color(0xFFFF9800),'emoji':'🫚','imageUrl':'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=400&q=80'},
    {'id':39, 'title':'Dried Chilli Powder',     'urdu':'پسی ہوئی مرچ',      'location':'Lahore, Punjab',      'price':350,  'unit':'per kg','min_order':2,   'stock':600,  'category':'Spices',    'color':const Color(0xFFF44336),'emoji':'🌶️','imageUrl':'https://images.unsplash.com/photo-1588315029754-2dd089d39a1a?w=400&q=80'},
    {'id':40, 'title':'Groundnut (Mungphali)',   'urdu':'مونگ پھلی',         'location':'Attock, Punjab',      'price':200,  'unit':'per kg','min_order':10,  'stock':500,  'category':'Oilseeds',  'color':const Color(0xFF795548),'emoji':'🥜','imageUrl':'https://images.unsplash.com/photo-1567892320421-72e11d8896f3?w=400&q=80'},
    {'id':41, 'title':'Sunflower Seeds',         'urdu':'سورج مکھی',         'location':'Bhakkar, Punjab',     'price':140,  'unit':'per kg','min_order':50,  'stock':800,  'category':'Oilseeds',  'color':const Color(0xFFFFC107),'emoji':'🌻','imageUrl':'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=400&q=80'},
    {'id':42, 'title':'Mustard (Sarson)',        'urdu':'سرسوں',             'location':'Sahiwal, Punjab',     'price':155,  'unit':'per kg','min_order':50,  'stock':1000, 'category':'Oilseeds',  'color':const Color(0xFFFFC107),'emoji':'🌱','imageUrl':'https://images.unsplash.com/photo-1615485008537-b9d3b31f3527?w=400&q=80'},
    {'id':43, 'title':'Cotton (Kapas)',          'urdu':'کپاس',              'location':'Vehari, Punjab',      'price':215,  'unit':'per kg','min_order':100, 'stock':2000, 'category':'Crops',     'color':const Color(0xFF6A1B9A),'emoji':'🌿','imageUrl':'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=400&q=80'},
    {'id':44, 'title':'Sugarcane (Ganna)',       'urdu':'گنا',               'location':'Mardan, KPK',         'price':10,   'unit':'per kg','min_order':1000,'stock':10000,'category':'Crops',     'color':const Color(0xFF4CAF50),'emoji':'🎋','imageUrl':'https://images.unsplash.com/photo-1563746924237-f81138e7da0c?w=400&q=80'},
    {'id':45, 'title':'Kashmiri Apple',          'urdu':'کشمیری سیب',        'location':'Gilgit, GB',          'price':200,  'unit':'per kg','min_order':5,   'stock':400,  'category':'Fruits',    'color':const Color(0xFFF44336),'emoji':'🍎','imageUrl':'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400&q=80'},
    {'id':46, 'title':'Malta Orange',            'urdu':'مالٹا',             'location':'Mirpur, AJK',         'price':80,   'unit':'per kg','min_order':20,  'stock':800,  'category':'Fruits',    'color':const Color(0xFFFF9800),'emoji':'🍊','imageUrl':'https://images.unsplash.com/photo-1557800636-894a64c1696f?w=400&q=80'},
    {'id':47, 'title':'Sweet Potato',            'urdu':'شکرقندی',           'location':'Attock, Punjab',      'price':80,   'unit':'per kg','min_order':10,  'stock':300,  'category':'Vegetables','color':const Color(0xFFFF5722),'emoji':'🍠','imageUrl':'https://images.unsplash.com/photo-1596591868231-05e808fd131d?w=400&q=80'},
    {'id':48, 'title':'Fresh Pomfret Fish',      'urdu':'پاپلیٹ مچھلی',      'location':'Karachi, Sindh',      'price':1800, 'unit':'per kg','min_order':2,   'stock':100,  'category':'Fish',      'color':const Color(0xFF0288D1),'emoji':'🐟','imageUrl':'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&q=80'},
    {'id':49, 'title':'Fresh Shrimp',            'urdu':'جھینگا',            'location':'Gwadar, Balochistan', 'price':2500, 'unit':'per kg','min_order':2,   'stock':150,  'category':'Seafood',   'color':const Color(0xFF00838F),'emoji':'🦐','imageUrl':'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400&q=80'},
    {'id':50, 'title':'White Onion',             'urdu':'سفید پیاز',         'location':'Larkana, Sindh',      'price':70,   'unit':'per kg','min_order':20,  'stock':1500, 'category':'Vegetables','color':const Color(0xFF9C27B0),'emoji':'🧅','imageUrl':'https://images.unsplash.com/photo-1508747703725-719777637510?w=400&q=80'},
  ];

  final List<Map<String, dynamic>> _userListings = [];

  List<Map<String, dynamic>> get _allProducts => [..._products, ..._userListings];

  List<Map<String, dynamic>> get _filtered {
    return _allProducts.where((p) {
      final matchCat = _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty ||
          (p['title'] as String).toLowerCase().contains(q) ||
          ((p['urdu'] ?? '') as String).contains(q) ||
          (p['location'] as String).toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  String _convertPrice(dynamic price) {
    final p = (price as num).toDouble();
    switch (_selectedUnit) {
      case 'pounds': return 'Rs${(p / 2.205).toStringAsFixed(0)}/lb';
      case 'tons':   return 'Rs${(p * 1000).toStringAsFixed(0)}/ton';
      default:       return '₨${p.toStringAsFixed(0)}';
    }
  }

  Future<void> _callSeller() async {
    final uri = Uri.parse('tel:$_sellerPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(Map<String, dynamic> p) async {
    final msg = Uri.encodeComponent(
      'Hello RaastKar! I am interested in ${p['title']} (${p['urdu'] ?? ''}). '
      'Price: ${_convertPrice(p['price'])}/${p['unit']}. Please confirm availability.');
    final uri = Uri.parse('https://wa.me/92$_sellerPhone?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showDetail(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, ctrl) => SingleChildScrollView(controller: ctrl, child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          if (p['imageUrl'] != null)
            SizedBox(
              height: 220, width: double.infinity,
              child: Image.network(p['imageUrl'] as String, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: (p['color'] as Color).withValues(alpha: 0.1),
                    child: Center(child: Text(p['emoji'] as String, style: const TextStyle(fontSize: 80))))),
            ),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if ((p['urdu'] ?? '').toString().isNotEmpty)
                  Text(p['urdu'] as String, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                child: Text(p['category'] as String, style: const TextStyle(color: Color(0xFF2E7D52), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D3B1F), Color(0xFF2E7D52)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _dStat('Price', '${_convertPrice(p['price'])}/${p['unit']}'),
                _dStat('Min Order', '${p['min_order']} kg'),
                _dStat('Stock', '${p['stock']} kg'),
              ]),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.location_on, 'Location', p['location'] as String),
            const SizedBox(height: 6),
            _infoRow(Icons.person, 'Seller', _sellerName),
            const SizedBox(height: 6),
            _infoRow(Icons.phone, 'Contact', '0300-2678621'),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: _callSeller,
                icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                label: const Text('Call Now', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _whatsapp(p),
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ]),
          ])),
        ])),
      ),
    );
  }

  Widget _dStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: const Color(0xFF2E7D52), size: 16),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
  ]);

  // ── Sell your crop ──
  Future<void> _showAddListingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getBool('farm_registered') ?? false;
    if (!registered) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌾', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Register Your Farm First!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('You need to register your farm before selling.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmRegistrationScreen())); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Register Farm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ));
      return;
    }
    _showListingForm();
  }

  void _showListingForm() {
    final titleCtrl    = TextEditingController();
    final priceCtrl    = TextEditingController();
    final stockCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final phoneCtrl    = TextEditingController();
    String selCat      = 'Grains';
    Uint8List? imgBytes;
    String? imgBase64;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(Tr.get('sellYourCrop'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
              if (img != null) { final b = await img.readAsBytes(); setModal(() { imgBytes = b; imgBase64 = base64Encode(b); }); }
            },
            child: Container(
              width: double.infinity, height: 130,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: imgBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(imgBytes!, fit: BoxFit.cover))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_a_photo, size: 36, color: Color(0xFF2E7D52)),
                      const SizedBox(height: 6),
                      Text(Tr.get('addPhoto'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D52))),
                    ]),
            ),
          ),
          const SizedBox(height: 10),
          TextField(controller: titleCtrl, decoration: _dec(Tr.get('productTitle'), Icons.title)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selCat, decoration: _dec(Tr.get('category'), Icons.category),
            items: ['Grains','Vegetables','Fruits','Spices','Oilseeds','Crops','Fish','Seafood','Other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setModal(() => selCat = v!),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _dec(Tr.get('pricePKR'), Icons.money))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: _dec(Tr.get('bagsAvailableLabel'), Icons.inventory))),
          ]),
          const SizedBox(height: 8),
          TextField(controller: locationCtrl, decoration: _dec(Tr.get('yourLocation'), Icons.location_on)),
          const SizedBox(height: 8),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _dec(Tr.get('whatsappNumber'), Icons.phone)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                try {
                  await http.post(
                    Uri.parse('${AuthService.baseUrl}/api/marketplace/notify'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'title': titleCtrl.text, 'category': selCat,
                      'price': priceCtrl.text, 'location': locationCtrl.text,
                      'phone': phoneCtrl.text,
                    }),
                  ).timeout(const Duration(seconds: 5));
                } catch (_) {}
                setState(() => _userListings.add({
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'title': titleCtrl.text, 'urdu': '',
                  'location': locationCtrl.text.isEmpty ? 'Pakistan' : locationCtrl.text,
                  'price': int.tryParse(priceCtrl.text) ?? 0, 'unit': 'per kg',
                  'min_order': 1, 'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'category': selCat, 'color': const Color(0xFF2E7D52),
                  'emoji': '🌱', 'imageUrl': null, 'imageBase64': imgBase64,
                  'isUserListing': true,
                }));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Listing added!'), backgroundColor: Color(0xFF2E7D52)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(Tr.get('postListing'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ])),
      )),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(fontSize: 13),
    prefixIcon: Icon(icon, color: const Color(0xFF2E7D52), size: 20),
    filled: true, fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddListingDialog,
        backgroundColor: const Color(0xFF2E7D52),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(Tr.get('sellYourCrop'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [

        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D3B1F), Color(0xFF1B5E20)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.storefront, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Tr.get('marketplace'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Fresh farm produce — direct from farmers', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 10, fontWeight: FontWeight.w600)),
              ])),
              GestureDetector(
                onTap: _callSeller,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.phone, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('0300-2678621', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              height: 38,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search products, location...', hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.white54, size: 18),
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ]),
        ),

        // ── Filters ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(children: [
            // Unit
            Row(children: [
              const Text('Unit: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ..._units.map((u) => GestureDetector(
                onTap: () => setState(() => _selectedUnit = u),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _selectedUnit == u ? const Color(0xFF1B5E20) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(u, style: TextStyle(color: _selectedUnit == u ? Colors.white : Colors.grey, fontSize: 11)),
                ),
              )),
            ]),
            const SizedBox(height: 6),
            // Category
            SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1B5E20) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(cat, style: TextStyle(color: sel ? Colors.white : Colors.grey.shade600, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        // Stats
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(children: [
            Text('${filtered.length} products', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.verified, color: Color(0xFF2E7D52), size: 12),
            const SizedBox(width: 4),
            const Text('Direct from farms', style: TextStyle(color: Color(0xFF2E7D52), fontSize: 11)),
          ]),
        ),

        // ── Grid ──
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🌾', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No products found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Try another category', style: TextStyle(color: Colors.grey)),
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 80),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.82 : 0.72,
                    crossAxisSpacing: 8,
                    mainAxisSpacing:  8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildCard(filtered[i]),
                ),
        ),
      ]),
    );
  }

  // ── Product Card ──
  Widget _buildCard(Map<String, dynamic> p) {
    final Color color    = p['color'] as Color;
    final String? imgUrl = p['imageUrl'] as String?;
    final String? imgB64 = p['imageBase64'] as String?;

    return GestureDetector(
      onTap: () => _showDetail(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Image — fixed 120px height, never stretches
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: imgB64 != null
                  ? Image.memory(base64Decode(imgB64), fit: BoxFit.cover)
                  : imgUrl != null
                      ? Image.network(
                          imgUrl, fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : Container(
                                  color: color.withValues(alpha: 0.08),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: color))),
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withValues(alpha: 0.08),
                            child: Center(child: Text(p['emoji'] as String, style: const TextStyle(fontSize: 44)))))
                      : Container(
                          color: color.withValues(alpha: 0.08),
                          child: Center(child: Text(p['emoji'] as String, style: const TextStyle(fontSize: 44)))),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(p['category'] as String, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              // Name
              Text(p['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              // Urdu
              if ((p['urdu'] ?? '').toString().isNotEmpty)
                Text(p['urdu'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              // Location
              Row(children: [
                const Icon(Icons.location_on, size: 10, color: Colors.grey),
                const SizedBox(width: 2),
                Expanded(child: Text(p['location'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 6),
              // Price + WhatsApp
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_convertPrice(p['price']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(p['unit'] as String, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                ])),
                GestureDetector(
                  onTap: () => _whatsapp(p),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.chat, color: Colors.white, size: 14),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
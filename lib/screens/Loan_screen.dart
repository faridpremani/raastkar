import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});
  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  static const String _base = 'https://raastkar-backend.vercel.app';
  static const Color _green = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF2E7D52);

  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _submitted  = false;
  int  _step = 0; // 0=personal 1=family 2=farm 3=loan 4=review

  // ── Step 1: Personal ──
  final _fullName    = TextEditingController();
  final _fatherName  = TextEditingController();
  final _cnic        = TextEditingController();
  final _mobile      = TextEditingController();
  final _altMobile   = TextEditingController();
  final _district    = TextEditingController();
  final _tehsil      = TextEditingController();
  final _address     = TextEditingController();
  String _province = '', _education = '', _maritalStatus = '', _dob = '';

  // ── Step 2: Family ──
  final _totalMembers   = TextEditingController();
  final _earners        = TextEditingController();
  final _dependents     = TextEditingController();
  final _farmIncome     = TextEditingController();
  final _otherIncome    = TextEditingController();
  final _familyIncome   = TextEditingController();
  final _expenses       = TextEditingController();
  final _existingLender = TextEditingController();
  final _existingEMI    = TextEditingController();
  String _familyOccupation = '', _workingAbroad = '', _existingLoan = 'no';

  // ── Step 3: Farm ──
  final _landAcres = TextEditingController();
  String _landOwnership = '', _primaryCrop = '', _secondaryCrop = '',
         _irrigation = '', _experience = '', _livestock = '';

  // ── Step 4: Loan ──
  final _loanAmount      = TextEditingController();
  final _loanPurpose     = TextEditingController();
  String _loanType = '', _repaymentPeriod = '', _preferredBank = '',
         _collateral = '', _guarantor = '';

  final List<String> _provinces = ['Punjab','Sindh','KPK','Balochistan','AJK','Gilgit Baltistan'];
  final List<String> _crops     = ['Wheat','Rice / Paddy','Sugarcane','Cotton','Maize','Vegetables','Fruits','Other'];
  final List<String> _banks     = ['Any bank (recommend best)','Zarai Taraqiati Bank (ZTBL)','Bank of Punjab (BOP)','National Bank (NBP)','Bank of Khyber (BOK)','HBL','MCB','Allied Bank'];
  final List<String> _loanTypes = ['Seasonal / Production loan','Development / Term loan','Livestock loan','Farm machinery / tractor','Solar tube well (PM scheme)','Cold storage / warehouse'];

  final List<String> _steps = ['Personal Info','Family & Income','Farm Details','Loan Details'];

  double get _totalIncome =>
      (double.tryParse(_farmIncome.text) ?? 0) +
      (double.tryParse(_otherIncome.text) ?? 0) +
      (double.tryParse(_familyIncome.text) ?? 0);

  double get _surplus => _totalIncome - (double.tryParse(_expenses.text) ?? 0);

  @override
  void dispose() {
    for (final c in [_fullName,_fatherName,_cnic,_mobile,_altMobile,_district,
        _tehsil,_address,_totalMembers,_earners,_dependents,_farmIncome,
        _otherIncome,_familyIncome,_expenses,_existingLender,_existingEMI,
        _landAcres,_loanAmount,_loanPurpose]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final body   = {
        'userId': userId,
        'fullName': _fullName.text, 'fatherName': _fatherName.text,
        'cnic': _cnic.text, 'dob': _dob, 'mobile': _mobile.text,
        'altMobile': _altMobile.text, 'province': _province,
        'district': _district.text, 'tehsil': _tehsil.text,
        'address': _address.text, 'education': _education,
        'maritalStatus': _maritalStatus,
        'totalMembers': _totalMembers.text, 'earningMembers': _earners.text,
        'dependents': _dependents.text, 'farmIncome': _farmIncome.text,
        'otherIncome': _otherIncome.text, 'familyIncome': _familyIncome.text,
        'monthlyExpenses': _expenses.text, 'familyOccupation': _familyOccupation,
        'workingAbroad': _workingAbroad, 'existingLoan': _existingLoan,
        'existingLender': _existingLender.text, 'existingEMI': _existingEMI.text,
        'landAcres': _landAcres.text, 'landOwnership': _landOwnership,
        'primaryCrop': _primaryCrop, 'secondaryCrop': _secondaryCrop,
        'irrigation': _irrigation, 'experience': _experience,
        'livestock': _livestock, 'loanType': _loanType,
        'loanAmount': _loanAmount.text, 'repaymentPeriod': _repaymentPeriod,
        'preferredBank': _preferredBank, 'loanPurpose': _loanPurpose.text,
        'collateral': _collateral, 'guarantor': _guarantor,
      };
      await http.post(
        Uri.parse('$_base/api/loan/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
      setState(() { _submitted = true; _submitting = false; });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF071F10), Color(0xFF1B5E20)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agricultural Loan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              Text('Kissan Package — SBP Approved', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Color(0xFF2E7D52), size: 56),
          ),
          const SizedBox(height: 20),
          const Text('Application Submitted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFCC02))),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.access_time, color: Color(0xFFFF8F00), size: 18), SizedBox(width: 8), Text('What happens next?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8F00)))]),
              SizedBox(height: 8),
              Text('1. Our loan officer reviews your application', style: TextStyle(fontSize: 13, color: Color(0xFF795548))),
              Text('2. We contact you within 2 working days', style: TextStyle(fontSize: 13, color: Color(0xFF795548))),
              Text('3. We guide you to the right bank', style: TextStyle(fontSize: 13, color: Color(0xFF795548))),
              Text('4. Bank processes your loan', style: TextStyle(fontSize: 13, color: Color(0xFF795548))),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Need help? WhatsApp: 03002678621', style: TextStyle(color: Color(0xFF2E7D52), fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _lightGreen, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _buildForm() {
    return SafeArea(
      child: Column(children: [
      // Step indicator
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(children: [
          Row(children: List.generate(_steps.length, (i) => Expanded(
            child: Row(children: [
              Expanded(child: Column(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: i <= _step ? _green : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: i < _step
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Center(child: Text('${i+1}', style: TextStyle(color: i == _step ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 4),
                Text(_steps[i], style: TextStyle(fontSize: 9, color: i <= _step ? _green : Colors.grey, fontWeight: i == _step ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
              ])),
              if (i < _steps.length - 1)
                Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 16), color: i < _step ? _green : Colors.grey.shade200)),
            ]),
          ))),
          const SizedBox(height: 8),
        ]),
      ),

      Expanded(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _step == 0 ? _step1Personal()
                 : _step == 1 ? _step2Family()
                 : _step == 2 ? _step3Farm()
                 : _step3Loan(),
          ),
        ),
      ),

      // Navigation buttons
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))]),
        child: Row(children: [
          if (_step > 0)
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1B5E20)), minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Back', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            )),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _submitting ? null : () {
              if (_step < 3) setState(() => _step++);
              else _submit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _green, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_step < 3 ? 'Next Step' : 'Submit Application', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          )),
        ]),
      ),
    ]));
  }

  Widget _secHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: _lightGreen, size: 20)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? type, bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label${required ? ' *' : ''}', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ]),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label${required ? ' *' : ''}', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          hint: Text('Select $label', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ]),
    );
  }

  Widget _infoBox(String text) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2E7D52).withValues(alpha: 0.3))),
    child: Row(children: [const Icon(Icons.info_outline, color: Color(0xFF2E7D52), size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 12)))]),
  );

  Widget _step1Personal() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secHeader('Personal Identification', Icons.person),
    _infoBox('Please fill in your details exactly as they appear on your CNIC.'),
    _field('Full name', _fullName, hint: 'e.g. Muhammad Tariq Ali', required: true),
    _field("Father's / husband's name", _fatherName, hint: 'e.g. Haji Bashir Ahmed', required: true),
    _field('CNIC number', _cnic, hint: '35202-1234567-1', type: TextInputType.number, required: true),
    _field('Mobile number', _mobile, hint: '03XX-XXXXXXX', type: TextInputType.phone, required: true),
    _field('Alternate / WhatsApp number', _altMobile, hint: '03XX-XXXXXXX', type: TextInputType.phone),
    _dropdown('Province', _province, _provinces, (v) => setState(() => _province = v ?? ''), required: true),
    _field('District', _district, hint: 'e.g. Faisalabad', required: true),
    _field('Tehsil / Union council', _tehsil, hint: 'e.g. Samundri'),
    _field('Permanent home address', _address, hint: 'Full address including village, city, postal code', maxLines: 3, required: true),
    _dropdown('Education level', _education, ['Illiterate','Primary (up to grade 5)','Middle (grade 6–8)','Matric','Intermediate','Bachelor\'s or above'], (v) => setState(() => _education = v ?? '')),
    _dropdown('Marital status', _maritalStatus, ['Married','Single','Widowed','Divorced'], (v) => setState(() => _maritalStatus = v ?? '')),
  ]);

  Widget _step2Family() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secHeader('Family Background & Income', Icons.family_restroom),
    _infoBox('Banks assess your total household earning capacity. Please provide accurate information.'),
    Row(children: [Expanded(child: _field('Total family members', _totalMembers, hint: 'e.g. 6', type: TextInputType.number, required: true)), const SizedBox(width: 12), Expanded(child: _field('Earning members', _earners, hint: 'e.g. 2', type: TextInputType.number, required: true))]),
    _field('Dependents (children, elderly etc.)', _dependents, hint: 'e.g. 4', type: TextInputType.number),
    Row(children: [Expanded(child: _field('Your farm income / month (PKR)', _farmIncome, hint: 'e.g. 45000', type: TextInputType.number, required: true)), const SizedBox(width: 12), Expanded(child: _field('Other income / month (PKR)', _otherIncome, hint: 'e.g. 15000', type: TextInputType.number))]),
    _field("Family members' combined income / month (PKR)", _familyIncome, hint: 'e.g. 20000', type: TextInputType.number),
    _field('Monthly household expenses (PKR)', _expenses, hint: 'e.g. 30000', type: TextInputType.number),
    if (_totalIncome > 0)
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _miniStat('Total income', 'PKR ${_totalIncome.toStringAsFixed(0)}', Colors.blue),
          _miniStat('Monthly surplus', 'PKR ${_surplus.toStringAsFixed(0)}', _surplus >= 0 ? Colors.green : Colors.red),
        ]),
      ),
    _dropdown('Family occupation / background', _familyOccupation, ['Farming only','Farming + government job','Farming + private job','Farming + business','Farming + overseas remittance','Farming + daily labour'], (v) => setState(() => _familyOccupation = v ?? '')),
    _dropdown('Any family member working abroad?', _workingAbroad, ['No','Yes — Saudi Arabia','Yes — UAE / Gulf','Yes — UK / Europe','Yes — Other country'], (v) => setState(() => _workingAbroad = v ?? '')),
    _dropdown('Any existing loans?', _existingLoan, ['no','yes'], (v) => setState(() => _existingLoan = v ?? 'no')),
    if (_existingLoan == 'yes') ...[
      _field('Lender name', _existingLender, hint: 'e.g. ZTBL, HBL, committee'),
      _field('Monthly instalment (PKR)', _existingEMI, hint: 'e.g. 8000', type: TextInputType.number),
    ],
  ]);

  Widget _miniStat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _step3Farm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secHeader('Farm & Land Details', Icons.agriculture),
    _field('Total land area (acres)', _landAcres, hint: 'e.g. 12.5', type: TextInputType.number, required: true),
    _dropdown('Land ownership type', _landOwnership, ['Owned (registered title deed / fard)','Leased / Theka','Shared / Batai','Family / ancestral land','Government allotted'], (v) => setState(() => _landOwnership = v ?? ''), required: true),
    _dropdown('Primary crop', _primaryCrop, _crops, (v) => setState(() => _primaryCrop = v ?? ''), required: true),
    _dropdown('Secondary crop', _secondaryCrop, ['None',..._crops], (v) => setState(() => _secondaryCrop = v ?? '')),
    _dropdown('Irrigation source', _irrigation, ['Canal water','Tube well (electric)','Tube well (diesel)','Rainwater','River / flood irrigation'], (v) => setState(() => _irrigation = v ?? '')),
    _dropdown('Farming experience', _experience, ['Less than 1 year','1–3 years','3–5 years','5–10 years','More than 10 years'], (v) => setState(() => _experience = v ?? ''), required: true),
    _dropdown('Do you own livestock?', _livestock, ['No livestock','1–5 animals','6–15 animals','More than 15 animals'], (v) => setState(() => _livestock = v ?? '')),
  ]);

  Widget _step3Loan() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secHeader('Loan Details', Icons.account_balance),
    _dropdown('Type of loan required', _loanType, _loanTypes, (v) => setState(() => _loanType = v ?? ''), required: true),
    if (_loanType.isNotEmpty) _loanTipBox(_loanType),
    _field('Loan amount required (PKR)', _loanAmount, hint: 'e.g. 500000', type: TextInputType.number, required: true),
    _dropdown('Repayment period', _repaymentPeriod, ['6 months (after harvest)','1 year','2 years','3 years','5 years','7 years'], (v) => setState(() => _repaymentPeriod = v ?? ''), required: true),
    _dropdown('Preferred bank', _preferredBank, _banks, (v) => setState(() => _preferredBank = v ?? '')),
    _field('Purpose of loan — describe in detail', _loanPurpose, hint: 'e.g. I need PKR 3 lakh to purchase wheat seeds (50 bags), DAP fertiliser (20 bags) for this rabi season on 8 acres...', maxLines: 5, required: true),
    _dropdown('Collateral available', _collateral, ['Land / property (mortgageable)','Gold / jewellery','Vehicle / tractor','Guarantor only','None (first-time applicant)'], (v) => setState(() => _collateral = v ?? '')),
    _dropdown('Guarantor available?', _guarantor, ['Yes — family member','Yes — neighbour / friend','Yes — government employee','No guarantor'], (v) => setState(() => _guarantor = v ?? '')),
    const SizedBox(height: 8),
    _infoBox('By submitting this application you authorise RaastKar to share your farm data with partner banks for loan processing.'),
  ]);

  Widget _loanTipBox(String type) {
    final tips = {
      'Seasonal / Production loan': 'Best for seeds, fertiliser, pesticides, labour. Max PKR 1.5M. Repaid after harvest (6–12 months). Lowest interest ~5% p.a.',
      'Development / Term loan': 'For land levelling, orchards, tube wells. Max PKR 5M. Repayment 3–7 years. Interest 7–9% p.a.',
      'Livestock loan': 'For cattle, buffalo, goats, poultry. Max PKR 1M per unit. Repayment 1–3 years. ~6% p.a.',
      'Farm machinery / tractor': 'Up to 70% of machine value financed. Repayment 3–5 years. ~7–8% p.a.',
      'Solar tube well (PM scheme)': 'Subsidised 2–3% p.a. Max PKR 2M. Repayment 5 years. Zero collateral under 12.5 acres.',
      'Cold storage / warehouse': 'Max PKR 3M. Repayment 5 years. ~8% p.a.',
    };
    final tip = tips[type] ?? '';
    if (tip.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFCC02))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_outline, color: Color(0xFFFF8F00), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(tip, style: const TextStyle(color: Color(0xFF795548), fontSize: 12, height: 1.5))),
      ]),
    );
  }
}
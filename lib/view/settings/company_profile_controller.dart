import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyProfileController extends ChangeNotifier {
  static const _kName = 'cp_name';
  static const _kTagline = 'cp_tagline';
  static const _kEmail = 'cp_email';
  static const _kPhone = 'cp_phone';
  static const _kAddress = 'cp_address';
  static const _kVendorNumber = 'cp_vendor_number';
  static const _kLogoPath = 'cp_logo_path';
  static const _kSignaturePath = 'cp_signature_path';

  String _name = 'FM Sons';
  String _tagline = 'Government Contractor General Order Supplier';
  String _email = 'fmsons514@gmail.com';
  String _phone = '';
  String _address = 'PHQ Hospital Road - Modern Glass Aluminium Decoration Center';
  String _vendorNumber = '30140988';
  String? _logoPath;
  String? _signaturePath;

  bool _initialized = false;

  String get name => _name;
  String get tagline => _tagline;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String get vendorNumber => _vendorNumber;
  String? get logoPath => _logoPath;
  String? get signaturePath => _signaturePath;

  CompanyProfileController() {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_kName) ?? _name;
    _tagline = prefs.getString(_kTagline) ?? _tagline;
    _email = prefs.getString(_kEmail) ?? _email;
    _phone = prefs.getString(_kPhone) ?? _phone;
    _address = prefs.getString(_kAddress) ?? _address;
    _vendorNumber = prefs.getString(_kVendorNumber) ?? _vendorNumber;
    _logoPath = prefs.getString(_kLogoPath);
    _signaturePath = prefs.getString(_kSignaturePath);
    _initialized = true;
    notifyListeners();
  }

  Future<void> save({
    required String name,
    required String tagline,
    required String email,
    required String phone,
    required String address,
    required String vendorNumber,
    String? logoPath,
  }) async {
    _name = name.trim();
    _tagline = tagline.trim();
    _email = email.trim();
    _phone = phone.trim();
    _address = address.trim();
    _vendorNumber = vendorNumber.trim();
    if (logoPath != null) _logoPath = logoPath;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _name);
    await prefs.setString(_kTagline, _tagline);
    await prefs.setString(_kEmail, _email);
    await prefs.setString(_kPhone, _phone);
    await prefs.setString(_kAddress, _address);
    await prefs.setString(_kVendorNumber, _vendorNumber);
    if (_logoPath != null) await prefs.setString(_kLogoPath, _logoPath!);
  }

  Future<void> setLogoPath(String path) async {
    _logoPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLogoPath, path);
  }

  Future<void> setSignaturePath(String path) async {
    _signaturePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSignaturePath, path);
  }
}

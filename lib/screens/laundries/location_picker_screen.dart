import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Hasil pilihan lokasi yang dikembalikan LocationPickerScreen: bukan cuma
/// titik koordinat, tapi juga alamat/kota/provinsi hasil reverse geocoding
/// dari titik tersebut, supaya bisa langsung dipakai buat auto-fill field
/// form di CreateLaundryScreen.
class LocationPickResult {
  final LatLng point;
  final String? address;
  final String? city;
  final String? province;

  const LocationPickResult({
    required this.point,
    this.address,
    this.city,
    this.province,
  });
}

/// Layar picker lokasi pakai flutter_map + tile OpenStreetMap (gratis,
/// tanpa API key, tanpa billing). Dipakai dari CreateLaundryScreen: buka
/// full-screen, user tap peta buat naro/geser marker, lalu konfirmasi
/// buat mengembalikan LocationPickResult (titik + alamat/kota/provinsi
/// hasil reverse geocoding) ke layar sebelumnya via
/// Navigator.pop(context, LocationPickResult(...)).
///
/// [initialLocation] opsional - kalau field lat/lng di form sudah pernah
/// diisi (mode edit), marker langsung muncul di posisi itu. Kalau null,
/// default ke pusat Indonesia (biar user tinggal pan/zoom ke lokasi
/// cabangnya).
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(-2.5, 118.0); // tengah Indonesia
  static const _primary = Color(0xFF0061A4);

  late final MapController _mapController;
  LatLng? _selected;

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Hasil reverse geocoding titik yang dipilih (alamat, kota, provinsi).
  // Diisi otomatis tiap kali user tap/geser titik di peta atau pilih dari
  // hasil pencarian, lalu dikembalikan bareng LatLng ke CreateLaundryScreen.
  String? _resolvedAddress;
  String? _resolvedCity;
  String? _resolvedProvince;
  bool _isResolvingAddress = false;
  int _reverseGeocodeToken = 0; // cegah race condition kalau tap cepat berkali-kali

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selected = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Debounce 500ms biar ga nge-hit Nominatim tiap ketikan.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _searchPlace(query));
  }

  /// Cari nama daerah/alamat lewat Nominatim (geocoding gratis punya OSM,
  /// pasangan dari tile yang udah dipakai di peta ini - jadi ga butuh API
  /// key tambahan). Dibatasi ke Indonesia (countrycodes=id) biar hasilnya
  /// relevan.
  Future<void> _searchPlace(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'countrycodes': 'id',
        'addressdetails': '1',
        'limit': '6',
      });
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'com.netwash.app'}, // wajib sesuai kebijakan Nominatim
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _searchResults = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (_) {
      // Diamkan - user tetap bisa cari manual lewat peta kalau search gagal.
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'].toString());
    final lon = double.tryParse(result['lon'].toString());
    if (lat == null || lon == null) return;

    final point = LatLng(lat, lon);
    final address = result['address'] as Map<String, dynamic>?;
    final parts = _extractLocationParts(address);

    setState(() {
      _selected = point;
      _searchResults = [];
      _searchController.text = result['display_name'] ?? '';
      _resolvedAddress = result['display_name'] as String?;
      _resolvedCity = parts.$1;
      _resolvedProvince = parts.$2;
    });
    _mapController.move(point, 16);
    FocusScope.of(context).unfocus();
  }

  /// Ambil (kota, provinsi) dari struktur address Nominatim. Field kota
  /// tidak konsisten namanya antar lokasi (bisa 'city', 'town', 'regency',
  /// atau 'county'), jadi dicoba berurutan sampai ketemu yang ada isinya.
  (String?, String?) _extractLocationParts(Map<String, dynamic>? address) {
    if (address == null) return (null, null);
    final city = address['city'] ??
        address['town'] ??
        address['regency'] ??
        address['county'] ??
        address['municipality'] ??
        address['village'];
    final province = address['state'] ?? address['province'];
    return (city as String?, province as String?);
  }

  /// Reverse geocode: dari titik LatLng hasil tap/geser di peta, cari tahu
  /// alamat, kota, dan provinsinya lewat Nominatim. Dipakai supaya field
  /// alamat/kota/provinsi di form CreateLaundryScreen bisa keisi otomatis
  /// begitu user menentukan titik, tanpa perlu ngetik manual (tapi tetap
  /// bisa diedit lagi setelahnya).
  Future<void> _reverseGeocode(LatLng point) async {
    final myToken = ++_reverseGeocodeToken;
    setState(() => _isResolvingAddress = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
      });
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'com.netwash.app'},
      );
      // Kalau ada tap/geser lain yang lebih baru sebelum request ini
      // selesai, buang hasil ini - jangan sampai overwrite hasil yang
      // lebih baru dengan hasil yang telat datang.
      if (myToken != _reverseGeocodeToken || !mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        final parts = _extractLocationParts(address);
        setState(() {
          _resolvedAddress = data['display_name'] as String?;
          _resolvedCity = parts.$1;
          _resolvedProvince = parts.$2;
        });
      }
    } catch (_) {
      // Diamkan - koordinat tetap tersimpan, user cukup isi alamat manual.
    } finally {
      if (myToken == _reverseGeocodeToken && mounted) {
        setState(() => _isResolvingAddress = false);
      }
    }
  }

  void _onTap(TapPosition tapPos, LatLng point) {
    setState(() => _selected = point);
    _reverseGeocode(point);
  }

  void _confirm() {
    if (_selected == null) return;
    Navigator.pop(
      context,
      LocationPickResult(
        point: _selected!,
        address: _resolvedAddress,
        city: _resolvedCity,
        province: _resolvedProvince,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? _defaultCenter,
              initialZoom: widget.initialLocation != null ? 15 : 4.5,
              onTap: _onTap,
            ),
            children: [
              // Tile OpenStreetMap - gratis, tapi WAJIB pasang User-Agent
              // custom (bukan default Flutter) sesuai kebijakan OSM tile
              // usage policy, kalau tidak request bisa diblokir.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.netwash.app', // ganti sesuai applicationId kamu
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, color: _primary, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar: tombol back + hint teks
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: const Color(0xFF1B1C1C)),
                            decoration: InputDecoration(
                              hintText: 'Cari nama daerah / alamat...',
                              hintStyle: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF707883)),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF707883)),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF707883)),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchResults = []);
                                          },
                                        )
                                      : null),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            constraints: const BoxConstraints(maxHeight: 260),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final r = _searchResults[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined, size: 18, color: _primary),
                                  title: Text(
                                    r['display_name'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF1B1C1C)),
                                  ),
                                  onTap: () => _selectSearchResult(r),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol konfirmasi di bawah
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selected != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}',
                            style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: _primary),
                          ),
                          const SizedBox(height: 4),
                          if (_isResolvingAddress)
                            Text(
                              'Mencari alamat...',
                              style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: const Color(0xFF707883)),
                            )
                          else if (_resolvedAddress != null)
                            Text(
                              _resolvedAddress!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: const Color(0xFF1B1C1C)),
                            ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selected == null ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Gunakan Lokasi Ini',
                        style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0B3B66)),
      ),
    );
  }
}
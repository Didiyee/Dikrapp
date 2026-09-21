import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../core/settings.dart';
import '../core/prayer.dart';

class QiblaScreen extends StatefulWidget {
  final AppSettings settings;
  const QiblaScreen({super.key, required this.settings});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? heading;
  bool noSensor = false;
  StreamSubscription<CompassEvent>? _sub;
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();

  AppSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    latCtrl.text = s.lat.toString();
    lngCtrl.text = s.lng.toString();
    _sub = FlutterCompass.events?.listen((e) {
      if (!mounted) return;
      if (e.heading == null) {
        setState(() => noSensor = true);
      } else {
        setState(() {
          heading = e.heading;
          noSensor = false;
        });
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && heading == null) setState(() => noSensor = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.tr('تم رفض إذن الموقع', 'Location permission denied'))));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high))
          .timeout(const Duration(seconds: 15));
      s.update((x) {
        x.lat = double.parse(pos.latitude.toStringAsFixed(4));
        x.lng = double.parse(pos.longitude.toStringAsFixed(4));
        x.useCoords = true;
      });
      latCtrl.text = s.lat.toString();
      lngCtrl.text = s.lng.toString();
      setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.tr('تعذّر تحديد الموقع', 'Could not get location'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bearing = qiblaBearing(s.lat, s.lng);
    final h = heading ?? 0;
    final relative = ((bearing - h) % 360 + 360) % 360;
    final aligned = relative < 8 || relative > 352;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('🧭 ${s.tr('اتجاه القبلة', 'Qibla direction')}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: aligned ? const Color(0xFFECFDF5) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: aligned ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 250, height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.grey.withValues(alpha: 0.15), Colors.grey.withValues(alpha: 0.05)],
                        ),
                        border: Border.all(color: const Color(0xFF047857).withValues(alpha: 0.3), width: 6),
                      ),
                    ),
                    Transform.rotate(
                      angle: -h * math.pi / 180,
                      child: const Stack(
                        children: [
                          Positioned(top: 12, left: 0, right: 0, child: Text('N', textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))),
                          Positioned(bottom: 12, left: 0, right: 0, child: Text('S', textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          Positioned(right: 14, top: 0, bottom: 0, child: Center(child: Text('E',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                          Positioned(left: 14, top: 0, bottom: 0, child: Center(child: Text('W',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ),
                    Transform.rotate(
                      angle: relative * math.pi / 180,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🕋', style: TextStyle(fontSize: 38)),
                          SizedBox(height: 2),
                          _Needle(),
                        ],
                      ),
                    ),
                    Container(
                      width: 52, height: 52,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF047857)),
                      child: const Center(child: Text('🧭', style: TextStyle(fontSize: 24))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('${s.tr('زاوية القبلة', 'Qibla angle')}: ${bearing.toStringAsFixed(1)}°',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (noSensor)
                Text(s.tr('حساس البوصلة غير متوفر — استخدم الزاوية مع بوصلة خارجية', 'No compass sensor — use the angle with an external compass'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.orange))
              else if (aligned)
                Text(s.tr('✅ أنت متجه نحو القبلة الآن — تقبّل الله', 'You are facing the Qibla'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857)))
              else
                Text(s.tr('أدر هاتفك حتى تتجه علامة 🕋 للأعلى', 'Rotate until 🕋 points up'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ${s.tr('موقعك الحالي', 'Your location')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Lat', border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        onSubmitted: (v) {
                          final d = double.tryParse(v);
                          if (d != null) s.update((x) => x.lat = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Lng', border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        onSubmitted: (v) {
                          final d = double.tryParse(v);
                          if (d != null) s.update((x) => x.lng = d);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _locate,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                        child: Text('🎯 GPS — ${s.tr('موقعي', 'Locate me')}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => s.update((x) => x.useCoords = !x.useCoords),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.useCoords ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.3),
                          foregroundColor: s.useCoords ? Colors.white : Colors.black87,
                        ),
                        child: Text(s.useCoords ? '✅ GPS' : s.tr('استخدام الإحداثيات', 'Use coords')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class _Needle extends StatelessWidget {
  const _Needle();
  @override
  Widget build(BuildContext context) {
    return Container(width: 5, height: 70,
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFDE68A)]),
            borderRadius: BorderRadius.circular(4)));
  }
}

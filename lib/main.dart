import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

/* PROYECTO: ITI-BB Scanner Sincro v2.2.3
  ESTADO: Paso 1 - Consolidación de Sintaxis y Seguridad
  OBJETIVO: Eliminar errores de compilación, advertencias de obsolescencia y asegurar BuildContext.
*/

void main() => runApp(const ITIBBApp());

class ITIBBApp extends StatelessWidget {
  const ITIBBApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A101E),
        primaryColor: const Color(0xFF3B82F6),
        useMaterial3: true,
      ),
      home: const ScannerHome(),
    );
  }
}

class ScannerHome extends StatefulWidget {
  const ScannerHome({super.key});
  @override
  State<ScannerHome> createState() => _ScannerHomeState();
}

class _ScannerHomeState extends State<ScannerHome> {
  final MobileScannerController controller = MobileScannerController();
  String serverIp = "192.168.1.16"; 
  bool canScan = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ITI-BB SCANNER", style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.lan), onPressed: _editIp),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!canScan) return;
              final code = capture.barcodes.first.rawValue;
              if (code != null && code.contains('ITIBB-INF-IND-')) {
                setState(() => canScan = false);
                final id = code.split('/').last;
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (c) => AssetDetails(id: id, ip: serverIp))
                ).then((_) {
                  // SUB-PASO 1.2: Guarda de montaje para seguridad asíncrona
                  if (mounted) setState(() => canScan = true);
                });
              }
            },
          ),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6), width: 4),
                borderRadius: BorderRadius.circular(30)
              ),
            ),
          ),
          _buildSignature(),
        ],
      ),
    );
  }

  Widget _buildSignature() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
        child: Text(
          "Informática Industrial - Adrian Siani Arellano",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  void _editIp() {
    TextEditingController c = TextEditingController(text: serverIp);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("IP del Servidor XAMPP"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () { 
            if (mounted) setState(() => serverIp = c.text); 
            Navigator.pop(ctx); 
          }, child: const Text("Confirmar")),
        ],
      ),
    );
  }
}

class AssetDetails extends StatefulWidget {
  final String id;
  final String ip;
  const AssetDetails({super.key, required this.id, required this.ip});
  @override
  State<AssetDetails> createState() => _AssetDetailsState();
}

class _AssetDetailsState extends State<AssetDetails> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  final List<String> labsValidos = [
    'LTICs',
    'Aula de Desarrollo',
    'Lab. 502 Informatica',
    'Lab. Mantenimineto / Redes' 
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  _fetch() async {
    try {
      final res = await http.get(Uri.parse('https://proyecto-itibb.vercel.app/api/asset/${widget.id}'))
          .timeout(const Duration(seconds: 10));
      
      // SUB-PASO 1.2: Evitar uso de BuildContext si el widget fue destruido
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() => data = json.decode(res.body));
      } else if (res.statusCode == 404) {
        setState(() => error = "ACTIVO NO CENSADO");
      }
    } catch (e) {
      if (mounted) setState(() => error = "FALLO DE CONEXIÓN");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Nuevo':
      case 'Bueno': return const Color(0xFF10B981);
      case 'Regular': return const Color(0xFFF59E0B);
      case 'Malo':
      case 'Crítico': return const Color(0xFFEF4444);
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return _buildErrorUI();

    final bool isUbicacionOk = labsValidos.contains(data!['id_lab'] ?? "");

    return Scaffold(
      appBar: AppBar(title: const Text("Ficha de Auditoría")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: data!['foto_url'] ?? "",
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator())),
                errorWidget: (c, u, e) => Container(color: Colors.white10, child: const Icon(Icons.image_not_supported, size: 50)),
              ),
            ),
            const SizedBox(height: 20),

            Text("ID INSTITUCIONAL", style: GoogleFonts.jetBrainsMono(color: const Color(0xFF3B82F6), fontSize: 12)),
            Text(data!['id_activo'] ?? widget.id, style: GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 15),
            
            _infoBlock("UBICACIÓN", data!['id_lab'], 
              extra: isUbicacionOk ? "VERIFICADA" : "NO VERIFICADA",
              extraColor: isUbicacionOk ? Colors.greenAccent : Colors.orangeAccent),

            const Divider(height: 40, color: Colors.white12),

            Text(data!['nombre_equipo'] ?? "N/A", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("${data!['marca_modelo'] ?? 'Sin datos'} | S/N: ${data!['nro_serie'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 20),

            _statusBadge(data!['estado']),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _infoBlock("REGISTRADO POR", data!['registrado_por'])),
                Expanded(child: _infoBlock("DOCUMENTACIÓN", data!['estado_documentacion'])),
              ],
            ),

            const SizedBox(height: 20),
            _infoBlock("OBSERVACIONES", data!['observaciones'], isMulti: true),

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _sync,
                icon: const Icon(Icons.cloud_sync, color: Colors.white),
                label: const Text("SINCRONIZAR LOCAL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, dynamic val, {String? extra, Color? extraColor, bool isMulti = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(val?.toString() ?? "N/A", style: TextStyle(fontSize: 16, color: isMulti ? Colors.white70 : Colors.white)),
          if (extra != null) 
            Text(extra, style: TextStyle(color: extraColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    Color c = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c, width: 2)
      ),
      child: Text("ESTADO: ${status?.toUpperCase()}", style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(error!, style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetch, child: const Text("REINTENTAR")),
          ],
        ),
      ),
    );
  }

  // ... (resto del código se mantiene igual, actualizo solo el método _sync)

  _sync() async {
    try {
      // MAPEADO PROFESIONAL: Evitamos NULLs y aseguramos todos los campos de la v2.2.3
      final Map<String, dynamic> syncData = {
        'id_activo': data!['id_activo'],
        'id_institucional': data!['id_institucional'] ?? "N/A", // Si no existe en nube, marcamos N/A
        'nombre_equipo': data!['nombre_equipo'],
        'categoria': data!['categoria'] ?? "Informática", // Campo calculado
        'marca_modelo': data!['marca_modelo'],
        'nro_serie': data!['nro_serie'],
        'origen': data!['origen'],
        'estado': data!['estado'],
        'estado_documentacion': data!['estado_documentacion'] ?? "Sin Documentación", // NUEVO
        'id_lab': data!['id_lab'],
        'registrado_por': data!['registrado_por'],
        'fecha_censo': data!['fecha_reg'] ?? DateTime.now().toString(),
        'observaciones': data!['observaciones'],
        'foto_url': data!['foto_url'], // NUEVO: Para guardar la evidencia
        'gps_lat': data!['gps_lat'],   // NUEVO: Georreferenciación
        'gps_long': data!['gps_long'], // NUEVO
      };

      final res = await http.post(
        Uri.parse('http://${widget.ip}/api/save_asset.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(syncData),
      ).timeout(const Duration(seconds: 5));
      
      if (!mounted) return;
      
      final r = json.decode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['message']),
          backgroundColor: r['status'] == 'success' ? Colors.green : Colors.red,
        )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Verifica Red Local o SQL")));
    }
  }
}
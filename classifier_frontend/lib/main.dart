import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'classifier_service.dart';

void main() => runApp(const MaterialApp(
      home: InferenceHome(),
      debugShowCheckedModeBanner: false,
    ));

class InferenceHome extends StatefulWidget {
  const InferenceHome({super.key});

  @override
  State<InferenceHome> createState() => _InferenceHomeState();
}

class _InferenceHomeState extends State<InferenceHome> {
  XFile? _pickedFile;
  Uint8List? _webBytes;
  String _serverStatus = "Ready to classify";
  bool _isLoading = false;
  final ClassifierService _service = ClassifierService();
  final List<String> _dynamicZones = ['computer desk', 'closet shelf', 'kitchen counter'];
  final TextEditingController _zoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureAndPredict() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _isLoading = true;
      _pickedFile = photo;
      _serverStatus = "Inferencing with HuggingFace API...";
    });

    if (kIsWeb) {
      _webBytes = await photo.readAsBytes();
    }

    final result = await _service.predictItem(
      imageFile: kIsWeb ? null : photo,
      imageBytes: kIsWeb ? _webBytes : null,
      zones: _dynamicZones,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['status'] == 'success') {
        _serverStatus = "Found: ${result['item']}\nRoute to: ${result['assigned_zone']}";
      } else {
        _serverStatus = "Error: ${result['message']}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Object Classifier"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Preview Box with Contain fit to prevent squashing
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.hardEdge,
              child: (_pickedFile != null)
                  ? (kIsWeb
                      ? (_webBytes != null ? Image.memory(_webBytes!, fit: BoxFit.contain) : const Center(child: CircularProgressIndicator()))
                      : Image.file(File(_pickedFile!.path), fit: BoxFit.contain))
                  : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 48, color: Colors.grey), Text("No image selected")])),
            ),
            const SizedBox(height: 24),

            // Loading overlay instead of just a spinner
            if (_isLoading)
              const Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text("Inferencing with HuggingFace API...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))])
            else
              Text(_serverStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: TextField(controller: _zoneController, decoration: const InputDecoration(labelText: "Add target zone", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              IconButton.filled(icon: const Icon(Icons.add), onPressed: () {
                if (_zoneController.text.trim().isNotEmpty) {
                  setState(() { _dynamicZones.add(_zoneController.text.trim()); _zoneController.clear(); });
                }
              }),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: _dynamicZones.map((zone) => Chip(label: Text(zone), onDeleted: () => setState(() => _dynamicZones.remove(zone)))).toList()),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _captureAndPredict,
                icon: const Icon(Icons.camera_enhance),
                label: const Text("SNAP & CLASSIFY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
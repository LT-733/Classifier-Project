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
      appBar: AppBar(title: const Text("NPU Object Classifier")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (_pickedFile != null)
                  ? (kIsWeb
                      ? (_webBytes != null
                          ? Image.memory(_webBytes!, height: 230, width: double.infinity, fit: BoxFit.cover)
                          : const SizedBox(height: 230))
                      : Image.file(File(_pickedFile!.path), height: 230, width: double.infinity, fit: BoxFit.cover))
                  : Container(
                      height: 230,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.camera_alt, size: 50, color: Colors.grey)),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _zoneController,
                    decoration: const InputDecoration(hintText: "Add target zone"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () {
                    if (_zoneController.text.trim().isNotEmpty) {
                      setState(() {
                        _dynamicZones.add(_zoneController.text.trim());
                        _zoneController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: _dynamicZones.map((zone) => Chip(
                label: Text(zone),
                onDeleted: () => setState(() => _dynamicZones.remove(zone)),
              )).toList(),
            ),
            const SizedBox(height: 25),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(_serverStatus, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _captureAndPredict,
              icon: const Icon(Icons.photo_camera),
              label: const Text("Snap Verification Photo"),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
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
  File? _selectedImage;
  String _serverStatus = "Ready to classify";
  final ClassifierService _service = ClassifierService();
  
  final List<String> _dynamicZones = ['computer desk', 'closet shelf', 'kitchen counter'];
  final TextEditingController _zoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureAndPredict() async {
    if (_dynamicZones.isEmpty) {
      setState(() => _serverStatus = "Error: Add at least one target zone first!");
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _selectedImage = File(photo.path);
      _serverStatus = "Sending data to Orange Pi NPU...";
    });

    final result = await _service.predictItem(
      imageFile: _selectedImage!,
      zones: _dynamicZones,
    );

    setState(() {
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
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 230, fit: BoxFit.cover)
            else
              Container(
                height: 230, 
                color: Colors.grey[200], 
                child: const Center(child: Icon(Icons.camera_alt, size: 50, color: Colors.grey))
              ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _zoneController,
                    decoration: const InputDecoration(
                      hintText: "Add target zone (e.g., bedroom)",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
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
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _dynamicZones.map((zone) => Chip(
                label: Text(zone),
                onDeleted: () => setState(() => _dynamicZones.remove(zone)),
              )).toList(),
            ),
            
            const SizedBox(height: 25),
            Text(
              _serverStatus, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _captureAndPredict,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              icon: const Icon(Icons.photo_camera),
              label: const Text("Snap Verification Photo"),
            ),
          ],
        ),
      ),
    );
  }
}
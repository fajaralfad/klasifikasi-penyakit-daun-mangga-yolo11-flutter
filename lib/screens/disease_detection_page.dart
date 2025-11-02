import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mangoleaf_disease_ai/models/tflite_model.dart';

class DiseaseDetectionPage extends StatefulWidget {
  @override
  _DiseaseDetectionPageState createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage> {
  final TFLiteModel _model = TFLiteModel();
  bool _isLoading = false;
  String _result = '';
  String _confidence = '';
  Uint8List? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _model.loadModel();
      print('Model initialized: ${_model.modelInfo}');
      
      // Show model info in console for debugging
      final modelInfo = _model.modelInfo;
      print('''
      === MODEL INFO ===
      Loaded: ${modelInfo['isLoaded']}
      Input Shape: ${modelInfo['inputShape']}
      Input Type: ${modelInfo['inputType']}
      Output Shape: ${modelInfo['outputShape']}
      Output Type: ${modelInfo['outputType']}
      ''');
    } catch (e) {
      print('Failed to initialize model: $e');
      _showErrorDialog('Failed to load model: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _result = '';
          _confidence = '';
        });
        
        await _analyzeImage(bytes);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    if (!_model.isLoaded) {
      setState(() {
        _result = 'Model not loaded';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      print('Image decoded: ${image.width}x${image.height}');

      // Run prediction
      final predictions = await _model.predict(image);
      
      if (predictions != null && predictions.isNotEmpty) {
        final topPrediction = _model.getTopPrediction(predictions);
        
        setState(() {
          _result = topPrediction['label'];
          _confidence = '${topPrediction['confidence'].toStringAsFixed(2)}%';
        });
        
        // Print semua prediksi untuk debugging
        final allPredictions = _model.getAllPredictions(predictions);
        print('All predictions:');
        for (var prediction in allPredictions) {
          print('${prediction['label']}: ${prediction['confidence'].toStringAsFixed(2)}%');
        }
      } else {
        setState(() {
          _result = 'Prediction failed - no results';
          _confidence = '';
        });
      }
    } catch (e) {
      print('Error analyzing image: $e');
      setState(() {
        _result = 'Error: ${e.toString()}';
        _confidence = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mango Leaf Disease Detection'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Select an image of mango leaf to detect disease',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: Icon(Icons.photo_library),
                      label: Text('Select Image from Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            if (_selectedImage != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        'Selected Image:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Image.memory(_selectedImage!, 
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
            
            if (_isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing image...'),
            ],
            
            if (_result.isNotEmpty) ...[
              Card(
                color: _result == 'Healthy' ? Colors.green[50] : Colors.orange[50],
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Detection Result:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _result,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _result == 'Healthy' ? Colors.green : Colors.orange,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Confidence: $_confidence',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
}
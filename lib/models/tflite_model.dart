import 'dart:typed_data';
import 'package:mangoleaf_disease_ai/models/class_labels.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteModel {
  late Interpreter _interpreter;
  bool _isLoaded = false;
  static const int inputSize = 224;
  
  // Variables untuk menyimpan info tensor
  late List<int> _inputShape;
  late TensorType _inputType;
  late List<int> _outputShape;
  late TensorType _outputType;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();

      // Load interpreter
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: options,
      );

      // Get dan print input/output tensor info untuk debugging
      var inputTensors = _interpreter.getInputTensors();
      var outputTensors = _interpreter.getOutputTensors();
      
      print('=== MODEL LOADING INFO ===');
      print('Number of input tensors: ${inputTensors.length}');
      print('Number of output tensors: ${outputTensors.length}');
      
      // Simpan info tensor input
      if (inputTensors.isNotEmpty) {
        _inputShape = inputTensors[0].shape;
        _inputType = inputTensors[0].type;
        print('=== INPUT TENSOR DETAILS ===');
        print('Shape: $_inputShape');
        print('Type: $_inputType');
        print('Name: ${inputTensors[0].name}');
      } else {
        throw Exception('No input tensors found');
      }
      
      // Simpan info tensor output
      if (outputTensors.isNotEmpty) {
        _outputShape = outputTensors[0].shape;
        _outputType = outputTensors[0].type;
        print('=== OUTPUT TENSOR DETAILS ===');
        print('Shape: $_outputShape');
        print('Type: $_outputType');
        print('Name: ${outputTensors[0].name}');
      } else {
        throw Exception('No output tensors found');
      }

      print('Model loaded successfully');
      _isLoaded = true;
    } catch (e) {
      print('Failed to load model: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  Future<List<dynamic>?> predict(img.Image image) async {
    try {
      if (!_isLoaded) {
        await loadModel();
      }

      print('Starting prediction...');
      
      // Preprocess image berdasarkan format yang dibutuhkan model
      final input = _preprocessImage(image);
      
      // Prepare output berdasarkan shape output tensor
      final output = _prepareOutput();
      
      print('Input prepared: ${input.runtimeType}');
      print('Output prepared: ${output.runtimeType}');

      // Run inference
      _interpreter.run(input, output);

      print('Inference completed successfully');
      
      // Return hasil berdasarkan format output
      return _formatOutput(output);
      
    } catch (e) {
      print('Error during prediction: $e');
      return null;
    }
  }

  dynamic _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    
    print('Image resized to: ${resized.width}x${resized.height}');
    print('Expected input shape: $_inputShape');

    // Berdasarkan shape input, pilih metode preprocessing yang tepat
    if (_inputShape.length == 4) {
      // Format: [batch, height, width, channels]
      if (_inputShape[1] == inputSize && _inputShape[2] == inputSize && _inputShape[3] == 3) {
        return _preprocessImageBatchFormat(resized);
      } else if (_inputShape[3] == inputSize && _inputShape[2] == inputSize && _inputShape[1] == 3) {
        // Format: [batch, channels, height, width] - less common
        return _preprocessImageChannelFirst(resized);
      }
    }
    
    // Default: format flat [1, 224*224*3]
    return _preprocessImageFlat(resized);
  }

  Float32List _preprocessImageFlat(img.Image image) {
    print('Using FLAT preprocessing');
    final input = Float32List(1 * inputSize * inputSize * 3);
    int index = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // Extract RGB components correctly
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        // Normalize to [-1, 1]
        input[index++] = (r / 127.5) - 1.0;
        input[index++] = (g / 127.5) - 1.0;
        input[index++] = (b / 127.5) - 1.0;
      }
    }
    
    return input;
  }

  List<List<List<List<double>>>> _preprocessImageBatchFormat(img.Image image) {
    print('Using BATCH FORMAT preprocessing [1, $inputSize, $inputSize, 3]');
    
    var input = List.generate(
      1, // batch size
      (_) => List.generate(
        inputSize, // height
        (_) => List.generate(
          inputSize, // width
          (_) => List.filled(3, 0.0), // channels [R, G, B]
        ),
      ),
    );

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // Extract RGB components correctly
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        input[0][y][x][0] = (r / 127.5) - 1.0; // R
        input[0][y][x][1] = (g / 127.5) - 1.0; // G
        input[0][y][x][2] = (b / 127.5) - 1.0; // B
      }
    }
    
    return input;
  }

  List<List<List<List<double>>>> _preprocessImageChannelFirst(img.Image image) {
    print('Using CHANNEL FIRST preprocessing [1, 3, $inputSize, $inputSize]');
    
    var input = List.generate(
      1, // batch size
      (_) => List.generate(
        3, // channels
        (_) => List.generate(
          inputSize, // height
          (_) => List.filled(inputSize, 0.0), // width
        ),
      ),
    );

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // Extract RGB components correctly
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        input[0][0][y][x] = (r / 127.5) - 1.0; // R channel
        input[0][1][y][x] = (g / 127.5) - 1.0; // G channel
        input[0][2][y][x] = (b / 127.5) - 1.0; // B channel
      }
    }
    
    return input;
  }

  dynamic _prepareOutput() {
    if (_outputShape.isEmpty) {
      // Default output shape jika tidak terdeteksi
      return List.filled(1 * ClassLabels.labels.length, 0.0)
          .reshape([1, ClassLabels.labels.length]);
    }
    
    // Buat output berdasarkan shape yang diharapkan
    final totalSize = _outputShape.reduce((value, element) => value * element);
    var output = List.filled(totalSize, 0.0);
    
    return output.reshape(_outputShape);
  }

  List<dynamic> _formatOutput(dynamic output) {
    // Konversi output ke format yang konsisten
    if (output is List<List<dynamic>>) {
      return output[0];
    } else if (output is List<dynamic>) {
      return output;
    } else {
      // Fallback untuk format lain
      return [output];
    }
  }

  // Method untuk mendapatkan prediksi dengan confidence score
  Map<String, dynamic> getTopPrediction(List<dynamic> predictions) {
    if (predictions == null || predictions.isEmpty) {
      return {'label': 'Unknown', 'confidence': 0.0, 'index': -1};
    }
    
    // Cari index dengan confidence tertinggi
    double maxConfidence = predictions[0].toDouble();
    int maxIndex = 0;
    
    for (int i = 1; i < predictions.length; i++) {
      double currentConfidence = predictions[i].toDouble();
      if (currentConfidence > maxConfidence) {
        maxConfidence = currentConfidence;
        maxIndex = i;
      }
    }
    
    // Konversi ke persentase
    double confidencePercent = (maxConfidence * 100);
    
    // Dapatkan label
    String label = maxIndex < ClassLabels.labels.length 
        ? ClassLabels.labels[maxIndex] 
        : 'Unknown';
    
    return {
      'label': label,
      'confidence': confidencePercent,
      'index': maxIndex,
    };
  }

  // Method untuk mendapatkan semua prediksi
  List<Map<String, dynamic>> getAllPredictions(List<dynamic> predictions) {
    if (predictions == null || predictions.isEmpty) {
      return [];
    }
    
    List<Map<String, dynamic>> results = [];
    
    for (int i = 0; i < predictions.length; i++) {
      if (i < ClassLabels.labels.length) {
        results.add({
          'label': ClassLabels.labels[i],
          'confidence': (predictions[i].toDouble() * 100),
          'index': i,
        });
      }
    }
    
    // Urutkan dari confidence tertinggi ke terendah
    results.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    
    return results;
  }

  void dispose() {
    if (_isLoaded) {
      _interpreter.close();
      _isLoaded = false;
      print('Model disposed');
    }
  }

  bool get isLoaded => _isLoaded;
  
  // Getter untuk debug info
  Map<String, dynamic> get modelInfo => {
    'isLoaded': _isLoaded,
    'inputShape': _inputShape.toString(),
    'inputType': _inputType.toString(),
    'outputShape': _outputShape.toString(),
    'outputType': _outputType.toString(),
  };
}
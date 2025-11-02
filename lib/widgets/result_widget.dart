import 'package:flutter/material.dart';

class ResultWidget extends StatelessWidget {
  final List<dynamic> predictions;
  final String selectedImagePath;

  const ResultWidget({
    Key? key,
    required this.predictions,
    required this.selectedImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get top prediction
    double maxConfidence = 0;
    int maxIndex = 0;
    
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] > maxConfidence) {
        maxConfidence = predictions[i];
        maxIndex = i;
      }
    }

    final confidence = (maxConfidence * 100).toStringAsFixed(2);

    return Column(
      children: [
        Text(
          'Prediction: ${_getDiseaseName(maxIndex)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'Confidence: $confidence%',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: predictions.length,
            itemBuilder: (context, index) {
              final confidence = (predictions[index] * 100).toStringAsFixed(2);
              return ListTile(
                title: Text(_getDiseaseName(index)),
                trailing: Text('$confidence%'),
                tileColor: index == maxIndex ? Colors.green[100] : null,
              );
            },
          ),
        ),
      ],
    );
  }

  String _getDiseaseName(int index) {
    switch (index) {
      case 0: return 'Healthy';
      case 1: return 'Anthracnose';
      case 2: return 'Bacterial Canker';
      case 3: return 'Cutting Weevil';
      case 4: return 'Die Back';
      case 5: return 'Gall Midge';
      case 6: return 'Powdery Mildew';
      case 7: return 'Sooty Mould';
      default: return 'Unknown';
    }
  }
}
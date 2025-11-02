class ClassLabels {
  static final List<String> labels = [
    'Anthracnose',
    'Bacterial Canker',
    'Cutting Weevil',
    'Die Back',
    'Gall Midge',
    'Healthy',
    'Powdery Mildew',
    'Sooty Mould',
  ];

  static String getLabel(int index) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return 'Unknown';
  }
}
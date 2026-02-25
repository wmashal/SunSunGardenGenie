class DesignResult {
  final String status;
  final List<String> imageUrls;
  final String summary;
  final String? errorMessage;

  DesignResult({
    required this.status,
    required this.imageUrls,
    required this.summary,
    this.errorMessage,
  });

  factory DesignResult.fromJson(Map<String, dynamic> json) {
    return DesignResult(
      status: json['status'] ?? 'error',
      imageUrls: json['result_image_urls'] != null
          ? List<String>.from(json['result_image_urls'])
          : [],
      summary: json['summary'] ?? 'Design generated successfully.',
      errorMessage: json['message'],
    );
  }

  bool get isSuccess => status == 'success';
}

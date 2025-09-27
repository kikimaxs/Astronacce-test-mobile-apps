class ImageHostingConfig {
  // ImgBB - Daftar gratis di https://imgbb.com/
  static const String imgbbApiKey = '430d65959ff227869286a26bac8c0dc7';
  
  // Hosting services yang didukung (diurutkan berdasarkan stabilitas)
  static const List<String> supportedHostingServices = [
    'Imgur.com',        // Paling stabil
    'Catbox.moe',       // Alternatif stabil
    'ImgBB.com',        // Bagus tapi kadang SSL issue
    'PostImages.org',   // Backup
    'FreeImage.host',   // Backup
  ];
  
  // Domain terpercaya yang skip SSL validation
  static const List<String> trustedDomains = [
    'i.ibb.co',
    'ibb.co',
    'i.imgur.com',
    'imgur.com',
    'files.catbox.moe',
    'catbox.moe',
    'postimg.cc',
    'freeimage.host',
  ];
  
  // Konfigurasi upload
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 2;
  static const int uploadTimeoutSeconds = 30;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  
  // Supported image formats
  static const List<String> supportedFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
}
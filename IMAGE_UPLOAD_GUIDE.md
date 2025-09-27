# Panduan Upload Gambar ke Hosting Gratis

## Fitur Utama

1. **Retry Mechanism**: Otomatis mencoba ulang jika upload gagal
2. **Multiple Hosting**: Mencoba beberapa hosting gratis secara berurutan
3. **Fallback ke Base64**: Jika semua hosting gagal, gunakan base64
4. **Kompres Gambar**: Otomatis kompres gambar besar
5. **Validasi URL**: Memastikan URL gambar dapat diakses

## Hosting Gratis yang Didukung

### 1. ImgBB (Direkomendasikan)
- **URL**: https://imgbb.com/
- **API Key**: Diperlukan (gratis)
- **Limit**: 32MB per file
- **Kelebihan**: Stabil, cepat, API yang baik
- **Cara Daftar**:
  1. Buka https://imgbb.com/
  2. Klik "Sign Up" dan buat akun
  3. Buka https://api.imgbb.com/
  4. Copy API key Anda
  5. Ganti `YOUR_IMGBB_API_KEY` di `image_upload_service.dart`

### 2. PostImages.org
- **URL**: https://postimages.org/
- **API Key**: Tidak diperlukan
- **Limit**: 24MB per file
- **Kelebihan**: Tidak perlu registrasi

### 3. FreeImage.host
- **URL**: https://freeimage.host/
- **API Key**: Tidak diperlukan
- **Limit**: 16MB per file
- **Kelebihan**: Simple API

## Cara Penggunaan

### 1. Upload File Gambar

```dart
import '../services/image_upload_service.dart';

// Upload dengan retry mechanism
String? imageUrl = await ImageUploadService.uploadImageWithRetry(
  imageFile: selectedImageFile,
  maxRetries: 3,
  retryDelay: 2,
);

if (imageUrl != null) {
  print('Upload berhasil: $imageUrl');
} else {
  print('Upload gagal');
}
```

### 2. Upload Base64 String

```dart
// Upload base64 dengan retry
String? imageUrl = await ImageUploadService.uploadBase64WithRetry(
  base64String: base64ImageData,
  maxRetries: 3,
  retryDelay: 2,
);
```

### 3. Validasi URL Gambar

```dart
bool isValid = await ImageUploadService.validateImageUrl(imageUrl);
```

### 4. Kompres Gambar

```dart
File? compressedImage = await ImageUploadService.compressImage(
  originalImageFile,
  quality: 85,
);
```

## Strategi Retry

Aplikasi menggunakan strategi retry yang cerdas:

1. **Percobaan 1**: Upload ke ImgBB (jika API key tersedia)
2. **Percobaan 2**: Upload ke PostImages.org
3. **Percobaan 3**: Upload ke FreeImage.host
4. **Fallback**: Jika semua gagal, gunakan base64

Setiap percobaan memiliki timeout 30 detik dan delay 2 detik antar percobaan.

## Error Handling

```dart
try {
  String? imageUrl = await ImageUploadService.uploadImageWithRetry(
    imageFile: imageFile,
  );
  
  if (imageUrl != null) {
    // Upload berhasil
    print('Image URL: $imageUrl');
  } else {
    // Semua percobaan gagal
    print('Upload gagal ke semua hosting');
  }
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

## Tips Optimasi

1. **Kompres Gambar**: Selalu kompres gambar sebelum upload
2. **Validasi Format**: Pastikan format gambar didukung
3. **Cek Ukuran**: Batasi ukuran file maksimal 5MB
4. **Cache URL**: Simpan URL gambar yang berhasil diupload
5. **Fallback**: Selalu sediakan fallback ke base64

## Troubleshooting

### Upload Selalu Gagal
1. Cek koneksi internet
2. Pastikan API key ImgBB benar
3. Cek ukuran file (maksimal 5MB)
4. Cek format file (jpg, png, gif, webp)

### URL Gambar Tidak Bisa Diakses
1. Tunggu beberapa detik (propagasi DNS)
2. Coba refresh browser
3. Cek apakah hosting masih aktif

### Performance Lambat
1. Kompres gambar sebelum upload
2. Kurangi retry attempts
3. Gunakan hosting yang lebih cepat

## Konfigurasi

Edit file `lib/config/image_hosting_config.dart` untuk mengubah:
- API keys
- Jumlah retry
- Timeout duration
- Ukuran file maksimal
- Format yang didukung
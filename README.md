# Astronacce Test Mobile App

A complete Flutter application with Node.js backend featuring user authentication, forgot password functionality, and user management.

## Backend Repository

**Important:** The backend is now separated into its own repository for better maintainability and deployment.

🔗 **Backend Repository:** [https://github.com/kikimaxs/astronance-api](https://github.com/kikimaxs/astronance-api)

Please clone and set up the backend separately from the above repository.

## Features

### Authentication
- ✅ User Registration with email validation
- ✅ User Login with JWT tokens
- ✅ Forgot Password with email verification
- ✅ Password Reset with secure tokens
- ✅ Direct Password Reset functionality
- ✅ Automatic logout and session management

### User Management
- ✅ User profile management
- ✅ User list with search and pagination
- ✅ Real-time user data updates

### Email Service
- ✅ Welcome emails for new users
- ✅ Password reset emails with secure tokens
- ✅ Password change notifications
- ✅ HTML email templates with responsive design

### Security Features
- ✅ Password hashing with bcrypt
- ✅ JWT token authentication
- ✅ Secure password reset tokens (1-hour expiry)
- ✅ Input validation and sanitization

## Tech Stack

### Backend
- **Node.js** with Express.js
- **TypeScript** for type safety
- **JWT** for authentication
- **bcryptjs** for password hashing
- **Nodemailer** for email service
- **express-validator** for input validation

### Frontend
- **Flutter** with Dart
- **BLoC** for state management
- **HTTP** for API communication
- **SharedPreferences** for local storage

## Setup Instructions

### Backend Setup

**Note:** The backend is now in a separate repository. Please follow these steps:

1. **Clone the backend repository:**
   ```bash
   git clone https://github.com/kikimaxs/astronance-api.git
   cd astronance-api
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Environment Configuration:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your configuration:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # JWT Configuration
   JWT_SECRET=your-super-secret-jwt-key-change-in-production
   JWT_EXPIRES_IN=7d
   
   # Email Configuration (Gmail example)
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-app-password
   
   # Application Configuration
   FROM_EMAIL=noreply@astronacce.com
   APP_URL=https://your-app.com
   ```

4. **Start the development server:**
   ```bash
   npm run dev
   ```

   The backend will be available at `http://localhost:3000`

### Flutter Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure API Environment (Important!):**
   
   The app can switch between local development and production APIs. Edit `lib/config/api_config.dart`:

   **For Local Development:**
   ```dart
   static const bool _useDevelopmentMode = true;  // Set to true for local
   ```

   **For Production:**
   ```dart
   static const bool _useDevelopmentMode = false; // Set to false for production
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

   **Important:** After changing the API configuration, always restart the app:
   ```bash
   # Stop the current app (Ctrl+C) then run again
   flutter run
   ```

## API Environment Switching

### Switching to Local Development

1. **Start your local backend server** (from the backend repository):
   ```bash
   cd astronance-api
   npm run dev
   ```

2. **Configure Flutter app for local development:**
   
   Edit `lib/config/api_config.dart`:
   ```dart
   static const bool _useDevelopmentMode = true;
   ```

3. **Restart the Flutter app:**
   ```bash
   flutter run
   ```

   The app will now use `http://localhost:3000` for API calls.

### Switching to Production

1. **Configure Flutter app for production:**
   
   Edit `lib/config/api_config.dart`:
   ```dart
   static const bool _useDevelopmentMode = false;
   ```

2. **Restart the Flutter app:**
   ```bash
   flutter run
   ```

   The app will now use the production Vercel URL for API calls.

### Programmatic Switching (Advanced)

You can also switch environments programmatically:

```dart
// Force development mode
ApiConfig.forceUseDevelopment();

// Force production mode
ApiConfig.forceUseProduction();

// Check current mode
bool isDev = ApiConfig.isDevelopmentMode;
String currentMode = ApiConfig.currentModeDescription;
```

## APK Builds
- **Link APK:** [Astronacci-Prod.apk](https://drive.google.com/file/d/1idx8OkQ6aMV3KyU8JSEudCu3w2kvw4w-/view?usp=drive_link)
- **Catatan:** Siap digunakan langsung tanpa perlu menjalankan server lokal
- **Konfigurasi:** `_useDevelopmentMode = false`
- **Target API:** Production Vercel URL

### Build Instructions

#### Building Development APK
1. **Configure for development:**
   ```dart
   // lib/config/api_config.dart
   static const bool _useDevelopmentMode = true;
   ```

2. **Build APK:**
   ```bash
   flutter build apk --release --target-platform android-arm64
   ```

3. **Rename file:**
   ```bash
   mv build/app/outputs/flutter-apk/app-release.apk astronacce_dev_v1.0.0.apk
   ```

#### Building Production APK
1. **Configure for production:**
   ```dart
   // lib/config/api_config.dart
   static const bool _useDevelopmentMode = false;
   ```

2. **Build APK:**
   ```bash
   flutter build apk --release --target-platform android-arm64
   ```

3. **Rename file:**
   ```bash
   mv build/app/outputs/flutter-apk/app-release.apk astronacce_prod_v1.0.0.apk
   ```

### Testing Notes

#### Development APK Testing
- Pastikan backend server berjalan di `http://localhost:3000`
- Perangkat Android harus terhubung ke jaringan yang sama dengan development server
- Ganti IP `192.168.1.100` dengan IP lokal komputer Anda
- Untuk mendapatkan IP lokal:
  ```bash
  # macOS/Linux
  ifconfig | grep "inet " | grep -v 127.0.0.1
  
  # Windows
  ipconfig | findstr "IPv4"
  ```

#### Production APK Testing
- Tidak memerlukan server lokal
- Langsung terhubung ke production API
- Memerlukan koneksi internet yang stabil

## Email Configuration

### Gmail Setup (Recommended for Development)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password:**
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a password for "Mail"
3. **Update .env file:**
   ```env
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-16-character-app-password
   ```

### Other Email Providers

The email service supports any SMTP provider. Update the `.env` file accordingly:

```env
# For Outlook/Hotmail
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587

# For Yahoo
SMTP_HOST=smtp.mail.yahoo.com
SMTP_PORT=587

# For custom SMTP
SMTP_HOST=your-smtp-server.com
SMTP_PORT=587
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password with token
- `POST /api/auth/direct-password-reset` - Direct password reset (Production only)
- `GET /api/auth/profile` - Get user profile (protected)
- `PUT /api/auth/profile` - Update user profile (protected)

### Users
- `GET /api/users` - Get all users with pagination (protected)
- `GET /api/users/:id` - Get user by ID (protected)

### Health Check
- `GET /health` - Server health check

## Testing the Forgot Password Feature

### Development Mode
In development mode, the reset token is included in the API response for easy testing:

1. **Request password reset:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/forgot-password \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@example.com"}'
   ```

2. **Response includes token:**
   ```json
   {
     "message": "If your email exists in our system, you will receive reset instructions.",
     "success": true,
     "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "expiresAt": "2024-01-01T13:00:00.000Z"
   }
   ```

3. **Reset password:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/reset-password \
     -H "Content-Type: application/json" \
     -d '{"token":"your-reset-token","newPassword":"newpassword123"}'
   ```

### Production Mode
In production, set `NODE_ENV=production` and the reset token will only be sent via email.

## Default Test Account

- **Email:** admin@example.com
- **Password:** password

## Troubleshooting

### Common Issues

1. **"Route not found" error during password reset:**
   - Make sure you're using production mode (`_useDevelopmentMode = false`) for direct password reset
   - Or ensure your local backend has the `/direct-password-reset` endpoint

2. **Connection refused errors:**
   - Check if the backend server is running on the correct port
   - Verify the API configuration in `api_config.dart`

3. **API switching not working:**
   - Always restart the Flutter app after changing `_useDevelopmentMode`
   - Use `flutter run` (not hot reload) for API configuration changes

## Project Structure

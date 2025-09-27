# Astronacce Test Mobile App

A complete Flutter application with Node.js backend featuring user authentication, forgot password functionality, and user management.

## Features

### Authentication
- ✅ User Registration with email validation
- ✅ User Login with JWT tokens
- ✅ Forgot Password with email verification
- ✅ Password Reset with secure tokens
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
- ✅ Password strength validation
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

1. **Navigate to backend directory:**
   ```bash
   cd backend
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

1. **Navigate to project root:**
   ```bash
   cd ..
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

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

## Project Structure

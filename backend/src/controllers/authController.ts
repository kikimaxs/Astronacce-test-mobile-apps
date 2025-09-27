import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { body, validationResult } from 'express-validator';
import { 
  User, 
  RegisterRequest, 
  LoginRequest, 
  ForgotPasswordRequest,
  DirectPasswordResetRequest,
  AuthResponse,
  PasswordResetToken 
} from '../types/auth';
import { generateToken, generateResetToken } from '../utils/jwt';
import { AuthRequest } from '../middleware/auth';
import { emailService } from '../services/emailService';

// In-memory storage (replace with database in production)
let users: User[] = [
  {
    id: 1,
    email: 'admin@example.com',
    password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
    name: 'Admin User',
    avatar: '',
    phone: '+1234567890',
    address: '123 Main St, City, Country',
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

let passwordResetTokens: PasswordResetToken[] = [];
let nextUserId = 2;

// Validation rules
export const registerValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('name').notEmpty().withMessage('Name is required')
];

export const loginValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required')
];

export const forgotPasswordValidation = [
  body('email').isEmail().withMessage('Valid email is required')
];

export const resetPasswordValidation = [
  body('token').notEmpty().withMessage('Reset token is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

export const directPasswordResetValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

export const updateProfileValidation = [
  body('name')
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2 })
    .withMessage('Name must be at least 2 characters'),
  body('phone')
    .optional()
    .isMobilePhone('any')
    .withMessage('Please provide a valid phone number'),
  body('address')
    .optional()
    .isLength({ min: 5 })
    .withMessage('Address must be at least 5 characters'),
  body('avatar')
    .optional()
    .custom((value) => {
      if (!value) return true; // Allow empty avatar
      
      // Check if it's a valid URL
      try {
        new URL(value);
        return true;
      } catch {
        // If not a URL, check if it's a valid base64 data URI
        const base64Pattern = /^data:image\/(jpeg|jpg|png|gif|webp);base64,([A-Za-z0-9+/=]+)$/;
        if (base64Pattern.test(value)) {
          return true;
        }
        throw new Error('Avatar must be a valid URL or base64 data URI');
      }
    })
];

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { email, password, name }: RegisterRequest = req.body;

    // Check if user already exists
    const existingUser = users.find(u => u.email === email);
    if (existingUser) {
      res.status(400).json({ error: 'Email already registered' });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser: User = {
      id: nextUserId++,
      email,
      password: hashedPassword,
      name,
      avatar: '',
      phone: '',
      address: '',
      createdAt: new Date(),
      updatedAt: new Date()
    };

    users.push(newUser);

    // Send welcome email (don't wait for it to complete)
    emailService.sendWelcomeEmail(newUser).catch(error => {
      console.error('Failed to send welcome email:', error);
    });

    // Generate token
    const token = generateToken(newUser.id);

    // Return user without password
    const { password: _, ...userWithoutPassword } = newUser;
    const response: AuthResponse = {
      user: userWithoutPassword,
      token
    };

    res.status(201).json(response);
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { email, password }: LoginRequest = req.body;

    // Find user
    const user = users.find(u => u.email === email);
    if (!user) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    // Generate token
    const token = generateToken(user.id);

    // Return user without password
    const { password: _, ...userWithoutPassword } = user;
    const response: AuthResponse = {
      user: userWithoutPassword,
      token
    };

    res.json(response);
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { email }: ForgotPasswordRequest = req.body;

    const user = users.find(u => u.email === email);
    if (!user) {
      // Don't reveal if email exists or not for security
      res.json({ 
        message: 'If your email exists in our system, you will receive reset instructions.',
        success: true
      });
      return;
    }

    // Generate reset token
    const resetToken = generateResetToken();
    const expiresAt = new Date(Date.now() + 3600000); // 1 hour

    // Store reset token (remove any existing tokens for this email)
    passwordResetTokens = passwordResetTokens.filter(t => t.email !== email);
    passwordResetTokens.push({ email, token: resetToken, expiresAt });

    // Send password reset email
    try {
      const emailSent = await emailService.sendPasswordResetEmail(user, resetToken);
      
      if (emailSent) {
        console.log(`✅ Password reset email sent to ${email}`);
      } else {
        console.log(`❌ Failed to send password reset email to ${email}`);
      }
    } catch (emailError) {
      console.error('Email sending error:', emailError);
    }

    // Always return success message for security (don't reveal if email exists)
    res.json({ 
      message: 'If your email exists in our system, you will receive reset instructions.',
      success: true,
      // Include token in development mode for testing
      ...(process.env.NODE_ENV === 'development' && { 
        resetToken,
        expiresAt: expiresAt.toISOString()
      })
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const resetPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { token, newPassword } = req.body;

    // Find valid reset token
    const resetTokenData = passwordResetTokens.find(
      t => t.token === token && t.expiresAt > new Date()
    );

    if (!resetTokenData) {
      res.status(400).json({ 
        error: 'Invalid or expired reset token',
        success: false
      });
      return;
    }

    // Find user and update password
    const userIndex = users.findIndex(u => u.email === resetTokenData.email);
    if (userIndex === -1) {
      res.status(400).json({ 
        error: 'User not found',
        success: false
      });
      return;
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    users[userIndex].password = hashedPassword;
    users[userIndex].updatedAt = new Date();

    // Remove used token and any other tokens for this email
    passwordResetTokens = passwordResetTokens.filter(t => t.email !== resetTokenData.email);

    // Send password change notification email
    try {
      await emailService.sendPasswordChangeNotification(users[userIndex]);
      console.log(`✅ Password change notification sent to ${users[userIndex].email}`);
    } catch (emailError) {
      console.error('Failed to send password change notification:', emailError);
    }

    res.json({ 
      message: 'Password reset successful. You can now login with your new password.',
      success: true
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getProfile = (req: AuthRequest, res: Response): void => {
  try {
    const user = users.find(u => u.id === req.userId);
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const { password: _, ...userWithoutPassword } = user;
    res.json(userWithoutPassword);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateProfile = (req: AuthRequest, res: Response): void => {
  try {
    console.log('📤 Profile update request received:', {
      userId: req.userId,
      body: {
        ...req.body,
        avatar: req.body.avatar ? `base64 data (${req.body.avatar.length} chars)` : 'null'
      }
    });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ Validation errors:', errors.array());
      res.status(400).json({ 
        error: 'Validation failed',
        errors: errors.array()
      });
      return;
    }

    const userIndex = users.findIndex(u => u.id === req.userId);
    if (userIndex === -1) {
      console.log('❌ User not found:', req.userId);
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const { name, phone, address, avatar } = req.body;

    // Validate required fields
    if (!name || name.trim().length === 0) {
      console.log('❌ Name is required');
      res.status(400).json({ error: 'Name is required' });
      return;
    }

    // Update user data
    users[userIndex].name = name.trim();
    if (phone !== undefined) users[userIndex].phone = phone.trim() || '';
    if (address !== undefined) users[userIndex].address = address.trim() || '';
    if (avatar !== undefined) users[userIndex].avatar = avatar || '';
    users[userIndex].updatedAt = new Date();

    console.log(`✅ Profile updated for user ID: ${req.userId}`);

    const { password: _, ...userWithoutPassword } = users[userIndex];
    res.json({
      message: 'Profile updated successfully',
      user: userWithoutPassword
    });
  } catch (error) {
    console.error('❌ Update profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const directPasswordReset = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { email, newPassword }: DirectPasswordResetRequest = req.body;

    // Cari user berdasarkan email
    const userIndex = users.findIndex(u => u.email === email);
    if (userIndex === -1) {
      res.status(404).json({ 
        error: 'Email tidak ditemukan dalam sistem',
        success: false
      });
      return;
    }

    // Hash password baru
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password user
    users[userIndex].password = hashedPassword;
    users[userIndex].updatedAt = new Date();

    // Hapus semua token reset password untuk email ini (jika ada)
    passwordResetTokens = passwordResetTokens.filter(t => t.email !== email);

    // Kirim notifikasi perubahan password (opsional)
    try {
      await emailService.sendPasswordChangeNotification(users[userIndex]);
      console.log(`✅ Password change notification sent to ${email}`);
    } catch (emailError) {
      console.error('Failed to send password change notification:', emailError);
      // Tidak menggagalkan proses jika email notifikasi gagal
    }

    console.log(`🔑 Password successfully reset for ${email}`);

    res.json({ 
      message: 'Password berhasil diubah. Anda dapat login dengan password baru.',
      success: true,
      user: {
        id: users[userIndex].id,
        email: users[userIndex].email,
        name: users[userIndex].name,
        avatar: users[userIndex].avatar,
        phone: users[userIndex].phone,
        address: users[userIndex].address
      }
    });
  } catch (error) {
    console.error('Direct password reset error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
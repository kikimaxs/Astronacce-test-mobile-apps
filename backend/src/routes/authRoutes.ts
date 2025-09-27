import { Router } from 'express';
import {
  register,
  login,
  forgotPassword,
  resetPassword,
  directPasswordReset,
  getProfile,
  updateProfile,
  registerValidation,
  loginValidation,
  forgotPasswordValidation,
  resetPasswordValidation,
  directPasswordResetValidation,
  updateProfileValidation
} from '../controllers/authController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// Authentication routes
router.post('/register', registerValidation, register);
router.post('/login', loginValidation, login);
router.post('/forgot-password', forgotPasswordValidation, forgotPassword);
router.post('/reset-password', resetPasswordValidation, resetPassword);
router.post('/direct-password-reset', directPasswordResetValidation, directPasswordReset);

// Protected routes
router.get('/profile', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfileValidation, updateProfile);

export default router;
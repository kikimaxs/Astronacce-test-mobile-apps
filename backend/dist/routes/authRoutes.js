"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authController_1 = require("../controllers/authController");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Authentication routes
router.post('/register', authController_1.registerValidation, authController_1.register);
router.post('/login', authController_1.loginValidation, authController_1.login);
router.post('/forgot-password', authController_1.forgotPasswordValidation, authController_1.forgotPassword);
router.post('/reset-password', authController_1.resetPasswordValidation, authController_1.resetPassword);
router.post('/direct-password-reset', authController_1.directPasswordResetValidation, authController_1.directPasswordReset);
// Protected routes
router.get('/profile', auth_1.authenticateToken, authController_1.getProfile);
router.put('/profile', auth_1.authenticateToken, authController_1.updateProfileValidation, authController_1.updateProfile);
exports.default = router;
//# sourceMappingURL=authRoutes.js.map
import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
export declare const registerValidation: import("express-validator").ValidationChain[];
export declare const loginValidation: import("express-validator").ValidationChain[];
export declare const forgotPasswordValidation: import("express-validator").ValidationChain[];
export declare const resetPasswordValidation: import("express-validator").ValidationChain[];
export declare const directPasswordResetValidation: import("express-validator").ValidationChain[];
export declare const updateProfileValidation: import("express-validator").ValidationChain[];
export declare const register: (req: Request, res: Response) => Promise<void>;
export declare const login: (req: Request, res: Response) => Promise<void>;
export declare const forgotPassword: (req: Request, res: Response) => Promise<void>;
export declare const resetPassword: (req: Request, res: Response) => Promise<void>;
export declare const getProfile: (req: AuthRequest, res: Response) => void;
export declare const updateProfile: (req: AuthRequest, res: Response) => void;
export declare const directPasswordReset: (req: Request, res: Response) => Promise<void>;
//# sourceMappingURL=authController.d.ts.map
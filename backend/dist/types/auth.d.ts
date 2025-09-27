export interface User {
    id: number;
    email: string;
    password: string;
    name: string;
    avatar?: string;
    phone?: string;
    address?: string;
    createdAt: Date;
    updatedAt: Date;
}
export interface RegisterRequest {
    email: string;
    password: string;
    name: string;
}
export interface LoginRequest {
    email: string;
    password: string;
}
export interface ForgotPasswordRequest {
    email: string;
}
export interface ResetPasswordRequest {
    token: string;
    newPassword: string;
}
export interface DirectPasswordResetRequest {
    email: string;
    newPassword: string;
}
export interface UpdateProfileRequest {
    name?: string;
    phone?: string;
    address?: string;
    avatar?: string;
}
export interface AuthResponse {
    user: Omit<User, 'password'>;
    token: string;
}
export interface PasswordResetToken {
    email: string;
    token: string;
    expiresAt: Date;
}
//# sourceMappingURL=auth.d.ts.map
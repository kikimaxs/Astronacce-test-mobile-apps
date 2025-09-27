import { User } from '../types/auth';
declare class EmailService {
    private transporter;
    private fromEmail;
    constructor();
    private verifyConnection;
    private generatePasswordResetTemplate;
    private generateWelcomeTemplate;
    sendPasswordResetEmail(user: User, resetToken: string): Promise<boolean>;
    sendWelcomeEmail(user: User): Promise<boolean>;
    sendPasswordChangeNotification(user: User): Promise<boolean>;
}
export declare const emailService: EmailService;
export {};
//# sourceMappingURL=emailService.d.ts.map
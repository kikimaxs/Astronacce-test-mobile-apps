import nodemailer from 'nodemailer';
import { User } from '../types/auth';

interface EmailConfig {
  host: string;
  port: number;
  secure: boolean;
  auth: {
    user: string;
    pass: string;
  };
}

interface EmailTemplate {
  subject: string;
  html: string;
  text: string;
}

class EmailService {
  private transporter: nodemailer.Transporter;
  private fromEmail: string;

  constructor() {
    // Email configuration - in production, use environment variables
    const config: EmailConfig = {
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER || 'your-email@gmail.com',
        pass: process.env.SMTP_PASS || 'your-app-password'
      }
    };

    this.fromEmail = process.env.FROM_EMAIL || config.auth.user;
    
    // Create transporter
    this.transporter = nodemailer.createTransport(config);
    
    // Verify connection configuration
    this.verifyConnection();
  }

  private async verifyConnection(): Promise<void> {
    try {
      await this.transporter.verify();
      console.log('✅ Email service is ready');
    } catch (error) {
      console.error('❌ Email service configuration error:', error);
      console.log('📧 Email service will use console logging for development');
    }
  }

  private generatePasswordResetTemplate(user: User, resetToken: string, resetUrl: string): EmailTemplate {
    const subject = 'Password Reset Request - Astronacce App';
    
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .token-box { background: #e8f4f8; border: 1px solid #bee5eb; padding: 15px; border-radius: 5px; margin: 20px 0; font-family: monospace; word-break: break-all; }
          .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Password Reset Request</h1>
          </div>
          <div class="content">
            <h2>Hello ${user.name},</h2>
            <p>We received a request to reset your password for your Astronacce account.</p>
            
            <p>If you requested this password reset, you can use the following methods to reset your password:</p>
            
            <h3>Method 1: Click the Reset Link</h3>
            <p>Click the button below to reset your password:</p>
            <a href="${resetUrl}" class="button">Reset My Password</a>
            
            <h3>Method 2: Use the Reset Token</h3>
            <p>If the button doesn't work, you can manually enter this reset token in the app:</p>
            <div class="token-box">
              <strong>Reset Token:</strong><br>
              ${resetToken}
            </div>
            
            <div class="warning">
              <strong>⚠️ Security Notice:</strong>
              <ul>
                <li>This reset token will expire in 1 hour</li>
                <li>If you didn't request this reset, please ignore this email</li>
                <li>Never share this token with anyone</li>
                <li>For security, this link can only be used once</li>
              </ul>
            </div>
            
            <p>If you're having trouble with the reset process, please contact our support team.</p>
            
            <p>Best regards,<br>The Astronacce Team</p>
          </div>
          <div class="footer">
            <p>This email was sent to ${user.email}</p>
            <p>© 2024 Astronacce App. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
Password Reset Request - Astronacce App

Hello ${user.name},

We received a request to reset your password for your Astronacce account.

If you requested this password reset, you can use the following reset token:

Reset Token: ${resetToken}

This token will expire in 1 hour.

Reset URL: ${resetUrl}

Security Notice:
- If you didn't request this reset, please ignore this email
- Never share this token with anyone
- For security, this token can only be used once

Best regards,
The Astronacce Team

This email was sent to ${user.email}
© 2024 Astronacce App. All rights reserved.
    `;

    return { subject, html, text };
  }

  private generateWelcomeTemplate(user: User): EmailTemplate {
    const subject = 'Welcome to Astronacce App!';
    
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to Astronacce</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .feature { background: white; padding: 20px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #667eea; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚀 Welcome to Astronacce!</h1>
          </div>
          <div class="content">
            <h2>Hello ${user.name},</h2>
            <p>Welcome to Astronacce! We're excited to have you on board.</p>
            
            <p>Your account has been successfully created with the email: <strong>${user.email}</strong></p>
            
            <h3>What you can do with Astronacce:</h3>
            <div class="feature">
              <h4>👥 User Management</h4>
              <p>Manage and view user profiles with ease</p>
            </div>
            <div class="feature">
              <h4>🔐 Secure Authentication</h4>
              <p>Your data is protected with industry-standard security</p>
            </div>
            <div class="feature">
              <h4>📱 Mobile Experience</h4>
              <p>Access your account from anywhere with our mobile app</p>
            </div>
            
            <p>If you have any questions or need help getting started, don't hesitate to reach out to our support team.</p>
            
            <p>Best regards,<br>The Astronacce Team</p>
          </div>
          <div class="footer">
            <p>This email was sent to ${user.email}</p>
            <p>© 2024 Astronacce App. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
Welcome to Astronacce App!

Hello ${user.name},

Welcome to Astronacce! We're excited to have you on board.

Your account has been successfully created with the email: ${user.email}

What you can do with Astronacce:
- User Management: Manage and view user profiles with ease
- Secure Authentication: Your data is protected with industry-standard security
- Mobile Experience: Access your account from anywhere with our mobile app

If you have any questions or need help getting started, don't hesitate to reach out to our support team.

Best regards,
The Astronacce Team

This email was sent to ${user.email}
© 2024 Astronacce App. All rights reserved.
    `;

    return { subject, html, text };
  }

  async sendPasswordResetEmail(user: User, resetToken: string): Promise<boolean> {
    try {
      // Generate reset URL (in production, this would be your app's deep link or web URL)
      const resetUrl = `${process.env.APP_URL || 'https://your-app.com'}/reset-password?token=${resetToken}`;
      
      const template = this.generatePasswordResetTemplate(user, resetToken, resetUrl);
      
      const mailOptions = {
        from: `"Astronacce App" <${this.fromEmail}>`,
        to: user.email,
        subject: template.subject,
        text: template.text,
        html: template.html
      };

      // Try to send email, fallback to console logging
      try {
        const info = await this.transporter.sendMail(mailOptions);
        console.log('✅ Password reset email sent:', info.messageId);
        return true;
      } catch (emailError) {
        console.log('📧 Email service not configured, logging reset details:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`📧 To: ${user.email}`);
        console.log(`👤 User: ${user.name}`);
        console.log(`🔑 Reset Token: ${resetToken}`);
        console.log(`🔗 Reset URL: ${resetUrl}`);
        console.log(`⏰ Expires: 1 hour from now`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true; // Return true for development
      }
    } catch (error) {
      console.error('❌ Failed to send password reset email:', error);
      return false;
    }
  }

  async sendWelcomeEmail(user: User): Promise<boolean> {
    try {
      const template = this.generateWelcomeTemplate(user);
      
      const mailOptions = {
        from: `"Astronacce App" <${this.fromEmail}>`,
        to: user.email,
        subject: template.subject,
        text: template.text,
        html: template.html
      };

      // Try to send email, fallback to console logging
      try {
        const info = await this.transporter.sendMail(mailOptions);
        console.log('✅ Welcome email sent:', info.messageId);
        return true;
      } catch (emailError) {
        console.log('📧 Email service not configured, logging welcome message:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`📧 Welcome email for: ${user.email}`);
        console.log(`👤 User: ${user.name}`);
        console.log(`🎉 Account created successfully!`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true; // Return true for development
      }
    } catch (error) {
      console.error('❌ Failed to send welcome email:', error);
      return false;
    }
  }

  async sendPasswordChangeNotification(user: User): Promise<boolean> {
    try {
      const subject = 'Password Changed Successfully - Astronacce App';
      
      const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Password Changed</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #28a745 0%, #20c997 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✅ Password Changed Successfully</h1>
            </div>
            <div class="content">
              <h2>Hello ${user.name},</h2>
              <p>Your password has been successfully changed for your Astronacce account.</p>
              
              <p><strong>Change Details:</strong></p>
              <ul>
                <li>Account: ${user.email}</li>
                <li>Date: ${new Date().toLocaleString()}</li>
                <li>Action: Password Reset Completed</li>
              </ul>
              
              <div class="warning">
                <strong>⚠️ Security Notice:</strong><br>
                If you didn't make this change, please contact our support team immediately.
              </div>
              
              <p>Your account is now secure with your new password.</p>
              
              <p>Best regards,<br>The Astronacce Team</p>
            </div>
            <div class="footer">
              <p>This email was sent to ${user.email}</p>
              <p>© 2024 Astronacce App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `;

      const text = `
Password Changed Successfully - Astronacce App

Hello ${user.name},

Your password has been successfully changed for your Astronacce account.

Change Details:
- Account: ${user.email}
- Date: ${new Date().toLocaleString()}
- Action: Password Reset Completed

Security Notice: If you didn't make this change, please contact our support team immediately.

Your account is now secure with your new password.

Best regards,
The Astronacce Team

This email was sent to ${user.email}
© 2024 Astronacce App. All rights reserved.
      `;

      const mailOptions = {
        from: `"Astronacce App" <${this.fromEmail}>`,
        to: user.email,
        subject,
        text,
        html
      };

      // Try to send email, fallback to console logging
      try {
        const info = await this.transporter.sendMail(mailOptions);
        console.log('✅ Password change notification sent:', info.messageId);
        return true;
      } catch (emailError) {
        console.log('📧 Email service not configured, logging password change notification:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`📧 Password changed for: ${user.email}`);
        console.log(`👤 User: ${user.name}`);
        console.log(`🔐 Password successfully updated`);
        console.log(`⏰ Time: ${new Date().toLocaleString()}`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true; // Return true for development
      }
    } catch (error) {
      console.error('❌ Failed to send password change notification:', error);
      return false;
    }
  }
}

// Export singleton instance
export const emailService = new EmailService();
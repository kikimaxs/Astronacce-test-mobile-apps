import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

// Convert string duration to seconds for numeric expiresIn
const parseExpiresIn = (duration: string): number => {
  const match = duration.match(/^(\d+)([dhms])$/);
  if (!match) return 7 * 24 * 60 * 60; // default 7 days in seconds
  
  const value = parseInt(match[1]);
  const unit = match[2];
  
  switch (unit) {
    case 's': return value;
    case 'm': return value * 60;
    case 'h': return value * 60 * 60;
    case 'd': return value * 24 * 60 * 60;
    default: return 7 * 24 * 60 * 60;
  }
};

export const generateToken = (userId: number): string => {
  return jwt.sign(
    { userId }, 
    JWT_SECRET, 
    { expiresIn: parseExpiresIn(JWT_EXPIRES_IN) }
  );
};

export const verifyToken = (token: string): { userId: number } => {
  return jwt.verify(token, JWT_SECRET) as { userId: number };
};

export const generateResetToken = (): string => {
  return jwt.sign(
    { type: 'reset' }, 
    JWT_SECRET, 
    { expiresIn: 3600 } // 1 hour in seconds
  );
};
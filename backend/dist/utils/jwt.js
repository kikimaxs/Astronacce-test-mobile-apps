"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateResetToken = exports.verifyToken = exports.generateToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
// Convert string duration to seconds for numeric expiresIn
const parseExpiresIn = (duration) => {
    const match = duration.match(/^(\d+)([dhms])$/);
    if (!match)
        return 7 * 24 * 60 * 60; // default 7 days in seconds
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
const generateToken = (userId) => {
    return jsonwebtoken_1.default.sign({ userId }, JWT_SECRET, { expiresIn: parseExpiresIn(JWT_EXPIRES_IN) });
};
exports.generateToken = generateToken;
const verifyToken = (token) => {
    return jsonwebtoken_1.default.verify(token, JWT_SECRET);
};
exports.verifyToken = verifyToken;
const generateResetToken = () => {
    return jsonwebtoken_1.default.sign({ type: 'reset' }, JWT_SECRET, { expiresIn: 3600 } // 1 hour in seconds
    );
};
exports.generateResetToken = generateResetToken;
//# sourceMappingURL=jwt.js.map
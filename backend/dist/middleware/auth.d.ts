import { Request, Response, NextFunction } from 'express';
export interface AuthRequest extends Request {
    userId?: number;
}
export declare const authenticateToken: (req: AuthRequest, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.d.ts.map
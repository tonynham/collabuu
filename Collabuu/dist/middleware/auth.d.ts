import { Request, Response, NextFunction } from 'express';
export interface AuthenticatedRequest extends Request {
    user?: {
        id: string;
        email: string;
        userType: 'business' | 'influencer' | 'customer';
        [key: string]: any;
    };
}
/**
 * Authentication middleware that verifies the JWT token from the Authorization header
 * and attaches the authenticated user to the request object.
 */
export declare const authenticateToken: (req: AuthenticatedRequest, res: Response, next: NextFunction) => Promise<Response<any, Record<string, any>> | undefined>;
/**
 * Role-based access control middleware that ensures the user has one of the specified roles.
 * @param allowedRoles - Array of user types allowed to access the route
 */
export declare const requireUserType: (userType: "business" | "influencer" | "customer") => (req: AuthenticatedRequest, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;
export declare const requireAnyUserType: (userTypes: ("business" | "influencer" | "customer")[]) => (req: AuthenticatedRequest, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;

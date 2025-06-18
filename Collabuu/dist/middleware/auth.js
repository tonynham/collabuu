"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAnyUserType = exports.requireUserType = exports.authenticateToken = void 0;
const supabase_1 = require("../config/supabase");
/**
 * Authentication middleware that verifies the JWT token from the Authorization header
 * and attaches the authenticated user to the request object.
 */
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
        if (!token) {
            return res.status(401).json({ error: 'Access token required' });
        }
        // Verify token with Supabase
        const { data: { user }, error } = await supabase_1.supabase.auth.getUser(token);
        if (error || !user) {
            return res.status(401).json({ error: 'Invalid or expired token' });
        }
        // Get user profile from database
        const { data: userProfile, error: profileError } = await supabase_1.supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        if (profileError || !userProfile) {
            return res.status(404).json({ error: 'User profile not found' });
        }
        // Attach user info to request
        req.user = {
            id: user.id,
            email: user.email || userProfile.email,
            userType: userProfile.user_type,
            firstName: userProfile.first_name,
            lastName: userProfile.last_name,
            username: userProfile.username,
            profileImageUrl: userProfile.profile_image_url,
            bio: userProfile.bio
        };
        next();
    }
    catch (error) {
        console.error('Authentication error:', error);
        res.status(500).json({ error: 'Authentication failed' });
    }
};
exports.authenticateToken = authenticateToken;
/**
 * Role-based access control middleware that ensures the user has one of the specified roles.
 * @param allowedRoles - Array of user types allowed to access the route
 */
const requireUserType = (userType) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        if (req.user.userType !== userType) {
            return res.status(403).json({
                error: `Access denied. ${userType} account required.`
            });
        }
        next();
    };
};
exports.requireUserType = requireUserType;
const requireAnyUserType = (userTypes) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        if (!userTypes.includes(req.user.userType)) {
            return res.status(403).json({
                error: `Access denied. One of the following account types required: ${userTypes.join(', ')}`
            });
        }
        next();
    };
};
exports.requireAnyUserType = requireAnyUserType;
//# sourceMappingURL=auth.js.map
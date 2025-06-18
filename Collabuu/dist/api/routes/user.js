"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserRouter = void 0;
const express_1 = __importDefault(require("express"));
const supabase_1 = require("../../config/supabase");
class UserRouter {
    constructor() {
        this.router = express_1.default.Router();
        this.router.post('/register', this.register.bind(this));
        this.router.post('/login', this.login.bind(this));
        this.router.post('/refresh', this.refreshToken.bind(this));
    }
    // Register a new user (all types)
    async register(req, res) {
        const { email, password, userType, firstName, lastName, username } = req.body;
        if (!email || !password || !userType) {
            return res.status(400).json({ error: 'Required fields: email, password, userType' });
        }
        // Sign up with Supabase Auth
        const { data: signUpData, error: signUpError } = await supabase_1.supabase.auth.signUp({
            email,
            password
        });
        if (signUpError || !signUpData.user) {
            return res.status(400).json({ error: signUpError?.message || 'Sign-up failed' });
        }
        // Create user profile record
        const { data: profileData, error: profileError } = await supabase_1.supabase
            .from('user_profiles')
            .insert([{ id: signUpData.user.id, email, user_type: userType, first_name: firstName, last_name: lastName, username }]);
        if (profileError) {
            return res.status(500).json({ error: 'Profile creation failed: ' + profileError.message });
        }
        res.status(201).json({ message: 'User registered successfully', userId: signUpData.user.id });
    }
    // Login existing user
    async login(req, res) {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Required fields: email, password' });
        }
        const { data: loginData, error: loginError } = await supabase_1.supabase.auth.signInWithPassword({
            email,
            password
        });
        if (loginError || !loginData.session) {
            return res.status(401).json({ error: loginError?.message || 'Invalid credentials' });
        }
        res.status(200).json({
            accessToken: loginData.session.access_token,
            refreshToken: loginData.session.refresh_token,
            expiresIn: loginData.session.expires_in
        });
    }
    // Refresh access token
    async refreshToken(req, res) {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return res.status(400).json({ error: 'Refresh token required' });
        }
        const { data, error } = await supabase_1.supabase.auth.refreshSession({ refresh_token: refreshToken });
        if (error || !data.session) {
            return res.status(401).json({ error: error?.message || 'Could not refresh token' });
        }
        res.status(200).json({
            accessToken: data.session.access_token,
            refreshToken: data.session.refresh_token,
            expiresIn: data.session.expires_in
        });
    }
}
exports.UserRouter = UserRouter;
//# sourceMappingURL=user.js.map
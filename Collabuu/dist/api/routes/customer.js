"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CustomerRouter = void 0;
const express_1 = __importDefault(require("express"));
const supabase_1 = require("../../config/supabase");
const user_1 = require("../../models/user");
class CustomerRouter {
    constructor() {
        this.router = express_1.default.Router();
        this.userService = new user_1.UserService(supabase_1.supabase);
        // Authentication
        this.router.post('/auth/register', this.register.bind(this));
        this.router.post('/auth/login', this.login.bind(this));
        // Profile Management
        this.router.get('/profile', this.getProfile.bind(this));
        this.router.put('/profile', this.updateProfile.bind(this));
        // Favorites Management
        this.router.get('/favorites', this.getFavorites.bind(this));
        this.router.post('/favorites', this.addFavorite.bind(this));
        this.router.post('/favorites/by-code', this.addFavoriteByCode.bind(this));
        this.router.delete('/favorites/:id', this.removeFavorite.bind(this));
        this.router.get('/favorites/:id/qr-code', this.getFavoriteQrCode.bind(this));
        this.router.get('/favorites/rewards', this.getFavoriteRewards.bind(this));
        this.router.get('/favorites/:favoriteId/reward-qr', this.getFavoriteRewardQr.bind(this));
        // Deals & Rewards
        this.router.get('/deals', this.getDeals.bind(this));
        this.router.get('/deals/:id', this.getDealDetails.bind(this));
        this.router.get('/rewards', this.getRewards.bind(this));
        this.router.get('/rewards/available', this.getAvailableRewards.bind(this));
        this.router.post('/rewards/:rewardId/redeem', this.redeemReward.bind(this));
        this.router.get('/rewards/history', this.getRewardHistory.bind(this));
        this.router.get('/rewards/redemptions', this.getRewardRedemptions.bind(this));
        this.router.post('/visits/loyalty-points', this.earnLoyaltyPoints.bind(this));
        this.router.get('/deals/media-events', this.getMediaEvents.bind(this));
        // Business Discovery
        this.router.get('/businesses', this.getBusinesses.bind(this));
        this.router.get('/businesses/search', this.searchBusinesses.bind(this));
        this.router.get('/businesses/:id', this.getBusinessDetails.bind(this));
        this.router.get('/businesses/categories', this.getBusinessCategories.bind(this));
        // Visit Tracking
        this.router.get('/visits', this.getVisits.bind(this));
        this.router.get('/visits/stats', this.getVisitStats.bind(this));
    }
    // Authentication Methods
    async register(req, res) {
        try {
            const { email, password, firstName, lastName, username, preferences } = req.body;
            // Validate required fields
            if (!email || !password || !firstName || !lastName) {
                return res.status(400).json({
                    error: 'Missing required fields: email, password, firstName, lastName'
                });
            }
            // Create auth user in Supabase
            const { data: authData, error: authError } = await supabase_1.supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        user_type: 'customer',
                        first_name: firstName,
                        last_name: lastName,
                        username
                    }
                }
            });
            if (authError) {
                return res.status(400).json({ error: authError.message });
            }
            if (!authData.user) {
                return res.status(400).json({ error: 'Failed to create user account' });
            }
            // Create user profile
            const user = await this.userService.createUser({
                id: authData.user.id,
                email,
                userType: 'customer',
                firstName,
                lastName,
                username
            });
            if (!user) {
                return res.status(500).json({ error: 'Failed to create user profile' });
            }
            // Create customer profile
            const { data: customerProfile, error: customerError } = await supabase_1.supabase
                .from('customer_profiles')
                .insert([{
                    user_id: authData.user.id,
                    preferences: preferences || [],
                    favorite_businesses: []
                }])
                .select()
                .single();
            if (customerError) {
                console.error('Customer profile creation error:', customerError);
                return res.status(500).json({ error: 'Failed to create customer profile' });
            }
            res.status(201).json({
                message: 'Customer registered successfully',
                user: {
                    id: user.id,
                    email: user.email,
                    userType: user.userType,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    username: user.username
                },
                customerProfile: {
                    id: customerProfile.id,
                    preferences: customerProfile.preferences,
                    favoriteBusinesses: customerProfile.favorite_businesses
                },
                session: authData.session
            });
        }
        catch (error) {
            console.error('Customer registration error:', error);
            res.status(500).json({ error: 'Internal server error during registration' });
        }
    }
    async login(req, res) {
        try {
            const { email, password } = req.body;
            if (!email || !password) {
                return res.status(400).json({ error: 'Email and password are required' });
            }
            // Authenticate with Supabase
            const { data: authData, error: authError } = await supabase_1.supabase.auth.signInWithPassword({
                email,
                password
            });
            if (authError) {
                return res.status(401).json({ error: authError.message });
            }
            if (!authData.user) {
                return res.status(401).json({ error: 'Authentication failed' });
            }
            // Get user profile
            const user = await this.userService.getUserById(authData.user.id);
            if (!user) {
                return res.status(404).json({ error: 'User profile not found' });
            }
            // Verify user is a customer
            if (user.userType !== 'customer') {
                return res.status(403).json({ error: 'Access denied. Customer account required.' });
            }
            // Get customer profile
            const { data: customerProfile, error: customerError } = await supabase_1.supabase
                .from('customer_profiles')
                .select('*')
                .eq('user_id', authData.user.id)
                .single();
            if (customerError || !customerProfile) {
                return res.status(404).json({ error: 'Customer profile not found' });
            }
            res.json({
                message: 'Login successful',
                user: {
                    id: user.id,
                    email: user.email,
                    userType: user.userType,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    username: user.username,
                    profileImageUrl: user.profileImageUrl,
                    bio: user.bio
                },
                customerProfile: {
                    id: customerProfile.id,
                    preferences: customerProfile.preferences,
                    favoriteBusinesses: customerProfile.favorite_businesses
                },
                session: authData.session
            });
        }
        catch (error) {
            console.error('Customer login error:', error);
            res.status(500).json({ error: 'Internal server error during login' });
        }
    }
    async getProfile(req, res) {
        // TODO: implement get customer profile
        res.status(200).json({});
    }
    async updateProfile(req, res) {
        // TODO: implement update customer profile
        res.status(200).json({});
    }
    async getFavorites(req, res) {
        // TODO: implement get customer favorites
        res.status(200).json([]);
    }
    async addFavorite(req, res) {
        // TODO: implement add favorite
        res.status(200).json({});
    }
    async addFavoriteByCode(req, res) {
        try {
            const customerId = req.user?.id;
            const { referralCode, deepLink } = req.body;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            if (!referralCode && !deepLink) {
                return res.status(400).json({ error: 'Referral code or deep link required' });
            }
            let campaignId;
            // Handle deep link
            if (deepLink) {
                // Extract campaign ID from deep link
                const urlParams = new URLSearchParams(deepLink.split('?')[1]);
                campaignId = urlParams.get('campaign') || '';
            }
            else {
                // Handle referral code - look up campaign by referral code
                const { data: referralData, error: referralError } = await supabase_1.supabase
                    .from('influencer_referrals')
                    .select('campaign_id')
                    .eq('referral_code', referralCode)
                    .single();
                if (referralError || !referralData) {
                    return res.status(404).json({ error: 'Invalid referral code' });
                }
                campaignId = referralData.campaign_id;
            }
            // Get campaign details
            const { data: campaign, error: campaignError } = await supabase_1.supabase
                .from('campaigns')
                .select('*')
                .eq('id', campaignId)
                .eq('status', 'active')
                .single();
            if (campaignError || !campaign) {
                return res.status(404).json({ error: 'Campaign not found or inactive' });
            }
            // Check if already favorited
            const { data: existingFavorite } = await supabase_1.supabase
                .from('customer_favorites')
                .select('id')
                .eq('customer_id', customerId)
                .eq('campaign_id', campaignId)
                .single();
            if (existingFavorite) {
                return res.status(409).json({ error: 'Campaign already in favorites' });
            }
            // Add to favorites
            const { data: favorite, error: favoriteError } = await supabase_1.supabase
                .from('customer_favorites')
                .insert([{
                    customer_id: customerId,
                    campaign_id: campaignId,
                    referral_code: referralCode,
                    source: referralCode ? 'referral_code' : 'deep_link'
                }])
                .select('*, campaigns(*)')
                .single();
            if (favoriteError) {
                console.error('Favorite creation error:', favoriteError);
                return res.status(500).json({ error: 'Failed to add to favorites' });
            }
            res.status(201).json({
                message: 'Campaign added to favorites successfully',
                favorite,
                campaign: favorite.campaigns
            });
        }
        catch (error) {
            console.error('Add favorite by code error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async removeFavorite(req, res) {
        // TODO: implement remove favorite
        res.status(200).json({});
    }
    async getFavoriteQrCode(req, res) {
        try {
            const customerId = req.user?.id;
            const favoriteId = req.params.id;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Get favorite record
            const { data: favorite, error: favoriteError } = await supabase_1.supabase
                .from('customer_favorites')
                .select('*, campaigns(*)')
                .eq('id', favoriteId)
                .eq('customer_id', customerId)
                .single();
            if (favoriteError || !favorite) {
                return res.status(404).json({ error: 'Favorite not found' });
            }
            // Generate QR code data
            const qrData = {
                type: 'visit',
                customerId,
                campaignId: favorite.campaign_id,
                favoriteId,
                timestamp: new Date().toISOString()
            };
            // Create QR code string
            const qrCodeString = JSON.stringify(qrData);
            // Generate QR code using the qrcode library
            const QRCode = require('qrcode');
            const qrCodeDataUrl = await QRCode.toDataURL(qrCodeString, {
                errorCorrectionLevel: 'M',
                type: 'image/png',
                quality: 0.92,
                margin: 1,
                color: {
                    dark: '#000000',
                    light: '#FFFFFF'
                }
            });
            res.json({
                qrCode: qrCodeDataUrl,
                qrData: qrCodeString,
                campaign: favorite.campaigns,
                expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24 hours
            });
        }
        catch (error) {
            console.error('QR code generation error:', error);
            res.status(500).json({ error: 'Failed to generate QR code' });
        }
    }
    async getFavoriteRewards(req, res) {
        // TODO: implement get redeemed rewards
        res.status(200).json([]);
    }
    async getFavoriteRewardQr(req, res) {
        // TODO: implement generate QR for reward redemption
        res.status(200).json({});
    }
    async getDeals(req, res) {
        // TODO: implement browse available deals
        res.status(200).json([]);
    }
    async getDealDetails(req, res) {
        // TODO: implement get deal details
        res.status(200).json({});
    }
    async getRewards(req, res) {
        // TODO: implement get loyalty points balance and rewards
        res.status(200).json({});
    }
    async getAvailableRewards(req, res) {
        // TODO: implement browse available loyalty reward campaigns
        res.status(200).json([]);
    }
    async redeemReward(req, res) {
        // TODO: implement redeem loyalty reward
        res.status(200).json({});
    }
    async getRewardHistory(req, res) {
        // TODO: implement loyalty points transaction history
        res.status(200).json([]);
    }
    async getRewardRedemptions(req, res) {
        // TODO: implement get reward redemption history
        res.status(200).json([]);
    }
    async earnLoyaltyPoints(req, res) {
        // TODO: implement earn loyalty points from visit
        res.status(200).json({});
    }
    async getMediaEvents(req, res) {
        // TODO: implement browse media events
        res.status(200).json([]);
    }
    async getBusinesses(req, res) {
        // TODO: implement browse businesses
        res.status(200).json([]);
    }
    async searchBusinesses(req, res) {
        // TODO: implement search businesses
        res.status(200).json([]);
    }
    async getBusinessDetails(req, res) {
        // TODO: implement get business details
        res.status(200).json({});
    }
    async getBusinessCategories(req, res) {
        // TODO: implement get business categories
        res.status(200).json([]);
    }
    async getVisits(req, res) {
        // TODO: implement get visit history
        res.status(200).json([]);
    }
    async getVisitStats(req, res) {
        // TODO: implement get visit statistics
        res.status(200).json({});
    }
}
exports.CustomerRouter = CustomerRouter;
//# sourceMappingURL=customer.js.map
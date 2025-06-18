"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LoyaltyRouter = void 0;
const express_1 = __importDefault(require("express"));
const supabase_1 = require("../../config/supabase");
const qrcode_1 = __importDefault(require("qrcode"));
class LoyaltyRouter {
    constructor() {
        this.router = express_1.default.Router();
        this.router.get('/points', this.getPoints.bind(this));
        this.router.get('/points/:businessId', this.getPointsForBusiness.bind(this));
        this.router.get('/transactions', this.getTransactions.bind(this));
        this.router.get('/rewards', this.getRewards.bind(this));
        this.router.post('/rewards/:campaignId/redeem', this.redeemReward.bind(this));
        this.router.get('/redemptions', this.getRedemptions.bind(this));
        this.router.get('/redemptions/:id/qr', this.getRedemptionQR.bind(this));
    }
    async getPoints(req, res) {
        try {
            const customerId = req.user?.id;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Get loyalty points for all businesses
            const { data: loyaltyPoints, error } = await supabase_1.supabase
                .from('loyalty_points')
                .select(`
          business_id, points_balance, total_earned, total_redeemed
        `)
                .eq('customer_id', customerId)
                .gt('points_balance', 0);
            if (error) {
                console.error('Loyalty points fetch error:', error);
                return res.status(500).json({ error: 'Failed to fetch loyalty points' });
            }
            // Get business details separately
            const businessIds = loyaltyPoints?.map(lp => lp.business_id) || [];
            const { data: businesses, error: businessError } = await supabase_1.supabase
                .from('business_profiles')
                .select('user_id, business_name, logo_url')
                .in('user_id', businessIds);
            if (businessError) {
                console.error('Business profiles fetch error:', businessError);
            }
            const businessMap = (businesses || []).reduce((acc, business) => {
                acc[business.user_id] = business;
                return acc;
            }, {});
            const totalPoints = loyaltyPoints?.reduce((sum, lp) => sum + lp.points_balance, 0) || 0;
            const totalEarned = loyaltyPoints?.reduce((sum, lp) => sum + lp.total_earned, 0) || 0;
            const pointsByBusiness = loyaltyPoints?.map(lp => ({
                businessId: lp.business_id,
                businessName: businessMap[lp.business_id]?.business_name || 'Unknown Business',
                businessLogo: businessMap[lp.business_id]?.logo_url,
                pointsBalance: lp.points_balance,
                totalEarned: lp.total_earned,
                totalRedeemed: lp.total_redeemed
            })) || [];
            res.status(200).json({
                totalPoints,
                totalEarned,
                pointsByBusiness
            });
        }
        catch (error) {
            console.error('Get points error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getPointsForBusiness(req, res) {
        try {
            const customerId = req.user?.id;
            const businessId = req.params.businessId;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data: loyaltyPoints, error } = await supabase_1.supabase
                .from('loyalty_points')
                .select('points_balance, total_earned, total_redeemed, created_at, updated_at')
                .eq('customer_id', customerId)
                .eq('business_id', businessId)
                .single();
            if (error && error.code !== 'PGRST116') {
                console.error('Loyalty points fetch error:', error);
                return res.status(500).json({ error: 'Failed to fetch loyalty points' });
            }
            // Get business details
            const { data: business, error: businessError } = await supabase_1.supabase
                .from('business_profiles')
                .select('business_name, logo_url, category')
                .eq('user_id', businessId)
                .single();
            if (businessError) {
                console.error('Business profile fetch error:', businessError);
            }
            if (!loyaltyPoints) {
                return res.status(200).json({
                    businessId,
                    pointsBalance: 0,
                    totalEarned: 0,
                    totalRedeemed: 0,
                    business: business ? {
                        name: business.business_name,
                        logo: business.logo_url,
                        category: business.category
                    } : null
                });
            }
            res.status(200).json({
                businessId,
                pointsBalance: loyaltyPoints.points_balance,
                totalEarned: loyaltyPoints.total_earned,
                totalRedeemed: loyaltyPoints.total_redeemed,
                business: business ? {
                    name: business.business_name,
                    logo: business.logo_url,
                    category: business.category
                } : null,
                memberSince: loyaltyPoints.created_at
            });
        }
        catch (error) {
            console.error('Get points for business error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getTransactions(req, res) {
        try {
            const customerId = req.user?.id;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { businessId, page = 1, limit = 20 } = req.query;
            const offset = (Number(page) - 1) * Number(limit);
            let query = supabase_1.supabase
                .from('loyalty_transactions')
                .select('id, transaction_type, points, description, created_at, business_id, visit_id')
                .eq('customer_id', customerId)
                .order('created_at', { ascending: false })
                .range(offset, offset + Number(limit) - 1);
            if (businessId) {
                query = query.eq('business_id', businessId);
            }
            const { data: transactions, error } = await query;
            if (error) {
                console.error('Loyalty transactions fetch error:', error);
                return res.status(500).json({ error: 'Failed to fetch loyalty transactions' });
            }
            // Get business details
            const businessIds = [...new Set(transactions?.map(t => t.business_id) || [])];
            const { data: businesses, error: businessError } = await supabase_1.supabase
                .from('business_profiles')
                .select('user_id, business_name, logo_url')
                .in('user_id', businessIds);
            if (businessError) {
                console.error('Business profiles fetch error:', businessError);
            }
            const businessMap = (businesses || []).reduce((acc, business) => {
                acc[business.user_id] = business;
                return acc;
            }, {});
            // Get visit details if needed
            const visitIds = transactions?.filter(t => t.visit_id).map(t => t.visit_id) || [];
            const { data: visits, error: visitError } = await supabase_1.supabase
                .from('visits')
                .select('id, visit_date')
                .in('id', visitIds);
            if (visitError) {
                console.error('Visits fetch error:', visitError);
            }
            const visitMap = (visits || []).reduce((acc, visit) => {
                acc[visit.id] = visit;
                return acc;
            }, {});
            const formattedTransactions = transactions?.map(transaction => ({
                id: transaction.id,
                type: transaction.transaction_type,
                points: transaction.points,
                description: transaction.description,
                createdAt: transaction.created_at,
                business: {
                    id: transaction.business_id,
                    name: businessMap[transaction.business_id]?.business_name || 'Unknown Business',
                    logo: businessMap[transaction.business_id]?.logo_url
                },
                visit: transaction.visit_id && visitMap[transaction.visit_id] ? {
                    id: transaction.visit_id,
                    date: visitMap[transaction.visit_id].visit_date
                } : null
            })) || [];
            res.status(200).json({
                transactions: formattedTransactions,
                pagination: {
                    page: Number(page),
                    limit: Number(limit)
                }
            });
        }
        catch (error) {
            console.error('Get transactions error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getRewards(req, res) {
        try {
            const customerId = req.user?.id;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { businessId } = req.query;
            // Get available loyalty reward campaigns
            let query = supabase_1.supabase
                .from('campaigns')
                .select('id, title, description, loyalty_points_cost, reward_type, reward_value, business_id')
                .eq('campaign_type', 'loyalty_reward')
                .eq('status', 'active');
            if (businessId) {
                query = query.eq('business_id', businessId);
            }
            const { data: campaigns, error } = await query;
            if (error) {
                console.error('Loyalty rewards fetch error:', error);
                return res.status(500).json({ error: 'Failed to fetch loyalty rewards' });
            }
            // Get business details
            const businessIds = [...new Set(campaigns?.map(c => c.business_id) || [])];
            const { data: businesses, error: businessError } = await supabase_1.supabase
                .from('business_profiles')
                .select('user_id, business_name, logo_url, category')
                .in('user_id', businessIds);
            if (businessError) {
                console.error('Business profiles fetch error:', businessError);
            }
            const businessMap = (businesses || []).reduce((acc, business) => {
                acc[business.user_id] = business;
                return acc;
            }, {});
            // Get customer's points for each business to check affordability
            const { data: customerPoints, error: pointsError } = await supabase_1.supabase
                .from('loyalty_points')
                .select('business_id, points_balance')
                .eq('customer_id', customerId)
                .in('business_id', businessIds);
            if (pointsError) {
                console.error('Customer points fetch error:', pointsError);
            }
            const pointsByBusiness = (customerPoints || []).reduce((acc, cp) => {
                acc[cp.business_id] = cp.points_balance;
                return acc;
            }, {});
            const rewards = campaigns?.map(campaign => ({
                id: campaign.id,
                title: campaign.title,
                description: campaign.description,
                pointsCost: campaign.loyalty_points_cost,
                rewardType: campaign.reward_type,
                rewardValue: campaign.reward_value,
                business: {
                    id: campaign.business_id,
                    name: businessMap[campaign.business_id]?.business_name || 'Unknown Business',
                    logo: businessMap[campaign.business_id]?.logo_url,
                    category: businessMap[campaign.business_id]?.category
                },
                customerPoints: pointsByBusiness[campaign.business_id] || 0,
                canAfford: (pointsByBusiness[campaign.business_id] || 0) >= campaign.loyalty_points_cost
            })) || [];
            res.status(200).json(rewards);
        }
        catch (error) {
            console.error('Get rewards error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async redeemReward(req, res) {
        try {
            const customerId = req.user?.id;
            const campaignId = req.params.campaignId;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Get campaign details
            const { data: campaign, error: campaignError } = await supabase_1.supabase
                .from('campaigns')
                .select('id, title, business_id, loyalty_points_cost, reward_type, reward_value')
                .eq('id', campaignId)
                .eq('campaign_type', 'loyalty_reward')
                .eq('status', 'active')
                .single();
            if (campaignError || !campaign) {
                return res.status(404).json({ error: 'Reward campaign not found' });
            }
            // Check customer's points balance
            const { data: loyaltyPoints, error: pointsError } = await supabase_1.supabase
                .from('loyalty_points')
                .select('points_balance, total_redeemed')
                .eq('customer_id', customerId)
                .eq('business_id', campaign.business_id)
                .single();
            if (pointsError || !loyaltyPoints) {
                return res.status(400).json({ error: 'No loyalty points found for this business' });
            }
            if (loyaltyPoints.points_balance < campaign.loyalty_points_cost) {
                return res.status(400).json({
                    error: 'Insufficient points',
                    required: campaign.loyalty_points_cost,
                    available: loyaltyPoints.points_balance
                });
            }
            // Create redemption record
            const expiresAt = new Date();
            expiresAt.setDate(expiresAt.getDate() + 30); // 30 days expiry
            const qrCodeData = `collabuu://redeem/${campaignId}/${customerId}/${Date.now()}`;
            const { data: redemption, error: redemptionError } = await supabase_1.supabase
                .from('reward_redemptions')
                .insert([{
                    customer_id: customerId,
                    campaign_id: campaignId,
                    business_id: campaign.business_id,
                    points_used: campaign.loyalty_points_cost,
                    reward_details: {
                        title: campaign.title,
                        type: campaign.reward_type,
                        value: campaign.reward_value
                    },
                    qr_code_data: qrCodeData,
                    expires_at: expiresAt.toISOString(),
                    status: 'pending'
                }])
                .select()
                .single();
            if (redemptionError) {
                console.error('Redemption creation error:', redemptionError);
                return res.status(500).json({ error: 'Failed to create redemption' });
            }
            // Deduct points and create transaction
            const newBalance = loyaltyPoints.points_balance - campaign.loyalty_points_cost;
            const { error: pointsUpdateError } = await supabase_1.supabase
                .from('loyalty_points')
                .update({
                points_balance: newBalance,
                total_redeemed: loyaltyPoints.total_redeemed + campaign.loyalty_points_cost,
                updated_at: new Date().toISOString()
            })
                .eq('customer_id', customerId)
                .eq('business_id', campaign.business_id);
            if (pointsUpdateError) {
                console.error('Points update error:', pointsUpdateError);
                // Rollback redemption
                await supabase_1.supabase.from('reward_redemptions').delete().eq('id', redemption.id);
                return res.status(500).json({ error: 'Failed to deduct points' });
            }
            // Create loyalty transaction
            await supabase_1.supabase
                .from('loyalty_transactions')
                .insert([{
                    customer_id: customerId,
                    business_id: campaign.business_id,
                    transaction_type: 'redeemed',
                    points: -campaign.loyalty_points_cost,
                    description: `Redeemed: ${campaign.title}`
                }]);
            res.status(201).json({
                message: 'Reward redeemed successfully',
                redemption: {
                    id: redemption.id,
                    qrCodeData: redemption.qr_code_data,
                    expiresAt: redemption.expires_at,
                    status: redemption.status,
                    reward: redemption.reward_details
                }
            });
        }
        catch (error) {
            console.error('Redeem reward error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getRedemptions(req, res) {
        try {
            const customerId = req.user?.id;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { status, page = 1, limit = 20 } = req.query;
            const offset = (Number(page) - 1) * Number(limit);
            let query = supabase_1.supabase
                .from('reward_redemptions')
                .select(`
          id, points_used, reward_details, status, qr_code_data,
          redeemed_at, validated_at, expires_at, business_id, campaign_id
        `)
                .eq('customer_id', customerId)
                .order('redeemed_at', { ascending: false })
                .range(offset, offset + Number(limit) - 1);
            if (status) {
                query = query.eq('status', status);
            }
            const { data: redemptions, error } = await query;
            if (error) {
                console.error('Redemptions fetch error:', error);
                return res.status(500).json({ error: 'Failed to fetch redemptions' });
            }
            // Get business and campaign details
            const businessIds = [...new Set(redemptions?.map(r => r.business_id) || [])];
            const campaignIds = [...new Set(redemptions?.map(r => r.campaign_id) || [])];
            const { data: businesses, error: businessError } = await supabase_1.supabase
                .from('business_profiles')
                .select('user_id, business_name, logo_url')
                .in('user_id', businessIds);
            const { data: campaigns, error: campaignError } = await supabase_1.supabase
                .from('campaigns')
                .select('id, title')
                .in('id', campaignIds);
            if (businessError) {
                console.error('Business profiles fetch error:', businessError);
            }
            if (campaignError) {
                console.error('Campaigns fetch error:', campaignError);
            }
            const businessMap = (businesses || []).reduce((acc, business) => {
                acc[business.user_id] = business;
                return acc;
            }, {});
            const campaignMap = (campaigns || []).reduce((acc, campaign) => {
                acc[campaign.id] = campaign;
                return acc;
            }, {});
            const formattedRedemptions = redemptions?.map(redemption => ({
                id: redemption.id,
                pointsUsed: redemption.points_used,
                reward: redemption.reward_details,
                status: redemption.status,
                qrCodeData: redemption.qr_code_data,
                redeemedAt: redemption.redeemed_at,
                validatedAt: redemption.validated_at,
                expiresAt: redemption.expires_at,
                business: {
                    id: redemption.business_id,
                    name: businessMap[redemption.business_id]?.business_name || 'Unknown Business',
                    logo: businessMap[redemption.business_id]?.logo_url
                },
                campaign: {
                    title: campaignMap[redemption.campaign_id]?.title || 'Unknown Campaign'
                }
            })) || [];
            res.status(200).json({
                redemptions: formattedRedemptions,
                pagination: {
                    page: Number(page),
                    limit: Number(limit)
                }
            });
        }
        catch (error) {
            console.error('Get redemptions error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getRedemptionQR(req, res) {
        try {
            const customerId = req.user?.id;
            const redemptionId = req.params.id;
            if (!customerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data: redemption, error } = await supabase_1.supabase
                .from('reward_redemptions')
                .select('qr_code_data, status, expires_at')
                .eq('id', redemptionId)
                .eq('customer_id', customerId)
                .single();
            if (error || !redemption) {
                return res.status(404).json({ error: 'Redemption not found' });
            }
            if (redemption.status === 'completed') {
                return res.status(400).json({ error: 'Redemption already used' });
            }
            if (new Date(redemption.expires_at) < new Date()) {
                return res.status(400).json({ error: 'Redemption expired' });
            }
            // Generate QR code
            const qrCodeImage = await qrcode_1.default.toDataURL(redemption.qr_code_data);
            res.status(200).json({
                qrCode: qrCodeImage,
                qrCodeData: redemption.qr_code_data,
                status: redemption.status,
                expiresAt: redemption.expires_at
            });
        }
        catch (error) {
            console.error('Get redemption QR error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}
exports.LoyaltyRouter = LoyaltyRouter;
//# sourceMappingURL=loyalty.js.map
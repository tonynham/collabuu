"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.InfluencerRouter = void 0;
// @ts-nocheck
const express_1 = __importDefault(require("express"));
const supabase_1 = require("../../config/supabase");
const campaign_1 = require("../../models/campaign");
const conversation_1 = require("../../models/conversation");
const user_1 = require("../../models/user");
class InfluencerRouter {
    constructor() {
        this.router = express_1.default.Router();
        this.campaignService = new campaign_1.CampaignService(supabase_1.supabase);
        this.conversationService = new conversation_1.ConversationService(supabase_1.supabase);
        this.userService = new user_1.UserService(supabase_1.supabase);
        // Authentication & Profile Management
        this.router.post('/auth/register', this.register.bind(this));
        this.router.post('/auth/login', this.login.bind(this));
        this.router.get('/profile', this.getProfile.bind(this));
        this.router.put('/profile', this.updateProfile.bind(this));
        this.router.post('/profile/upload-image', this.uploadProfileImage.bind(this));
        this.router.post('/profile/social-links', this.updateSocialLinks.bind(this));
        // Opportunity discovery
        this.router.get('/opportunities', this.getOpportunities.bind(this));
        this.router.get('/opportunities/:id', this.getOpportunityDetails.bind(this));
        this.router.post('/opportunities/:id/apply', this.applyToOpportunity.bind(this));
        this.router.get('/opportunities/categories', this.getOpportunityCategories.bind(this));
        this.router.get('/opportunities/recommended', this.getRecommendedOpportunities.bind(this));
        this.router.get('/opportunities/media-events', this.getMediaEvents.bind(this));
        // Invites
        this.router.get('/invites', this.getInvites.bind(this));
        this.router.post('/invites/:inviteId/accept', this.acceptInvite.bind(this));
        this.router.post('/invites/:inviteId/decline', this.declineInvite.bind(this));
        // Campaign management
        this.router.get('/campaigns', this.getAllCampaigns.bind(this));
        this.router.get('/campaigns/:id', this.getCampaignDetails.bind(this));
        this.router.post('/campaigns/:id/withdraw', this.withdrawApplication.bind(this));
        this.router.get('/campaigns/pending', this.getPendingCampaigns.bind(this));
        this.router.post('/campaigns/:id/submit-content', this.submitContent.bind(this));
        this.router.get('/campaigns/:id/performance', this.getCampaignPerformance.bind(this));
        this.router.post('/campaigns/:id/generate-code', this.generateCode.bind(this));
        this.router.post('/campaigns/:id/generate-deeplink', this.generateDeeplink.bind(this));
        this.router.get('/campaigns/:id/visits', this.getCampaignVisits.bind(this));
        this.router.get('/campaigns/:id/referral-code', this.getReferralCode.bind(this));
        this.router.get('/campaigns/:id/media-event/details', this.getMediaEventDetails.bind(this));
        this.router.post('/campaigns/:id/media-event/checkin', this.checkinMediaEvent.bind(this));
        // Content & Performance Tracking
        this.router.post('/content/submit', this.submitInfluencerContent.bind(this));
        this.router.get('/content', this.getContentHistory.bind(this));
        this.router.get('/content/:contentId', this.getContentDetails.bind(this));
        this.router.put('/content/:contentId', this.updateContent.bind(this));
        this.router.delete('/content/:contentId', this.deleteContent.bind(this));
        this.router.get('/content/platforms', this.getContentPlatforms.bind(this));
        this.router.get('/performance/overview', this.getPerformanceOverview.bind(this));
        this.router.get('/performance/earnings', this.getPerformanceEarnings.bind(this));
        // Messaging
        this.router.get('/conversations', this.getConversations.bind(this));
        this.router.get('/conversations/:id/messages', this.getMessages.bind(this));
        this.router.post('/conversations/:id/messages', this.sendMessage.bind(this));
        this.router.get('/conversations/by-campaign/:campaignId', this.getConversationByCampaign.bind(this));
        this.router.get('/conversations/:id/campaign-status', this.getConversationCampaignStatus.bind(this));
        this.router.get('/credits/balance', this.getCreditBalance.bind(this));
        this.router.get('/credits/history', this.getCreditHistory.bind(this));
        this.router.post('/credits/withdraw', this.withdrawCredits.bind(this));
        this.router.get('/credits/withdrawal-history', this.getWithdrawalHistory.bind(this));
        this.router.get('/wallet/balance', this.getWalletBalance.bind(this));
        this.router.get('/wallet/transactions', this.getWalletTransactions.bind(this));
        this.router.post('/wallet/withdrawals', this.createWalletWithdrawal.bind(this));
        this.router.get('/wallet/withdrawals/:id', this.getWalletWithdrawal.bind(this));
        this.router.delete('/wallet/withdrawals/:id/cancel', this.cancelWalletWithdrawal.bind(this));
        this.router.get('/wallet/payment-methods', this.getWalletPaymentMethods.bind(this));
        this.router.post('/wallet/payment-methods', this.addWalletPaymentMethod.bind(this));
        this.router.delete('/wallet/payment-methods/:methodId', this.removeWalletPaymentMethod.bind(this));
        this.router.post('/profile/verification/request', this.requestProfileVerification.bind(this));
        this.router.get('/profile/verification/status', this.getProfileVerificationStatus.bind(this));
        this.router.get('/profile/stats', this.getProfileStats.bind(this));
        this.router.get('/messages/unread-count', this.getUnreadMessageCount.bind(this));
        this.router.put('/conversations/:id/typing', this.setTypingIndicator.bind(this));
        this.router.get('/dashboard/summary', this.getDashboardSummary.bind(this));
        this.router.get('/dashboard/chart-data', this.getDashboardChartData.bind(this));
        this.router.post('/search', this.search.bind(this));
        this.router.get('/search/history', this.getSearchHistory.bind(this));
        this.router.delete('/search/history', this.clearSearchHistory.bind(this));
    }
    async getOpportunities(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const campaigns = await this.campaignService.getPublicCampaigns();
            return res.status(200).json(campaigns);
        }
        catch (err) {
            console.error(err);
            return res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getOpportunityDetails(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const campaignId = req.params.id;
            const campaign = await this.campaignService.getCampaignById(campaignId);
            if (!campaign || campaign.visibility !== 'public') {
                return res.status(404).json({ error: 'Opportunity not found' });
            }
            return res.status(200).json(campaign);
        }
        catch (err) {
            console.error(err);
            return res.status(500).json({ error: 'Internal server error' });
        }
    }
    async applyToOpportunity(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const campaignId = req.params.id;
            const message = req.body.message;
            const application = await this.campaignService.applyCampaign(campaignId, influencerId, message);
            if (!application) {
                return res.status(500).json({ error: 'Failed to apply to opportunity' });
            }
            return res.status(201).json(application);
        }
        catch (err) {
            console.error(err);
            return res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getOpportunityCategories(req, res) {
        // TODO: implement categories list
        res.status(200).json([]);
    }
    async getRecommendedOpportunities(req, res) {
        // TODO: implement personalized recommendations
        res.status(200).json([]);
    }
    async getMediaEvents(req, res) {
        // TODO: implement media events listing
        res.status(200).json([]);
    }
    async getInvites(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data, error } = await supabase_1.supabase
                .from('campaign_invites')
                .select('*')
                .eq('influencer_id', influencerId);
            if (error) {
                return res.status(500).json({ error: error.message });
            }
            res.status(200).json(data);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async acceptInvite(req, res) {
        try {
            const influencerId = req.user?.id;
            const inviteId = req.params.inviteId;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data, error } = await supabase_1.supabase
                .from('campaign_invites')
                .update({ status: 'accepted' })
                .eq('id', inviteId)
                .eq('influencer_id', influencerId)
                .select()
                .single();
            if (error) {
                return res.status(500).json({ error: error.message });
            }
            res.status(200).json(data);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async declineInvite(req, res) {
        try {
            const influencerId = req.user?.id;
            const inviteId = req.params.inviteId;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data, error } = await supabase_1.supabase
                .from('campaign_invites')
                .update({ status: 'rejected' })
                .eq('id', inviteId)
                .eq('influencer_id', influencerId)
                .select()
                .single();
            if (error) {
                return res.status(500).json({ error: error.message });
            }
            res.status(200).json(data);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getAllCampaigns(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data, error } = await supabase_1.supabase
                .from('campaign_applications')
                .select('*')
                .eq('influencer_id', influencerId);
            if (error) {
                return res.status(500).json({ error: error.message });
            }
            res.status(200).json(data);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getCampaignDetails(req, res) {
        try {
            const influencerId = req.user?.id;
            const campaignId = req.params.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const { data: application, error: appError } = await supabase_1.supabase
                .from('campaign_applications')
                .select('*')
                .eq('influencer_id', influencerId)
                .eq('campaign_id', campaignId)
                .single();
            if (appError || !application) {
                return res.status(404).json({ error: 'Application not found' });
            }
            const { data: campaign, error: campError } = await supabase_1.supabase
                .from('campaigns')
                .select('*')
                .eq('id', campaignId)
                .single();
            if (campError || !campaign) {
                return res.status(404).json({ error: 'Campaign not found' });
            }
            res.status(200).json({ application, campaign });
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async withdrawApplication(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const campaignId = req.params.id;
            const { data, error } = await supabase_1.supabase
                .from('campaign_applications')
                .update({ status: 'withdrawn', updated_at: new Date().toISOString() })
                .eq('campaign_id', campaignId)
                .eq('influencer_id', influencerId)
                .eq('status', 'pending')
                .select()
                .single();
            if (error || !data) {
                return res.status(404).json({ error: 'Application not found or cannot be withdrawn' });
            }
            return res.status(200).json({ message: 'Application withdrawn', application: data });
        }
        catch (err) {
            console.error(err);
            return res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getPendingCampaigns(req, res) {
        // TODO: implement pending campaigns retrieval
        res.status(200).json([]);
    }
    async getConversations(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const conversations = await this.conversationService.getUserConversations(influencerId, 'influencer');
            res.status(200).json(conversations);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getMessages(req, res) {
        try {
            const influencerId = req.user?.id;
            const conversationId = req.params.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const messages = await this.conversationService.getMessagesByConversationId(conversationId);
            res.status(200).json(messages);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async sendMessage(req, res) {
        try {
            const influencerId = req.user?.id;
            const conversationId = req.params.id;
            const { content } = req.body;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            if (!content) {
                return res.status(400).json({ error: 'Content required' });
            }
            const message = await this.conversationService.sendMessage(conversationId, influencerId, content);
            res.status(201).json(message);
        }
        catch (err) {
            console.error(err);
            res.status(500).json({ error: err.message || 'Internal server error' });
        }
    }
    // Authentication & Profile Management
    async register(req, res) {
        try {
            const { email, password, firstName, lastName, username, niche, platforms } = req.body;
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
                        user_type: 'influencer',
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
                userType: 'influencer',
                firstName,
                lastName,
                username
            });
            if (!user) {
                return res.status(500).json({ error: 'Failed to create user profile' });
            }
            // Create influencer profile
            const { data: influencerProfile, error: influencerError } = await supabase_1.supabase
                .from('influencer_profiles')
                .insert([{
                    user_id: authData.user.id,
                    niche,
                    platforms: platforms || [],
                    followers: 0,
                    engagement_rate: 0
                }])
                .select()
                .single();
            if (influencerError) {
                console.error('Influencer profile creation error:', influencerError);
                return res.status(500).json({ error: 'Failed to create influencer profile' });
            }
            res.status(201).json({
                message: 'Influencer registered successfully',
                user: {
                    id: user.id,
                    email: user.email,
                    userType: user.userType,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    username: user.username
                },
                influencerProfile: {
                    id: influencerProfile.id,
                    niche: influencerProfile.niche,
                    platforms: influencerProfile.platforms,
                    followers: influencerProfile.followers,
                    engagementRate: influencerProfile.engagement_rate
                },
                session: authData.session
            });
        }
        catch (error) {
            console.error('Influencer registration error:', error);
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
            // Verify user is an influencer
            if (user.userType !== 'influencer') {
                return res.status(403).json({ error: 'Access denied. Influencer account required.' });
            }
            // Get influencer profile
            const { data: influencerProfile, error: influencerError } = await supabase_1.supabase
                .from('influencer_profiles')
                .select('*')
                .eq('user_id', authData.user.id)
                .single();
            if (influencerError || !influencerProfile) {
                return res.status(404).json({ error: 'Influencer profile not found' });
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
                influencerProfile: {
                    id: influencerProfile.id,
                    niche: influencerProfile.niche,
                    platforms: influencerProfile.platforms,
                    followers: influencerProfile.followers,
                    engagementRate: influencerProfile.engagement_rate,
                    paymentInfo: influencerProfile.payment_info
                },
                session: authData.session
            });
        }
        catch (error) {
            console.error('Influencer login error:', error);
            res.status(500).json({ error: 'Internal server error during login' });
        }
    }
    async getProfile(req, res) {
        // TODO: implement get influencer profile
        res.status(200).json({});
    }
    async updateProfile(req, res) {
        // TODO: implement update influencer profile
        res.status(200).json({});
    }
    async uploadProfileImage(req, res) {
        // TODO: implement profile image upload
        res.status(200).json({});
    }
    async updateSocialLinks(req, res) {
        // TODO: implement social links update
        res.status(200).json({});
    }
    async submitContent(req, res) {
        try {
            const influencerId = req.user?.id;
            const campaignId = req.params.id;
            const { contentUrl, description, platform } = req.body;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            if (!contentUrl) {
                return res.status(400).json({ error: 'Content URL is required' });
            }
            // Check if influencer is accepted for this campaign
            const { data: application, error: appError } = await supabase_1.supabase
                .from('campaign_applications')
                .select('status')
                .eq('influencer_id', influencerId)
                .eq('campaign_id', campaignId)
                .eq('status', 'accepted')
                .single();
            if (appError || !application) {
                return res.status(403).json({ error: 'Not authorized for this campaign' });
            }
            // Detect platform from URL if not provided
            let detectedPlatform = platform;
            if (!detectedPlatform) {
                if (contentUrl.includes('instagram.com'))
                    detectedPlatform = 'Instagram';
                else if (contentUrl.includes('tiktok.com'))
                    detectedPlatform = 'TikTok';
                else if (contentUrl.includes('youtube.com') || contentUrl.includes('youtu.be'))
                    detectedPlatform = 'YouTube';
                else if (contentUrl.includes('facebook.com'))
                    detectedPlatform = 'Facebook';
                else if (contentUrl.includes('twitter.com') || contentUrl.includes('x.com'))
                    detectedPlatform = 'Twitter/X';
                else if (contentUrl.includes('linkedin.com'))
                    detectedPlatform = 'LinkedIn';
                else if (contentUrl.includes('snapchat.com'))
                    detectedPlatform = 'Snapchat';
                else if (contentUrl.includes('pinterest.com'))
                    detectedPlatform = 'Pinterest';
                else if (contentUrl.includes('medium.com'))
                    detectedPlatform = 'Medium';
                else if (contentUrl.includes('substack.com'))
                    detectedPlatform = 'Substack';
                else if (contentUrl.includes('spotify.com'))
                    detectedPlatform = 'Spotify';
                else if (contentUrl.includes('twitch.tv'))
                    detectedPlatform = 'Twitch';
                else
                    detectedPlatform = 'Other';
            }
            // Determine content type
            let contentType = 'post';
            if (contentUrl.includes('/reel/') || contentUrl.includes('/reels/'))
                contentType = 'reel';
            else if (contentUrl.includes('/stories/') || contentUrl.includes('/story/'))
                contentType = 'story';
            else if (contentUrl.includes('youtube.com/watch') || contentUrl.includes('youtu.be/'))
                contentType = 'video';
            else if (contentUrl.includes('youtube.com/shorts/'))
                contentType = 'short';
            else if (contentUrl.includes('tiktok.com/'))
                contentType = 'video';
            else if (contentUrl.includes('/article/') || contentUrl.includes('/p/'))
                contentType = 'article';
            // Submit content
            const { data: submission, error: submissionError } = await supabase_1.supabase
                .from('content_submissions')
                .insert([{
                    campaign_id: campaignId,
                    influencer_id: influencerId,
                    content_url: contentUrl,
                    content_type: contentType,
                    platform: detectedPlatform,
                    description,
                    status: 'pending'
                }])
                .select()
                .single();
            if (submissionError) {
                console.error('Content submission error:', submissionError);
                return res.status(500).json({ error: 'Failed to submit content' });
            }
            res.status(201).json({
                message: 'Content submitted successfully',
                submission: {
                    id: submission.id,
                    contentUrl: submission.content_url,
                    contentType: submission.content_type,
                    platform: submission.platform,
                    description: submission.description,
                    status: submission.status,
                    submittedAt: submission.submitted_at
                }
            });
        }
        catch (error) {
            console.error('Submit content error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getCampaignPerformance(req, res) {
        // TODO: implement campaign performance retrieval
        res.status(200).json({});
    }
    async generateCode(req, res) {
        // TODO: implement QR code generation
        res.status(200).json({});
    }
    async generateDeeplink(req, res) {
        try {
            const influencerId = req.user?.id;
            const campaignId = req.params.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Check if influencer is accepted for this campaign
            const { data: application, error: appError } = await supabase_1.supabase
                .from('campaign_applications')
                .select('status')
                .eq('influencer_id', influencerId)
                .eq('campaign_id', campaignId)
                .eq('status', 'accepted')
                .single();
            if (appError || !application) {
                return res.status(403).json({ error: 'Not authorized for this campaign' });
            }
            // Get campaign details
            const { data: campaign, error: campaignError } = await supabase_1.supabase
                .from('campaigns')
                .select('title, business_id')
                .eq('id', campaignId)
                .single();
            if (campaignError || !campaign) {
                return res.status(404).json({ error: 'Campaign not found' });
            }
            // Generate deep link
            const baseUrl = process.env.APP_BASE_URL || 'https://app.collabuu.com';
            const deepLink = `${baseUrl}/campaign?id=${campaignId}&ref=${influencerId}&utm_source=influencer&utm_medium=referral&utm_campaign=${campaignId}`;
            // Track deep link generation
            await supabase_1.supabase
                .from('influencer_links')
                .insert([{
                    influencer_id: influencerId,
                    campaign_id: campaignId,
                    link_type: 'deep_link',
                    link_url: deepLink,
                    generated_at: new Date().toISOString()
                }]);
            res.json({
                deepLink,
                campaignId,
                campaignTitle: campaign.title,
                shareText: `Check out this amazing deal from ${campaign.title}! ${deepLink}`,
                socialShareUrls: {
                    facebook: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(deepLink)}`,
                    twitter: `https://twitter.com/intent/tweet?url=${encodeURIComponent(deepLink)}&text=${encodeURIComponent(`Check out this amazing deal from ${campaign.title}!`)}`,
                    instagram: deepLink, // Instagram doesn't support URL sharing, just provide the link
                    linkedin: `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(deepLink)}`
                }
            });
        }
        catch (error) {
            console.error('Generate deep link error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getCampaignVisits(req, res) {
        // TODO: implement visit history retrieval
        res.status(200).json([]);
    }
    async getReferralCode(req, res) {
        try {
            const influencerId = req.user?.id;
            const campaignId = req.params.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Check if influencer is accepted for this campaign
            const { data: application, error: appError } = await supabase_1.supabase
                .from('campaign_applications')
                .select('status')
                .eq('influencer_id', influencerId)
                .eq('campaign_id', campaignId)
                .eq('status', 'accepted')
                .single();
            if (appError || !application) {
                return res.status(403).json({ error: 'Not authorized for this campaign' });
            }
            // Check if referral code already exists
            const { data: existingReferral, error: existingError } = await supabase_1.supabase
                .from('influencer_referrals')
                .select('referral_code')
                .eq('influencer_id', influencerId)
                .eq('campaign_id', campaignId)
                .single();
            if (existingReferral) {
                return res.json({
                    referralCode: existingReferral.referral_code,
                    campaignId
                });
            }
            // Generate new referral code
            const referralCode = `${influencerId.slice(0, 8)}-${campaignId.slice(0, 8)}-${Date.now().toString(36)}`.toUpperCase();
            // Save referral code
            const { data: newReferral, error: referralError } = await supabase_1.supabase
                .from('influencer_referrals')
                .insert([{
                    influencer_id: influencerId,
                    campaign_id: campaignId,
                    referral_code: referralCode
                }])
                .select()
                .single();
            if (referralError) {
                console.error('Referral code creation error:', referralError);
                return res.status(500).json({ error: 'Failed to generate referral code' });
            }
            res.json({
                referralCode: newReferral.referral_code,
                campaignId
            });
        }
        catch (error) {
            console.error('Get referral code error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getMediaEventDetails(req, res) {
        // TODO: implement media event details
        res.status(200).json({});
    }
    async checkinMediaEvent(req, res) {
        // TODO: implement media event check-in
        res.status(200).json({});
    }
    async submitInfluencerContent(req, res) {
        // TODO: implement influencer content submission
        res.status(200).json({});
    }
    async getContentHistory(req, res) {
        // TODO: implement content history retrieval
        res.status(200).json([]);
    }
    async getContentDetails(req, res) {
        // TODO: implement content details retrieval
        res.status(200).json({});
    }
    async updateContent(req, res) {
        // TODO: implement content update
        res.status(200).json({});
    }
    async deleteContent(req, res) {
        // TODO: implement content deletion
        res.status(200).json({});
    }
    async getContentPlatforms(req, res) {
        // TODO: implement content platforms listing
        res.status(200).json([]);
    }
    async getPerformanceOverview(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Get all accepted campaigns for this influencer
            const { data: acceptedCampaigns, error: campaignsError } = await supabase_1.supabase
                .from('campaign_applications')
                .select(`
          campaign_id,
          campaigns!inner(
            id, title, campaign_type, credits_per_action, status,
            business_id, user_profiles!inner(first_name, last_name)
          )
        `)
                .eq('influencer_id', influencerId)
                .eq('status', 'accepted');
            if (campaignsError) {
                console.error('Campaigns fetch error:', campaignsError);
                return res.status(500).json({ error: 'Failed to fetch campaigns' });
            }
            // Get all visits for this influencer
            const { data: visits, error: visitsError } = await supabase_1.supabase
                .from('visits')
                .select('campaign_id, status, credits_earned, visit_date')
                .eq('influencer_id', influencerId);
            if (visitsError) {
                console.error('Visits fetch error:', visitsError);
                return res.status(500).json({ error: 'Failed to fetch visits' });
            }
            // Get all content submissions
            const { data: submissions, error: submissionsError } = await supabase_1.supabase
                .from('content_submissions')
                .select('campaign_id, status, submitted_at')
                .eq('influencer_id', influencerId);
            if (submissionsError) {
                console.error('Submissions fetch error:', submissionsError);
                return res.status(500).json({ error: 'Failed to fetch submissions' });
            }
            // Get referral link clicks
            const { data: links, error: linksError } = await supabase_1.supabase
                .from('influencer_links')
                .select('clicks, campaign_id')
                .eq('influencer_id', influencerId);
            if (linksError) {
                console.error('Links fetch error:', linksError);
                return res.status(500).json({ error: 'Failed to fetch link data' });
            }
            // Calculate overall metrics
            const totalCampaigns = acceptedCampaigns?.length || 0;
            const totalVisits = visits?.length || 0;
            const approvedVisits = visits?.filter(v => v.status === 'approved').length || 0;
            const pendingVisits = visits?.filter(v => v.status === 'pending').length || 0;
            const totalCreditsEarned = visits?.reduce((sum, v) => sum + (v.credits_earned || 0), 0) || 0;
            const totalClicks = links?.reduce((sum, l) => sum + (l.clicks || 0), 0) || 0;
            const totalSubmissions = submissions?.length || 0;
            const approvedSubmissions = submissions?.filter(s => s.status === 'approved').length || 0;
            // Recent activity (last 30 days)
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            const recentVisits = visits?.filter(v => new Date(v.visit_date) >= thirtyDaysAgo).length || 0;
            const recentSubmissions = submissions?.filter(s => new Date(s.submitted_at) >= thirtyDaysAgo).length || 0;
            // Campaign performance breakdown
            const campaignPerformance = acceptedCampaigns?.map(app => {
                const campaign = app.campaigns;
                const campaignVisits = visits?.filter(v => v.campaign_id === campaign.id) || [];
                const campaignSubmissions = submissions?.filter(s => s.campaign_id === campaign.id) || [];
                const campaignClicks = links?.filter(l => l.campaign_id === campaign.id).reduce((sum, l) => sum + (l.clicks || 0), 0) || 0;
                return {
                    campaignId: campaign.id,
                    title: campaign.title,
                    type: campaign.campaign_type,
                    businessName: `${campaign.user_profiles.first_name} ${campaign.user_profiles.last_name}`,
                    visits: campaignVisits.length,
                    approvedVisits: campaignVisits.filter(v => v.status === 'approved').length,
                    creditsEarned: campaignVisits.reduce((sum, v) => sum + (v.credits_earned || 0), 0),
                    submissions: campaignSubmissions.length,
                    approvedSubmissions: campaignSubmissions.filter(s => s.status === 'approved').length,
                    clicks: campaignClicks,
                    conversionRate: campaignClicks > 0 ? ((campaignVisits.filter(v => v.status === 'approved').length / campaignClicks) * 100).toFixed(1) : '0.0'
                };
            }) || [];
            res.status(200).json({
                overview: {
                    totalCampaigns,
                    totalVisits,
                    approvedVisits,
                    pendingVisits,
                    totalCreditsEarned,
                    totalClicks,
                    totalSubmissions,
                    approvedSubmissions,
                    conversionRate: totalClicks > 0 ? `${((approvedVisits / totalClicks) * 100).toFixed(1)}%` : '0.0%',
                    contentApprovalRate: totalSubmissions > 0 ? `${((approvedSubmissions / totalSubmissions) * 100).toFixed(1)}%` : '0.0%'
                },
                recentActivity: {
                    visitsLast30Days: recentVisits,
                    submissionsLast30Days: recentSubmissions
                },
                campaignPerformance
            });
        }
        catch (error) {
            console.error('Get performance overview error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    async getPerformanceEarnings(req, res) {
        try {
            const influencerId = req.user?.id;
            if (!influencerId) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            // Get all visits with earnings
            const { data: visits, error: visitsError } = await supabase_1.supabase
                .from('visits')
                .select(`
          id, campaign_id, credits_earned, visit_date, approved_at, status,
          campaigns!inner(
            title, campaign_type, credits_per_action,
            business_id, user_profiles!inner(first_name, last_name)
          )
        `)
                .eq('influencer_id', influencerId)
                .order('visit_date', { ascending: false });
            if (visitsError) {
                console.error('Visits fetch error:', visitsError);
                return res.status(500).json({ error: 'Failed to fetch visits' });
            }
            // Calculate earnings by time period
            const now = new Date();
            const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
            const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
            const thisYear = new Date(now.getFullYear(), 0, 1);
            const approvedVisits = visits?.filter(v => v.status === 'approved') || [];
            const thisMonthEarnings = approvedVisits
                .filter(v => new Date(v.approved_at || v.visit_date) >= thisMonth)
                .reduce((sum, v) => sum + (v.credits_earned || 0), 0);
            const lastMonthEarnings = approvedVisits
                .filter(v => {
                const date = new Date(v.approved_at || v.visit_date);
                return date >= lastMonth && date < thisMonth;
            })
                .reduce((sum, v) => sum + (v.credits_earned || 0), 0);
            const thisYearEarnings = approvedVisits
                .filter(v => new Date(v.approved_at || v.visit_date) >= thisYear)
                .reduce((sum, v) => sum + (v.credits_earned || 0), 0);
            const totalEarnings = approvedVisits.reduce((sum, v) => sum + (v.credits_earned || 0), 0);
            const pendingEarnings = visits?.filter(v => v.status === 'pending').reduce((sum, v) => sum + (v.credits_earned || 0), 0) || 0;
            // Earnings by campaign type
            const earningsByCampaignType = approvedVisits.reduce((acc, visit) => {
                const type = visit.campaigns.campaign_type;
                if (!acc[type]) {
                    acc[type] = { earnings: 0, visits: 0 };
                }
                acc[type].earnings += visit.credits_earned || 0;
                acc[type].visits += 1;
                return acc;
            }, {});
            // Monthly earnings breakdown (last 12 months)
            const monthlyEarnings = [];
            for (let i = 11; i >= 0; i--) {
                const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
                const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
                const monthEarnings = approvedVisits
                    .filter(v => {
                    const date = new Date(v.approved_at || v.visit_date);
                    return date >= monthStart && date <= monthEnd;
                })
                    .reduce((sum, v) => sum + (v.credits_earned || 0), 0);
                monthlyEarnings.push({
                    month: monthStart.toLocaleDateString('en-US', { year: 'numeric', month: 'short' }),
                    earnings: monthEarnings,
                    visits: approvedVisits.filter(v => {
                        const date = new Date(v.approved_at || v.visit_date);
                        return date >= monthStart && date <= monthEnd;
                    }).length
                });
            }
            // Recent earnings transactions
            const recentEarnings = approvedVisits.slice(0, 20).map(visit => ({
                id: visit.id,
                campaignTitle: visit.campaigns.title,
                campaignType: visit.campaigns.campaign_type,
                businessName: `${visit.campaigns.user_profiles.first_name} ${visit.campaigns.user_profiles.last_name}`,
                creditsEarned: visit.credits_earned,
                visitDate: visit.visit_date,
                approvedAt: visit.approved_at
            }));
            res.status(200).json({
                summary: {
                    totalEarnings,
                    pendingEarnings,
                    thisMonthEarnings,
                    lastMonthEarnings,
                    thisYearEarnings,
                    monthlyGrowth: lastMonthEarnings > 0 ?
                        `${(((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100).toFixed(1)}%` :
                        thisMonthEarnings > 0 ? '+100%' : '0%'
                },
                earningsByCampaignType,
                monthlyEarnings,
                recentEarnings
            });
        }
        catch (error) {
            console.error('Get performance earnings error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
    // Extended Messaging
    async getConversationByCampaign(req, res) {
        // TODO: implement conversation retrieval by campaign
        res.status(200).json([]);
    }
    async getConversationCampaignStatus(req, res) {
        // TODO: implement campaign status check for messaging
        res.status(200).json({ allowed: false });
    }
    // Credits & Withdrawals
    async getCreditBalance(req, res) {
        // TODO: implement credit balance retrieval
        res.status(200).json({ balance: 0 });
    }
    async getCreditHistory(req, res) {
        // TODO: implement credit transaction history retrieval
        res.status(200).json([]);
    }
    async withdrawCredits(req, res) {
        // TODO: implement credit withdrawal request
        res.status(200).json({});
    }
    async getWithdrawalHistory(req, res) {
        // TODO: implement withdrawal history retrieval
        res.status(200).json([]);
    }
    // Advanced Wallet & Payment Management
    async getWalletBalance(req, res) {
        // TODO: implement wallet balance retrieval
        res.status(200).json({ balance: 0 });
    }
    async getWalletTransactions(req, res) {
        // TODO: implement wallet transactions history
        res.status(200).json([]);
    }
    async createWalletWithdrawal(req, res) {
        // TODO: implement wallet withdrawal creation
        res.status(200).json({});
    }
    async getWalletWithdrawal(req, res) {
        // TODO: implement single wallet withdrawal retrieval
        res.status(200).json({});
    }
    async cancelWalletWithdrawal(req, res) {
        // TODO: implement cancellation of wallet withdrawal
        res.status(200).json({});
    }
    async getWalletPaymentMethods(req, res) {
        // TODO: implement retrieval of payment methods
        res.status(200).json([]);
    }
    async addWalletPaymentMethod(req, res) {
        // TODO: implement adding a new payment method
        res.status(200).json({});
    }
    async removeWalletPaymentMethod(req, res) {
        // TODO: implement removal of a payment method
        res.status(200).json({});
    }
    // Profile Verification & Statistics
    async requestProfileVerification(req, res) {
        // TODO: implement influencer profile verification request
        res.status(200).json({});
    }
    async getProfileVerificationStatus(req, res) {
        // TODO: implement retrieval of verification status
        res.status(200).json({ verified: false });
    }
    async getProfileStats(req, res) {
        // TODO: implement influencer statistics retrieval
        res.status(200).json({ followers: 0, engagement: {} });
    }
    // Advanced Messaging Enhancements
    async getUnreadMessageCount(req, res) {
        // TODO: implement unread message count retrieval
        res.status(200).json({ unread: 0 });
    }
    async setTypingIndicator(req, res) {
        // TODO: implement typing indicator update
        res.status(200).json({});
    }
    // Analytics & Dashboard
    async getDashboardSummary(req, res) {
        // TODO: implement dashboard summary retrieval
        res.status(200).json({});
    }
    async getDashboardChartData(req, res) {
        // TODO: implement dashboard chart data retrieval
        res.status(200).json({});
    }
    // Search & Discovery
    async search(req, res) {
        // TODO: implement universal search
        res.status(200).json([]);
    }
    async getSearchHistory(req, res) {
        // TODO: implement retrieval of search history
        res.status(200).json([]);
    }
    async clearSearchHistory(req, res) {
        // TODO: implement clearing search history
        res.status(200).json({});
    }
}
exports.InfluencerRouter = InfluencerRouter;
//# sourceMappingURL=influencer.js.map
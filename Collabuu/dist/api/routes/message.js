"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageRouter = void 0;
const express_1 = __importDefault(require("express"));
const supabase_1 = require("../../config/supabase");
const auth_1 = require("../../middleware/auth");
class MessageRouter {
    constructor() {
        this.router = express_1.default.Router();
        // Generic messaging endpoints
        this.router.get('/conversations', auth_1.authenticateToken, this.getConversations.bind(this));
        this.router.get('/conversations/:id', auth_1.authenticateToken, this.getConversationById.bind(this));
        this.router.get('/conversations/:id/messages', auth_1.authenticateToken, this.getMessages.bind(this));
        this.router.post('/conversations/:id/messages', auth_1.authenticateToken, this.sendMessage.bind(this));
    }
    async getConversations(req, res) {
        try {
            const userId = req.user.id;
            const userType = req.user.user_type;
            const { limit = 20, offset = 0 } = req.query;
            let query = supabase_1.supabase
                .from('conversations')
                .select(`
          id, campaign_id, business_id, influencer_id, status, created_at, updated_at,
          campaigns!inner(id, title, campaign_type, status),
          business_profiles!inner(id, business_name, logo_url),
          influencer_profiles!inner(id, username, profile_image_url),
          messages(id, content, sender_type, created_at)
        `);
            // Filter based on user type
            if (userType === 'business') {
                query = query.eq('business_id', userId);
            }
            else if (userType === 'influencer') {
                query = query.eq('influencer_id', userId);
            }
            else {
                // Customers don't have direct conversations in this system
                return res.status(403).json({ error: 'Customers cannot access conversations' });
            }
            // Apply pagination and ordering
            query = query
                .range(Number(offset), Number(offset) + Number(limit) - 1)
                .order('updated_at', { ascending: false });
            const { data: conversations, error } = await query;
            if (error) {
                console.error('Get conversations error:', error);
                return res.status(500).json({ error: 'Failed to retrieve conversations' });
            }
            // Format conversations with last message
            const formattedConversations = conversations?.map(conv => ({
                id: conv.id,
                campaign: {
                    id: conv.campaigns.id,
                    title: conv.campaigns.title,
                    type: conv.campaigns.campaign_type,
                    status: conv.campaigns.status
                },
                business: {
                    id: conv.business_profiles.id,
                    name: conv.business_profiles.business_name,
                    logo: conv.business_profiles.logo_url
                },
                influencer: {
                    id: conv.influencer_profiles.id,
                    username: conv.influencer_profiles.username,
                    profileImage: conv.influencer_profiles.profile_image_url
                },
                status: conv.status,
                lastMessage: conv.messages && conv.messages.length > 0 ? {
                    content: conv.messages[0].content,
                    senderType: conv.messages[0].sender_type,
                    createdAt: conv.messages[0].created_at
                } : null,
                createdAt: conv.created_at,
                updatedAt: conv.updated_at
            })) || [];
            res.status(200).json({
                conversations: formattedConversations,
                total: formattedConversations.length
            });
        }
        catch (error) {
            console.error('Get conversations error:', error);
            res.status(500).json({ error: 'Failed to retrieve conversations' });
        }
    }
    async getConversationById(req, res) {
        try {
            const { id } = req.params;
            const userId = req.user.id;
            const userType = req.user.user_type;
            if (!id) {
                return res.status(400).json({ error: 'Conversation ID is required' });
            }
            let query = supabase_1.supabase
                .from('conversations')
                .select(`
          id, campaign_id, business_id, influencer_id, status, created_at, updated_at,
          campaigns!inner(id, title, description, campaign_type, status, start_date, end_date),
          business_profiles!inner(id, business_name, description, logo_url, location),
          influencer_profiles!inner(id, username, bio, profile_image_url)
        `)
                .eq('id', id);
            // Apply access control
            if (userType === 'business') {
                query = query.eq('business_id', userId);
            }
            else if (userType === 'influencer') {
                query = query.eq('influencer_id', userId);
            }
            else {
                return res.status(403).json({ error: 'Access denied' });
            }
            const { data: conversation, error } = await query.single();
            if (error || !conversation) {
                return res.status(404).json({ error: 'Conversation not found or access denied' });
            }
            res.status(200).json({
                conversation: {
                    id: conversation.id,
                    campaign: conversation.campaigns,
                    business: conversation.business_profiles,
                    influencer: conversation.influencer_profiles,
                    status: conversation.status,
                    createdAt: conversation.created_at,
                    updatedAt: conversation.updated_at
                }
            });
        }
        catch (error) {
            console.error('Get conversation by ID error:', error);
            res.status(500).json({ error: 'Failed to retrieve conversation' });
        }
    }
    async getMessages(req, res) {
        try {
            const { id } = req.params;
            const userId = req.user.id;
            const userType = req.user.user_type;
            const { limit = 50, offset = 0 } = req.query;
            if (!id) {
                return res.status(400).json({ error: 'Conversation ID is required' });
            }
            // First verify access to conversation
            let accessQuery = supabase_1.supabase
                .from('conversations')
                .select('id, business_id, influencer_id')
                .eq('id', id);
            if (userType === 'business') {
                accessQuery = accessQuery.eq('business_id', userId);
            }
            else if (userType === 'influencer') {
                accessQuery = accessQuery.eq('influencer_id', userId);
            }
            else {
                return res.status(403).json({ error: 'Access denied' });
            }
            const { data: conversation, error: accessError } = await accessQuery.single();
            if (accessError || !conversation) {
                return res.status(404).json({ error: 'Conversation not found or access denied' });
            }
            // Get messages
            const { data: messages, error } = await supabase_1.supabase
                .from('messages')
                .select(`
          id, conversation_id, sender_id, sender_type, content, 
          is_read, created_at, updated_at
        `)
                .eq('conversation_id', id)
                .range(Number(offset), Number(offset) + Number(limit) - 1)
                .order('created_at', { ascending: true });
            if (error) {
                console.error('Get messages error:', error);
                return res.status(500).json({ error: 'Failed to retrieve messages' });
            }
            // Mark messages as read for the current user
            const unreadMessages = messages?.filter(msg => !msg.is_read && msg.sender_id !== userId);
            if (unreadMessages && unreadMessages.length > 0) {
                await supabase_1.supabase
                    .from('messages')
                    .update({ is_read: true })
                    .in('id', unreadMessages.map(msg => msg.id));
            }
            res.status(200).json({
                messages: messages || [],
                total: messages?.length || 0
            });
        }
        catch (error) {
            console.error('Get messages error:', error);
            res.status(500).json({ error: 'Failed to retrieve messages' });
        }
    }
    async sendMessage(req, res) {
        try {
            const { id } = req.params;
            const userId = req.user.id;
            const userType = req.user.user_type;
            const { content } = req.body;
            if (!id) {
                return res.status(400).json({ error: 'Conversation ID is required' });
            }
            if (!content || typeof content !== 'string' || content.trim().length === 0) {
                return res.status(400).json({ error: 'Message content is required' });
            }
            // Verify access to conversation and check if it's active
            let accessQuery = supabase_1.supabase
                .from('conversations')
                .select(`
          id, business_id, influencer_id, status,
          campaigns!inner(id, status, end_date)
        `)
                .eq('id', id);
            if (userType === 'business') {
                accessQuery = accessQuery.eq('business_id', userId);
            }
            else if (userType === 'influencer') {
                accessQuery = accessQuery.eq('influencer_id', userId);
            }
            else {
                return res.status(403).json({ error: 'Access denied' });
            }
            const { data: conversation, error: accessError } = await accessQuery.single();
            if (accessError || !conversation) {
                return res.status(404).json({ error: 'Conversation not found or access denied' });
            }
            // Check if conversation is still active
            if (conversation.status !== 'active') {
                return res.status(400).json({ error: 'Cannot send messages to inactive conversation' });
            }
            // Check if campaign is still active
            const campaign = conversation.campaigns;
            const now = new Date();
            const endDate = new Date(campaign.end_date);
            if (campaign.status !== 'active' || now > endDate) {
                return res.status(400).json({ error: 'Cannot send messages after campaign has ended' });
            }
            // Send message
            const { data: message, error } = await supabase_1.supabase
                .from('messages')
                .insert([{
                    conversation_id: id,
                    sender_id: userId,
                    sender_type: userType,
                    content: content.trim(),
                    is_read: false
                }])
                .select()
                .single();
            if (error) {
                console.error('Send message error:', error);
                return res.status(500).json({ error: 'Failed to send message' });
            }
            // Update conversation updated_at
            await supabase_1.supabase
                .from('conversations')
                .update({ updated_at: new Date().toISOString() })
                .eq('id', id);
            res.status(201).json({
                message: {
                    id: message.id,
                    conversationId: message.conversation_id,
                    senderId: message.sender_id,
                    senderType: message.sender_type,
                    content: message.content,
                    isRead: message.is_read,
                    createdAt: message.created_at
                }
            });
        }
        catch (error) {
            console.error('Send message error:', error);
            res.status(500).json({ error: 'Failed to send message' });
        }
    }
}
exports.MessageRouter = MessageRouter;
//# sourceMappingURL=message.js.map
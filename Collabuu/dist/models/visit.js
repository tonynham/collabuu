"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VisitService = void 0;
class VisitService {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
    }
    async getVisitById(id) {
        const { data, error } = await this.supabase
            .from('visits')
            .select('*')
            .eq('id', id)
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbVisitToVisit(data);
    }
    async getVisitsByBusiness(businessId, filters) {
        let query = this.supabase
            .from('visits')
            .select('*')
            .eq('business_id', businessId);
        if (filters?.status) {
            query = query.eq('status', filters.status);
        }
        if (filters?.startDate) {
            query = query.gte('created_at', filters.startDate.toISOString());
        }
        if (filters?.endDate) {
            query = query.lte('created_at', filters.endDate.toISOString());
        }
        const { data, error } = await query.order('created_at', { ascending: false });
        if (error || !data) {
            return [];
        }
        return data.map(this.mapDbVisitToVisit);
    }
    async getVisitsByCampaign(campaignId) {
        const { data, error } = await this.supabase
            .from('visits')
            .select('*')
            .eq('campaign_id', campaignId)
            .order('created_at', { ascending: false });
        if (error || !data) {
            return [];
        }
        return data.map(this.mapDbVisitToVisit);
    }
    async getVisitsByInfluencer(influencerId) {
        const { data, error } = await this.supabase
            .from('visits')
            .select('*')
            .eq('influencer_id', influencerId)
            .order('created_at', { ascending: false });
        if (error || !data) {
            return [];
        }
        return data.map(this.mapDbVisitToVisit);
    }
    async createVisit(visit) {
        const { data, error } = await this.supabase
            .from('visits')
            .insert([{
                campaign_id: visit.campaignId,
                influencer_id: visit.influencerId,
                customer_id: visit.customerId,
                business_id: visit.businessId,
                status: visit.status,
                credits_earned: visit.creditsEarned,
                loyalty_points_earned: visit.loyaltyPointsEarned
            }])
            .select()
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbVisitToVisit(data);
    }
    async approveVisit(id, creditsEarned, loyaltyPointsEarned) {
        const { data, error } = await this.supabase
            .from('visits')
            .update({
            status: 'approved',
            credits_earned: creditsEarned,
            loyalty_points_earned: loyaltyPointsEarned,
            approved_at: new Date().toISOString()
        })
            .eq('id', id)
            .select()
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbVisitToVisit(data);
    }
    async rejectVisit(id) {
        const { data, error } = await this.supabase
            .from('visits')
            .update({
            status: 'rejected'
        })
            .eq('id', id)
            .select()
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbVisitToVisit(data);
    }
    async verifyQrCode(qrCode) {
        // This is a simplified implementation
        // In a real app, QR codes would be stored and validated against stored values
        try {
            // QR code might contain encoded data like "{campaignId}:{influencerId}:{customerId}"
            const [campaignId, influencerId, customerId] = qrCode.split(':');
            if (!campaignId || !influencerId || !customerId) {
                return { isValid: false };
            }
            // Verify the campaign exists and is active
            const { data: campaignData, error: campaignError } = await this.supabase
                .from('campaigns')
                .select('id, status')
                .eq('id', campaignId)
                .eq('status', 'active')
                .single();
            if (campaignError || !campaignData) {
                return { isValid: false };
            }
            return {
                isValid: true,
                campaignId,
                influencerId,
                customerId
            };
        }
        catch (error) {
            return { isValid: false };
        }
    }
    async getVisitStats(businessId, period) {
        // Build query based on period
        let query = this.supabase
            .from('visits')
            .select('*')
            .eq('business_id', businessId);
        if (period?.startDate) {
            query = query.gte('created_at', period.startDate.toISOString());
        }
        if (period?.endDate) {
            query = query.lte('created_at', period.endDate.toISOString());
        }
        const { data, error } = await query;
        if (error || !data) {
            return {
                total: 0,
                approved: 0,
                rejected: 0,
                pending: 0,
                byDay: {},
                byInfluencer: {}
            };
        }
        const visits = data.map(this.mapDbVisitToVisit);
        // Calculate stats
        const byDay = {};
        const byInfluencer = {};
        let approved = 0;
        let rejected = 0;
        let pending = 0;
        for (const visit of visits) {
            // Count by status
            if (visit.status === 'approved')
                approved++;
            if (visit.status === 'rejected')
                rejected++;
            if (visit.status === 'pending')
                pending++;
            // Group by day
            const day = visit.createdAt.toISOString().split('T')[0]; // YYYY-MM-DD
            byDay[day] = (byDay[day] || 0) + 1;
            // Group by influencer
            byInfluencer[visit.influencerId] = (byInfluencer[visit.influencerId] || 0) + 1;
        }
        return {
            total: visits.length,
            approved,
            rejected,
            pending,
            byDay,
            byInfluencer
        };
    }
    // Helper to convert database object to Visit interface
    mapDbVisitToVisit(dbVisit) {
        return {
            id: dbVisit.id,
            campaignId: dbVisit.campaign_id,
            influencerId: dbVisit.influencer_id,
            customerId: dbVisit.customer_id,
            businessId: dbVisit.business_id,
            status: dbVisit.status,
            creditsEarned: dbVisit.credits_earned,
            loyaltyPointsEarned: dbVisit.loyalty_points_earned,
            createdAt: new Date(dbVisit.created_at),
            approvedAt: dbVisit.approved_at ? new Date(dbVisit.approved_at) : undefined
        };
    }
}
exports.VisitService = VisitService;
//# sourceMappingURL=visit.js.map
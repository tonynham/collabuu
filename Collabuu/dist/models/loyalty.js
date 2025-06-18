"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LoyaltyService = void 0;
class LoyaltyService {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
    }
    async getLoyaltyPoints(customerId, businessId) {
        const { data, error } = await this.supabase
            .from('loyalty_points')
            .select('*')
            .eq('customer_id', customerId)
            .eq('business_id', businessId)
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbLoyaltyToLoyalty(data);
    }
    async createOrUpdateLoyaltyPoints(customerId, businessId, pointsToAdd) {
        // Check if loyalty record exists
        const existingLoyalty = await this.getLoyaltyPoints(customerId, businessId);
        if (existingLoyalty) {
            // Update existing record
            const { data, error } = await this.supabase
                .from('loyalty_points')
                .update({
                points_balance: existingLoyalty.pointsBalance + pointsToAdd,
                total_points_earned: existingLoyalty.totalPointsEarned + (pointsToAdd > 0 ? pointsToAdd : 0),
                total_points_spent: existingLoyalty.totalPointsSpent + (pointsToAdd < 0 ? Math.abs(pointsToAdd) : 0),
                updated_at: new Date().toISOString()
            })
                .eq('id', existingLoyalty.id)
                .select()
                .single();
            if (error || !data) {
                return null;
            }
            return this.mapDbLoyaltyToLoyalty(data);
        }
        else {
            // Create new record
            const { data, error } = await this.supabase
                .from('loyalty_points')
                .insert([{
                    customer_id: customerId,
                    business_id: businessId,
                    points_balance: pointsToAdd,
                    total_points_earned: pointsToAdd > 0 ? pointsToAdd : 0,
                    total_points_spent: pointsToAdd < 0 ? Math.abs(pointsToAdd) : 0
                }])
                .select()
                .single();
            if (error || !data) {
                return null;
            }
            return this.mapDbLoyaltyToLoyalty(data);
        }
    }
    async addLoyaltyTransaction(loyaltyId, transactionType, pointsAmount, description, referenceId) {
        const { data, error } = await this.supabase
            .from('loyalty_transactions')
            .insert([{
                loyalty_id: loyaltyId,
                transaction_type: transactionType,
                points_amount: pointsAmount,
                description,
                reference_id: referenceId
            }])
            .select()
            .single();
        if (error || !data) {
            return null;
        }
        return {
            id: data.id,
            loyaltyId: data.loyalty_id,
            transactionType: data.transaction_type,
            pointsAmount: data.points_amount,
            description: data.description,
            referenceId: data.reference_id,
            createdAt: new Date(data.created_at)
        };
    }
    async getCustomerLoyaltyTransactions(customerId, businessId) {
        // First get all loyalty IDs for the customer
        let loyaltyQuery = this.supabase
            .from('loyalty_points')
            .select('id')
            .eq('customer_id', customerId);
        if (businessId) {
            loyaltyQuery = loyaltyQuery.eq('business_id', businessId);
        }
        const { data: loyaltyData, error: loyaltyError } = await loyaltyQuery;
        if (loyaltyError || !loyaltyData || loyaltyData.length === 0) {
            return [];
        }
        // Get transactions for all loyalty IDs
        const loyaltyIds = loyaltyData.map(item => item.id);
        const { data: transactionData, error: transactionError } = await this.supabase
            .from('loyalty_transactions')
            .select('*')
            .in('loyalty_id', loyaltyIds)
            .order('created_at', { ascending: false });
        if (transactionError || !transactionData) {
            return [];
        }
        return transactionData.map(item => ({
            id: item.id,
            loyaltyId: item.loyalty_id,
            transactionType: item.transaction_type,
            pointsAmount: item.points_amount,
            description: item.description,
            referenceId: item.reference_id,
            createdAt: new Date(item.created_at)
        }));
    }
    async redeemReward(customerId, businessId, campaignId, pointsToSpend) {
        // Check if customer has enough points
        const loyalty = await this.getLoyaltyPoints(customerId, businessId);
        if (!loyalty || loyalty.pointsBalance < pointsToSpend) {
            throw new Error('Insufficient loyalty points');
        }
        // Create redemption record
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 30); // Expire in 30 days
        // Generate unique QR code
        const qrCode = `${customerId}:${businessId}:${campaignId}:${Date.now()}`;
        const { data: redemptionData, error: redemptionError } = await this.supabase
            .from('reward_redemptions')
            .insert([{
                customer_id: customerId,
                business_id: businessId,
                campaign_id: campaignId,
                points_spent: pointsToSpend,
                status: 'pending',
                qr_code: qrCode,
                expires_at: expiresAt.toISOString()
            }])
            .select()
            .single();
        if (redemptionError || !redemptionData) {
            return null;
        }
        // Deduct points from customer's balance
        await this.createOrUpdateLoyaltyPoints(customerId, businessId, -pointsToSpend);
        // Add transaction record
        await this.addLoyaltyTransaction(loyalty.id, 'spend', pointsToSpend, 'Reward redemption', redemptionData.id);
        return {
            id: redemptionData.id,
            customerId: redemptionData.customer_id,
            businessId: redemptionData.business_id,
            campaignId: redemptionData.campaign_id,
            pointsSpent: redemptionData.points_spent,
            status: redemptionData.status,
            qrCode: redemptionData.qr_code,
            createdAt: new Date(redemptionData.created_at),
            redeemedAt: redemptionData.redeemed_at ? new Date(redemptionData.redeemed_at) : undefined,
            expiresAt: new Date(redemptionData.expires_at)
        };
    }
    async verifyRewardQrCode(qrCode) {
        const { data, error } = await this.supabase
            .from('reward_redemptions')
            .select('*')
            .eq('qr_code', qrCode)
            .eq('status', 'pending')
            .gt('expires_at', new Date().toISOString())
            .single();
        if (error || !data) {
            return null;
        }
        return {
            id: data.id,
            customerId: data.customer_id,
            businessId: data.business_id,
            campaignId: data.campaign_id,
            pointsSpent: data.points_spent,
            status: data.status,
            qrCode: data.qr_code,
            createdAt: new Date(data.created_at),
            redeemedAt: data.redeemed_at ? new Date(data.redeemed_at) : undefined,
            expiresAt: new Date(data.expires_at)
        };
    }
    async approveRewardRedemption(redemptionId) {
        const { data, error } = await this.supabase
            .from('reward_redemptions')
            .update({
            status: 'approved',
            redeemed_at: new Date().toISOString()
        })
            .eq('id', redemptionId)
            .eq('status', 'pending')
            .select()
            .single();
        if (error || !data) {
            return null;
        }
        return {
            id: data.id,
            customerId: data.customer_id,
            businessId: data.business_id,
            campaignId: data.campaign_id,
            pointsSpent: data.points_spent,
            status: data.status,
            qrCode: data.qr_code,
            createdAt: new Date(data.created_at),
            redeemedAt: data.redeemed_at ? new Date(data.redeemed_at) : undefined,
            expiresAt: new Date(data.expires_at)
        };
    }
    async getCustomerRedemptions(customerId, status) {
        let query = this.supabase
            .from('reward_redemptions')
            .select('*')
            .eq('customer_id', customerId);
        if (status) {
            query = query.eq('status', status);
        }
        const { data, error } = await query.order('created_at', { ascending: false });
        if (error || !data) {
            return [];
        }
        return data.map(item => ({
            id: item.id,
            customerId: item.customer_id,
            businessId: item.business_id,
            campaignId: item.campaign_id,
            pointsSpent: item.points_spent,
            status: item.status,
            qrCode: item.qr_code,
            createdAt: new Date(item.created_at),
            redeemedAt: item.redeemed_at ? new Date(item.redeemed_at) : undefined,
            expiresAt: new Date(item.expires_at)
        }));
    }
    async getBusinessRedemptions(businessId, status) {
        let query = this.supabase
            .from('reward_redemptions')
            .select('*')
            .eq('business_id', businessId);
        if (status) {
            query = query.eq('status', status);
        }
        const { data, error } = await query.order('created_at', { ascending: false });
        if (error || !data) {
            return [];
        }
        return data.map(item => ({
            id: item.id,
            customerId: item.customer_id,
            businessId: item.business_id,
            campaignId: item.campaign_id,
            pointsSpent: item.points_spent,
            status: item.status,
            qrCode: item.qr_code,
            createdAt: new Date(item.created_at),
            redeemedAt: item.redeemed_at ? new Date(item.redeemed_at) : undefined,
            expiresAt: new Date(item.expires_at)
        }));
    }
    // Helper to convert database object to LoyaltyPoints interface
    mapDbLoyaltyToLoyalty(dbLoyalty) {
        return {
            id: dbLoyalty.id,
            customerId: dbLoyalty.customer_id,
            businessId: dbLoyalty.business_id,
            pointsBalance: dbLoyalty.points_balance,
            totalPointsEarned: dbLoyalty.total_points_earned,
            totalPointsSpent: dbLoyalty.total_points_spent,
            createdAt: new Date(dbLoyalty.created_at),
            updatedAt: dbLoyalty.updated_at ? new Date(dbLoyalty.updated_at) : undefined
        };
    }
}
exports.LoyaltyService = LoyaltyService;
//# sourceMappingURL=loyalty.js.map
import { SupabaseClient } from '@supabase/supabase-js';
export type TransactionType = 'earn' | 'spend' | 'expire' | 'adjust';
export type RedemptionStatus = 'pending' | 'approved' | 'rejected' | 'expired';
export interface LoyaltyPoints {
    id: string;
    customerId: string;
    businessId: string;
    pointsBalance: number;
    totalPointsEarned: number;
    totalPointsSpent: number;
    createdAt: Date;
    updatedAt?: Date;
}
export interface LoyaltyTransaction {
    id: string;
    loyaltyId: string;
    transactionType: TransactionType;
    pointsAmount: number;
    description?: string;
    referenceId?: string;
    createdAt: Date;
}
export interface RewardRedemption {
    id: string;
    customerId: string;
    businessId: string;
    campaignId: string;
    pointsSpent: number;
    status: RedemptionStatus;
    qrCode: string;
    createdAt: Date;
    redeemedAt?: Date;
    expiresAt: Date;
}
export declare class LoyaltyService {
    private supabase;
    constructor(supabaseClient: SupabaseClient);
    getLoyaltyPoints(customerId: string, businessId: string): Promise<LoyaltyPoints | null>;
    createOrUpdateLoyaltyPoints(customerId: string, businessId: string, pointsToAdd: number): Promise<LoyaltyPoints | null>;
    addLoyaltyTransaction(loyaltyId: string, transactionType: TransactionType, pointsAmount: number, description?: string, referenceId?: string): Promise<LoyaltyTransaction | null>;
    getCustomerLoyaltyTransactions(customerId: string, businessId?: string): Promise<LoyaltyTransaction[]>;
    redeemReward(customerId: string, businessId: string, campaignId: string, pointsToSpend: number): Promise<RewardRedemption | null>;
    verifyRewardQrCode(qrCode: string): Promise<RewardRedemption | null>;
    approveRewardRedemption(redemptionId: string): Promise<RewardRedemption | null>;
    getCustomerRedemptions(customerId: string, status?: RedemptionStatus): Promise<RewardRedemption[]>;
    getBusinessRedemptions(businessId: string, status?: RedemptionStatus): Promise<RewardRedemption[]>;
    private mapDbLoyaltyToLoyalty;
}

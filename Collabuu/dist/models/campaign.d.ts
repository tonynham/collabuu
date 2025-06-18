import { SupabaseClient } from '@supabase/supabase-js';
export type CampaignType = 'pay_per_customer' | 'pay_per_post' | 'media_event' | 'loyalty_reward';
export type CampaignVisibility = 'public' | 'private';
export type CampaignStatus = 'draft' | 'active' | 'paused' | 'completed' | 'cancelled' | 'expired';
export interface Campaign {
    id: string;
    businessId: string;
    title: string;
    description: string;
    campaignType: CampaignType;
    visibility: CampaignVisibility;
    status: CampaignStatus;
    requirements?: string;
    targetCustomers?: number;
    influencerSpots?: number;
    periodStart: Date;
    periodEnd: Date;
    creditsPerAction: number;
    totalCredits: number;
    imageUrl?: string;
    createdAt: Date;
    updatedAt?: Date;
}
export interface CampaignMetrics {
    campaignId: string;
    visits: number;
    submissions: number;
    approved: number;
    rejected: number;
    conversion: number;
    engagementRate: number;
    totalCreditsSpent: number;
    totalLoyaltyPointsIssued: number;
}
export interface CampaignParticipant {
    id: string;
    campaignId: string;
    influencerId: string;
    status: 'pending' | 'active' | 'rejected' | 'completed';
    metrics?: {
        visits: number;
        contentSubmitted: number;
        contentApproved: number;
        creditsEarned: number;
    };
    createdAt: Date;
    updatedAt?: Date;
}
export interface CampaignApplication {
    id: string;
    campaignId: string;
    influencerId: string;
    message?: string;
    status: 'pending' | 'accepted' | 'rejected' | 'withdrawn';
    createdAt: Date;
    updatedAt?: Date;
}
export interface MediaEventDetails {
    id: string;
    campaignId: string;
    eventDate: Date;
    location: string;
    details: string;
    maxParticipants?: number;
    registeredParticipants: number;
    createdAt: Date;
    updatedAt?: Date;
}
export interface LoyaltyRewardDetails {
    id: string;
    campaignId: string;
    pointCost: number;
    rewardType: 'discount' | 'free_item' | 'percentage_off' | 'other';
    rewardValue: number;
    description: string;
    terms?: string;
    createdAt: Date;
    updatedAt?: Date;
}
export declare class CampaignService {
    private supabase;
    constructor(supabaseClient: SupabaseClient);
    getCampaignById(id: string): Promise<Campaign | null>;
    getBusinessCampaigns(businessId: string, filters?: {
        status?: CampaignStatus;
        type?: CampaignType;
    }): Promise<Campaign[]>;
    getPublicCampaigns(filters?: {
        type?: CampaignType;
        category?: string;
    }): Promise<Campaign[]>;
    createCampaign(campaign: Omit<Campaign, 'id' | 'createdAt' | 'updatedAt'>): Promise<Campaign | null>;
    updateCampaign(id: string, updates: Partial<Campaign>): Promise<Campaign | null>;
    deleteCampaign(id: string): Promise<boolean>;
    getCampaignMetrics(campaignId: string): Promise<CampaignMetrics | null>;
    applyCampaign(campaignId: string, influencerId: string, message?: string): Promise<CampaignApplication | null>;
    private mapDbCampaignToCampaign;
}

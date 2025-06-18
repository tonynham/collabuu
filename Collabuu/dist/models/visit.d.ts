import { SupabaseClient } from '@supabase/supabase-js';
export type VisitStatus = 'pending' | 'approved' | 'rejected';
export interface Visit {
    id: string;
    campaignId: string;
    influencerId: string;
    customerId: string;
    businessId: string;
    status: VisitStatus;
    creditsEarned?: number;
    loyaltyPointsEarned?: number;
    createdAt: Date;
    approvedAt?: Date;
}
export interface VisitVerification {
    qrCode: string;
    campaignId: string;
    influencerId: string;
    customerId: string;
    location?: {
        latitude: number;
        longitude: number;
    };
}
export interface VisitStats {
    total: number;
    approved: number;
    rejected: number;
    pending: number;
    byDay: Record<string, number>;
    byInfluencer: Record<string, number>;
}
export declare class VisitService {
    private supabase;
    constructor(supabaseClient: SupabaseClient);
    getVisitById(id: string): Promise<Visit | null>;
    getVisitsByBusiness(businessId: string, filters?: {
        status?: VisitStatus;
        startDate?: Date;
        endDate?: Date;
    }): Promise<Visit[]>;
    getVisitsByCampaign(campaignId: string): Promise<Visit[]>;
    getVisitsByInfluencer(influencerId: string): Promise<Visit[]>;
    createVisit(visit: Omit<Visit, 'id' | 'createdAt' | 'approvedAt'>): Promise<Visit | null>;
    approveVisit(id: string, creditsEarned: number, loyaltyPointsEarned: number): Promise<Visit | null>;
    rejectVisit(id: string): Promise<Visit | null>;
    verifyQrCode(qrCode: string): Promise<{
        isValid: boolean;
        campaignId?: string;
        influencerId?: string;
        customerId?: string;
    }>;
    getVisitStats(businessId: string, period?: {
        startDate: Date;
        endDate: Date;
    }): Promise<VisitStats>;
    private mapDbVisitToVisit;
}

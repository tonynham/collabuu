import { SupabaseClient } from '@supabase/supabase-js';
export interface User {
    id: string;
    email: string;
    userType: 'business' | 'influencer' | 'customer';
    firstName?: string;
    lastName?: string;
    username?: string;
    profileImageUrl?: string;
    bio?: string;
    createdAt: Date;
    updatedAt?: Date;
}
export interface BusinessUser extends User {
    businessProfile: BusinessProfile;
}
export interface InfluencerUser extends User {
    influencerProfile?: InfluencerProfile;
}
export interface CustomerUser extends User {
    customerProfile?: CustomerProfile;
}
export interface BusinessProfile {
    id: string;
    userId: string;
    businessName: string;
    category: string;
    description?: string;
    address?: string;
    phone?: string;
    email?: string;
    hours?: Record<string, any>;
    availableCredits: number;
    estimatedVisits: number;
    website?: string;
    logoUrl?: string;
    isVerified: boolean;
    socialMediaHandles?: Record<string, string>;
    businessHours?: Record<string, any>;
    createdAt: Date;
    updatedAt?: Date;
}
export interface InfluencerProfile {
    id: string;
    userId: string;
    niche?: string;
    followers?: number;
    engagementRate?: number;
    platforms?: string[];
    paymentInfo?: Record<string, any>;
    createdAt: Date;
    updatedAt?: Date;
}
export interface CustomerProfile {
    id: string;
    userId: string;
    preferences?: string[];
    favoriteBusinesses?: string[];
    createdAt: Date;
    updatedAt?: Date;
}
export declare class UserService {
    private supabase;
    constructor(supabaseClient: SupabaseClient);
    getUserById(id: string): Promise<User | null>;
    getUserByEmail(email: string): Promise<User | null>;
    createUser(user: Partial<User>): Promise<User | null>;
    updateUser(id: string, updates: Partial<User>): Promise<User | null>;
    private mapDbUserToUser;
}

import { SupabaseClient } from '@supabase/supabase-js';

// Base User interface
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

// Extended interfaces for different user types
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

// User service for handling user-related operations
export class UserService {
  private supabase: SupabaseClient;

  constructor(supabaseClient: SupabaseClient) {
    this.supabase = supabaseClient;
  }

  async getUserById(id: string): Promise<User | null> {
    const { data, error } = await this.supabase
      .from('user_profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbUserToUser(data);
  }

  async getUserByEmail(email: string): Promise<User | null> {
    const { data, error } = await this.supabase
      .from('user_profiles')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbUserToUser(data);
  }

  async createUser(user: Partial<User>): Promise<User | null> {
    const { data, error } = await this.supabase
      .from('user_profiles')
      .insert([{
        id: user.id,
        email: user.email,
        user_type: user.userType,
        first_name: user.firstName,
        last_name: user.lastName,
        username: user.username,
        profile_image_url: user.profileImageUrl,
        bio: user.bio
      }])
      .select()
      .single();

    if (error || !data) {
      console.error('UserService.createUser error:', error);
      return null;
    }

    return this.mapDbUserToUser(data);
  }

  async updateUser(id: string, updates: Partial<User>): Promise<User | null> {
    const { data, error } = await this.supabase
      .from('user_profiles')
      .update({
        first_name: updates.firstName,
        last_name: updates.lastName,
        username: updates.username,
        profile_image_url: updates.profileImageUrl,
        bio: updates.bio,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbUserToUser(data);
  }

  // Helper to convert database object to User interface
  private mapDbUserToUser(dbUser: any): User {
    return {
      id: dbUser.id,
      email: dbUser.email,
      userType: dbUser.user_type,
      firstName: dbUser.first_name,
      lastName: dbUser.last_name,
      username: dbUser.username,
      profileImageUrl: dbUser.profile_image_url,
      bio: dbUser.bio,
      createdAt: new Date(dbUser.created_at),
      updatedAt: dbUser.updated_at ? new Date(dbUser.updated_at) : undefined
    };
  }
} 
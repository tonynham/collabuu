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
  conversion: number; // Percentage of visits that resulted in a purchase/action
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

export class CampaignService {
  private supabase: SupabaseClient;

  constructor(supabaseClient: SupabaseClient) {
    this.supabase = supabaseClient;
  }

  async getCampaignById(id: string): Promise<Campaign | null> {
    const { data, error } = await this.supabase
      .from('campaigns')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbCampaignToCampaign(data);
  }

  async getBusinessCampaigns(businessId: string, filters?: {
    status?: CampaignStatus,
    type?: CampaignType
  }): Promise<Campaign[]> {
    let query = this.supabase
      .from('campaigns')
      .select('*')
      .eq('business_id', businessId);

    if (filters?.status) {
      query = query.eq('status', filters.status);
    }

    if (filters?.type) {
      query = query.eq('campaign_type', filters.type);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error || !data) {
      return [];
    }

    return data.map(this.mapDbCampaignToCampaign);
  }

  async getPublicCampaigns(filters?: {
    type?: CampaignType,
    category?: string
  }): Promise<Campaign[]> {
    let query = this.supabase
      .from('campaigns')
      .select('*')
      .eq('visibility', 'public')
      .eq('status', 'active');

    if (filters?.type) {
      query = query.eq('campaign_type', filters.type);
    }

    // If category filter is added, we'd need to join with business_profiles
    // This would require a more complex query

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error || !data) {
      return [];
    }

    return data.map(this.mapDbCampaignToCampaign);
  }

  async createCampaign(campaign: Omit<Campaign, 'id' | 'createdAt' | 'updatedAt'>): Promise<Campaign | null> {
    const { data, error } = await this.supabase
      .from('campaigns')
      .insert([{
        business_id: campaign.businessId,
        title: campaign.title,
        description: campaign.description,
        campaign_type: campaign.campaignType,
        visibility: campaign.visibility,
        status: campaign.status,
        requirements: campaign.requirements,
        target_customers: campaign.targetCustomers,
        influencer_spots: campaign.influencerSpots,
        period_start: campaign.periodStart.toISOString(),
        period_end: campaign.periodEnd.toISOString(),
        credits_per_action: campaign.creditsPerAction,
        total_credits: campaign.totalCredits,
        image_url: campaign.imageUrl
      }])
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbCampaignToCampaign(data);
  }

  async updateCampaign(id: string, updates: Partial<Campaign>): Promise<Campaign | null> {
    const updateData: Record<string, any> = {};
    
    // Map camelCase properties to snake_case for database
    if (updates.title) updateData.title = updates.title;
    if (updates.description) updateData.description = updates.description;
    if (updates.status) updateData.status = updates.status;
    if (updates.visibility) updateData.visibility = updates.visibility;
    if (updates.requirements) updateData.requirements = updates.requirements;
    if (updates.targetCustomers) updateData.target_customers = updates.targetCustomers;
    if (updates.influencerSpots) updateData.influencer_spots = updates.influencerSpots;
    if (updates.periodStart) updateData.period_start = updates.periodStart.toISOString();
    if (updates.periodEnd) updateData.period_end = updates.periodEnd.toISOString();
    if (updates.creditsPerAction) updateData.credits_per_action = updates.creditsPerAction;
    if (updates.totalCredits) updateData.total_credits = updates.totalCredits;
    if (updates.imageUrl) updateData.image_url = updates.imageUrl;
    
    // Always update the updated_at timestamp
    updateData.updated_at = new Date().toISOString();

    const { data, error } = await this.supabase
      .from('campaigns')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbCampaignToCampaign(data);
  }

  async deleteCampaign(id: string): Promise<boolean> {
    const { error } = await this.supabase
      .from('campaigns')
      .delete()
      .eq('id', id);

    return !error;
  }

  async getCampaignMetrics(campaignId: string): Promise<CampaignMetrics | null> {
    // This would typically involve multiple queries to different tables
    // For simplicity, we'll use a basic implementation here
    const { data, error } = await this.supabase
      .from('campaigns')
      .select(`
        id,
        visits:visits(count),
        submitted_content:submitted_content(count)
      `)
      .eq('id', campaignId)
      .single();

    if (error || !data) {
      return null;
    }

    // More complex metrics would need additional queries and calculations
    return {
      campaignId: data.id,
      visits: data.visits[0]?.count || 0,
      submissions: data.submitted_content[0]?.count || 0,
      approved: 0, // Would need additional query
      rejected: 0, // Would need additional query
      conversion: 0, // Would need calculation based on data
      engagementRate: 0, // Would need calculation based on data
      totalCreditsSpent: 0, // Would need additional query
      totalLoyaltyPointsIssued: 0 // Would need additional query
    };
  }

  async applyCampaign(campaignId: string, influencerId: string, message?: string): Promise<CampaignApplication | null> {
    const { data, error } = await this.supabase
      .from('campaign_applications')
      .insert([{
        campaign_id: campaignId,
        influencer_id: influencerId,
        message: message,
        status: 'pending'
      }])
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    return {
      id: data.id,
      campaignId: data.campaign_id,
      influencerId: data.influencer_id,
      message: data.message,
      status: data.status,
      createdAt: new Date(data.created_at),
      updatedAt: data.updated_at ? new Date(data.updated_at) : undefined
    };
  }

  // Helper to convert database object to Campaign interface
  private mapDbCampaignToCampaign(dbCampaign: any): Campaign {
    return {
      id: dbCampaign.id,
      businessId: dbCampaign.business_id,
      title: dbCampaign.title,
      description: dbCampaign.description,
      campaignType: dbCampaign.campaign_type,
      visibility: dbCampaign.visibility,
      status: dbCampaign.status,
      requirements: dbCampaign.requirements,
      targetCustomers: dbCampaign.target_customers,
      influencerSpots: dbCampaign.influencer_spots,
      periodStart: new Date(dbCampaign.period_start),
      periodEnd: new Date(dbCampaign.period_end),
      creditsPerAction: dbCampaign.credits_per_action,
      totalCredits: dbCampaign.total_credits,
      imageUrl: dbCampaign.image_url,
      createdAt: new Date(dbCampaign.created_at),
      updatedAt: dbCampaign.updated_at ? new Date(dbCampaign.updated_at) : undefined
    };
  }
} 
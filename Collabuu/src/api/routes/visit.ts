import express, { Request, Response } from 'express';
import { supabase } from '../../config/supabase';
import { authenticateToken } from '../../middleware/auth';

export class VisitRouter {
  public router = express.Router();

  constructor() {
    // Generic visit endpoints
    this.router.get('/', authenticateToken, this.getAllVisits.bind(this));
    this.router.get('/:id', authenticateToken, this.getVisitById.bind(this));
    this.router.post('/:id/validate', authenticateToken, this.validateVisit.bind(this));
  }

  private async getAllVisits(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const userType = (req as any).user.user_type;
      const { status, limit = 20, offset = 0 } = req.query;

      let query = supabase
        .from('visits')
        .select(`
          id, customer_id, business_id, campaign_id, referral_code_id,
          visit_date, status, qr_code, notes, created_at,
          customer_profiles!inner(id, first_name, last_name, profile_image_url),
          business_profiles!inner(id, business_name, logo_url),
          campaigns(id, title, campaign_type)
        `);

      // Filter based on user type
      if (userType === 'business') {
        query = query.eq('business_id', userId);
      } else if (userType === 'customer') {
        query = query.eq('customer_id', userId);
      } else {
        // For influencers, show visits from their campaigns
        const { data: influencerCampaigns } = await supabase
          .from('campaigns')
          .select('id')
          .eq('influencer_id', userId);
        
        if (influencerCampaigns && influencerCampaigns.length > 0) {
          const campaignIds = influencerCampaigns.map(c => c.id);
          query = query.in('campaign_id', campaignIds);
        } else {
          // No campaigns, return empty result
          return res.status(200).json({ visits: [], total: 0 });
        }
      }

      // Apply status filter if provided
      if (status && typeof status === 'string') {
        query = query.eq('status', status);
      }

      // Apply pagination
      query = query
        .range(Number(offset), Number(offset) + Number(limit) - 1)
        .order('created_at', { ascending: false });

      const { data: visits, error } = await query;

      if (error) {
        console.error('Get visits error:', error);
        return res.status(500).json({ error: 'Failed to retrieve visits' });
      }

      res.status(200).json({ 
        visits: visits || [],
        total: visits?.length || 0
      });
    } catch (error) {
      console.error('Get all visits error:', error);
      res.status(500).json({ error: 'Failed to retrieve visits' });
    }
  }

  private async getVisitById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const userId = (req as any).user.id;
      const userType = (req as any).user.user_type;
      
      if (!id) {
        return res.status(400).json({ error: 'Visit ID is required' });
      }

      let query = supabase
        .from('visits')
        .select(`
          id, customer_id, business_id, campaign_id, referral_code_id,
          visit_date, status, qr_code, notes, created_at, updated_at,
          customer_profiles!inner(id, first_name, last_name, email, profile_image_url),
          business_profiles!inner(id, business_name, description, logo_url, location),
          campaigns(id, title, description, campaign_type, budget),
          campaign_referral_codes(id, code, influencer_id)
        `)
        .eq('id', id);

      // Apply access control based on user type
      if (userType === 'business') {
        query = query.eq('business_id', userId);
      } else if (userType === 'customer') {
        query = query.eq('customer_id', userId);
      }

      const { data: visit, error } = await query.single();

      if (error || !visit) {
        return res.status(404).json({ error: 'Visit not found or access denied' });
      }

      res.status(200).json({ visit });
    } catch (error) {
      console.error('Get visit by ID error:', error);
      res.status(500).json({ error: 'Failed to retrieve visit' });
    }
  }

  private async validateVisit(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const userId = (req as any).user.id;
      const userType = (req as any).user.user_type;
      const { action = 'approve', notes } = req.body;
      
      if (!id) {
        return res.status(400).json({ error: 'Visit ID is required' });
      }

      // Only businesses can validate visits
      if (userType !== 'business') {
        return res.status(403).json({ error: 'Only businesses can validate visits' });
      }

      // Get the visit
      const { data: visit, error: fetchError } = await supabase
        .from('visits')
        .select(`
          id, customer_id, business_id, campaign_id, referral_code_id, status,
          campaigns!inner(id, title, campaign_type, budget, business_id),
          campaign_referral_codes(id, code, influencer_id)
        `)
        .eq('id', id)
        .eq('business_id', userId)
        .single();

      if (fetchError || !visit) {
        return res.status(404).json({ error: 'Visit not found or access denied' });
      }

      if (visit.status !== 'pending') {
        return res.status(400).json({ error: 'Visit has already been processed' });
      }

      const newStatus = action === 'approve' ? 'approved' : 'rejected';
      
      // Update visit status
      const { error: updateError } = await supabase
        .from('visits')
        .update({ 
          status: newStatus,
          notes: notes || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', id);

      if (updateError) {
        console.error('Update visit error:', updateError);
        return res.status(500).json({ error: 'Failed to update visit status' });
      }

      // If approved, handle rewards and loyalty points
      await this.processVisitRewards(visit);

      res.status(200).json({ 
        message: `Visit ${newStatus} successfully`,
        visitId: id,
        status: newStatus
      });
    } catch (error) {
      console.error('Validate visit error:', error);
      res.status(500).json({ error: 'Failed to validate visit' });
    }
  }

  private async processVisitRewards(visit: any) {
    try {
      const campaign = (visit as any).campaigns;
      
      // Award loyalty points to customer
      await supabase
        .from('loyalty_points')
        .upsert({
          customer_id: visit.customer_id,
          business_id: visit.business_id,
          points_earned: 10, // Default points per visit
          points_available: 10,
          last_visit_date: new Date().toISOString()
        }, {
          onConflict: 'customer_id,business_id'
        });

      // Record loyalty transaction
      await supabase
        .from('loyalty_transactions')
        .insert({
          customer_id: visit.customer_id,
          business_id: visit.business_id,
          transaction_type: 'earned',
          points: 10,
          description: `Visit reward - ${campaign.title}`,
          visit_id: visit.id
        });

      // If there's a referral code, update usage count
      if (visit.referral_code_id) {
        // Get current usage count and increment
        const { data: referralCode } = await supabase
          .from('campaign_referral_codes')
          .select('usage_count')
          .eq('id', visit.referral_code_id)
          .single();
        
        if (referralCode) {
          await supabase
            .from('campaign_referral_codes')
            .update({ 
              usage_count: (referralCode.usage_count || 0) + 1
            })
            .eq('id', visit.referral_code_id);
        }
      }

      console.log('Visit rewards processed successfully');
    } catch (error) {
      console.error('Process visit rewards error:', error);
      // Don't throw error as visit validation was successful
    }
  }
} 
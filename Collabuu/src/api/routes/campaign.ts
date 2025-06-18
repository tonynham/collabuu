import express, { Request, Response } from 'express';
import { supabase } from '../../config/supabase';
import { authenticateToken } from '../../middleware/auth';

export class CampaignRouter {
  public router = express.Router();

  constructor() {
    this.router.get('/by-deeplink/:code', this.getByDeeplink.bind(this));
    this.router.post('/validate-referral-code', this.validateReferralCode.bind(this));
  }

  private async getByDeeplink(req: Request, res: Response) {
    try {
      const { code } = req.params;
      
      if (!code) {
        return res.status(400).json({ error: 'Deeplink code is required' });
      }

      // Find campaign by deeplink code
      const { data: campaign, error } = await supabase
        .from('campaigns')
        .select(`
          id, title, description, campaign_type, budget, requirements,
          start_date, end_date, status, deeplink_code,
          business_profiles!inner(
            id, business_name, description, logo_url, location,
            contact_email, contact_phone, website_url
          )
        `)
        .eq('deeplink_code', code)
        .eq('status', 'active')
        .single();

      if (error || !campaign) {
        return res.status(404).json({ error: 'Campaign not found or inactive' });
      }

      // Check if campaign is still valid (within date range)
      const now = new Date();
      const startDate = new Date(campaign.start_date);
      const endDate = new Date(campaign.end_date);

      if (now < startDate || now > endDate) {
        return res.status(400).json({ error: 'Campaign is not currently active' });
      }

      res.status(200).json({ campaign });
    } catch (error) {
      console.error('Get campaign by deeplink error:', error);
      res.status(500).json({ error: 'Failed to retrieve campaign' });
    }
  }

  private async validateReferralCode(req: Request, res: Response) {
    try {
      const { referralCode, campaignId } = req.body;
      
      if (!referralCode) {
        return res.status(400).json({ error: 'Referral code is required' });
      }

      // Find the referral code
      const { data: referral, error } = await supabase
        .from('campaign_referral_codes')
        .select(`
          id, code, campaign_id, influencer_id, is_active, usage_count, max_uses,
          campaigns!inner(id, title, status, start_date, end_date),
          influencer_profiles!inner(id, username, profile_image_url)
        `)
        .eq('code', referralCode)
        .eq('is_active', true)
        .single();

      if (error || !referral) {
        return res.status(404).json({ 
          valid: false, 
          error: 'Invalid or inactive referral code' 
        });
      }

      // If campaignId is provided, validate it matches
      if (campaignId && referral.campaign_id !== campaignId) {
        return res.status(400).json({ 
          valid: false, 
          error: 'Referral code does not match campaign' 
        });
      }

      // Check if campaign is active and within date range
      const campaign = (referral as any).campaigns;
      if (campaign.status !== 'active') {
        return res.status(400).json({ 
          valid: false, 
          error: 'Campaign is not active' 
        });
      }

      const now = new Date();
      const startDate = new Date(campaign.start_date);
      const endDate = new Date(campaign.end_date);

      if (now < startDate || now > endDate) {
        return res.status(400).json({ 
          valid: false, 
          error: 'Campaign is not currently active' 
        });
      }

      // Check usage limits
      if (referral.max_uses && referral.usage_count >= referral.max_uses) {
        return res.status(400).json({ 
          valid: false, 
          error: 'Referral code has reached maximum usage limit' 
        });
      }

      const influencer = (referral as any).influencer_profiles;
      res.status(200).json({ 
        valid: true,
        referral: {
          id: referral.id,
          code: referral.code,
          campaign: {
            id: campaign.id,
            title: campaign.title
          },
          influencer: {
            id: influencer.id,
            username: influencer.username,
            profile_image_url: influencer.profile_image_url
          },
          usage_count: referral.usage_count,
          max_uses: referral.max_uses
        }
      });
    } catch (error) {
      console.error('Validate referral code error:', error);
      res.status(500).json({ 
        valid: false, 
        error: 'Failed to validate referral code' 
      });
    }
  }
} 
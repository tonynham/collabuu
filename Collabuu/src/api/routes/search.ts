import express, { Request, Response } from 'express';
import { supabase } from '../../config/supabase';
import { authenticateToken } from '../../middleware/auth';

export class SearchRouter {
  public router = express.Router();

  constructor() {
    this.router.get('/global', authenticateToken, this.globalSearch.bind(this));
    this.router.get('/suggestions', authenticateToken, this.getSuggestions.bind(this));
  }

  private async globalSearch(req: Request, res: Response) {
    try {
      const { query, type, limit = 20, offset = 0 } = req.query;
      
      if (!query || typeof query !== 'string') {
        return res.status(400).json({ error: 'Search query is required' });
      }

      const searchQuery = `%${query.toLowerCase()}%`;
      const results: any = {
        businesses: [],
        influencers: [],
        campaigns: []
      };

      // Search businesses if type is not specified or is 'business'
      if (!type || type === 'business') {
        const { data: businesses } = await supabase
          .from('business_profiles')
          .select('id, business_name, description, category, location, logo_url')
          .or(`business_name.ilike.${searchQuery},description.ilike.${searchQuery},category.ilike.${searchQuery}`)
          .eq('is_active', true)
          .range(Number(offset), Number(offset) + Number(limit) - 1);
        
        results.businesses = businesses || [];
      }

      // Search influencers if type is not specified or is 'influencer'
      if (!type || type === 'influencer') {
        const { data: influencers } = await supabase
          .from('influencer_profiles')
          .select('id, username, bio, categories, follower_count, profile_image_url')
          .or(`username.ilike.${searchQuery},bio.ilike.${searchQuery}`)
          .eq('is_active', true)
          .range(Number(offset), Number(offset) + Number(limit) - 1);
        
        results.influencers = influencers || [];
      }

      // Search campaigns if type is not specified or is 'campaign'
      if (!type || type === 'campaign') {
        const { data: campaigns } = await supabase
          .from('campaigns')
          .select(`
            id, title, description, campaign_type, budget, 
            business_profiles!inner(business_name, logo_url)
          `)
          .or(`title.ilike.${searchQuery},description.ilike.${searchQuery}`)
          .eq('status', 'active')
          .range(Number(offset), Number(offset) + Number(limit) - 1);
        
        results.campaigns = campaigns || [];
      }

      res.status(200).json(results);
    } catch (error) {
      console.error('Global search error:', error);
      res.status(500).json({ error: 'Failed to perform search' });
    }
  }

  private async getSuggestions(req: Request, res: Response) {
    try {
      const { query, type = 'all' } = req.query;
      
      if (!query || typeof query !== 'string') {
        return res.status(400).json({ error: 'Search query is required' });
      }

      const searchQuery = `${query.toLowerCase()}%`;
      const suggestions: string[] = [];

      // Get business name suggestions
      if (type === 'all' || type === 'business') {
        const { data: businessSuggestions } = await supabase
          .from('business_profiles')
          .select('business_name')
          .ilike('business_name', searchQuery)
          .eq('is_active', true)
          .limit(5);
        
        businessSuggestions?.forEach(b => suggestions.push(b.business_name));
      }

      // Get influencer username suggestions
      if (type === 'all' || type === 'influencer') {
        const { data: influencerSuggestions } = await supabase
          .from('influencer_profiles')
          .select('username')
          .ilike('username', searchQuery)
          .eq('is_active', true)
          .limit(5);
        
        influencerSuggestions?.forEach(i => suggestions.push(i.username));
      }

      // Get campaign title suggestions
      if (type === 'all' || type === 'campaign') {
        const { data: campaignSuggestions } = await supabase
          .from('campaigns')
          .select('title')
          .ilike('title', searchQuery)
          .eq('status', 'active')
          .limit(5);
        
        campaignSuggestions?.forEach(c => suggestions.push(c.title));
      }

      // Remove duplicates and limit to 10 suggestions
      const uniqueSuggestions = [...new Set(suggestions)].slice(0, 10);
      
      res.status(200).json({ suggestions: uniqueSuggestions });
    } catch (error) {
      console.error('Search suggestions error:', error);
      res.status(500).json({ error: 'Failed to get search suggestions' });
    }
  }
} 
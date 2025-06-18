import express, { Request, Response } from 'express';
import { supabase } from '../../config/supabase';
import { UserService } from '../../models/user';
import { authenticateToken, requireUserType, AuthenticatedRequest } from '../../middleware/auth';

export class CustomerRouter {
  public router = express.Router();
  private userService = new UserService(supabase);

  constructor() {
    // Authentication
    this.router.post('/auth/register', this.register.bind(this) as any);
    this.router.post('/auth/login', this.login.bind(this) as any);
    // Profile Management
    this.router.get('/profile', this.getProfile.bind(this));
    this.router.put('/profile', this.updateProfile.bind(this));

    // Favorites Management
    this.router.get('/favorites', this.getFavorites.bind(this));
    this.router.post('/favorites', this.addFavorite.bind(this));
    this.router.post('/favorites/by-code', this.addFavoriteByCode.bind(this));
    this.router.delete('/favorites/:id', this.removeFavorite.bind(this));
    this.router.get('/favorites/:id/qr-code', this.getFavoriteQrCode.bind(this));
    this.router.get('/favorites/rewards', this.getFavoriteRewards.bind(this));
    this.router.get('/favorites/:favoriteId/reward-qr', this.getFavoriteRewardQr.bind(this));

    // Deals & Rewards
    this.router.get('/deals', this.getDeals.bind(this));
    this.router.get('/deals/:id', this.getDealDetails.bind(this));
    this.router.get('/rewards', this.getRewards.bind(this));
    this.router.get('/rewards/available', this.getAvailableRewards.bind(this));
    this.router.post('/rewards/:rewardId/redeem', this.redeemReward.bind(this));
    this.router.get('/rewards/history', this.getRewardHistory.bind(this));
    this.router.get('/rewards/redemptions', this.getRewardRedemptions.bind(this));
    this.router.post('/visits/loyalty-points', this.earnLoyaltyPoints.bind(this));
    this.router.get('/deals/media-events', this.getMediaEvents.bind(this));

    // Business Discovery
    this.router.get('/businesses', this.getBusinesses.bind(this));
    this.router.get('/businesses/search', this.searchBusinesses.bind(this));
    this.router.get('/businesses/:id', this.getBusinessDetails.bind(this));
    this.router.get('/businesses/categories', this.getBusinessCategories.bind(this));

    // Visit Tracking
    this.router.get('/visits', this.getVisits.bind(this));
    this.router.get('/visits/stats', this.getVisitStats.bind(this));
  }

  // Authentication Methods
  private async register(req: Request, res: Response) {
    try {
      const { email, password, firstName, lastName, username, preferences } = req.body;

      // Validate required fields
      if (!email || !password || !firstName || !lastName) {
        return res.status(400).json({ 
          error: 'Missing required fields: email, password, firstName, lastName' 
        });
      }

      // Create auth user in Supabase
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            user_type: 'customer',
            first_name: firstName,
            last_name: lastName,
            username
          }
        }
      });

      if (authError) {
        return res.status(400).json({ error: authError.message });
      }

      if (!authData.user) {
        return res.status(400).json({ error: 'Failed to create user account' });
      }

      // Create user profile
      const user = await this.userService.createUser({
        id: authData.user.id,
        email,
        userType: 'customer',
        firstName,
        lastName,
        username
      });

      if (!user) {
        return res.status(500).json({ error: 'Failed to create user profile' });
      }

      // Create customer profile
      const { data: customerProfile, error: customerError } = await supabase
        .from('customer_profiles')
        .insert([{
          user_id: authData.user.id,
          preferences: preferences || [],
          favorite_businesses: []
        }])
        .select()
        .single();

      if (customerError) {
        console.error('Customer profile creation error:', customerError);
        return res.status(500).json({ error: 'Failed to create customer profile' });
      }

      res.status(201).json({
        message: 'Customer registered successfully',
        user: {
          id: user.id,
          email: user.email,
          userType: user.userType,
          firstName: user.firstName,
          lastName: user.lastName,
          username: user.username
        },
        customerProfile: {
          id: customerProfile.id,
          preferences: customerProfile.preferences,
          favoriteBusinesses: customerProfile.favorite_businesses
        },
        session: authData.session
      });

    } catch (error) {
      console.error('Customer registration error:', error);
      res.status(500).json({ error: 'Internal server error during registration' });
    }
  }

  private async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
      }

      // Authenticate with Supabase
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (authError) {
        return res.status(401).json({ error: authError.message });
      }

      if (!authData.user) {
        return res.status(401).json({ error: 'Authentication failed' });
      }

      // Get user profile
      const user = await this.userService.getUserById(authData.user.id);
      if (!user) {
        return res.status(404).json({ error: 'User profile not found' });
      }

      // Verify user is a customer
      if (user.userType !== 'customer') {
        return res.status(403).json({ error: 'Access denied. Customer account required.' });
      }

      // Get customer profile
      const { data: customerProfile, error: customerError } = await supabase
        .from('customer_profiles')
        .select('*')
        .eq('user_id', authData.user.id)
        .single();

      if (customerError || !customerProfile) {
        return res.status(404).json({ error: 'Customer profile not found' });
      }

      res.json({
        message: 'Login successful',
        user: {
          id: user.id,
          email: user.email,
          userType: user.userType,
          firstName: user.firstName,
          lastName: user.lastName,
          username: user.username,
          profileImageUrl: user.profileImageUrl,
          bio: user.bio
        },
        customerProfile: {
          id: customerProfile.id,
          preferences: customerProfile.preferences,
          favoriteBusinesses: customerProfile.favorite_businesses
        },
        session: authData.session
      });

    } catch (error) {
      console.error('Customer login error:', error);
      res.status(500).json({ error: 'Internal server error during login' });
    }
  }

  private async getProfile(req: Request, res: Response) {
    // TODO: implement get customer profile
    res.status(200).json({});
  }

  private async updateProfile(req: Request, res: Response) {
    // TODO: implement update customer profile
    res.status(200).json({});
  }

  private async getFavorites(req: Request, res: Response) {
    // TODO: implement get customer favorites
    res.status(200).json([]);
  }

  private async addFavorite(req: Request, res: Response) {
    // TODO: implement add favorite
    res.status(200).json({});
  }

  private async addFavoriteByCode(req: Request, res: Response) {
    try {
      const customerId = req.user?.id;
      const { referralCode, deepLink } = req.body;

      if (!customerId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      if (!referralCode && !deepLink) {
        return res.status(400).json({ error: 'Referral code or deep link required' });
      }

      let campaignId: string;

      // Handle deep link
      if (deepLink) {
        // Extract campaign ID from deep link
        const urlParams = new URLSearchParams(deepLink.split('?')[1]);
        campaignId = urlParams.get('campaign') || '';
      } else {
        // Handle referral code - look up campaign by referral code
        const { data: referralData, error: referralError } = await supabase
          .from('influencer_referrals')
          .select('campaign_id')
          .eq('referral_code', referralCode)
          .single();

        if (referralError || !referralData) {
          return res.status(404).json({ error: 'Invalid referral code' });
        }

        campaignId = referralData.campaign_id;
      }

      // Get campaign details
      const { data: campaign, error: campaignError } = await supabase
        .from('campaigns')
        .select('*')
        .eq('id', campaignId)
        .eq('status', 'active')
        .single();

      if (campaignError || !campaign) {
        return res.status(404).json({ error: 'Campaign not found or inactive' });
      }

      // Check if already favorited
      const { data: existingFavorite } = await supabase
        .from('customer_favorites')
        .select('id')
        .eq('customer_id', customerId)
        .eq('campaign_id', campaignId)
        .single();

      if (existingFavorite) {
        return res.status(409).json({ error: 'Campaign already in favorites' });
      }

      // Add to favorites
      const { data: favorite, error: favoriteError } = await supabase
        .from('customer_favorites')
        .insert([{
          customer_id: customerId,
          campaign_id: campaignId,
          referral_code: referralCode,
          source: referralCode ? 'referral_code' : 'deep_link'
        }])
        .select('*, campaigns(*)')
        .single();

      if (favoriteError) {
        console.error('Favorite creation error:', favoriteError);
        return res.status(500).json({ error: 'Failed to add to favorites' });
      }

      res.status(201).json({
        message: 'Campaign added to favorites successfully',
        favorite,
        campaign: favorite.campaigns
      });

    } catch (error) {
      console.error('Add favorite by code error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async removeFavorite(req: Request, res: Response) {
    // TODO: implement remove favorite
    res.status(200).json({});
  }

  private async getFavoriteQrCode(req: Request, res: Response) {
    try {
      const customerId = req.user?.id;
      const favoriteId = req.params.id;

      if (!customerId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      // Get favorite record
      const { data: favorite, error: favoriteError } = await supabase
        .from('customer_favorites')
        .select('*, campaigns(*)')
        .eq('id', favoriteId)
        .eq('customer_id', customerId)
        .single();

      if (favoriteError || !favorite) {
        return res.status(404).json({ error: 'Favorite not found' });
      }

      // Generate QR code data
      const qrData = {
        type: 'visit',
        customerId,
        campaignId: favorite.campaign_id,
        favoriteId,
        timestamp: new Date().toISOString()
      };

      // Create QR code string
      const qrCodeString = JSON.stringify(qrData);

      // Generate QR code using the qrcode library
      const QRCode = require('qrcode');
      const qrCodeDataUrl = await QRCode.toDataURL(qrCodeString, {
        errorCorrectionLevel: 'M',
        type: 'image/png',
        quality: 0.92,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });

      res.json({
        qrCode: qrCodeDataUrl,
        qrData: qrCodeString,
        campaign: favorite.campaigns,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24 hours
      });

    } catch (error) {
      console.error('QR code generation error:', error);
      res.status(500).json({ error: 'Failed to generate QR code' });
    }
  }

  private async getFavoriteRewards(req: Request, res: Response) {
    // TODO: implement get redeemed rewards
    res.status(200).json([]);
  }

  private async getFavoriteRewardQr(req: Request, res: Response) {
    // TODO: implement generate QR for reward redemption
    res.status(200).json({});
  }

  private async getDeals(req: Request, res: Response) {
    // TODO: implement browse available deals
    res.status(200).json([]);
  }

  private async getDealDetails(req: Request, res: Response) {
    // TODO: implement get deal details
    res.status(200).json({});
  }

  private async getRewards(req: Request, res: Response) {
    // TODO: implement get loyalty points balance and rewards
    res.status(200).json({});
  }

  private async getAvailableRewards(req: Request, res: Response) {
    // TODO: implement browse available loyalty reward campaigns
    res.status(200).json([]);
  }

  private async redeemReward(req: Request, res: Response) {
    // TODO: implement redeem loyalty reward
    res.status(200).json({});
  }

  private async getRewardHistory(req: Request, res: Response) {
    // TODO: implement loyalty points transaction history
    res.status(200).json([]);
  }

  private async getRewardRedemptions(req: Request, res: Response) {
    // TODO: implement get reward redemption history
    res.status(200).json([]);
  }

  private async earnLoyaltyPoints(req: Request, res: Response) {
    // TODO: implement earn loyalty points from visit
    res.status(200).json({});
  }

  private async getMediaEvents(req: Request, res: Response) {
    // TODO: implement browse media events
    res.status(200).json([]);
  }

  private async getBusinesses(req: Request, res: Response) {
    // TODO: implement browse businesses
    res.status(200).json([]);
  }

  private async searchBusinesses(req: Request, res: Response) {
    // TODO: implement search businesses
    res.status(200).json([]);
  }

  private async getBusinessDetails(req: Request, res: Response) {
    // TODO: implement get business details
    res.status(200).json({});
  }

  private async getBusinessCategories(req: Request, res: Response) {
    // TODO: implement get business categories
    res.status(200).json([]);
  }

  private async getVisits(req: Request, res: Response) {
    // TODO: implement get visit history
    res.status(200).json([]);
  }

  private async getVisitStats(req: Request, res: Response) {
    // TODO: implement get visit statistics
    res.status(200).json({});
  }
} 
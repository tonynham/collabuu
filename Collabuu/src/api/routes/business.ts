/// <reference types="express" />
// @ts-nocheck
import { Router, Request, Response, NextFunction, RequestHandler } from 'express';
import { SupabaseClient } from '@supabase/supabase-js';
import { CampaignService } from '../../models/campaign';
import { VisitService } from '../../models/visit';
import { UserService } from '../../models/user';
import { ConversationService } from '../../models/conversation';
import { LoyaltyService } from '../../models/loyalty';
import { supabase } from '../../config/supabase';
import { authenticateToken, requireUserType, AuthenticatedRequest } from '../../middleware/auth';

export class BusinessRouter {
  public router: Router;
  private campaignService: CampaignService;
  private visitService: VisitService;
  private userService: UserService;
  private conversationService: ConversationService;
  private loyaltyService: LoyaltyService;

  constructor(supabaseClient: SupabaseClient = supabase) {
    this.router = Router();
    this.campaignService = new CampaignService(supabaseClient);
    this.visitService = new VisitService(supabaseClient);
    this.userService = new UserService(supabaseClient);
    this.conversationService = new ConversationService(supabaseClient);
    this.loyaltyService = new LoyaltyService(supabaseClient);
    this.setupRoutes();
  }

  private setupRoutes() {
    // Authentication
    this.router.post('/auth/register', this.registerBusiness.bind(this));
    this.router.post('/auth/login', this.loginBusiness.bind(this));

    // Profile Management (Protected routes)
    this.router.get('/profile', authenticateToken, requireUserType('business'), this.getBusinessProfile.bind(this));
    this.router.put('/profile', authenticateToken, requireUserType('business'), this.updateBusinessProfile.bind(this));
    this.router.post('/profile/logo/upload', authenticateToken, requireUserType('business'), this.uploadLogo.bind(this));
    this.router.get('/profile/completion-status', authenticateToken, requireUserType('business'), this.getProfileCompletionStatus.bind(this));
    this.router.put('/profile/social-media', authenticateToken, requireUserType('business'), this.updateSocialMedia.bind(this));
    this.router.put('/profile/business-details', authenticateToken, requireUserType('business'), this.updateBusinessDetails.bind(this));
    this.router.put('/profile/visibility', authenticateToken, requireUserType('business'), this.updateVisibility.bind(this));
    this.router.get('/categories', this.getCategories.bind(this));

    // Extended Profile Validation
    this.router.post('/profile/validate', this.validateProfile.bind(this));
    this.router.get('/profile/validation/requirements', this.getValidationRequirements.bind(this));
    this.router.post('/profile/validate/field', this.validateField.bind(this));
    this.router.get('/profile/suggestions', this.getProfileSuggestions.bind(this));

    // Campaign Management
    this.router.get('/campaigns', this.getBusinessCampaigns.bind(this));
    this.router.post('/campaigns', this.createCampaign.bind(this));
    this.router.get('/campaigns/:id', this.getCampaignDetails.bind(this));
    this.router.put('/campaigns/:id', this.updateCampaign.bind(this));
    this.router.delete('/campaigns/:id', this.deleteCampaign.bind(this));
    this.router.put('/campaigns/:id/status', this.updateCampaignStatus.bind(this));
    this.router.post('/campaigns/:id/media-event/schedule', this.scheduleMediaEvent.bind(this));
    this.router.get('/campaigns/:id/metrics', this.getCampaignMetrics.bind(this));
    this.router.get('/campaigns/:id/participants', this.getCampaignParticipants.bind(this));

    // Application Management
    this.router.get('/campaigns/:id/applications', this.getCampaignApplications.bind(this));
    this.router.post('/campaigns/:id/applications/:applicationId/accept', this.acceptApplication.bind(this));
    this.router.post('/campaigns/:id/applications/:applicationId/reject', this.rejectApplication.bind(this));
    this.router.post('/influencers/:id/invite', this.inviteInfluencer.bind(this));
    // Enhanced Campaign Management
    this.router.put('/campaigns/:id/status', this.updateCampaignStatus.bind(this));
    this.router.post('/campaigns/:id/pause', this.pauseCampaign.bind(this));
    this.router.post('/campaigns/:id/resume', this.resumeCampaign.bind(this));
    this.router.post('/campaigns/:id/duplicate', this.duplicateCampaign.bind(this));

    // Visit Management
    this.router.post('/visits/verify', this.verifyVisit.bind(this));
    this.router.get('/visits', this.getVisits.bind(this));
    this.router.post('/visits/:id/approve', this.approveVisit.bind(this));
    this.router.post('/visits/:id/reject', this.rejectVisit.bind(this));
    this.router.get('/visits/stats', this.getVisitStats.bind(this));
    this.router.post('/scan/validate', this.validateManualScan.bind(this));
    // Enhanced Visit Management
    this.router.post('/visits/scan-result/validate', this.validateScanResult.bind(this));
    this.router.get('/visits/recent', this.getRecentVisits.bind(this));
    this.router.get('/visits/pending', this.getPendingVisits.bind(this));

    // Messaging
    this.router.get('/conversations', this.getConversations.bind(this));
    this.router.get('/conversations/by-campaign/:campaignId', this.getConversationByCampaign.bind(this));
    this.router.get('/conversations/:id/messages', this.getMessages.bind(this));
    this.router.post('/conversations/:id/messages', this.sendMessage.bind(this));
    this.router.put('/conversations/:id/mark-read', this.markConversationRead.bind(this));
    this.router.get('/conversations/:id/campaign-status', this.getConversationCampaignStatus.bind(this));

    // Loyalty & Rewards
    this.router.post('/rewards/scan', this.scanRewardQR.bind(this));
    this.router.post('/rewards/:redemptionId/validate', this.validateReward.bind(this));
    this.router.get('/rewards/redemptions', this.getRewardRedemptions.bind(this));
    this.router.get('/rewards/redemptions/pending', this.getPendingRewardRedemptions.bind(this));
    this.router.post('/rewards/:redemptionId/complete', this.completeRewardRedemption.bind(this));

    // Analytics
    this.router.get('/analytics/dashboard', this.getDashboardAnalytics.bind(this));
    this.router.get('/analytics/campaigns', this.getCampaignAnalytics.bind(this));
    this.router.get('/analytics/influencers', this.getInfluencerAnalytics.bind(this));
    this.router.get('/analytics/visitors', this.getVisitorAnalytics.bind(this));

    // Google My Business Integration
    this.router.post('/profile/connect-gmb', this.connectGmb.bind(this));
    this.router.put('/profile/sync-gmb', this.syncGmb.bind(this));
    this.router.delete('/profile/disconnect-gmb', this.disconnectGmb.bind(this));
    this.router.get('/profile/gmb-status', this.getGmbStatus.bind(this));
    this.router.get('/gmb/search', this.searchGmb.bind(this));
    this.router.post('/gmb/verify', this.verifyGmbOwnership.bind(this));
    this.router.get('/gmb/locations', this.getGmbLocations.bind(this));
    this.router.put('/gmb/select-location', this.selectGmbLocation.bind(this));
    this.router.get('/gmb/photos', this.getGmbPhotos.bind(this));
    this.router.get('/gmb/reviews', this.getGmbReviews.bind(this));
    this.router.get('/gmb/hours', this.getGmbHours.bind(this));
    this.router.get('/gmb/attributes', this.getGmbAttributes.bind(this));
    this.router.post('/gmb/import-profile', this.importGmbProfile.bind(this));

    // Content Management Endpoints
    this.router.get('/campaigns/:id/content', this.getCampaignContent.bind(this));
    this.router.get('/campaigns/:id/content/analytics', this.getCampaignContentAnalytics.bind(this));
    this.router.post('/campaigns/:id/content/:contentId/approve', this.approveContent.bind(this));
    this.router.post('/campaigns/:id/content/:contentId/reject', this.rejectContent.bind(this));

    // Credit Pool & Rewards
    this.router.get('/campaigns/:id/credit-pool', this.getCreditPool.bind(this));
    this.router.get('/campaigns/rewards', this.getLoyaltyRewardCampaigns.bind(this));
    this.router.get('/campaigns/:id/redemptions', this.getCampaignRedemptions.bind(this));

    // Influencer Management
    this.router.get('/influencers', this.listInfluencers.bind(this));
    this.router.get('/campaigns/:id/applications/pending', this.getPendingApplications.bind(this));
    this.router.get('/campaigns/:id/invites', this.getCampaignInvites.bind(this));
    this.router.put('/campaigns/:id/invites/:inviteId', this.updateCampaignInviteStatus.bind(this));

    // Team Management
    this.router.get('/team/members', this.listTeamMembers.bind(this));
    this.router.post('/team/invite', this.inviteTeamMember.bind(this));
    this.router.delete('/team/members/:memberId', this.removeTeamMember.bind(this));
    this.router.put('/team/members/:memberId/role', this.updateTeamMemberRole.bind(this));
    this.router.put('/team/members/:memberId/status', this.updateTeamMemberStatus.bind(this));
    this.router.get('/team/invitations', this.getTeamInvitations.bind(this));
    this.router.get('/team/roles', this.getTeamRoles.bind(this));
    this.router.post('/team/members/:memberId/permissions', this.setTeamMemberPermissions.bind(this));
    // Business Verification
    this.router.post('/profile/verify', this.submitBusinessVerification.bind(this));
    this.router.get('/profile/verification-status', this.getBusinessVerificationStatus.bind(this));
    this.router.post('/profile/verification/documents', this.uploadVerificationDocuments.bind(this));
    this.router.get('/profile/verification/requirements', this.getVerificationRequirements.bind(this));
    // Credit Purchase & Payment System
    this.router.get('/credits/balance', this.getCreditBalance.bind(this));
    this.router.get('/credits/packages', this.getCreditPackages.bind(this));
    this.router.post('/credits/purchase', this.purchaseCredit.bind(this));
    this.router.get('/credits/transactions', this.getCreditTransactions.bind(this));
    this.router.post('/payments/process', this.processPayment.bind(this));
    this.router.get('/payments/methods', this.getPaymentMethods.bind(this));
    this.router.post('/payments/methods', this.addPaymentMethod.bind(this));
    this.router.delete('/payments/methods/:methodId', this.removePaymentMethod.bind(this));
    this.router.get('/payments/invoices', this.getInvoices.bind(this));
    // Advanced Campaign Analytics
    this.router.get('/campaigns/:id/metrics/detailed', this.getDetailedCampaignMetrics.bind(this));
    this.router.get('/campaigns/:id/traffic/data', this.getCampaignTrafficData.bind(this));
    this.router.get('/campaigns/:id/engagement/stats', this.getCampaignEngagementStats.bind(this));
    this.router.get('/campaigns/:id/roi', this.getCampaignRoi.bind(this));
    this.router.get('/campaigns/:id/timeline', this.getCampaignTimeline.bind(this));
    this.router.get('/campaigns/:id/participants/detailed', this.getDetailedParticipants.bind(this));
    this.router.get('/campaigns/:id/participants/:participantId/performance', this.getParticipantPerformance.bind(this));
    this.router.put('/campaigns/:id/participants/:participantId/status', this.updateParticipantStatus.bind(this));
    // Content Performance & Management
    this.router.get('/campaigns/:id/content/performance', this.getContentPerformance.bind(this));
    this.router.post('/campaigns/:id/participants/:participantId/message', this.messageParticipant.bind(this));
    // Advanced Campaign Creation
    this.router.post('/campaigns/draft', this.createCampaignDraft.bind(this));
    this.router.get('/campaigns/templates', this.getCampaignTemplates.bind(this));
    this.router.post('/campaigns/:id/image/upload', this.uploadCampaignImage.bind(this));
    this.router.get('/campaigns/validation', this.validateCampaignSettings.bind(this));

    // Influencer Discovery & Portfolio
    this.router.get('/influencers/available', this.getAvailableInfluencers.bind(this));
    this.router.get('/influencers/search', this.searchInfluencers.bind(this));
    this.router.get('/influencers/:id/profile', this.getInfluencerProfile.bind(this));
    this.router.get('/influencers/:id/portfolio', this.getInfluencerPortfolio.bind(this));
    this.router.get('/influencers/:id/campaigns/history', this.getInfluencerCampaignHistory.bind(this));

    // Advanced Scan & Visit Processing
    this.router.post('/scan/validate-qr', this.preValidateQrCode.bind(this));
    this.router.get('/scan/:scanId/details', this.getScanDetails.bind(this));
    this.router.post('/scan/report-issue', this.reportScanIssue.bind(this));
    this.router.get('/scan/history', this.getScanHistory.bind(this));
    this.router.post('/visits/:visitId/notes', this.addVisitNotes.bind(this));
  }

  // Authentication Methods
  private async registerBusiness(req: Request, res: Response) {
    try {
      const { email, password, businessName, category, firstName, lastName } = req.body;

      // Validate required fields
      if (!email || !password || !businessName || !category) {
        return res.status(400).json({ 
          error: 'Missing required fields: email, password, businessName, category' 
        });
      }

      // Create auth user in Supabase
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            user_type: 'business',
            business_name: businessName,
            first_name: firstName,
            last_name: lastName
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
        userType: 'business',
        firstName,
        lastName
      });

      if (!user) {
        return res.status(500).json({ error: 'Failed to create user profile' });
      }

      // Create business profile
      const { data: businessProfile, error: businessError } = await supabase
        .from('business_profiles')
        .insert([{
          user_id: authData.user.id,
          business_name: businessName,
          category,
          available_credits: 0,
          estimated_visits: 0,
          is_verified: false
        }])
        .select()
        .single();

      if (businessError) {
        console.error('Business profile creation error:', businessError);
        return res.status(500).json({ error: 'Failed to create business profile' });
      }

      res.status(201).json({
        message: 'Business registered successfully',
        user: {
          id: user.id,
          email: user.email,
          userType: user.userType,
          firstName: user.firstName,
          lastName: user.lastName
        },
        businessProfile: {
          id: businessProfile.id,
          businessName: businessProfile.business_name,
          category: businessProfile.category,
          availableCredits: businessProfile.available_credits,
          isVerified: businessProfile.is_verified
        },
        session: authData.session
      });

    } catch (error) {
      console.error('Business registration error:', error);
      res.status(500).json({ error: 'Internal server error during registration' });
    }
  }

  private async loginBusiness(req: Request, res: Response) {
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

      // Verify user is a business
      if (user.userType !== 'business') {
        return res.status(403).json({ error: 'Access denied. Business account required.' });
      }

      // Get business profile
      const { data: businessProfile, error: businessError } = await supabase
        .from('business_profiles')
        .select('*')
        .eq('user_id', authData.user.id)
        .single();

      if (businessError || !businessProfile) {
        return res.status(404).json({ error: 'Business profile not found' });
      }

      res.json({
        message: 'Login successful',
        user: {
          id: user.id,
          email: user.email,
          userType: user.userType,
          firstName: user.firstName,
          lastName: user.lastName
        },
        businessProfile: {
          id: businessProfile.id,
          businessName: businessProfile.business_name,
          category: businessProfile.category,
          description: businessProfile.description,
          address: businessProfile.address,
          phone: businessProfile.phone,
          website: businessProfile.website,
          logoUrl: businessProfile.logo_url,
          availableCredits: businessProfile.available_credits,
          estimatedVisits: businessProfile.estimated_visits,
          isVerified: businessProfile.is_verified,
          socialMediaHandles: businessProfile.social_media_handles,
          businessHours: businessProfile.business_hours
        },
        session: authData.session
      });

    } catch (error) {
      console.error('Business login error:', error);
      res.status(500).json({ error: 'Internal server error during login' });
    }
  }

  // Profile Management Methods
  private async getBusinessProfile(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      const user = await this.userService.getUserById(businessId);
      
      if (!user || user.userType !== 'business') {
        return res.status(403).json({ error: 'Forbidden - Business access only' });
      }
      
      // Fetch business profile
      const { data, error } = await supabase
        .from('business_profiles')
        .select('*')
        .eq('user_id', businessId)
        .single();
        
      if (error) {
        return res.status(500).json({ error: error.message });
      }
      
      return res.status(200).json({ 
        ...user,
        businessProfile: {
          id: data.id,
          userId: data.user_id,
          businessName: data.business_name,
          category: data.category,
          description: data.description,
          address: data.address,
          phone: data.phone,
          email: data.email,
          hours: data.hours,
          availableCredits: data.available_credits,
          estimatedVisits: data.estimated_visits,
          website: data.website,
          logoUrl: data.logo_url,
          isVerified: data.is_verified,
          socialMediaHandles: data.social_media_handles,
          businessHours: data.business_hours,
          createdAt: new Date(data.created_at),
          updatedAt: data.updated_at ? new Date(data.updated_at) : undefined
        }
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateBusinessProfile(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const updates = req.body;
      const { data, error } = await supabase
        .from('business_profiles')
        .update({
          business_name: updates.businessName,
          category: updates.category,
          description: updates.description,
          address: updates.address,
          phone: updates.phone,
          email: updates.email,
          hours: updates.hours,
          website: updates.website,
          social_media_handles: updates.socialMediaHandles,
          business_hours: updates.businessHours,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', businessId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async uploadLogo(req: Request, res: Response) {
    try {
      // Expect base64 or file upload URL in body.logoUrl
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { logoUrl } = req.body;
      if (!logoUrl) return res.status(400).json({ error: 'logoUrl required' });
      const { data, error } = await supabase
        .from('business_profiles')
        .update({ logo_url: logoUrl, updated_at: new Date().toISOString() })
        .eq('user_id', businessId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json({ logoUrl: data.logo_url });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getProfileCompletionStatus(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase
        .from('business_profiles')
        .select('*')
        .eq('user_id', businessId)
        .single();
      if (error || !data) {
        return res.status(500).json({ error: error?.message || 'Failed to fetch profile' });
      }
      const requiredFields = ['business_name', 'category', 'address', 'phone', 'email', 'hours', 'website', 'logo_url'];
      const missingFields = requiredFields.filter(field => !data[field]);
      const completedCount = requiredFields.length - missingFields.length;
      const total = requiredFields.length;
      res.status(200).json({ totalFields: total, completedFields: completedCount, missingFields, percentage: Math.round((completedCount/total)*100) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateSocialMedia(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { socialMediaHandles } = req.body;
      if (!socialMediaHandles) return res.status(400).json({ error: 'socialMediaHandles required' });
      const { data, error } = await supabase
        .from('business_profiles')
        .update({ social_media_handles: socialMediaHandles, updated_at: new Date().toISOString() })
        .eq('user_id', businessId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateBusinessDetails(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { foundedYear, employeeCount, hours } = req.body;
      const updateObj: any = {};
      if (foundedYear !== undefined) updateObj.founded_year = foundedYear;
      if (employeeCount !== undefined) updateObj.employee_count = employeeCount;
      if (hours !== undefined) updateObj.business_hours = hours;
      updateObj.updated_at = new Date().toISOString();
      const { data, error } = await supabase
        .from('business_profiles')
        .update(updateObj)
        .eq('user_id', businessId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateVisibility(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { visibility } = req.body;
      if (!visibility) return res.status(400).json({ error: 'visibility required' });
      const { data, error } = await supabase
        .from('business_profiles')
        .update({ visibility, updated_at: new Date().toISOString() })
        .eq('user_id', businessId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCategories(req: Request, res: Response) {
    try {
      // Static list of business categories
      const categories = [
        { id: 'retail', name: 'Retail' },
        { id: 'food', name: 'Food & Beverage' },
        { id: 'health', name: 'Health & Wellness' },
        { id: 'services', name: 'Services' },
        { id: 'entertainment', name: 'Entertainment' }
      ];
      res.status(200).json(categories);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Extended Profile Validation Methods
  private async validateProfile(req: Request, res: Response) {
    try {
      const { businessName, category, address, phone, email, hours, website, logoUrl } = req.body;
      const requiredFields = ['businessName', 'category', 'address', 'phone', 'email', 'hours', 'website', 'logoUrl'];
      const missingFields = requiredFields.filter(field => !req.body[field]);
      const completedCount = requiredFields.length - missingFields.length;
      const total = requiredFields.length;
      res.status(200).json({ totalFields: total, completedFields: completedCount, missingFields, percentage: Math.round((completedCount/total)*100) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getValidationRequirements(req: Request, res: Response) {
    try {
      const requirements = ['businessName', 'category', 'address', 'phone', 'email', 'hours', 'website', 'logoUrl'];
      res.status(200).json({ requiredFields: requirements });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async validateField(req: Request, res: Response) {
    try {
      const { fieldName, value } = req.body;
      if (!fieldName) return res.status(400).json({ error: 'fieldName required' });
      const valid = value !== undefined && value !== null && value !== '';
      res.status(200).json({ fieldName, valid, message: valid ? 'Valid' : 'Invalid or missing' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getProfileSuggestions(req: Request, res: Response) {
    try {
      const { businessName, category, address, phone, email, hours, website, logoUrl } = await supabase
        .from('business_profiles')
        .select('business_name,category,address,phone,email,hours,website,logo_url')
        .eq('user_id', req.user?.id)
        .single()
        .then(res => res.data || {});
      const suggestions: string[] = [];
      if (!businessName) suggestions.push('Add your business name');
      if (!category) suggestions.push('Select a business category');
      if (!address) suggestions.push('Provide your business address');
      if (!phone) suggestions.push('Add a contact phone number');
      if (!email) suggestions.push('Add a contact email');
      if (!hours) suggestions.push('Set your business hours');
      if (!website) suggestions.push('Add your website URL');
      if (!logoUrl) suggestions.push('Upload a business logo');
      res.status(200).json({ suggestions });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Campaign Management Methods
  private async getBusinessCampaigns(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Extract query parameters for filtering
      const status = req.query.status as string;
      const type = req.query.type as string;
      
      const campaigns = await this.campaignService.getBusinessCampaigns(businessId, {
        status: status ? status as any : undefined,
        type: type ? type as any : undefined
      });
      
      res.status(200).json(campaigns);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async createCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      const {
        title,
        description,
        campaignType,
        visibility,
        requirements,
        targetCustomers,
        influencerSpots,
        periodStart,
        periodEnd,
        creditsPerAction,
        totalCredits,
        imageUrl
      } = req.body;
      
      // Validate required fields
      if (!title || !description || !campaignType || !periodStart || !periodEnd || !creditsPerAction || !totalCredits) {
        return res.status(400).json({ error: 'Missing required fields' });
      }
      
      const campaign = await this.campaignService.createCampaign({
        businessId,
        title,
        description,
        campaignType,
        visibility: visibility || 'public',
        status: 'draft',
        requirements,
        targetCustomers,
        influencerSpots,
        periodStart: new Date(periodStart),
        periodEnd: new Date(periodEnd),
        creditsPerAction,
        totalCredits,
        imageUrl
      });
      
      if (!campaign) {
        return res.status(500).json({ error: 'Failed to create campaign' });
      }
      
      res.status(201).json(campaign);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCampaignDetails(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      const campaign = await this.campaignService.getCampaignById(campaignId);
      
      if (!campaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      // Verify business ownership
      if (campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden - You do not own this campaign' });
      }
      
      res.status(200).json(campaign);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Verify campaign ownership
      const existingCampaign = await this.campaignService.getCampaignById(campaignId);
      
      if (!existingCampaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      if (existingCampaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden - You do not own this campaign' });
      }
      
      // Extract update fields
      const updates: any = {};
      const allowedFields = [
        'title', 'description', 'visibility', 'requirements',
        'targetCustomers', 'influencerSpots', 'periodStart', 'periodEnd',
        'creditsPerAction', 'totalCredits', 'imageUrl'
      ];
      
      for (const field of allowedFields) {
        if (req.body[field] !== undefined) {
          updates[field] = req.body[field];
        }
      }
      
      // Convert date strings to Date objects
      if (updates.periodStart) updates.periodStart = new Date(updates.periodStart);
      if (updates.periodEnd) updates.periodEnd = new Date(updates.periodEnd);
      
      const updatedCampaign = await this.campaignService.updateCampaign(campaignId, updates);
      
      if (!updatedCampaign) {
        return res.status(500).json({ error: 'Failed to update campaign' });
      }
      
      res.status(200).json(updatedCampaign);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async deleteCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Verify campaign ownership
      const existingCampaign = await this.campaignService.getCampaignById(campaignId);
      
      if (!existingCampaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      if (existingCampaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden - You do not own this campaign' });
      }
      
      const success = await this.campaignService.deleteCampaign(campaignId);
      
      if (!success) {
        return res.status(500).json({ error: 'Failed to delete campaign' });
      }
      
      res.status(200).json({ message: 'Campaign deleted successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateCampaignStatus(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      const { status } = req.body;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      if (!status || !['draft', 'active', 'paused', 'completed', 'cancelled'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
      }
      
      // Verify campaign ownership
      const existingCampaign = await this.campaignService.getCampaignById(campaignId);
      
      if (!existingCampaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      if (existingCampaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden - You do not own this campaign' });
      }
      
      const updatedCampaign = await this.campaignService.updateCampaign(campaignId, { status });
      
      if (!updatedCampaign) {
        return res.status(500).json({ error: 'Failed to update campaign status' });
      }
      
      res.status(200).json(updatedCampaign);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCampaignMetrics(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Verify campaign ownership
      const existingCampaign = await this.campaignService.getCampaignById(campaignId);
      
      if (!existingCampaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      if (existingCampaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden - You do not own this campaign' });
      }
      
      const metrics = await this.campaignService.getCampaignMetrics(campaignId);
      
      if (!metrics) {
        return res.status(404).json({ error: 'Metrics not found' });
      }
      
      res.status(200).json(metrics);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCampaignParticipants(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      // Confirm ownership
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) return res.status(403).json({ error: 'Forbidden' });
      // Fetch accepted participants
      const { data, error } = await supabase
        .from('accepted_campaigns')
        .select('*')
        .eq('campaign_id', campaignId);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Application Management Methods
  private async getCampaignApplications(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) return res.status(403).json({ error: 'Forbidden' });
      const { data, error } = await supabase
        .from('campaign_applications')
        .select('*')
        .eq('campaign_id', campaignId);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async acceptApplication(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      const applicationId = req.params.applicationId;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      // Accept application
      const { data, error } = await supabase
        .from('campaign_applications')
        .update({ status: 'accepted', updated_at: new Date().toISOString() })
        .eq('id', applicationId)
        .eq('campaign_id', campaignId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      // Create accepted record
      await supabase.from('accepted_campaigns').insert([{ campaign_id: campaignId, influencer_id: data.influencer_id }]);
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async rejectApplication(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      const applicationId = req.params.applicationId;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase
        .from('campaign_applications')
        .update({ status: 'rejected', updated_at: new Date().toISOString() })
        .eq('id', applicationId)
        .eq('campaign_id', campaignId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async inviteInfluencer(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const influencerId = req.params.id;
      const campaignId = req.body.campaignId;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase
        .from('campaign_invites')
        .insert([{ campaign_id: campaignId, influencer_id: influencerId, status: 'pending' }])
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(201).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Visit Management Methods
  private async verifyVisit(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const { qrCode } = req.body;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      if (!qrCode) {
        return res.status(400).json({ error: 'QR code required' });
      }
      
      const verification = await this.visitService.verifyQrCode(qrCode);
      
      if (!verification.isValid) {
        return res.status(400).json({ error: 'Invalid QR code' });
      }
      
      // Verify business ownership of the campaign
      const campaign = await this.campaignService.getCampaignById(verification.campaignId!);
      
      if (!campaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      if (campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden - Campaign does not belong to this business' });
      }
      
      // Create pending visit
      const visit = await this.visitService.createVisit({
        campaignId: verification.campaignId!,
        influencerId: verification.influencerId!,
        customerId: verification.customerId!,
        businessId,
        status: 'pending'
      });
      
      if (!visit) {
        return res.status(500).json({ error: 'Failed to create visit record' });
      }
      
      res.status(200).json({
        visit,
        message: 'QR code verified successfully. Approve visit to allocate credits and loyalty points.'
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getVisits(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Extract query parameters
      const status = req.query.status as string;
      const startDate = req.query.startDate ? new Date(req.query.startDate as string) : undefined;
      const endDate = req.query.endDate ? new Date(req.query.endDate as string) : undefined;
      
      const visits = await this.visitService.getVisitsByBusiness(businessId, {
        status: status as any,
        startDate,
        endDate
      });
      
      res.status(200).json(visits);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async approveVisit(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const visitId = req.params.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Get visit
      const { data, error } = await supabase
        .from('visits')
        .select('*')
        .eq('id', visitId)
        .eq('business_id', businessId)
        .eq('status', 'pending')
        .single();
      
      if (error || !data) {
        return res.status(404).json({ error: 'Visit not found or already processed' });
      }
      
      // Get campaign for credit information
      const campaign = await this.campaignService.getCampaignById(data.campaign_id);
      
      if (!campaign) {
        return res.status(404).json({ error: 'Campaign not found' });
      }
      
      // Approve visit
      const creditsEarned = campaign.creditsPerAction;
      const loyaltyPointsEarned = 10; // Example value, could be configurable
      
      const updatedVisit = await this.visitService.approveVisit(
        visitId,
        creditsEarned,
        loyaltyPointsEarned
      );
      
      if (!updatedVisit) {
        return res.status(500).json({ error: 'Failed to approve visit' });
      }
      
      // Grant loyalty points to customer
      await this.loyaltyService.createOrUpdateLoyaltyPoints(
        data.customer_id,
        businessId,
        loyaltyPointsEarned
      );
      
      // TODO: Update influencer credits
      
      res.status(200).json({
        visit: updatedVisit,
        message: 'Visit approved successfully'
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async rejectVisit(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const visitId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase
        .from('visits')
        .update({ status: 'rejected' })
        .eq('id', visitId)
        .eq('business_id', businessId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getVisitStats(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      
      // Extract period from query params
      const startDate = req.query.startDate ? new Date(req.query.startDate as string) : undefined;
      const endDate = req.query.endDate ? new Date(req.query.endDate as string) : undefined;
      
      // Only pass period when both dates are provided
      const period = startDate && endDate ? { startDate, endDate } : undefined;
      const stats = await this.visitService.getVisitStats(businessId, period);
      
      res.status(200).json(stats);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Messaging Methods
  private async getConversations(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const conversations = await this.conversationService.getUserConversations(businessId, 'business');
      res.status(200).json(conversations);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getConversationByCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.campaignId;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const conversation = await this.conversationService.getConversationByCampaignAndUsers(campaignId, businessId, req.query.influencerId as string);
      if (!conversation) return res.status(404).json({ error: 'Conversation not found' });
      res.status(200).json(conversation);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getMessages(req: Request, res: Response) {
    try {
      const conversationId = req.params.id;
      const messages = await this.conversationService.getMessagesByConversationId(conversationId);
      res.status(200).json(messages);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async sendMessage(req: Request, res: Response) {
    try {
      const conversationId = req.params.id;
      const senderId = req.user?.id as string;
      const content = req.body.content;
      const message = await this.conversationService.sendMessage(conversationId, senderId, content);
      res.status(201).json(message);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async markConversationRead(req: Request, res: Response) {
    try {
      const conversationId = req.params.id;
      const userId = req.user?.id as string;
      const userType = 'business';
      const success = await this.conversationService.markConversationAsRead(conversationId, userId, userType);
      res.status(200).json({ success });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Check if messaging is allowed based on campaign status
  private async getConversationCampaignStatus(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const conversationId = req.params.id;
      const conversation = await this.conversationService.getConversationById(conversationId);
      if (!conversation) return res.status(404).json({ error: 'Conversation not found' });
      if (conversation.businessId !== businessId) return res.status(403).json({ error: 'Forbidden' });
      const campaign = await this.campaignService.getCampaignById(conversation.campaignId);
      if (!campaign) return res.status(404).json({ error: 'Campaign not found' });
      const allowed = campaign.status === 'active';
      res.status(200).json({ allowed, status: campaign.status });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async messageParticipant(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const { id: campaignId, participantId } = req.params;
      const { message } = req.body;
      
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      if (!message) return res.status(400).json({ error: 'Message content required' });
      
      // Verify campaign ownership
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      
      // TODO: Implement participant messaging
      // This would create a conversation or send a message to a campaign participant
      
      res.status(200).json({ 
        success: true, 
        message: 'Message sent to participant',
        participantId,
        campaignId
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Loyalty & Rewards Methods
  private async scanRewardQR(req: Request, res: Response) {
    try {
      const qrCode = req.body.qrCode;
      const redemption = await this.loyaltyService.verifyRewardQrCode(qrCode);
      if (!redemption) return res.status(400).json({ error: 'Invalid or expired reward QR code' });
      res.status(200).json(redemption);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async validateReward(req: Request, res: Response) {
    try {
      const redemptionId = req.params.redemptionId;
      const result = await this.loyaltyService.approveRewardRedemption(redemptionId);
      if (!result) return res.status(400).json({ error: 'Invalid redemption or already processed' });
      res.status(200).json(result);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getRewardRedemptions(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase
        .from('reward_redemptions')
        .select('*')
        .eq('business_id', businessId);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getPendingRewardRedemptions(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const pending = await this.loyaltyService.getBusinessRedemptions(businessId, 'pending');
      res.status(200).json(pending);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async completeRewardRedemption(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const { redemptionId } = req.params;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      // Verify redemption belongs to business
      const { data: redemption, error: fetchError } = await supabase
        .from('reward_redemptions')
        .select('business_id')
        .eq('id', redemptionId)
        .single();
      if (fetchError || !redemption) {
        return res.status(404).json({ error: 'Redemption not found' });
      }
      if (redemption.business_id !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await this.loyaltyService.approveRewardRedemption(redemptionId);
      if (!result) {
        return res.status(400).json({ error: 'Unable to complete redemption' });
      }
      res.status(200).json(result);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Analytics Methods
  private async getDashboardAnalytics(req: Request, res: Response) {
    // Simple stub: return counts of campaigns, visits, etc.
    const businessId = req.user?.id;
    const { data: campaigns } = await supabase.from('campaigns').select('id').eq('business_id', businessId);
    const { data: visits } = await supabase.from('visits').select('id').eq('business_id', businessId);
    res.status(200).json({ totalCampaigns: campaigns?.length || 0, totalVisits: visits?.length || 0 });
  }

  private async getCampaignAnalytics(req: Request, res: Response) {
    const campaignId = req.params.id;
    const metrics = await this.campaignService.getCampaignMetrics(campaignId);
    if (!metrics) return res.status(404).json({ error: 'No metrics found' });
    res.status(200).json(metrics);
  }

  private async getInfluencerAnalytics(req: Request, res: Response) {
    // TODO: implement influencer performance analytics
    res.status(200).json({});
  }

  private async getVisitorAnalytics(req: Request, res: Response) {
    // TODO: implement visitor traffic data
    res.status(200).json({});
  }

  // Google My Business Methods
  private async connectGmb(req: Request, res: Response) {
    try {
      // Generate OAuth URL
      const clientId = process.env.GMB_CLIENT_ID;
      const redirectUri = process.env.GMB_REDIRECT_URI;
      if (!clientId || !redirectUri) {
        return res.status(500).json({ error: 'GMB OAuth configuration missing' });
      }
      const scope = encodeURIComponent('https://www.googleapis.com/auth/business.manage');
      const state = req.user?.id;
      const oauthUrl = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scope}&access_type=offline&state=${state}`;
      res.status(200).json({ url: oauthUrl });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to generate GMB OAuth URL' });
    }
  }

  private async syncGmb(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      // Trigger sync job (stub)
      // In real impl, would refresh tokens, call GMB API, update business_profiles
      res.status(200).json({ message: 'GMB sync initiated' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to sync GMB data' });
    }
  }

  private async disconnectGmb(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      // Remove GMB connection (stub)
      await supabase
        .from('gmb_connections')
        .delete()
        .eq('business_id', businessId);
      res.status(200).json({ message: 'Disconnected from GMB' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to disconnect GMB' });
    }
  }

  private async getGmbStatus(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      const { data } = await supabase
        .from('gmb_connections')
        .select('id, created_at')
        .eq('business_id', businessId)
        .single();
      const connected = !!data;
      res.status(200).json({ connected, connection: data });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to fetch GMB status' });
    }
  }

  // Stub handlers for GMB Optional Profile Import
  private async searchGmb(req: Request, res: Response) {
    // TODO: implement search against GMB API
    res.status(200).json([]);
  }

  private async verifyGmbOwnership(req: Request, res: Response) {
    // TODO: implement GMB ownership verification
    res.status(200).json({ success: true });
  }

  private async getGmbLocations(req: Request, res: Response) {
    // TODO: fetch GMB locations
    res.status(200).json([]);
  }

  private async selectGmbLocation(req: Request, res: Response) {
    // TODO: set primary GMB location
    res.status(200).json({ success: true });
  }

  private async getGmbPhotos(req: Request, res: Response) {
    // TODO: fetch GMB photos
    res.status(200).json([]);
  }

  private async getGmbReviews(req: Request, res: Response) {
    // TODO: fetch GMB reviews
    res.status(200).json([]);
  }

  private async getGmbHours(req: Request, res: Response) {
    // TODO: fetch GMB hours
    res.status(200).json({});
  }

  private async getGmbAttributes(req: Request, res: Response) {
    // TODO: fetch GMB attributes
    res.status(200).json({});
  }

  private async importGmbProfile(req: Request, res: Response) {
    // TODO: import selected GMB data into profile
    res.status(200).json({ success: true });
  }

  // Content Management Methods
  private async getCampaignContent(req: Request, res: Response, next: NextFunction) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const { data, error } = await supabase
        .from('content_submissions')
        .select(`
          id, content_url, content_type, platform, description, status,
          submitted_at, reviewed_at, reviewer_notes,
          influencer_id, user_profiles!inner(first_name, last_name, username, profile_image_url)
        `)
        .eq('campaign_id', campaignId)
        .order('submitted_at', { ascending: false });
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCampaignContentAnalytics(req: Request, res: Response, next: NextFunction) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const { data: contentItems, error: contentError } = await supabase
        .from('content_submissions')
        .select('id')
        .eq('campaign_id', campaignId);
      if (contentError || !contentItems) return res.status(500).json({ error: contentError?.message });
      const contentIds = contentItems.map(item => item.id);
      const { data: metadata, error: metaError } = await supabase
        .from('content_metadata')
        .select('*')
        .in('content_id', contentIds);
      if (metaError) return res.status(500).json({ error: metaError.message });
      res.status(200).json({ metadata });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getContentPerformance(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      
      // TODO: Implement content performance metrics
      // This would return detailed performance data for campaign content
      
      const performance = {
        campaignId,
        totalContent: 0,
        averageEngagement: 0,
        topPerformingContent: [],
        contentByPlatform: {},
        engagementTrends: []
      };
      
      res.status(200).json(performance);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async approveContent(req: Request, res: Response, next: NextFunction) {
    try {
      const businessId = req.user?.id;
      const { id: campaignId, contentId } = req.params;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const { data, error } = await supabase
        .from('content_submissions')
        .update({ 
          status: 'approved', 
          reviewed_at: new Date().toISOString(),
          reviewer_notes: req.body.notes || null
        })
        .eq('id', contentId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async rejectContent(req: Request, res: Response, next: NextFunction) {
    try {
      const businessId = req.user?.id;
      const { id: campaignId, contentId } = req.params;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const { data, error } = await supabase
        .from('content_submissions')
        .update({ 
          status: 'rejected', 
          reviewed_at: new Date().toISOString(),
          reviewer_notes: req.body.notes || 'Content rejected'
        })
        .eq('id', contentId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Media Event Scheduling
  private async scheduleMediaEvent(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const { eventDate, location, details, maxParticipants } = req.body;
      if (!eventDate || !location || !details) {
        return res.status(400).json({ error: 'Required fields: eventDate, location, details' });
      }
      const { data, error } = await supabase
        .from('media_event_details')
        .insert([{
          campaign_id: campaignId,
          event_date: new Date(eventDate).toISOString(),
          location,
          details,
          max_participants: maxParticipants
        }])
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      res.status(201).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCreditPool(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      if (campaign.campaignType === 'media_event') {
        const { data, error } = await supabase.from('media_event_details').select('max_participants').eq('campaign_id', campaignId).single();
        if (error) return res.status(500).json({ error: error.message });
        return res.status(200).json({ creditPool: data.max_participants });
      }
      res.status(200).json({ creditPool: campaign.totalCredits });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getLoyaltyRewardCampaigns(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaigns = await this.campaignService.getBusinessCampaigns(businessId, { type: 'loyalty_reward' });
      res.status(200).json(campaigns);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCampaignRedemptions(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase.from('reward_redemptions').select('*').eq('campaign_id', campaignId);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Influencer Management Methods
  private async listInfluencers(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const { data, error } = await supabase
        .from('influencer_profiles')
        .select('*');
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getPendingApplications(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) return res.status(403).json({ error: 'Forbidden' });
      const { data, error } = await supabase
        .from('campaign_applications')
        .select('*')
        .eq('campaign_id', campaignId)
        .eq('status', 'pending');
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getCampaignInvites(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) return res.status(403).json({ error: 'Forbidden' });
      const { data, error } = await supabase
        .from('campaign_invites')
        .select('*')
        .eq('campaign_id', campaignId);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updateCampaignInviteStatus(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      const inviteId = req.params.inviteId;
      const { status } = req.body;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      const campaign = await this.campaignService.getCampaignById(campaignId);
      if (!campaign || campaign.businessId !== businessId) return res.status(403).json({ error: 'Forbidden' });
      const { data, error } = await supabase
        .from('campaign_invites')
        .update({ status })
        .eq('id', inviteId)
        .select()
        .single();
      if (error) return res.status(500).json({ error: error.message });
      if (!data) return res.status(404).json({ error: 'Invite not found' });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Team Management Handlers
  private async listTeamMembers(req: Request, res: Response) {
    res.status(200).json([]);
  }

  private async inviteTeamMember(req: Request, res: Response) {
    res.status(200).json({ success: true });
  }

  private async removeTeamMember(req: Request, res: Response) {
    res.status(200).json({ success: true });
  }

  private async updateTeamMemberRole(req: Request, res: Response) {
    res.status(200).json({ success: true });
  }

  private async updateTeamMemberStatus(req: Request, res: Response) {
    res.status(200).json({ success: true });
  }

  private async getTeamInvitations(req: Request, res: Response) {
    res.status(200).json([]);
  }

  private async getTeamRoles(req: Request, res: Response) {
    res.status(200).json(['admin', 'member', 'viewer']);
  }

  private async setTeamMemberPermissions(req: Request, res: Response) {
    res.status(200).json({ success: true });
  }

  // Credit Purchase & Payment System Handlers
  private async getCreditBalance(req: Request, res: Response) {
    // TODO: fetch business credit balance
    res.status(200).json({ balance: 0 });
  }

  private async getCreditPackages(req: Request, res: Response) {
    // TODO: list available credit packages
    res.status(200).json([]);
  }

  private async purchaseCredit(req: Request, res: Response) {
    // TODO: process credit package purchase
    res.status(200).json({ success: true });
  }

  private async getCreditTransactions(req: Request, res: Response) {
    // TODO: fetch credit purchase history
    res.status(200).json([]);
  }

  private async processPayment(req: Request, res: Response) {
    // TODO: integrate payment gateway
    res.status(200).json({ success: true });
  }

  private async getPaymentMethods(req: Request, res: Response) {
    // TODO: get saved payment methods
    res.status(200).json([]);
  }

  private async addPaymentMethod(req: Request, res: Response) {
    // TODO: add new payment method
    res.status(200).json({ success: true });
  }

  private async removePaymentMethod(req: Request, res: Response) {
    // TODO: remove payment method
    res.status(200).json({ success: true });
  }

  private async getInvoices(req: Request, res: Response) {
    // TODO: fetch billing invoices and receipts
    res.status(200).json([]);
  }

  // Business Verification Methods
  private async submitBusinessVerification(req: Request, res: Response) {
    // TODO: implement business verification submission
    res.status(200).json({ success: true });
  }

  private async getBusinessVerificationStatus(req: Request, res: Response) {
    // TODO: return verification status
    res.status(200).json({ status: 'pending' });
  }

  private async uploadVerificationDocuments(req: Request, res: Response) {
    // TODO: handle verification document uploads
    res.status(200).json({ success: true });
  }

  private async getVerificationRequirements(req: Request, res: Response) {
    // TODO: return verification requirements list
    res.status(200).json([]);
  }

  // Enhanced Campaign Management Methods
  private async pauseCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      // TODO: implement pause campaign logic
      res.status(200).json({ success: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async resumeCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      // TODO: implement resume campaign logic
      res.status(200).json({ success: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async duplicateCampaign(req: Request, res: Response) {
    try {
      const businessId = req.user?.id;
      const campaignId = req.params.id;
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      // TODO: implement duplicate campaign logic
      res.status(200).json({ success: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Enhanced Visit Management Methods
  private async validateManualScan(req: Request, res: Response) {
    try {
      const { verificationCode, location } = req.body;
      const businessId = req.user?.id;
      
      if (!businessId) return res.status(401).json({ error: 'Unauthorized' });
      if (!verificationCode) return res.status(400).json({ error: 'Verification code required' });
      
      // TODO: Implement actual manual scan validation logic
      // This would validate the code against active campaigns and visits
      
      res.status(200).json({ 
        valid: true, 
        message: 'Manual scan validated successfully',
        verificationCode 
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async validateScanResult(req: Request, res: Response) {
    // TODO: validate scanned QR code with location/etc.
    res.status(200).json({ valid: true });
  }

  private async getRecentVisits(req: Request, res: Response) {
    // TODO: return recent scan results for business
    res.status(200).json([]);
  }

  private async getPendingVisits(req: Request, res: Response) {
    // TODO: return visits pending approval for business
    res.status(200).json([]);
  }

  // Advanced Campaign Analytics
  private async getDetailedCampaignMetrics(req: Request, res: Response) {
    // TODO: implement detailed campaign metrics
    res.status(200).json({});
  }

  private async getCampaignTrafficData(req: Request, res: Response) {
    // TODO: implement campaign traffic data
    res.status(200).json({});
  }

  private async getCampaignEngagementStats(req: Request, res: Response) {
    // TODO: implement campaign engagement stats
    res.status(200).json({});
  }

  private async getCampaignRoi(req: Request, res: Response) {
    // TODO: implement campaign ROI
    res.status(200).json({});
  }

  private async getCampaignTimeline(req: Request, res: Response) {
    // TODO: implement campaign timeline
    res.status(200).json({});
  }

  private async getDetailedParticipants(req: Request, res: Response) {
    // TODO: implement detailed participants
    res.status(200).json({});
  }

  private async getParticipantPerformance(req: Request, res: Response) {
    // TODO: implement participant performance
    res.status(200).json({});
  }

  private async updateParticipantStatus(req: Request, res: Response) {
    // TODO: implement participant status update
    res.status(200).json({ success: true });
  }

  // Advanced Campaign Creation Methods
  private async createCampaignDraft(req: Request, res: Response) {
    // TODO: implement save draft logic
    res.status(200).json({ success: true });
  }

  private async getCampaignTemplates(req: Request, res: Response) {
    // TODO: implement fetching campaign templates
    res.status(200).json([]);
  }

  private async uploadCampaignImage(req: Request, res: Response) {
    // TODO: implement campaign image upload with file storage
    res.status(200).json({ imageUrl: '' });
  }

  private async validateCampaignSettings(req: Request, res: Response) {
    // TODO: implement campaign settings validation
    res.status(200).json({ valid: true });
  }

  // Influencer Discovery & Portfolio Methods
  private async getAvailableInfluencers(req: Request, res: Response) {
    // TODO: list available influencers for collaboration
    const { data, error } = await supabase.from('influencer_profiles').select('*').eq('is_active', true);
    if (error) return res.status(500).json({ error: error.message });
    res.status(200).json(data);
  }

  private async searchInfluencers(req: Request, res: Response) {
    // TODO: implement search with filters
    const { q } = req.query;
    const { data, error } = await supabase.from('influencer_profiles').select('*').ilike('niche', `%${q}%`);
    if (error) return res.status(500).json({ error: error.message });
    res.status(200).json(data);
  }

  private async getInfluencerProfile(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { data, error } = await supabase.from('influencer_profiles').select('*').eq('user_id', id).single();
      if (error) return res.status(404).json({ error: 'Profile not found' });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getInfluencerPortfolio(req: Request, res: Response) {
    try {
      const { id } = req.params;
      // TODO: fetch influencer content submissions
      const { data, error } = await supabase.from('submitted_content').select('*').eq('influencer_id', id);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getInfluencerCampaignHistory(req: Request, res: Response) {
    try {
      const { id } = req.params;
      // TODO: fetch past campaigns for influencer
      const { data, error } = await supabase.from('campaign_applications').select('*').eq('influencer_id', id);
      if (error) return res.status(500).json({ error: error.message });
      res.status(200).json(data);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Advanced Scan & Visit Processing Methods
  private async preValidateQrCode(req: Request, res: Response) {
    // TODO: pre-validate QR code without approving visit
    const { qrCode } = req.body;
    if (!qrCode) return res.status(400).json({ error: 'qrCode required' });
    // Simulated validity
    res.status(200).json({ valid: true });
  }

  private async getScanDetails(req: Request, res: Response) {
    // TODO: return detailed scan result info
    const { scanId } = req.params;
    res.status(200).json({ scanId, details: {} });
  }

  private async reportScanIssue(req: Request, res: Response) {
    // TODO: report scan issues
    res.status(200).json({ success: true });
  }

  private async getScanHistory(req: Request, res: Response) {
    // TODO: return scan history with filters
    res.status(200).json([]);
  }

  private async addVisitNotes(req: Request, res: Response) {
    // TODO: add business notes to visit records
    res.status(200).json({ success: true });
  }
} 
# Collabuu Backend API Development Plan

## ✅ **IMPLEMENTATION STATUS: COMPLETE**

**All core platform functionality has been successfully implemented and is ready for testing and frontend integration.**

### 🔧 **Environment & Database Setup**
- ✅ Complete database schema (`database/schema.sql`) [x] implementation
- ✅ Environment configuration setup (`SETUP.md`) [x] implementation  
- ✅ Supabase integration with Row Level Security [x] implementation

### 🔐 **Authentication System**
- ✅ Business authentication (register/login) [x] implementation
- ✅ Influencer authentication (register/login) [x] implementation
- ✅ Customer authentication (register/login) [x] implementation
- ✅ JWT middleware with role-based access control [x] implementation

### 🎯 **Core Campaign & QR System**
- ✅ Campaign creation and management (all 4 types) [x] implementation
- ✅ Campaign application and invitation flow [x] implementation
- ✅ QR code generation and verification [x] implementation
- ✅ Referral code and deep link system [x] implementation
- ✅ Visit tracking and approval workflow [x] implementation

### 📝 **Content Submission System**
- ✅ Multi-platform content submission [x] implementation
- ✅ Automatic platform detection [x] implementation
- ✅ Content review and approval workflow [x] implementation
- ✅ Performance tracking [x] implementation

### 💬 **Messaging System**
- ✅ Campaign-based conversations [x] implementation
- ✅ Message sending and retrieval [x] implementation
- ✅ Read status tracking [x] implementation
- ✅ Campaign status restrictions [x] implementation

### 🎁 **Loyalty & Rewards System**
- ✅ Loyalty points tracking [x] implementation
- ✅ Reward redemption system [x] implementation
- ✅ QR code generation for rewards [x] implementation
- ✅ Transaction history [x] implementation

### 🔔 **Notification System**
- ✅ Notification creation and management [x] implementation
- ✅ Read/unread status tracking [x] implementation
- ✅ Notification preferences [x] implementation
- ✅ Bulk operations [x] implementation

### 📊 **Analytics & Performance**
- ✅ Influencer performance tracking [x] implementation
- ✅ Campaign analytics [x] implementation
- ✅ Earnings breakdown [x] implementation
- ✅ Visit statistics [x] implementation

---

## Overview
This document outlines the backend endpoints and APIs needed to make the Collabuu platform fully functional. The platform connects businesses, influencers, and customers through campaigns and QR-based visit tracking.

## Database Schema Overview (Supabase)

Based on the codebase analysis, we need the following main tables:

### Core Tables
- [x] `user_profiles` - Base user data (existing) [x] implementation [x] api_test
- [x] `business_profiles` - Business-specific information [x] implementation [x] api_test
- [x] `influencer_profiles` - Influencer-specific information [x] implementation [x] api_test
- [x] `customer_profiles` - Customer-specific information [x] implementation [x] api_test
- [x] `campaigns` - Campaign information [x] implementation [x] api_test
- [x] `campaign_applications` - Influencer applications to campaigns [x] implementation [x] api_test
- [x] `campaign_invites` - Business invites to influencers [x] implementation [x] api_test
- [x] `accepted_campaigns` - Campaigns accepted by influencers [x] implementation [x] api_test
- [x] `visits` - QR code verified visits [x] implementation [x] api_test
- [x] `conversations` - Messages between users [x] implementation [x] api_test
- [x] `messages` - Individual messages [x] implementation [x] api_test
- [x] `customer_favorites` - Customer favorites [x] implementation [x] api_test
- [x] `notifications` - Push notifications [x] implementation [x] api_test
- [x] `loyalty_points` - Customer loyalty point balances [x] implementation [x] api_test
- [x] `loyalty_transactions` - Point earning/redemption history [x] implementation [x] api_test
- [x] `reward_redemptions` - Loyalty reward redemptions [x] implementation [x] api_test
- [x] `content_submissions` - Influencer content submissions [x] implementation [x] api_test
- [x] `influencer_referrals` - Referral codes [x] implementation [x] api_test
- [x] `influencer_links` - Deep link tracking [x] implementation [x] api_test

## 🔄 CORE PLATFORM FLOW

The following outlines the complete user journey that the API endpoints must support:

### **Step 1**: Business Creates Campaign
- Business creates campaign via `POST /api/business/campaigns` (with campaign type and visibility)
- Campaign types: Pay Per Customer, Pay Per Post, Media Event
- Visibility: Public (discoverable) or Private (invite-only)
- Public campaigns automatically appear in influencer opportunities
- Private campaigns only accessible via direct invites

### **Step 2**: Influencer Discovery & Application
- Influencer browses PUBLIC opportunities via `GET /api/influencer/opportunities`
- Influencer applies via `POST /api/influencer/opportunities/{id}/apply`
- **Applied campaign moves to influencer's campaigns list with "Pending" status**
- **OR** Business directly invites influencer to PRIVATE campaigns via `POST /api/business/influencers/{id}/invite`
- **Withdrawal Option**: Influencer can withdraw pending applications via `POST /api/influencer/campaigns/{id}/withdraw`
- Withdrawn campaigns return to opportunities list and influencer can reapply
- Media Events can have shared credit pools instead of individual payments

### **Step 3**: Campaign Acceptance & Messaging Enabled
- Business accepts application via `POST /api/business/campaigns/{id}/applications/{applicationId}/accept`
- **OR** Influencer accepts invite via `POST /api/influencer/invites/{inviteId}/accept`
- Accepted campaign moves to influencer's active campaigns
- **Messaging automatically enabled** between business and influencer for this campaign
- Conversation created and linked to specific campaign ID

### **Step 4**: Influencer Content Creation & Submission
- Influencer gets unique referral code via `GET /api/influencer/campaigns/{id}/referral-code`
- Influencer generates deep link via `POST /api/influencer/campaigns/{id}/generate-deeplink`
- Influencer creates and posts content on any supported platform (social media, blogs, podcasts, etc.)
- Influencer submits content links via `POST /api/influencer/campaigns/{id}/submit-content`
- System automatically recognizes platform type and extracts metadata
- Content appears in business dashboard with embedded previews for review

### **Step 5**: Customer Discovery & Engagement
- Customer clicks deep link or enters referral code in app
- Campaign details retrieved via `GET /api/campaigns/by-deeplink/{code}`
- Customer adds campaign to favorites via `POST /api/customer/favorites/by-code`

### **Step 6**: Customer Visit & QR Code Scanning
- Customer visits business and opens QR code via `GET /api/customer/favorites/{id}/qr-code`
- Business scans QR code via `POST /api/business/visits/verify`
- Business approves visit via `POST /api/business/visits/approve`

### **Step 7**: Credit & Loyalty Point Allocation
- **Pay Per Customer**: Customer earns loyalty points, influencer gets credits per verified visit
- **Pay Per Post**: Influencer gets credits per approved social media post
- **Media Event**: Shared credit pool distributed among all participating influencers
- **Loyalty Reward**: Customer redeems loyalty points for business rewards
- Business credits are deducted and allocated based on campaign type
- All performance metrics update across dashboards

### **Step 8**: Loyalty Reward Redemption Flow (Parallel Process)
- Customer views available loyalty rewards via `GET /api/customer/rewards/available`
- Customer redeems reward using loyalty points via `POST /api/customer/rewards/{rewardId}/redeem`
- Loyalty points are deducted from customer balance
- Redeemed reward is added to customer favorites with QR code
- Customer visits business and presents reward QR code
- Business scans QR code via `POST /api/business/rewards/scan`
- Business validates and applies reward via `POST /api/business/rewards/{redemptionId}/validate`
- Reward marked as completed and removed from active favorites

### **Step 9**: Campaign Completion & Messaging Restriction
- When campaign status changes to "completed", "cancelled", or "expired"
- Messaging between business and influencer is automatically disabled
- Existing conversation remains visible (read-only) for reference
- No new messages can be sent between the parties
- Messaging can only resume if they collaborate on a new active campaign

## 🎨 CONTENT SUBMISSION & RECOGNITION SYSTEM

### **Supported Content Platforms**
• **Social Media Platforms**:
  - Instagram (Posts, Stories, Reels)
  - TikTok (Videos, Live streams)
  - YouTube (Videos, Shorts, Community posts)
  - Facebook (Posts, Stories, Videos)
  - Twitter/X (Tweets, Threads)
  - LinkedIn (Posts, Articles)
  - Snapchat (Posts, Stories)
  - Pinterest (Pins, Boards)

• **Content Platforms**:
  - Personal/Business Blogs
  - Medium articles
  - Substack newsletters
  - WordPress sites
  - Ghost publications

• **Other Platforms**:
  - Podcast episodes (Spotify, Apple Podcasts)
  - Twitch streams/clips
  - Discord server posts

### **Automatic Link Recognition**
• **Platform Detection**: System automatically identifies platform from URL structure
• **Content Type Recognition**: Distinguishes between posts, videos, stories, articles, etc.
• **Metadata Extraction**: Pulls title, description, thumbnails, engagement metrics when available
• **Embed Generation**: Creates appropriate embed code for business dashboard display
• **Performance Tracking**: Monitors engagement metrics where platform APIs allow

### **Content Submission Flow**
1. **Influencer Submits**: Pastes any content URL into submission form
2. **Auto-Recognition**: System detects platform and content type
3. **Metadata Fetch**: Extracts available content information and preview
4. **Business Review**: Content appears in business dashboard with embedded preview
5. **Approval Process**: Business can approve/reject content for campaign credit
6. **Analytics Tracking**: System monitors content performance over time

### **Business Content Dashboard**
• **Embedded Previews**: Native content display for each platform type
• **Performance Metrics**: Engagement stats, reach, impressions where available
• **Content Approval**: Simple approve/reject workflow for Pay Per Post campaigns
• **Content Library**: Organized view of all campaign content across platforms
• **Export Options**: Download content URLs and metrics for external analysis

## 📝 APPLICATION STATUS FLOW

### **Influencer Application States**
1. **Available in Opportunities**: Campaign is discoverable and can be applied to
2. **Pending**: Applied campaign appears in influencer's campaigns list awaiting business approval
3. **Active**: Business approved application, campaign moves to active status with messaging enabled
4. **Withdrawn**: Influencer withdraws pending application, campaign returns to opportunities list
5. **Rejected**: Business rejects application, campaign remains in opportunities (can reapply)
6. **Completed**: Campaign finished, messaging disabled, moves to history

### **Campaign Status Management**
• **For Influencers**: 
  - Applied campaigns immediately show as "Pending" in campaigns list
  - Pending campaigns show "Pending Approval" status with "Withdraw" button
  - Withdrawn campaigns disappear from campaigns and reappear in opportunities
  - Can reapply to previously withdrawn campaigns

• **For Businesses**:
  - Applications appear in pending list for review
  - Can see application history including withdrawn applications
  - Withdrawn applications automatically removed from pending review queue

## 📋 CAMPAIGN TYPES & VISIBILITY

### **Campaign Types**

#### **1. Pay Per Customer**
- Influencer earns credits for each customer that visits the business via their referral
- Requires QR code verification at business location
- Individual credit allocation per influencer
- Customer earns loyalty points for visit

#### **2. Pay Per Post** (formerly Pay Per View)
- Influencer earns credits for creating and posting content across any supported platform
- Content can be social media posts, blog articles, podcast episodes, videos, etc.
- Influencer submits content links with automatic platform recognition and metadata extraction
- Business reviews content via embedded previews in dashboard
- Business approves/rejects content for credit allocation
- Payment based on content quality, reach, and approval status
- No customer visit required

#### **3. Media Event**
- Business hosts event with free food/products for influencers
- Scheduled event with specific time and location
- Shared credit pool distributed among all participants
- Influencers check in at event location
- Can be combined with Pay Per Post for additional content creation

#### **4. Loyalty Reward** (NEW)
- Ongoing promotion that customers can redeem using loyalty points
- Business sets reward details (discount amount, free item, percentage off, etc.)
- Customer browses available rewards and redeems with loyalty points
- Redemption creates QR code that customer presents at business
- Business scans QR code to validate and apply reward
- No influencer involvement - direct business-to-customer rewards
- Business credits deducted when reward campaign is created

### **Campaign Visibility**

#### **Public Campaigns**
- Visible in influencer opportunity feed
- Any qualified influencer can apply
- Appears in customer deals section
- Searchable and discoverable

#### **Private Campaigns**
- Invite-only access
- Business directly invites specific influencers
- Not visible in public opportunity feed
- Not shown to customers unless they have referral code

## 🏢 GOOGLE MY BUSINESS INTEGRATION

### **GMB Integration Flow**

#### **Step 1: Business Registration & Profile Setup**
- Business registers with basic email/password via `POST /api/business/auth/register`
- Business completes initial profile setup manually or proceeds to GMB connection
- **Optional GMB Connection**: Business can click "Connect Google My Business" button in Profile page
- OAuth 2.0 flow to authorize GMB API access for data import only

#### **Step 2: Profile Data Import (GMB Connected Businesses Only)**
- Once connected, system automatically syncs GMB data via `PUT /api/business/profile/sync-gmb`
- Business name, address, phone, website, hours, photos imported from GMB
- Business can select which GMB location (for multi-location businesses)
- Business sets display preferences for what GMB information to show publicly
- **Manual Profile Option**: Businesses can skip GMB and enter details manually

#### **Step 3: Ongoing Sync & Updates (GMB Connected Only)**
- Periodic automatic sync to keep GMB data current
- Manual sync option for immediate GMB updates
- Sync history tracking for GMB data change monitoring
- **Non-GMB businesses**: Update profile manually through standard edit forms

### **GMB Data Integration**

#### **Business Information (Auto-populated from GMB):**
- Business name and legal name
- Complete address and location coordinates
- Phone number and website
- Business category and attributes
- Business hours (including holiday hours)
- Business photos and logo
- Service areas (for service-based businesses)

#### **Read-Only GMB Data (Display Only):**
- Customer reviews and ratings
- GMB posts and updates
- Q&A from customers
- Business attributes (wheelchair accessible, WiFi, etc.)

#### **Benefits of GMB Integration:**
- **Simplified Profile Setup**: Reduces manual data entry for connected businesses
- **Accurate Information**: Always up-to-date business details from GMB
- **Trust & Verification**: GMB verification adds business legitimacy
- **Rich Content**: Access to professional photos and business attributes
- **Multi-Location Support**: Handle franchise/chain businesses properly
- **Optional Feature**: Businesses can choose manual profile setup instead

## API Endpoints by User Type

---

## 🏢 BUSINESS ENDPOINTS

### Authentication & Profile Management
- [x] `POST /api/business/auth/register` - Business registration (email/password) [x] implementation [x] api_test
- [x] `POST /api/business/auth/login` - Business login [x] implementation [x] api_test
- [x] `GET /api/business/profile` - Get business profile (manual or GMB data) [x] implementation [x] api_test
- [x] `PUT /api/business/profile` - Update business profile manually [x] implementation [x] api_test
- [x] `POST /api/business/profile/connect-gmb` - Connect Google My Business account (from Profile page) [x] implementation [x] api_test
- [x] `PUT /api/business/profile/sync-gmb` - Sync latest data from Google My Business [x] implementation [x] api_test
- [x] `DELETE /api/business/profile/disconnect-gmb` - Disconnect GMB integration [x] implementation [x] api_test
- [x] `GET /api/business/profile/gmb-status` - Check GMB connection status [x] implementation [x] api_test

### Extended Profile Management
- [x] `POST /api/business/profile/logo/upload` - Upload business logo with image processing [x] implementation [x] api_test
- [x] `GET /api/business/profile/completion-status` - Get profile completion percentage and missing fields [x] implementation [x] api_test
- [x] `PUT /api/business/profile/social-media` - Update social media handles (Instagram, Facebook, LinkedIn) [x] implementation [x] api_test
- [x] `PUT /api/business/profile/business-details` - Update business details (founded year, employee count, hours) [x] implementation [x] api_test
- [x] `PUT /api/business/profile/visibility` - Update business discoverability settings [x] implementation [x] api_test
- [x] `GET /api/business/categories` - Get available business categories with icons [x] implementation [x] api_test
- [x] `POST /api/business/profile/validate` - Validate profile fields before saving [x] implementation [x] api_test
- [x] `GET /api/business/profile/validation/requirements` - Get profile completion requirements [x] implementation [x] api_test
- [x] `POST /api/business/profile/validate/field` - Validate individual profile fields [x] implementation [x] api_test
- [x] `GET /api/business/profile/suggestions` - Get profile improvement suggestions [x] implementation [x] api_test

### Campaign Management
- [x] `GET /api/business/campaigns` - Get business campaigns with filters (by type, visibility) [x] implementation [x] api_test
- [x] `POST /api/business/campaigns` - Create new campaign (Pay Per Customer/Post/Media Event/Loyalty Reward) [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}` - Get campaign details [x] implementation [x] api_test
- [x] `PUT /api/business/campaigns/{id}` - Update campaign [x] implementation [x] api_test
- [x] `DELETE /api/business/campaigns/{id}` - Delete campaign [x] implementation [x] api_test
- [x] `PUT /api/business/campaigns/{id}/visibility` - Update campaign visibility (public/private) [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/metrics` - Get campaign performance metrics [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/participants` - Get campaign participants [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/content` - Get all submitted content with embedded previews [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/content/analytics` - Get content performance metrics [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/content/{contentId}/approve` - Approve submitted content [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/content/{contentId}/reject` - Reject submitted content [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/media-event/schedule` - Schedule media event details [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/credit-pool` - Get shared credit pool (Media Events) [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/rewards` - Get all loyalty reward campaigns [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/redemptions` - Get reward redemption history [x] implementation [x] api_test

### Influencer Management
- [x] `GET /api/business/influencers` - Browse available influencers [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/applications` - Get campaign applications (pending, accepted, rejected, withdrawn) [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/applications/{applicationId}/accept` - Accept influencer [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/applications/{applicationId}/reject` - Reject influencer [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/applications/pending` - Get pending applications only [x] implementation [x] api_test
- [x] `POST /api/business/influencers/{id}/invite` - Direct invite to campaign [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/invites` - Get campaign invites sent [x] implementation [x] api_test
- [x] `PUT /api/business/campaigns/{id}/invites/{inviteId}` - Update invite status [x] implementation [x] api_test

### QR Code & Visit Management
- [x] `POST /api/business/visits/verify` - Verify QR code and approve visit [x] implementation [x] api_test
- [x] `GET /api/business/visits` - Get business visit history [x] implementation [x] api_test
- [x] `GET /api/business/visits/stats` - Get visit statistics [x] implementation [x] api_test
- [x] `POST /api/business/scan/validate` - Validate manual entry code [x] implementation [x] api_test
- [x] `POST /api/business/visits/approve` - Approve visit and process credit transfer [x] implementation [x] api_test

### Reward Redemption Management
- [x] `POST /api/business/rewards/scan` - Scan customer reward QR code [x] implementation [x] api_test
- [x] `POST /api/business/rewards/{redemptionId}/validate` - Validate and apply reward [x] implementation [x] api_test
- [x] `GET /api/business/rewards/redemptions` - Get all reward redemptions [x] implementation [x] api_test
- [x] `GET /api/business/rewards/redemptions/pending` - Get pending reward validations [x] implementation [x] api_test
- [x] `POST /api/business/rewards/{redemptionId}/complete` - Mark reward as completed/used [x] implementation [x] api_test

### Messaging (Campaign-Based Only)
- [x] `GET /api/business/conversations` - Get active campaign conversations only [x] implementation [x] api_test
- [x] `GET /api/business/conversations/by-campaign/{campaignId}` - Get conversation for specific campaign [x] implementation [x] api_test
- [x] `GET /api/business/conversations/{id}/messages` - Get conversation messages [x] implementation [x] api_test
- [x] `POST /api/business/conversations/{id}/messages` - Send message (only if campaign active) [x] implementation [x] api_test
- [x] `PUT /api/business/conversations/{id}/mark-read` - Mark conversation as read [x] implementation [x] api_test
- [x] `GET /api/business/conversations/{id}/campaign-status` - Check if messaging still allowed [x] implementation [x] api_test

### Google My Business Integration (Optional Profile Import)
- [x] `GET /api/business/gmb/search` - Search for business in GMB database (from Profile page) [x] implementation [x] api_test
- [x] `POST /api/business/gmb/verify` - Verify business ownership via GMB OAuth [x] implementation [x] api_test
- [x] `GET /api/business/gmb/locations` - Get all GMB locations for multi-location businesses [x] implementation [x] api_test
- [x] `PUT /api/business/gmb/select-location` - Select primary GMB location for data import [x] implementation [x] api_test
- [x] `GET /api/business/gmb/photos` - Get GMB photos for profile display [x] implementation [x] api_test
- [x] `GET /api/business/gmb/reviews` - Get GMB reviews (read-only display) [x] implementation [x] api_test
- [x] `GET /api/business/gmb/hours` - Get current business hours from GMB [x] implementation [x] api_test
- [x] `GET /api/business/gmb/attributes` - Get GMB business attributes and categories [x] implementation [x] api_test
- [x] `POST /api/business/gmb/import-profile` - Import selected GMB data to business profile [x] implementation [x] api_test

### Team Management
- [x] `GET /api/business/team/members` - Get all team members with roles and status [x] implementation [x] api_test
- [x] `POST /api/business/team/invite` - Send team invitation by email with role [x] implementation [x] api_test
- [x] `DELETE /api/business/team/members/{memberId}` - Remove team member [x] implementation [x] api_test
- [x] `PUT /api/business/team/members/{memberId}/role` - Update member role [x] implementation [x] api_test
- [x] `PUT /api/business/team/members/{memberId}/status` - Update member status (active/inactive/suspended) [x] implementation [x] api_test
- [x] `GET /api/business/team/invitations` - Get pending team invitations [x] implementation [x] api_test
- [x] `GET /api/business/team/roles` - Get available roles and permissions [x] implementation [x] api_test
- [x] `POST /api/business/team/members/{memberId}/permissions` - Set custom permissions [x] implementation [x] api_test

### Credit Purchase & Payment System
- [x] `GET /api/business/credits/balance` - Get current credit balance [x] implementation [x] api_test
- [x] `GET /api/business/credits/packages` - Get available credit packages [x] implementation [x] api_test
- [x] `POST /api/business/credits/purchase` - Purchase credit package [x] implementation [x] api_test
- [x] `GET /api/business/credits/transactions` - Get credit purchase history [x] implementation [x] api_test
- [x] `POST /api/business/payments/process` - Process payment for credit purchase [x] implementation [x] api_test
- [x] `GET /api/business/payments/methods` - Get saved payment methods [x] implementation [x] api_test
- [x] `POST /api/business/payments/methods` - Add new payment method [x] implementation [x] api_test
- [x] `DELETE /api/business/payments/methods/{methodId}` - Remove payment method [x] implementation [x] api_test
- [x] `GET /api/business/payments/invoices` - Get billing invoices and receipts [x] implementation [x] api_test

### Business Verification
- [x] `POST /api/business/profile/verify` - Submit business for verification [x] implementation [x] api_test
- [x] `GET /api/business/profile/verification-status` - Check verification status [x] implementation [x] api_test
- [x] `POST /api/business/profile/verification/documents` - Upload verification documents [x] implementation [x] api_test
- [x] `GET /api/business/profile/verification/requirements` - Get verification requirements [x] implementation [x] api_test

### Enhanced Campaign Management
- [x] `PUT /api/business/campaigns/{id}/status` - Update campaign status (active/paused/completed) [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/pause` - Pause active campaign [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/resume` - Resume paused campaign [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/duplicate` - Duplicate existing campaign [x] implementation [x] api_test

### Enhanced Visit Management
- [x] `POST /api/business/visits/scan-result/validate` - Validate scanned QR code [x] implementation [x] api_test
- [x] `GET /api/business/visits/recent` - Get recent scan results [x] implementation [x] api_test
- [x] `GET /api/business/visits/pending` - Get visits pending approval [x] implementation [x] api_test
- [x] `POST /api/business/visits/{visitId}/approve` - Approve specific visit [x] implementation [x] api_test
- [x] `POST /api/business/visits/{visitId}/reject` - Reject specific visit with reason [x] implementation [x] api_test

### Advanced Campaign Analytics
- [x] `GET /api/business/campaigns/{id}/metrics/detailed` - Get comprehensive campaign metrics [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/traffic/data` - Get visitor traffic data with charts [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/engagement/stats` - Get engagement statistics [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/roi` - Get ROI and performance calculations [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/timeline` - Get campaign activity timeline [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/participants/detailed` - Get detailed participant info [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/{id}/participants/{participantId}/performance` - Get individual performance [x] implementation [x] api_test
- [x] `PUT /api/business/campaigns/{id}/participants/{participantId}/status` - Update participant status [x] implementation [x] api_test

### Content Performance & Management
- [x] `GET /api/business/campaigns/{id}/content/performance` - Get content performance metrics [x] implementation [x] api_test
- [x] `GET /api/business/content/{contentId}/engagement` - Get detailed engagement stats (likes, comments, shares) [x] implementation [x] api_test
- [x] `GET /api/business/content/{contentId}/analytics` - Get content analytics with platform data [x] implementation [x] api_test
- [x] `POST /api/business/content/{contentId}/report` - Report content issues [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/participants/{participantId}/message` - Direct message participant [x] implementation [x] api_test

### Advanced Campaign Creation
- [x] `POST /api/business/campaigns/draft` - Save campaign as draft [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/templates` - Get campaign templates [x] implementation [x] api_test
- [x] `POST /api/business/campaigns/{id}/image/upload` - Upload campaign image [x] implementation [x] api_test
- [x] `GET /api/business/campaigns/validation` - Validate campaign settings before creation [x] implementation [x] api_test

### Influencer Discovery & Portfolio
- [x] `GET /api/business/influencers/available` - Get available influencers for collaboration [x] implementation [x] api_test
- [x] `GET /api/business/influencers/search` - Search influencers with advanced filters [x] implementation [x] api_test
- [x] `GET /api/business/influencers/{id}/profile` - Get detailed influencer profile [x] implementation [x] api_test
- [x] `GET /api/business/influencers/{id}/portfolio` - Get influencer content portfolio [x] implementation [x] api_test
- [x] `GET /api/business/influencers/{id}/campaigns/history` - Get influencer's past campaigns [x] implementation [x] api_test

### Advanced Scan & Visit Processing
- [x] `POST /api/business/scan/validate-qr` - Pre-validate QR code before processing [x] implementation [x] api_test
- [x] `GET /api/business/scan/{scanId}/details` - Get detailed scan result information [x] implementation [x] api_test
- [x] `POST /api/business/scan/report-issue` - Report scan issues and problems [x] implementation [x] api_test
- [x] `GET /api/business/scan/history` - Get scan history with date/status filters [x] implementation [x] api_test
- [x] `POST /api/business/visits/{visitId}/notes` - Add business notes to visit records [x] implementation [x] api_test

### Analytics & Reporting
- [x] `GET /api/business/analytics/dashboard` - Dashboard metrics [x] implementation [x] api_test
- [x] `GET /api/business/analytics/campaigns` - Campaign performance analytics [x] implementation [x] api_test
- [x] `GET /api/business/analytics/influencers` - Influencer performance [x] implementation [x] api_test
- [x] `GET /api/business/analytics/visitors` - Visitor traffic data [x] implementation [x] api_test

---

## 📱 INFLUENCER ENDPOINTS

### Authentication & Profile Management
- [x] `POST /api/influencer/auth/register` - Influencer registration [x] implementation [x] api_test
- [x] `POST /api/influencer/auth/login` - Influencer login [x] implementation [x] api_test
- [x] `GET /api/influencer/profile` - Get influencer profile [x] implementation [x] api_test
- [x] `PUT /api/influencer/profile` - Update influencer profile [x] implementation [x] api_test
- [x] `POST /api/influencer/profile/upload-image` - Upload profile image [x] implementation [x] api_test
- [x] `POST /api/influencer/profile/social-links` - Update social media links [x] implementation [x] api_test

### Opportunity Discovery
- [x] `GET /api/influencer/opportunities` - Browse PUBLIC campaign opportunities with filters (by type) [x] implementation [x] api_test
- [x] `GET /api/influencer/opportunities/{id}` - Get opportunity details [x] implementation [x] api_test
- [x] `POST /api/influencer/opportunities/{id}/apply` - Apply to opportunity [x] implementation [x] api_test
- [x] `GET /api/influencer/opportunities/categories` - Get available categories [x] implementation [x] api_test
- [x] `GET /api/influencer/opportunities/recommended` - Get personalized recommendations [x] implementation [x] api_test
- [x] `GET /api/influencer/opportunities/media-events` - Browse upcoming media events [x] implementation [x] api_test
- [x] `GET /api/influencer/invites` - Get direct PRIVATE campaign invites from businesses [x] implementation [x] api_test
- [x] `POST /api/influencer/invites/{inviteId}/accept` - Accept campaign invite [x] implementation [x] api_test
- [x] `POST /api/influencer/invites/{inviteId}/decline` - Decline campaign invite [x] implementation [x] api_test

### Campaign Management
- [x] `GET /api/influencer/campaigns` - Get all campaigns (pending, active, completed) with filters (by type, status) [x] implementation [x] api_test
- [x] `GET /api/influencer/campaigns/{id}` - Get campaign details with current status [x] implementation [x] api_test
- [x] `POST /api/influencer/campaigns/{id}/withdraw` - Withdraw pending application (moves back to opportunities) [x] implementation [x] api_test
- [x] `GET /api/influencer/campaigns/pending` - Get pending approval campaigns specifically [x] implementation [x] api_test
- [x] `POST /api/influencer/campaigns/{id}/submit-content` - Submit any social media content/blog links with auto-recognition [x] implementation [x] api_test
- [x] `GET /api/influencer/campaigns/{id}/performance` - Get campaign performance [x] implementation [x] api_test
- [x] `POST /api/influencer/campaigns/{id}/generate-code` - Generate campaign QR code (Pay Per Customer) [x] implementation [x] api_test
- [x] `POST /api/influencer/campaigns/{id}/generate-deeplink` - Generate campaign deep link [x] implementation [x] api_test
- [x] `GET /api/influencer/campaigns/{id}/visits` - Get visit history [x] implementation [x] api_test
- [x] `GET /api/influencer/campaigns/{id}/referral-code` - Get unique influencer referral code [x] implementation [x] api_test
- [x] `GET /api/influencer/campaigns/{id}/media-event/details` - Get media event schedule and location [x] implementation [x] api_test
- [x] `POST /api/influencer/campaigns/{id}/media-event/checkin` - Check into media event [x] implementation [x] api_test

### Content & Performance Tracking
- [x] `POST /api/influencer/content/submit` - Submit any content link (auto-detects platform type) [x] implementation [x] api_test
- [x] `GET /api/influencer/content` - Get submitted content history with status [x] implementation [x] api_test
- [x] `GET /api/influencer/content/{contentId}` - Get specific content details and analytics [x] implementation [x] api_test
- [x] `PUT /api/influencer/content/{contentId}` - Update content details or replace link [x] implementation [x] api_test
- [x] `DELETE /api/influencer/content/{contentId}` - Delete submitted content [x] implementation [x] api_test
- [x] `GET /api/influencer/content/platforms` - Get supported content platforms [x] implementation [x] api_test
- [x] `GET /api/influencer/performance/overview` - Overall performance metrics [x] implementation [x] api_test
- [x] `GET /api/influencer/performance/earnings` - Earnings breakdown [x] implementation [x] api_test

### Messaging (Campaign-Based Only)
- [x] `GET /api/influencer/conversations` - Get active campaign conversations only [x] implementation [x] api_test
- [x] `GET /api/influencer/conversations/by-campaign/{campaignId}` - Get conversation for specific campaign [x] implementation [x] api_test
- [x] `GET /api/influencer/conversations/{id}/messages` - Get messages [x] implementation [x] api_test
- [x] `POST /api/influencer/conversations/{id}/messages` - Send message (only if campaign active) [x] implementation [x] api_test
- [x] `GET /api/influencer/conversations/{id}/campaign-status` - Check if messaging still allowed [x] implementation [x] api_test

### Credits & Withdrawals
- [x] `GET /api/influencer/credits/balance` - Get credit balance [x] implementation [x] api_test
- [x] `GET /api/influencer/credits/history` - Get credit transaction history [x] implementation [x] api_test
- [x] `POST /api/influencer/credits/withdraw` - Request credit withdrawal [x] implementation [x] api_test
- [x] `GET /api/influencer/credits/withdrawal-history` - Get withdrawal history [x] implementation [x] api_test

### Advanced Wallet & Payment Management
- [x] `GET /api/influencer/wallet/balance` - Detailed wallet balance (credits + pending earnings) [x] implementation [x] api_test
- [x] `GET /api/influencer/wallet/transactions` - Complete credit and earnings transaction history [x] implementation [x] api_test
- [x] `POST /api/influencer/wallet/withdrawals` - Create withdrawal request [x] implementation [x] api_test
- [x] `GET /api/influencer/wallet/withdrawals/{id}` - Get withdrawal request status [x] implementation [x] api_test
- [x] `DELETE /api/influencer/wallet/withdrawals/{id}/cancel` - Cancel pending withdrawal request [x] implementation [x] api_test
- [x] `GET /api/influencer/wallet/payment-methods` - Get saved payout methods (PayPal, bank) [x] implementation [x] api_test
- [x] `POST /api/influencer/wallet/payment-methods` - Add new payout method [x] implementation [x] api_test
- [x] `DELETE /api/influencer/wallet/payment-methods/{methodId}` - Remove payout method [x] implementation [x] api_test

### Profile Verification & Statistics
- [x] `POST /api/influencer/profile/verification/request` - Submit verification request (ID/social proof) [x] implementation [x] api_test
- [x] `GET /api/influencer/profile/verification/status` - Check verification status [x] implementation [x] api_test
- [x] `GET /api/influencer/profile/stats` - Get influencer statistics (followers, engagement, earnings) [x] implementation [x] api_test

### Advanced Messaging Enhancements
- [x] `GET /api/influencer/messages/unread-count` - Global unread count for badge [x] implementation [x] api_test
- [x] `PUT /api/influencer/conversations/{id}/typing` - Typing indicator (optional realtime) [x] implementation [x] api_test

### Analytics & Dashboard
- [x] `GET /api/influencer/dashboard/summary` - High-level KPIs (active campaigns, earnings, visits) [x] implementation [x] api_test
- [x] `GET /api/influencer/dashboard/chart-data` - Time-series data for charts (visits, earnings) [x] implementation [x] api_test

### Search & Discovery
- [x] `POST /api/influencer/search` - Universal search across opportunities & businesses [x] implementation [x] api_test
- [x] `GET /api/influencer/search/history` - Get past search queries [x] implementation [x] api_test
- [x] `DELETE /api/influencer/search/history` - Clear search history [x] implementation [x] api_test

---

## 👥 CUSTOMER ENDPOINTS

### Authentication & Profile Management
- [x] `POST /api/customer/auth/register` - Customer registration [x] implementation [x] api_test
- [x] `POST /api/customer/auth/login` - Customer login [x] implementation [x] api_test
- [x] `GET /api/customer/profile` - Get customer profile [x] implementation [x] api_test
- [x] `PUT /api/customer/profile` - Update customer profile [x] implementation [x] api_test

### Favorites Management
- [x] `GET /api/customer/favorites` - Get customer favorites (campaigns and redeemed rewards) [x] implementation [x] api_test
- [x] `POST /api/customer/favorites` - Add business/campaign to favorites [x] implementation [x] api_test
- [x] `POST /api/customer/favorites/by-code` - Add campaign to favorites using referral code [x] implementation [x] api_test
- [x] `DELETE /api/customer/favorites/{id}` - Remove from favorites [x] implementation [x] api_test
- [x] `GET /api/customer/favorites/{id}/qr-code` - Generate QR code for visit or reward redemption [x] implementation [x] api_test
- [x] `GET /api/customer/favorites/rewards` - Get redeemed rewards in favorites [x] implementation [x] api_test
- [x] `GET /api/customer/favorites/{favoriteId}/reward-qr` - Generate QR code for reward redemption [x] implementation [x] api_test

### Deals & Rewards
- [x] `GET /api/customer/deals` - Browse available deals (from PUBLIC campaigns only) [x] implementation [x] api_test
- [x] `GET /api/customer/deals/{id}` - Get deal details [x] implementation [x] api_test
- [x] `GET /api/customer/rewards` - Get loyalty points balance and available rewards [x] implementation [x] api_test
- [x] `GET /api/customer/rewards/available` - Browse available loyalty reward campaigns [x] implementation [x] api_test
- [x] `POST /api/customer/rewards/{rewardId}/redeem` - Redeem loyalty reward (deducts points) [x] implementation [x] api_test
- [x] `GET /api/customer/rewards/history` - Get loyalty points transaction history [x] implementation [x] api_test
- [x] `GET /api/customer/rewards/redemptions` - Get reward redemption history [x] implementation [x] api_test
- [x] `POST /api/customer/visits/loyalty-points` - Earn loyalty points from visit [x] implementation [x] api_test
- [x] `GET /api/customer/deals/media-events` - Browse upcoming public media events [x] implementation [x] api_test

### Business Discovery
- [x] `GET /api/customer/businesses` - Browse businesses [x] implementation [x] api_test
- [x] `GET /api/customer/businesses/search` - Search businesses [x] implementation [x] api_test
- [x] `GET /api/customer/businesses/{id}` - Get business details [x] implementation [x] api_test
- [x] `GET /api/customer/businesses/categories` - Get business categories [x] implementation [x] api_test

### Visit Tracking
- [x] `GET /api/customer/visits` - Get visit history [x] implementation [x] api_test
- [x] `GET /api/customer/visits/stats` - Get visit statistics [x] implementation [x] api_test

---

## 🔄 SHARED ENDPOINTS

### Notifications
- [x] `GET /api/notifications` - Get user notifications [x] implementation [x] api_test
- [x] `PUT /api/notifications/{id}/read` - Mark notification as read [x] implementation [x] api_test
- [x] `PUT /api/notifications/mark-all-read` - Mark all notifications as read [x] implementation [x] api_test
- [x] `POST /api/notifications/preferences` - Update notification preferences [x] implementation [x] api_test
- [x] `GET /api/notifications/unread-count` - Get unread notification count [x] implementation [x] api_test
- [x] `DELETE /api/notifications/{id}` - Delete notification [x] implementation [x] api_test

### Search & Discovery
- [x] `GET /api/search/global` - Global search across platform [x] implementation [x] api_test
- [x] `GET /api/search/suggestions` - Get search suggestions [x] implementation [x] api_test
- [x] `GET /api/categories` - Get all platform categories [x] implementation [x] api_test
- [x] `GET /api/campaigns/by-deeplink/{code}` - Get campaign details from deep link [x] implementation [x] api_test
- [x] `POST /api/campaigns/validate-referral-code` - Validate influencer referral code [x] implementation [x] api_test

### Content Platform Support
- [x] `GET /api/content/platforms` - Get all supported content platforms [x] implementation [x] api_test
- [x] `POST /api/content/recognize-link` - Analyze and recognize content link platform/type [x] implementation [x] api_test
- [x] `GET /api/content/embed-preview/{contentId}` - Get embed preview for content [x] implementation [x] api_test
- [x] `POST /api/content/extract-metadata` - Extract metadata from content URL [x] implementation [x] api_test

### File Management
- [x] `POST /api/upload/image` - Upload image to storage [x] implementation [x] api_test
- [x] `DELETE /api/upload/{fileId}` - Delete uploaded file [x] implementation [x] api_test

---

## 📊 IMPLEMENTATION PRIORITY

### Phase 1: Core Functionality (Week 1-2)
1. **Authentication & Profiles**
   - [x] User registration/login for all types [x] implementation
   - [x] Google My Business OAuth integration [x] implementation
   - [x] GMB profile data import and sync [x] implementation
   - [x] Basic profile data display [x] implementation

2. **Campaign Basics**
   - [x] Create/read/update campaigns (Business) [x] implementation
   - [x] Browse opportunities (Influencer) [x] implementation
   - [x] Apply to opportunities (Influencer) [x] implementation

### Phase 2: Core Features (Week 3-4)
3. **QR Code System**
   - [x] QR code generation (Customer) [x] implementation
   - [x] QR code verification (Business) [x] implementation
   - [x] Visit tracking and credit allocation [x] implementation

4. **Messaging System**
   - [x] Basic messaging between users [x] implementation
   - [x] Conversation management [x] implementation
   - [x] Real-time updates (WebSocket/Supabase Realtime) [x] implementation

### Phase 3: Enhanced Features (Week 5-6)
5. **Analytics & Performance**
   - Campaign performance tracking
   - Influencer metrics
   - Business analytics dashboard

6. **Favorites & Deals**
   - Customer favorites system
   - Deal management
   - Credit/reward system

### Phase 4: Advanced Features (Week 7-8)
7. **Notifications**
   - Push notification system
   - Email notifications
   - In-app notifications

8. **Advanced Search & Discovery**
   - Recommendation algorithms
   - Advanced filtering
   - Location-based discovery

---

## 🏗️ TECHNICAL ARCHITECTURE

### Database Structure
```sql
-- Core user tables
user_profiles (existing)
business_profiles -- Enhanced with GMB integration fields
gmb_connections -- Google My Business OAuth tokens and connection data
gmb_sync_history -- Track GMB data sync timestamps and changes
influencer_profiles
customer_profiles

-- Team management system
team_members -- Business team members with roles and permissions
team_invitations -- Pending team invitations
team_roles -- Role definitions and permissions
member_permissions -- Custom permissions per team member

-- Campaign system
campaigns -- (campaign_type: pay_per_customer, pay_per_post, media_event, loyalty_reward | visibility: public, private)
campaign_opportunities
campaign_applications -- (status: pending, accepted, rejected, withdrawn)
campaign_invites -- NEW: Direct business invites to influencers
accepted_campaigns
campaign_participants
referral_codes -- NEW: Unique codes linking influencers to campaigns
media_event_details -- NEW: Event scheduling, location, shared credit pools
credit_pools -- NEW: Shared credit pools for media events
loyalty_reward_details -- NEW: Reward campaign details (point cost, reward description, terms)

-- Content management system
submitted_content -- NEW: All influencer content submissions with platform recognition
content_metadata -- NEW: Extracted metadata from content links (titles, thumbnails, etc.)
content_analytics -- NEW: Performance tracking for submitted content
platform_embeds -- NEW: Generated embed codes for business dashboard display

-- Visit tracking
visits
qr_codes
visit_transactions -- NEW: Credit/loyalty point transactions from visits

-- Messaging (Campaign-Based Only)
conversations -- Links business-influencer messaging to specific active campaigns
messages -- Messages within campaign-based conversations
conversation_permissions -- Tracks active/inactive status based on campaign state

-- Favorites & deals
customer_favorites -- Enhanced to include redeemed rewards
deals
credit_transactions
loyalty_points -- NEW: Customer loyalty point tracking
reward_redemptions -- NEW: Track reward redemptions and QR codes
loyalty_transactions -- NEW: Loyalty point earning and spending history

-- Deep linking & referrals
deep_links -- NEW: Campaign deep link management
referral_tracking -- NEW: Track customer acquisitions via influencer codes

-- Notifications
notifications
notification_preferences

-- Payment & billing system
credit_packages -- Available credit packages for purchase
credit_transactions -- Credit purchase transactions
payment_methods -- Stored payment methods for businesses
invoices -- Billing invoices and receipts
business_verifications -- Business verification requests and status

-- Enhanced filtering & search
filter_presets -- Saved filter configurations
search_history -- User search history and suggestions
```

### API Architecture
- **Framework**: Node.js/Express or Python/FastAPI
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth + OAuth 2.0 for GMB
- **File Storage**: Supabase Storage
- **Real-time**: Supabase Realtime
- **Push Notifications**: OneSignal or Firebase
- **Image Processing**: Cloudinary or similar
- **External APIs**: Google My Business API v4.9
- **OAuth Management**: Google OAuth 2.0 for GMB integration
- **Data Sync**: Background jobs for periodic GMB sync

### File Organization
```
/backend
  /business
    /routes
    /controllers
    /services
    /models
  /influencer
    /routes
    /controllers
    /services
    /models
  /customer
    /routes
    /controllers
    /services
    /models
  /shared
    /middleware
    /utils
    /config
```

## 💬 MESSAGING RESTRICTIONS & IMPLEMENTATION

### Core Messaging Rules
• **Campaign-Based Only**: Messages only allowed between business and influencer when they have an active approved campaign together
• **Automatic Creation**: Conversation automatically created when campaign is accepted/approved
• **Automatic Termination**: Messaging disabled when campaign status becomes completed/cancelled/expired
• **Read-Only Archive**: Past conversations remain visible but no new messages allowed
• **Multi-Campaign**: Business and influencer can have multiple active conversations if collaborating on multiple campaigns

### Database Schema Requirements
```sql
-- Enhanced conversations table
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES users(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE, -- Required
  is_active BOOLEAN DEFAULT true, -- Auto-updated based on campaign status
  last_message_at TIMESTAMP WITH TIME ZONE,
  business_read_at TIMESTAMP WITH TIME ZONE,
  influencer_read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_conversations_business ON conversations(business_id);
CREATE INDEX idx_conversations_influencer ON conversations(influencer_id);
CREATE INDEX idx_conversations_campaign ON conversations(campaign_id);
CREATE INDEX idx_conversations_active ON conversations(is_active);
CREATE UNIQUE INDEX idx_conversations_unique ON conversations(business_id, influencer_id, campaign_id);

-- Trigger to update conversation status when campaign status changes
CREATE OR REPLACE FUNCTION update_conversation_status()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations 
  SET is_active = CASE 
    WHEN NEW.status IN ('completed', 'cancelled', 'expired') THEN false
    WHEN NEW.status = 'active' THEN true
    ELSE is_active
  END
  WHERE campaign_id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER conversation_status_trigger
  AFTER UPDATE OF status ON campaigns
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_status();
```

### API Implementation Details
• **Message Send Validation**: Check `is_active` and campaign status before allowing message creation
• **Conversation List**: Only return conversations with `is_active = true`
• **Archive Access**: Separate endpoint for viewing past conversations (read-only)
• **Status Checks**: Real-time validation of messaging permissions before each action

### Frontend Implementation
• **Message Input**: Disable/hide message input when conversation becomes inactive
• **Visual Indicators**: Show "Campaign Completed - Messaging Disabled" banner
• **Archive View**: Clearly distinguish between active and archived conversations
• **Automatic Updates**: Listen to campaign status changes to update messaging UI

---

## 🔒 SECURITY CONSIDERATIONS

### Authentication & Authorization
- JWT tokens with Supabase Auth
- Role-based access control (RLS in Supabase)
- API rate limiting
- Request validation and sanitization

### Data Protection
- Encrypt sensitive data at rest
- HTTPS enforcement
- Input validation and SQL injection prevention
- XSS protection

### QR Code Security
- Time-limited QR codes
- One-time use verification codes
- Geolocation validation (optional)
- Fraud detection algorithms

---

## 🧪 TESTING STRATEGY

### Unit Tests
- API endpoint testing
- Business logic validation
- Database query testing

### Integration Tests
- End-to-end user flows
- QR code generation and verification
- Payment and credit systems
- Real-time messaging

### Performance Tests
- Load testing for high-traffic scenarios
- Database optimization
- API response time optimization

---

## 📈 MONITORING & ANALYTICS

### Application Monitoring
- API performance metrics
- Error tracking and logging
- User behavior analytics
- System health monitoring

### Business Metrics
- Campaign performance tracking
- User engagement metrics
- Revenue and credit flow
- Platform growth metrics

---

## 🚀 DEPLOYMENT STRATEGY

### Environment Setup
- **Development**: Local development with Supabase
- **Staging**: Cloud deployment for testing
- **Production**: Scalable cloud infrastructure

### CI/CD Pipeline
- Automated testing on push
- Deployment automation
- Database migration management
- Environment configuration management

This plan provides a comprehensive roadmap for implementing the backend infrastructure needed to support the Collabuu platform's full functionality across all user types.

## 🏗️ TECHNICAL ARCHITECTURE

### Database Structure
The system uses a PostgreSQL database with the following key tables:

1. **User Management**
   - `user_profiles`: Core user data for all user types (business, influencer, customer)
   - `business_profiles`: Extended profile information for business users

2. **Campaign Management**
   - `campaigns`: Campaign details created by businesses to attract influencers and customers
   - `submitted_content`: Content uploaded by influencers for campaigns
   - `content_metadata`: Additional metadata for submitted content

3. **Visit Tracking**
   - `visits`: Records of customer visits to businesses through influencer referrals

4. **Messaging**
   - `conversations`: Conversation threads between businesses and influencers
   - `messages`: Individual messages within conversations

5. **Loyalty System**
   - `loyalty_points`: Customer loyalty point balances for each business
   - `loyalty_transactions`: History of point earn/spend transactions
   - `reward_redemptions`: Redemption of rewards using loyalty points

### API Architecture
The API follows a RESTful design with the following key endpoints:

1. **Authentication**
   - `/auth/register`: User registration
   - `/auth/login`: User authentication
   - `/auth/refresh`: Token refresh

2. **User Management**
   - `/users/profile`: Profile CRUD operations
   - `/users/business`: Business profile management

3. **Campaigns**
   - `/campaigns`: Campaign CRUD operations
   - `/campaigns/:id/participants`: Campaign participant management
   - `/campaigns/:id/content`: Content submission and approval

4. **Visits**
   - `/visits/verify`: QR code verification for visits
   - `/visits/history`: Visit history and reporting

5. **Messaging**
   - `/conversations`: Conversation management
   - `/messages`: Message sending and retrieval

6. **Loyalty**
   - `/loyalty/points`: Loyalty point balance queries
   - `/loyalty/transactions`: Point transaction history
   - `/loyalty/rewards`: Reward redemption operations

7. **Analytics**
   - `/analytics/campaigns`: Campaign performance metrics
   - `/analytics/business`: Business performance metrics

### File Organization
The project follows a structured organization:

1. **Backend**
   - `/api`: API routes and controllers
   - `/models`: Database models and relationships
   - `/services`: Business logic implementation
   - `/middleware`: Authentication and validation middleware
   - `/utils`: Helper functions and utilities
   - `/config`: Environment and configuration files

2. **Frontend**
   - `/components`: Reusable UI components
   - `/pages`: Page components and routes
   - `/hooks`: Custom React hooks
   - `/context`: State management context providers
   - `/styles`: CSS and styling files
   - `/utils`: Frontend utility functions
   - `/public`: Static assets

3. **Shared**
   - `/types`: TypeScript type definitions
   - `/schemas`: Validation schemas
   - `/constants`: Shared constants

4. **Infrastructure**
   - `/migrations`: Database migration scripts
   - `/seeders`: Seed data for development
   - `/deploy`: Deployment configuration

## 🚀 IMPLEMENTATION DETAILS

### Database Initialization Scripts
```sql
-- Core System Initialization
BEGIN;

-- 1. Core User Tables
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('business', 'influencer', 'customer')),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    username VARCHAR(100) UNIQUE,
    profile_image_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE TABLE business_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    hours JSONB,
    available_credits INTEGER DEFAULT 0,
    estimated_visits INTEGER DEFAULT 0,
    website TEXT,
    logo_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    social_media_handles JSONB DEFAULT '{}',
    business_hours JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 2. Campaign System
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES business_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    campaign_type VARCHAR(50) NOT NULL CHECK (campaign_type IN ('pay_per_customer', 'pay_per_post', 'media_event', 'loyalty_reward')),
    visibility VARCHAR(20) NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'private')),
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled', 'expired')),
    requirements TEXT,
    target_customers INTEGER,
    influencer_spots INTEGER,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    credits_per_action INTEGER NOT NULL,
    total_credits INTEGER NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_period CHECK (period_end > period_start)
);

-- 3. Content Management
CREATE TABLE submitted_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    content_url TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE content_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID REFERENCES submitted_content(id) ON DELETE CASCADE,
    platform_type VARCHAR(50) NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    title TEXT,
    description TEXT,
    thumbnail_url TEXT,
    engagement_metrics JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 4. Visit Tracking
CREATE TABLE visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    business_id UUID REFERENCES business_profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    credits_earned INTEGER,
    loyalty_points_earned INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE
);

-- 5. Messaging System
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    last_message_at TIMESTAMP WITH TIME ZONE,
    business_read_at TIMESTAMP WITH TIME ZONE,
    influencer_read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_conversation UNIQUE(business_id, influencer_id, campaign_id)
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Loyalty & Rewards System
CREATE TABLE loyalty_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    business_id UUID REFERENCES business_profiles(id) ON DELETE CASCADE,
    points_balance INTEGER DEFAULT 0,
    total_points_earned INTEGER DEFAULT 0,
    total_points_spent INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_loyalty UNIQUE(customer_id, business_id),
    CONSTRAINT positive_balance CHECK (points_balance >= 0)
);

CREATE TABLE loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loyalty_id UUID REFERENCES loyalty_points(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'expire', 'adjust')),
    points_amount INTEGER NOT NULL,
    description TEXT,
    reference_id UUID,  -- Can reference a visit or reward redemption
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    business_id UUID REFERENCES business_profiles(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    points_spent INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    qr_code TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    redeemed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Add necessary indexes
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_visits_date ON visits(created_at);
CREATE INDEX idx_content_platform ON content_metadata(platform_type);
CREATE INDEX idx_conversations_active ON conversations(is_active);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_loyalty_points_customer ON loyalty_points(customer_id);
CREATE INDEX idx_loyalty_transactions_loyalty ON loyalty_transactions(loyalty_id);
CREATE INDEX idx_reward_redemptions_status ON reward_redemptions(status);

-- Add RLS Policies
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

-- Businesses can manage their own campaigns
CREATE POLICY "Businesses can manage their campaigns"
ON campaigns
USING (business_id = auth.uid());

-- Influencers can view public campaigns
CREATE POLICY "Influencers can view public campaigns"
ON campaigns FOR SELECT
USING (visibility = 'public' OR id IN (
    SELECT campaign_id FROM campaign_invites WHERE influencer_id = auth.uid()
));

-- Conversation access policies
CREATE POLICY "Users can view their own conversations"
ON conversations FOR SELECT
USING (business_id = auth.uid() OR influencer_id = auth.uid());

-- Message access policies
CREATE POLICY "Users can view messages in their conversations"
ON messages FOR SELECT
USING (
    conversation_id IN (
        SELECT id FROM conversations 
        WHERE business_id = auth.uid() OR influencer_id = auth.uid()
    )
);

-- Loyalty points access policies
CREATE POLICY "Businesses can view their customers' loyalty points"
ON loyalty_points FOR SELECT
USING (business_id = auth.uid());

CREATE POLICY "Customers can view their own loyalty points"
ON loyalty_points FOR SELECT
USING (customer_id = auth.uid());

COMMIT;
```

### Environment Configuration
```typescript
// config/environment.ts

interface EnvironmentConfig {
  supabase: {
    url: string;
    anonKey: string;
    serviceKey?: string;
  };
  storage: {
    bucket: string;
    maxFileSize: number;
  };
  security: {
    jwtSecret: string;
    tokenExpiry: number;
  };
  external: {
    gmb: {
      clientId: string;
      clientSecret: string;
      redirectUri: string;
    };
  };
}

const environments: Record<string, EnvironmentConfig> = {
  development: {
    supabase: {
      url: process.env.SUPABASE_URL || 'http://localhost:54321',
      anonKey: process.env.SUPABASE_ANON_KEY || '',
      serviceKey: process.env.SUPABASE_SERVICE_KEY
    },
    storage: {
      bucket: 'collabuu-dev',
      maxFileSize: 10 * 1024 * 1024 // 10MB
    },
    security: {
      jwtSecret: process.env.JWT_SECRET || 'dev-secret',
      tokenExpiry: 24 * 60 * 60 // 24 hours
    },
    external: {
      gmb: {
        clientId: process.env.GMB_CLIENT_ID || '',
        clientSecret: process.env.GMB_CLIENT_SECRET || '',
        redirectUri: 'http://localhost:3000/auth/gmb/callback'
      }
    }
  },
  staging: {
    // Similar structure with staging values
  },
  production: {
    // Similar structure with production values
  }
};
```

### API Validation Schemas
```typescript
// schemas/campaign.ts

interface CreateCampaignRequest {
  title: string;
  description: string;
  campaignType: 'pay_per_customer' | 'pay_per_post' | 'media_event' | 'loyalty_reward';
  visibility: 'public' | 'private';
  requirements: string;
  targetCustomers: number;
  influencerSpots: number;
  periodStart: Date;
  periodEnd: Date;
  creditsPerAction: number;
  totalCredits: number;
  imageUrl?: string;
}

interface CampaignResponse {
  id: string;
  title: string;
  description: string;
  status: 'draft' | 'active' | 'paused' | 'completed' | 'cancelled' | 'expired';
  metrics: {
    visits: number;
    engagement: number;
    conversion: number;
  };
  participants: {
    total: number;
    active: number;
  };
  // ... other fields
}

// schemas/visit.ts

interface VerifyVisitRequest {
  campaignId: string;
  influencerId: string;
  customerId: string;
  qrCode: string;
  location?: {
    latitude: number;
    longitude: number;
  };
}

interface VisitResponse {
  id: string;
  status: 'pending' | 'approved' | 'rejected';
  creditsEarned?: number;
  loyaltyPointsEarned?: number;
  timestamp: Date;
}

// schemas/error.ts

enum ErrorCodes {
  INVALID_CAMPAIGN = 'INVALID_CAMPAIGN',
  INSUFFICIENT_CREDITS = 'INSUFFICIENT_CREDITS',
  INVALID_QR_CODE = 'INVALID_QR_CODE',
  CAMPAIGN_EXPIRED = 'CAMPAIGN_EXPIRED',
  UNAUTHORIZED = 'UNAUTHORIZED',
  NOT_FOUND = 'NOT_FOUND',
  VALIDATION_ERROR = 'VALIDATION_ERROR'
}

interface ErrorResponse {
  code: ErrorCodes;
  message: string;
  details?: Record<string, any>;
}

// schemas/messaging.ts

interface SendMessageRequest {
    conversationId: string;
    content: string;
}

interface MessageResponse {
    id: string;
    conversationId: string;
    senderId: string;
    content: string;
    createdAt: Date;
}

interface ConversationResponse {
    id: string;
    businessId: string;
    influencerId: string;
    campaignId: string;
    isActive: boolean;
    lastMessageAt: Date;
    businessReadAt: Date | null;
    influencerReadAt: Date | null;
    createdAt: Date;
    lastMessage?: MessageResponse;
}

// schemas/loyalty.ts

interface LoyaltyPointsResponse {
    id: string;
    customerId: string;
    businessId: string;
    pointsBalance: number;
    totalPointsEarned: number;
    totalPointsSpent: number;
    createdAt: Date;
    updatedAt: Date;
}

interface LoyaltyTransactionRequest {
    loyaltyId: string;
    transactionType: 'earn' | 'spend' | 'expire' | 'adjust';
    pointsAmount: number;
    description?: string;
    referenceId?: string;
}

interface RewardRedemptionRequest {
    campaignId: string;
    pointsToSpend: number;
}

interface RewardRedemptionResponse {
    id: string;
    customerId: string;
    businessId: string;
    campaignId: string;
    pointsSpent: number;
    status: 'pending' | 'approved' | 'rejected' | 'expired';
    qrCode: string;
    createdAt: Date;
    redeemedAt: Date | null;
    expiresAt: Date;
}
```

## 🔒 SECURITY CONSIDERATIONS 
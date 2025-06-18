// @ts-nocheck
import express from 'express';
import { authenticateToken } from '../middleware/auth';
import { UserRouter } from './routes/user';
import { BusinessRouter } from './routes/business';
import { InfluencerRouter } from './routes/influencer';
import { CustomerRouter } from './routes/customer';
import { CampaignRouter } from './routes/campaign';
import { VisitRouter } from './routes/visit';
import { MessageRouter } from './routes/message';
import { LoyaltyRouter } from './routes/loyalty';
import { SearchRouter } from './routes/search';
import { NotificationRouter } from './routes/notification';
import { ContentRouter } from './routes/content';
import { UploadRouter } from './routes/upload';
import { CategoriesRouter } from './routes/categories';

export function setupRoutes(app: express.Express): void {
  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
  });

  // API routes (auth endpoints are handled within each router)
  app.use('/api/business', new BusinessRouter().router);
  app.use('/api/influencer', new InfluencerRouter().router);
  app.use('/api/customer', new CustomerRouter().router);
  
  // Protected shared endpoints
  app.use('/api/campaign', authenticateToken, new CampaignRouter().router);
  app.use('/api/visit', authenticateToken, new VisitRouter().router);
  app.use('/api/message', authenticateToken, new MessageRouter().router);
  app.use('/api/loyalty', authenticateToken, new LoyaltyRouter().router);
  app.use('/api/search', authenticateToken, new SearchRouter().router);
  app.use('/api/notification', authenticateToken, new NotificationRouter().router);
  app.use('/api/categories', new CategoriesRouter().router);
  app.use('/api/content', authenticateToken, new ContentRouter().router);
  app.use('/api/upload', authenticateToken, new UploadRouter().router);
} 
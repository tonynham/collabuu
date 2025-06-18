"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupRoutes = setupRoutes;
const auth_1 = require("../middleware/auth");
const business_1 = require("./routes/business");
const influencer_1 = require("./routes/influencer");
const customer_1 = require("./routes/customer");
const campaign_1 = require("./routes/campaign");
const visit_1 = require("./routes/visit");
const message_1 = require("./routes/message");
const loyalty_1 = require("./routes/loyalty");
const search_1 = require("./routes/search");
const notification_1 = require("./routes/notification");
const content_1 = require("./routes/content");
const upload_1 = require("./routes/upload");
const categories_1 = require("./routes/categories");
function setupRoutes(app) {
    // Health check endpoint
    app.get('/health', (req, res) => {
        res.json({ status: 'OK', timestamp: new Date().toISOString() });
    });
    // API routes (auth endpoints are handled within each router)
    app.use('/api/business', new business_1.BusinessRouter().router);
    app.use('/api/influencer', new influencer_1.InfluencerRouter().router);
    app.use('/api/customer', new customer_1.CustomerRouter().router);
    // Protected shared endpoints
    app.use('/api/campaign', auth_1.authenticateToken, new campaign_1.CampaignRouter().router);
    app.use('/api/visit', auth_1.authenticateToken, new visit_1.VisitRouter().router);
    app.use('/api/message', auth_1.authenticateToken, new message_1.MessageRouter().router);
    app.use('/api/loyalty', auth_1.authenticateToken, new loyalty_1.LoyaltyRouter().router);
    app.use('/api/search', auth_1.authenticateToken, new search_1.SearchRouter().router);
    app.use('/api/notification', auth_1.authenticateToken, new notification_1.NotificationRouter().router);
    app.use('/api/categories', new categories_1.CategoriesRouter().router);
    app.use('/api/content', auth_1.authenticateToken, new content_1.ContentRouter().router);
    app.use('/api/upload', auth_1.authenticateToken, new upload_1.UploadRouter().router);
}
//# sourceMappingURL=routes.js.map
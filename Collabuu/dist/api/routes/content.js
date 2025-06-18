"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContentRouter = void 0;
const express_1 = __importDefault(require("express"));
const supabase_1 = require("../../config/supabase");
const auth_1 = require("../../middleware/auth");
class ContentRouter {
    constructor() {
        this.router = express_1.default.Router();
        this.router.get('/platforms', this.getPlatforms.bind(this));
        this.router.post('/recognize-link', this.recognizeLink.bind(this));
        this.router.get('/embed-preview/:contentId', auth_1.authenticateToken, this.getEmbedPreview.bind(this));
        this.router.post('/extract-metadata', this.extractMetadata.bind(this));
    }
    async getPlatforms(req, res) {
        try {
            const platforms = [
                {
                    id: 'instagram',
                    name: 'Instagram',
                    icon: 'instagram',
                    urlPatterns: ['instagram.com', 'instagr.am'],
                    supportedTypes: ['post', 'story', 'reel']
                },
                {
                    id: 'tiktok',
                    name: 'TikTok',
                    icon: 'tiktok',
                    urlPatterns: ['tiktok.com', 'vm.tiktok.com'],
                    supportedTypes: ['video']
                },
                {
                    id: 'youtube',
                    name: 'YouTube',
                    icon: 'youtube',
                    urlPatterns: ['youtube.com', 'youtu.be'],
                    supportedTypes: ['video', 'short']
                },
                {
                    id: 'twitter',
                    name: 'Twitter/X',
                    icon: 'twitter',
                    urlPatterns: ['twitter.com', 'x.com'],
                    supportedTypes: ['tweet', 'thread']
                },
                {
                    id: 'facebook',
                    name: 'Facebook',
                    icon: 'facebook',
                    urlPatterns: ['facebook.com', 'fb.com'],
                    supportedTypes: ['post', 'story']
                },
                {
                    id: 'linkedin',
                    name: 'LinkedIn',
                    icon: 'linkedin',
                    urlPatterns: ['linkedin.com'],
                    supportedTypes: ['post', 'article']
                },
                {
                    id: 'blog',
                    name: 'Blog/Website',
                    icon: 'globe',
                    urlPatterns: ['*'],
                    supportedTypes: ['article', 'post']
                },
                {
                    id: 'podcast',
                    name: 'Podcast',
                    icon: 'microphone',
                    urlPatterns: ['spotify.com', 'apple.com', 'anchor.fm', 'soundcloud.com'],
                    supportedTypes: ['episode']
                }
            ];
            res.status(200).json({ platforms });
        }
        catch (error) {
            console.error('Get platforms error:', error);
            res.status(500).json({ error: 'Failed to get platforms' });
        }
    }
    async recognizeLink(req, res) {
        try {
            const { url } = req.body;
            if (!url || typeof url !== 'string') {
                return res.status(400).json({ error: 'URL is required' });
            }
            const normalizedUrl = url.toLowerCase();
            let platform = 'unknown';
            let contentType = 'post';
            // Instagram detection
            if (normalizedUrl.includes('instagram.com') || normalizedUrl.includes('instagr.am')) {
                platform = 'instagram';
                if (normalizedUrl.includes('/reel/')) {
                    contentType = 'reel';
                }
                else if (normalizedUrl.includes('/stories/')) {
                    contentType = 'story';
                }
                else {
                    contentType = 'post';
                }
            }
            // TikTok detection
            else if (normalizedUrl.includes('tiktok.com')) {
                platform = 'tiktok';
                contentType = 'video';
            }
            // YouTube detection
            else if (normalizedUrl.includes('youtube.com') || normalizedUrl.includes('youtu.be')) {
                platform = 'youtube';
                if (normalizedUrl.includes('/shorts/')) {
                    contentType = 'short';
                }
                else {
                    contentType = 'video';
                }
            }
            // Twitter/X detection
            else if (normalizedUrl.includes('twitter.com') || normalizedUrl.includes('x.com')) {
                platform = 'twitter';
                contentType = 'tweet';
            }
            // Facebook detection
            else if (normalizedUrl.includes('facebook.com') || normalizedUrl.includes('fb.com')) {
                platform = 'facebook';
                if (normalizedUrl.includes('/stories/')) {
                    contentType = 'story';
                }
                else {
                    contentType = 'post';
                }
            }
            // LinkedIn detection
            else if (normalizedUrl.includes('linkedin.com')) {
                platform = 'linkedin';
                if (normalizedUrl.includes('/pulse/')) {
                    contentType = 'article';
                }
                else {
                    contentType = 'post';
                }
            }
            // Podcast platforms
            else if (normalizedUrl.includes('spotify.com') || normalizedUrl.includes('apple.com') ||
                normalizedUrl.includes('anchor.fm') || normalizedUrl.includes('soundcloud.com')) {
                platform = 'podcast';
                contentType = 'episode';
            }
            // Default to blog/website
            else {
                platform = 'blog';
                contentType = 'article';
            }
            res.status(200).json({
                platform,
                contentType,
                url,
                recognized: platform !== 'unknown'
            });
        }
        catch (error) {
            console.error('Recognize link error:', error);
            res.status(500).json({ error: 'Failed to recognize link' });
        }
    }
    async getEmbedPreview(req, res) {
        try {
            const { contentId } = req.params;
            if (!contentId) {
                return res.status(400).json({ error: 'Content ID is required' });
            }
            // Get content submission details
            const { data: content, error } = await supabase_1.supabase
                .from('content_submissions')
                .select(`
          id, content_url, platform, content_type, title, description,
          thumbnail_url, metadata, status
        `)
                .eq('id', contentId)
                .single();
            if (error || !content) {
                return res.status(404).json({ error: 'Content not found' });
            }
            // Generate embed preview based on platform
            let embedData = {
                id: content.id,
                url: content.content_url,
                platform: content.platform,
                contentType: content.content_type,
                title: content.title,
                description: content.description,
                thumbnailUrl: content.thumbnail_url,
                embedHtml: null,
                canEmbed: false
            };
            // For supported platforms, generate embed HTML
            switch (content.platform) {
                case 'youtube':
                    const youtubeId = this.extractYouTubeId(content.content_url);
                    if (youtubeId) {
                        embedData.embedHtml = `<iframe width="560" height="315" src="https://www.youtube.com/embed/${youtubeId}" frameborder="0" allowfullscreen></iframe>`;
                        embedData.canEmbed = true;
                    }
                    break;
                case 'instagram':
                    embedData.embedHtml = `<blockquote class="instagram-media" data-instgrm-permalink="${content.content_url}"></blockquote>`;
                    embedData.canEmbed = true;
                    break;
                case 'twitter':
                    embedData.embedHtml = `<blockquote class="twitter-tweet"><a href="${content.content_url}"></a></blockquote>`;
                    embedData.canEmbed = true;
                    break;
                default:
                    embedData.canEmbed = false;
            }
            res.status(200).json({ embed: embedData });
        }
        catch (error) {
            console.error('Get embed preview error:', error);
            res.status(500).json({ error: 'Failed to get embed preview' });
        }
    }
    async extractMetadata(req, res) {
        try {
            const { url } = req.body;
            if (!url || typeof url !== 'string') {
                return res.status(400).json({ error: 'URL is required' });
            }
            // Basic metadata extraction (in a real app, you'd use a service like Open Graph)
            const metadata = {
                url,
                title: this.extractTitleFromUrl(url),
                description: '',
                thumbnailUrl: '',
                platform: '',
                contentType: '',
                duration: null,
                publishedAt: null,
                author: '',
                tags: []
            };
            // Platform-specific metadata extraction
            const recognition = await this.recognizeLink({ body: { url } }, {});
            // Simulate metadata extraction based on platform
            if (url.includes('youtube.com') || url.includes('youtu.be')) {
                metadata.platform = 'youtube';
                metadata.contentType = url.includes('/shorts/') ? 'short' : 'video';
                metadata.thumbnailUrl = this.getYouTubeThumbnail(url);
            }
            else if (url.includes('instagram.com')) {
                metadata.platform = 'instagram';
                metadata.contentType = url.includes('/reel/') ? 'reel' : 'post';
            }
            else if (url.includes('tiktok.com')) {
                metadata.platform = 'tiktok';
                metadata.contentType = 'video';
            }
            res.status(200).json({ metadata });
        }
        catch (error) {
            console.error('Extract metadata error:', error);
            res.status(500).json({ error: 'Failed to extract metadata' });
        }
    }
    // Helper methods
    extractYouTubeId(url) {
        const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
        const match = url.match(regex);
        return match ? match[1] : null;
    }
    getYouTubeThumbnail(url) {
        const videoId = this.extractYouTubeId(url);
        return videoId ? `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg` : '';
    }
    extractTitleFromUrl(url) {
        try {
            const urlObj = new URL(url);
            const pathParts = urlObj.pathname.split('/').filter(part => part.length > 0);
            return pathParts.length > 0 ? pathParts[pathParts.length - 1].replace(/[-_]/g, ' ') : 'Untitled';
        }
        catch {
            return 'Untitled';
        }
    }
}
exports.ContentRouter = ContentRouter;
//# sourceMappingURL=content.js.map
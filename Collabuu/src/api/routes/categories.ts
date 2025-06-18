import express, { Request, Response } from 'express';

export class CategoriesRouter {
  public router = express.Router();

  constructor() {
    this.router.get('/', this.getCategories.bind(this));
  }

  private async getCategories(req: Request, res: Response) {
    try {
      const categories = [
        // Business Categories
        {
          id: 'restaurant',
          name: 'Restaurant & Food',
          type: 'business',
          icon: 'utensils',
          description: 'Restaurants, cafes, food delivery, catering'
        },
        {
          id: 'retail',
          name: 'Retail & Shopping',
          type: 'business',
          icon: 'shopping-bag',
          description: 'Clothing, accessories, electronics, home goods'
        },
        {
          id: 'beauty',
          name: 'Beauty & Wellness',
          type: 'business',
          icon: 'heart',
          description: 'Salons, spas, fitness, health services'
        },
        {
          id: 'entertainment',
          name: 'Entertainment',
          type: 'business',
          icon: 'music',
          description: 'Events, venues, entertainment services'
        },
        {
          id: 'travel',
          name: 'Travel & Hospitality',
          type: 'business',
          icon: 'plane',
          description: 'Hotels, travel agencies, tourism'
        },
        {
          id: 'automotive',
          name: 'Automotive',
          type: 'business',
          icon: 'car',
          description: 'Car dealerships, repair shops, automotive services'
        },
        {
          id: 'professional',
          name: 'Professional Services',
          type: 'business',
          icon: 'briefcase',
          description: 'Legal, financial, consulting, real estate'
        },
        {
          id: 'technology',
          name: 'Technology',
          type: 'business',
          icon: 'laptop',
          description: 'Software, hardware, tech services'
        },

        // Influencer Categories
        {
          id: 'lifestyle',
          name: 'Lifestyle',
          type: 'influencer',
          icon: 'home',
          description: 'Daily life, home decor, personal experiences'
        },
        {
          id: 'fashion',
          name: 'Fashion & Style',
          type: 'influencer',
          icon: 'shirt',
          description: 'Clothing, accessories, style tips'
        },
        {
          id: 'fitness',
          name: 'Fitness & Health',
          type: 'influencer',
          icon: 'dumbbell',
          description: 'Workouts, nutrition, wellness'
        },
        {
          id: 'food',
          name: 'Food & Cooking',
          type: 'influencer',
          icon: 'chef-hat',
          description: 'Recipes, restaurant reviews, cooking tips'
        },
        {
          id: 'travel_influencer',
          name: 'Travel',
          type: 'influencer',
          icon: 'map',
          description: 'Travel destinations, tips, experiences'
        },
        {
          id: 'tech_influencer',
          name: 'Technology',
          type: 'influencer',
          icon: 'smartphone',
          description: 'Tech reviews, tutorials, industry news'
        },
        {
          id: 'gaming',
          name: 'Gaming',
          type: 'influencer',
          icon: 'gamepad',
          description: 'Game reviews, streaming, esports'
        },
        {
          id: 'parenting',
          name: 'Parenting & Family',
          type: 'influencer',
          icon: 'baby',
          description: 'Parenting tips, family activities, child care'
        },
        {
          id: 'education',
          name: 'Education',
          type: 'influencer',
          icon: 'book',
          description: 'Learning, tutorials, educational content'
        },
        {
          id: 'finance',
          name: 'Finance & Business',
          type: 'influencer',
          icon: 'dollar-sign',
          description: 'Financial advice, business tips, investing'
        },
        {
          id: 'art',
          name: 'Art & Creativity',
          type: 'influencer',
          icon: 'palette',
          description: 'Art, design, creative projects, DIY'
        },
        {
          id: 'music_influencer',
          name: 'Music',
          type: 'influencer',
          icon: 'headphones',
          description: 'Music reviews, performances, industry content'
        }
      ];

      const { type } = req.query;
      
      // Filter by type if specified
      let filteredCategories = categories;
      if (type && (type === 'business' || type === 'influencer')) {
        filteredCategories = categories.filter(cat => cat.type === type);
      }

      res.status(200).json({ 
        categories: filteredCategories,
        total: filteredCategories.length
      });
    } catch (error) {
      console.error('Get categories error:', error);
      res.status(500).json({ error: 'Failed to get categories' });
    }
  }
} 
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase URL or anonymous key. Please check your environment variables.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Type definitions for the auth user to enable req.user in Express routes
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        userType: 'business' | 'influencer' | 'customer';
        [key: string]: any;
      };
    }
  }
} 
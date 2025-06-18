export declare const supabase: import("@supabase/supabase-js").SupabaseClient<any, "public", any>;
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

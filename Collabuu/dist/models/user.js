"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserService = void 0;
// User service for handling user-related operations
class UserService {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
    }
    async getUserById(id) {
        const { data, error } = await this.supabase
            .from('user_profiles')
            .select('*')
            .eq('id', id)
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbUserToUser(data);
    }
    async getUserByEmail(email) {
        const { data, error } = await this.supabase
            .from('user_profiles')
            .select('*')
            .eq('email', email)
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbUserToUser(data);
    }
    async createUser(user) {
        const { data, error } = await this.supabase
            .from('user_profiles')
            .insert([{
                id: user.id,
                email: user.email,
                user_type: user.userType,
                first_name: user.firstName,
                last_name: user.lastName,
                username: user.username,
                profile_image_url: user.profileImageUrl,
                bio: user.bio
            }])
            .select()
            .single();
        if (error || !data) {
            console.error('UserService.createUser error:', error);
            return null;
        }
        return this.mapDbUserToUser(data);
    }
    async updateUser(id, updates) {
        const { data, error } = await this.supabase
            .from('user_profiles')
            .update({
            first_name: updates.firstName,
            last_name: updates.lastName,
            username: updates.username,
            profile_image_url: updates.profileImageUrl,
            bio: updates.bio,
            updated_at: new Date().toISOString()
        })
            .eq('id', id)
            .select()
            .single();
        if (error || !data) {
            return null;
        }
        return this.mapDbUserToUser(data);
    }
    // Helper to convert database object to User interface
    mapDbUserToUser(dbUser) {
        return {
            id: dbUser.id,
            email: dbUser.email,
            userType: dbUser.user_type,
            firstName: dbUser.first_name,
            lastName: dbUser.last_name,
            username: dbUser.username,
            profileImageUrl: dbUser.profile_image_url,
            bio: dbUser.bio,
            createdAt: new Date(dbUser.created_at),
            updatedAt: dbUser.updated_at ? new Date(dbUser.updated_at) : undefined
        };
    }
}
exports.UserService = UserService;
//# sourceMappingURL=user.js.map
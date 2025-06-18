import { SupabaseClient } from '@supabase/supabase-js';
export interface Message {
    id: string;
    conversationId: string;
    senderId: string;
    content: string;
    createdAt: Date;
}
export interface Conversation {
    id: string;
    businessId: string;
    influencerId: string;
    campaignId: string;
    isActive: boolean;
    lastMessageAt?: Date;
    businessReadAt?: Date;
    influencerReadAt?: Date;
    createdAt: Date;
}
export interface ConversationWithLastMessage extends Conversation {
    lastMessage?: Message;
    unreadCount?: number;
}
export declare class ConversationService {
    private supabase;
    constructor(supabaseClient: SupabaseClient);
    getConversationById(id: string): Promise<Conversation | null>;
    getConversationWithMessages(id: string): Promise<ConversationWithLastMessage | null>;
    getMessagesByConversationId(conversationId: string, options?: {
        limit?: number;
        offset?: number;
    }): Promise<Message[]>;
    getUserConversations(userId: string, userType: 'business' | 'influencer'): Promise<ConversationWithLastMessage[]>;
    getConversationByCampaignAndUsers(campaignId: string, businessId: string, influencerId: string): Promise<Conversation | null>;
    createConversation(campaignId: string, businessId: string, influencerId: string): Promise<Conversation | null>;
    sendMessage(conversationId: string, senderId: string, content: string): Promise<Message | null>;
    markConversationAsRead(conversationId: string, userId: string, userType: 'business' | 'influencer'): Promise<boolean>;
    updateConversationStatus(conversationId: string, isActive: boolean): Promise<Conversation | null>;
    private mapDbConversationToConversation;
    private mapDbMessageToMessage;
}

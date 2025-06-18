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

export class ConversationService {
  private supabase: SupabaseClient;

  constructor(supabaseClient: SupabaseClient) {
    this.supabase = supabaseClient;
  }

  async getConversationById(id: string): Promise<Conversation | null> {
    const { data, error } = await this.supabase
      .from('conversations')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbConversationToConversation(data);
  }

  async getConversationWithMessages(id: string): Promise<ConversationWithLastMessage | null> {
    // Get conversation
    const conversation = await this.getConversationById(id);
    
    if (!conversation) {
      return null;
    }

    // Get messages separately for pagination
    const { data: messagesData, error: messagesError } = await this.supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', id)
      .order('created_at', { ascending: false })
      .limit(1);

    if (messagesError || !messagesData || messagesData.length === 0) {
      return {
        ...conversation,
        lastMessage: undefined,
        unreadCount: 0
      };
    }

    return {
      ...conversation,
      lastMessage: this.mapDbMessageToMessage(messagesData[0]),
      unreadCount: 0 // Would need additional query to calculate
    };
  }

  async getMessagesByConversationId(conversationId: string, options?: {
    limit?: number;
    offset?: number;
  }): Promise<Message[]> {
    let query = this.supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: false });

    if (options?.limit) {
      query = query.limit(options.limit);
    }

    if (options?.offset) {
      query = query.range(options.offset, options.offset + (options.limit || 20) - 1);
    }

    const { data, error } = await query;

    if (error || !data) {
      return [];
    }

    return data.map(this.mapDbMessageToMessage);
  }

  async getUserConversations(userId: string, userType: 'business' | 'influencer'): Promise<ConversationWithLastMessage[]> {
    // Get all conversations for user
    const field = userType === 'business' ? 'business_id' : 'influencer_id';
    
    const { data: conversationsData, error: conversationsError } = await this.supabase
      .from('conversations')
      .select('*')
      .eq(field, userId)
      .order('last_message_at', { ascending: false });

    if (conversationsError || !conversationsData) {
      return [];
    }

    // Map to conversations
    const conversations = conversationsData.map(this.mapDbConversationToConversation);
    
    // For each conversation, get the last message and unread count
    const conversationsWithMessages: ConversationWithLastMessage[] = [];
    
    for (const conversation of conversations) {
      const { data: lastMessageData } = await this.supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversation.id)
        .order('created_at', { ascending: false })
        .limit(1);

      const lastMessage = lastMessageData && lastMessageData.length > 0 
        ? this.mapDbMessageToMessage(lastMessageData[0]) 
        : undefined;

      // Calculate unread count
      // This is a simplified implementation
      const readAt = userType === 'business' ? conversation.businessReadAt : conversation.influencerReadAt;
      
      const { count: unreadCount } = await this.supabase
        .from('messages')
        .select('*', { count: 'exact', head: true })
        .eq('conversation_id', conversation.id)
        .neq('sender_id', userId)
        .gt('created_at', readAt?.toISOString() || '1970-01-01');

      conversationsWithMessages.push({
        ...conversation,
        lastMessage,
        unreadCount: unreadCount || 0
      });
    }

    return conversationsWithMessages;
  }

  async getConversationByCampaignAndUsers(campaignId: string, businessId: string, influencerId: string): Promise<Conversation | null> {
    const { data, error } = await this.supabase
      .from('conversations')
      .select('*')
      .eq('campaign_id', campaignId)
      .eq('business_id', businessId)
      .eq('influencer_id', influencerId)
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbConversationToConversation(data);
  }

  async createConversation(campaignId: string, businessId: string, influencerId: string): Promise<Conversation | null> {
    // First check if conversation already exists
    const existingConversation = await this.getConversationByCampaignAndUsers(
      campaignId,
      businessId,
      influencerId
    );

    if (existingConversation) {
      return existingConversation;
    }

    // Create new conversation
    const { data, error } = await this.supabase
      .from('conversations')
      .insert([{
        campaign_id: campaignId,
        business_id: businessId,
        influencer_id: influencerId,
        is_active: true
      }])
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbConversationToConversation(data);
  }

  async sendMessage(conversationId: string, senderId: string, content: string): Promise<Message | null> {
    // First check if conversation is active
    const conversation = await this.getConversationById(conversationId);

    if (!conversation || !conversation.isActive) {
      throw new Error('Conversation is not active');
    }

    // Send message
    const { data, error } = await this.supabase
      .from('messages')
      .insert([{
        conversation_id: conversationId,
        sender_id: senderId,
        content: content
      }])
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    // Update conversation last_message_at
    await this.supabase
      .from('conversations')
      .update({
        last_message_at: new Date().toISOString()
      })
      .eq('id', conversationId);

    return this.mapDbMessageToMessage(data);
  }

  async markConversationAsRead(conversationId: string, userId: string, userType: 'business' | 'influencer'): Promise<boolean> {
    const field = userType === 'business' ? 'business_read_at' : 'influencer_read_at';
    
    const { error } = await this.supabase
      .from('conversations')
      .update({
        [field]: new Date().toISOString()
      })
      .eq('id', conversationId);

    return !error;
  }

  async updateConversationStatus(conversationId: string, isActive: boolean): Promise<Conversation | null> {
    const { data, error } = await this.supabase
      .from('conversations')
      .update({
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .eq('id', conversationId)
      .select()
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapDbConversationToConversation(data);
  }

  // Helper to convert database object to Conversation interface
  private mapDbConversationToConversation(dbConversation: any): Conversation {
    return {
      id: dbConversation.id,
      businessId: dbConversation.business_id,
      influencerId: dbConversation.influencer_id,
      campaignId: dbConversation.campaign_id,
      isActive: dbConversation.is_active,
      lastMessageAt: dbConversation.last_message_at ? new Date(dbConversation.last_message_at) : undefined,
      businessReadAt: dbConversation.business_read_at ? new Date(dbConversation.business_read_at) : undefined,
      influencerReadAt: dbConversation.influencer_read_at ? new Date(dbConversation.influencer_read_at) : undefined,
      createdAt: new Date(dbConversation.created_at)
    };
  }

  // Helper to convert database object to Message interface
  private mapDbMessageToMessage(dbMessage: any): Message {
    return {
      id: dbMessage.id,
      conversationId: dbMessage.conversation_id,
      senderId: dbMessage.sender_id,
      content: dbMessage.content,
      createdAt: new Date(dbMessage.created_at)
    };
  }
} 
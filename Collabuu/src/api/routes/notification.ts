import express, { Request, Response } from 'express';
import { supabase } from '../../config/supabase';
import { AuthenticatedRequest } from '../../middleware/auth';

export class NotificationRouter {
  public router = express.Router();

  constructor() {
    this.router.get('/', this.getNotifications.bind(this));
    this.router.put('/:id/read', this.markAsRead.bind(this));
    this.router.put('/mark-all-read', this.markAllRead.bind(this));
    this.router.post('/preferences', this.updatePreferences.bind(this));
    this.router.get('/unread-count', this.getUnreadCount.bind(this));
    this.router.delete('/:id', this.deleteNotification.bind(this));
  }

  private async getNotifications(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { page = 1, limit = 20, unreadOnly = false } = req.query;
      const offset = (Number(page) - 1) * Number(limit);

      let query = supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .range(offset, offset + Number(limit) - 1);

      if (unreadOnly === 'true') {
        query = query.eq('is_read', false);
      }

      const { data: notifications, error } = await query;

      if (error) {
        console.error('Notifications fetch error:', error);
        return res.status(500).json({ error: 'Failed to fetch notifications' });
      }

      // Get total count for pagination
      let countQuery = supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId);

      if (unreadOnly === 'true') {
        countQuery = countQuery.eq('is_read', false);
      }

      const { count, error: countError } = await countQuery;

      if (countError) {
        console.error('Notifications count error:', countError);
      }

      res.status(200).json({
        notifications: notifications || [],
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total: count || 0,
          totalPages: Math.ceil((count || 0) / Number(limit))
        }
      });

    } catch (error) {
      console.error('Get notifications error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async markAsRead(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.id;
      const notificationId = req.params.id;

      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { data, error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', notificationId)
        .eq('user_id', userId)
        .select()
        .single();

      if (error) {
        console.error('Mark as read error:', error);
        return res.status(500).json({ error: 'Failed to mark notification as read' });
      }

      if (!data) {
        return res.status(404).json({ error: 'Notification not found' });
      }

      res.status(200).json({ message: 'Notification marked as read', notification: data });

    } catch (error) {
      console.error('Mark as read error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async markAllRead(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { data, error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .eq('is_read', false)
        .select('id');

      if (error) {
        console.error('Mark all read error:', error);
        return res.status(500).json({ error: 'Failed to mark all notifications as read' });
      }

      res.status(200).json({ 
        message: 'All notifications marked as read', 
        updatedCount: data?.length || 0 
      });

    } catch (error) {
      console.error('Mark all read error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async getUnreadCount(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { count, error } = await supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) {
        console.error('Unread count error:', error);
        return res.status(500).json({ error: 'Failed to get unread count' });
      }

      res.status(200).json({ unreadCount: count || 0 });

    } catch (error) {
      console.error('Get unread count error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async deleteNotification(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.id;
      const notificationId = req.params.id;

      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', userId);

      if (error) {
        console.error('Delete notification error:', error);
        return res.status(500).json({ error: 'Failed to delete notification' });
      }

      res.status(200).json({ message: 'Notification deleted successfully' });

    } catch (error) {
      console.error('Delete notification error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async updatePreferences(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.id;
      const { preferences } = req.body;

      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      if (!preferences || typeof preferences !== 'object') {
        return res.status(400).json({ error: 'Invalid preferences format' });
      }

      // For now, we'll store preferences in the user_profiles table
      // In a more complex system, you might have a separate notification_preferences table
      const { data, error } = await supabase
        .from('user_profiles')
        .update({ 
          notification_preferences: preferences,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)
        .select('notification_preferences')
        .single();

      if (error) {
        console.error('Update preferences error:', error);
        return res.status(500).json({ error: 'Failed to update notification preferences' });
      }

      res.status(200).json({ 
        message: 'Notification preferences updated successfully',
        preferences: data?.notification_preferences || preferences
      });

    } catch (error) {
      console.error('Update preferences error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Helper method to create notifications (can be called from other parts of the app)
  static async createNotification(userId: string, title: string, message: string, type: string, data: any = {}) {
    try {
      const { data: notification, error } = await supabase
        .from('notifications')
        .insert([{
          user_id: userId,
          title,
          message,
          type,
          data,
          is_read: false
        }])
        .select()
        .single();

      if (error) {
        console.error('Create notification error:', error);
        return null;
      }

      return notification;
    } catch (error) {
      console.error('Create notification error:', error);
      return null;
    }
  }
} 
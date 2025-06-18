export declare class NotificationRouter {
    router: import("express-serve-static-core").Router;
    constructor();
    private getNotifications;
    private markAsRead;
    private markAllRead;
    private getUnreadCount;
    private deleteNotification;
    private updatePreferences;
    static createNotification(userId: string, title: string, message: string, type: string, data?: any): Promise<any>;
}

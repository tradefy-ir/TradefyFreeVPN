package com.tradefy.tradefy_vpn;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import androidx.core.app.NotificationCompat;

final class SessionNotifier {
    static final int NOTIFICATION_ID = 4102;
    private static final String CHANNEL_ID = "tradefy_session";
    private static final String MESSAGE =
            "جلسه یک‌ساعته به پایان رسید. برای اتصال دوباره وارد اپ شوید.";

    private SessionNotifier() {}

    static void showExpired(Context context) {
        Context app = context.getApplicationContext();
        NotificationManager manager =
                (NotificationManager) app.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) {
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "نشست TradefyVPN",
                    NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription("اطلاع پایان نشست رایگان");
            manager.createNotificationChannel(channel);
        }

        Intent launch = app.getPackageManager().getLaunchIntentForPackage(app.getPackageName());
        if (launch == null) {
            launch = new Intent(app, MainActivity.class);
        }
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent content = PendingIntent.getActivity(app, NOTIFICATION_ID, launch, flags);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(app, CHANNEL_ID)
                .setSmallIcon(app.getApplicationInfo().icon)
                .setContentTitle("TradefyVPN")
                .setContentText(MESSAGE)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(MESSAGE))
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(content);

        manager.notify(NOTIFICATION_ID, builder.build());
    }

    static void cancel(Context context) {
        NotificationManager manager =
                (NotificationManager) context.getApplicationContext()
                        .getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.cancel(NOTIFICATION_ID);
        }
    }
}

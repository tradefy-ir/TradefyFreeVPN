package com.tradefy.tradefy_vpn;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import dev.amirzr.flutter_v2ray_client.v2ray.V2rayController;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.tradefy.tradefy_vpn/session";
    private static final String DISCONNECT_ACTION = "FROM_DISCONNECT_BTN";
    private static final String TAG = "TradefyVpn";

    private MethodChannel sessionChannel;
    private boolean pendingNotificationDisconnect;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Api31Splash.dismissImmediately(this);
        }
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        sessionChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        );
        sessionChannel.setMethodCallHandler((call, result) -> {
            if ("scheduleTimeout".equals(call.method)) {
                Number millis = call.argument("millis");
                scheduleTimeout(millis == null ? 3_600_000L : millis.longValue());
                result.success(true);
            } else if ("cancelTimeout".equals(call.method)) {
                cancelTimeout();
                result.success(true);
            } else if ("consumePendingDisconnect".equals(call.method)) {
                result.success(pendingNotificationDisconnect);
                pendingNotificationDisconnect = false;
            } else {
                result.notImplemented();
            }
        });
        if (isDisconnectAction(getIntent())) {
            stopVpnFromNotification();
            getIntent().setAction(Intent.ACTION_MAIN);
        }
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (isDisconnectAction(intent)) {
            stopVpnFromNotification();
            intent.setAction(Intent.ACTION_MAIN);
            setIntent(intent);
        }
    }

    private boolean isDisconnectAction(@Nullable Intent intent) {
        return intent != null && DISCONNECT_ACTION.equals(intent.getAction());
    }

    private void stopVpnFromNotification() {
        Log.i(TAG, "Notification disconnect tapped, stopping Xray");
        pendingNotificationDisconnect = true;
        try {
            V2rayController.StopV2ray(getApplicationContext());
        } catch (Throwable error) {
            Log.w(TAG, "Could not stop Xray: " + error.getMessage());
        }
        if (sessionChannel != null) {
            sessionChannel.invokeMethod("notificationDisconnect", null);
        }
    }

    private PendingIntent timeoutIntent() {
        Intent intent = new Intent(this, SessionTimeoutReceiver.class);
        intent.setAction(SessionTimeoutReceiver.ACTION);
        return PendingIntent.getBroadcast(
                this,
                SessionTimeoutReceiver.REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );
    }

    private void scheduleTimeout(long millis) {
        AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
        PendingIntent pending = timeoutIntent();
        long triggerAt = SystemClock.elapsedRealtime() + millis;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pending
            );
        } else {
            alarmManager.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pending);
        }
    }

    private void cancelTimeout() {
        AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
        alarmManager.cancel(timeoutIntent());
    }
}

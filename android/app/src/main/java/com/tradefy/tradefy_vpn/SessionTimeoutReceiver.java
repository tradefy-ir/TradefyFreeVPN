package com.tradefy.tradefy_vpn;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import dev.amirzr.flutter_v2ray_client.v2ray.V2rayController;

public class SessionTimeoutReceiver extends BroadcastReceiver {
    public static final String ACTION = "com.tradefy.tradefy_vpn.SESSION_TIMEOUT";
    public static final int REQUEST_CODE = 4101;
    private static final String TAG = "TradefySession";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || !ACTION.equals(intent.getAction())) {
            return;
        }
        Log.i(TAG, "Free session expired, stopping Xray");
        try {
            V2rayController.StopV2ray(context.getApplicationContext());
        } catch (Throwable error) {
            Log.w(TAG, "Could not stop Xray: " + error.getMessage());
        }
    }
}

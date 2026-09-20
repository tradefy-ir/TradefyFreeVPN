package com.tradefy.tradefy_vpn;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

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
        VpnRuntime.reset(context);
        SessionNotifier.showExpired(context);
    }
}

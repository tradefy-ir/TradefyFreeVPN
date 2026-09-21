package com.tradefy.tradefy_vpn;

import android.content.Context;
import android.content.Intent;
import android.util.Log;
import dev.amirzr.flutter_v2ray_client.v2ray.V2rayController;
import dev.amirzr.flutter_v2ray_client.v2ray.services.V2rayProxyOnlyService;
import dev.amirzr.flutter_v2ray_client.v2ray.services.V2rayVPNService;
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs;

final class VpnRuntime {
    private static final String TAG = "TradefyVpnRuntime";

    private VpnRuntime() {}

    static void reset(Context context) {
        Context app = context.getApplicationContext();
        try {
            AppConfigs.ENABLE_TRAFFIC_AND_SPEED_STATICS = false;
            AppConfigs.V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED;
            AppConfigs.V2RAY_CONNECTION_MODE = AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN;
            V2rayController.StopV2ray(app);
        } catch (Throwable error) {
            Log.w(TAG, "StopV2ray failed: " + error.getMessage());
        }
        try {
            app.stopService(new Intent(app, V2rayVPNService.class));
        } catch (Throwable ignored) {
        }
        try {
            app.stopService(new Intent(app, V2rayProxyOnlyService.class));
        } catch (Throwable ignored) {
        }
        AppConfigs.V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED;
        AppConfigs.V2RAY_CONNECTION_MODE = AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN;
        AppConfigs.ENABLE_TRAFFIC_AND_SPEED_STATICS = false;
    }
}

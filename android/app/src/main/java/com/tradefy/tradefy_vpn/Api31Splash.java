package com.tradefy.tradefy_vpn;

import android.app.Activity;
import android.os.Build;
import android.window.SplashScreenView;
import androidx.annotation.RequiresApi;

@RequiresApi(api = Build.VERSION_CODES.S)
final class Api31Splash {
    private Api31Splash() {}

    static void dismissImmediately(Activity activity) {
        activity.getSplashScreen().setOnExitAnimationListener(SplashScreenView::remove);
    }
}

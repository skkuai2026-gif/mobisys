package com.rho.bgservice;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import com.rhomobile.rhodes.Logger;

public class BackgroundServiceRestarterBroadcastReceiver extends BroadcastReceiver {
	private static final String LOG_TAG = BackgroundServiceRestarterBroadcastReceiver.class.getSimpleName();

    @Override
    public void onReceive(Context context, Intent intent) {
        Logger.I(LOG_TAG, "Service Stops! Oooooooooooooppppssssss!!!!");

        context.startService(new Intent(context, BackgroundService.class));;
    }

}

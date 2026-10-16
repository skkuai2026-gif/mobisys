package com.rho.bgservice;

import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.RhodesActivity;
import com.rhomobile.rhodes.extmanager.AbstractRhoListener;
import com.rhomobile.rhodes.extmanager.IRhoExtManager;

import android.content.IntentFilter;
import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;

import com.rhomobile.rhodes.ConnectionChangeReceiver;

public class BGServiceRhoListener extends AbstractRhoListener {
	private static final String LOG_TAG = BGServiceRhoListener.class.getSimpleName();
	private final BackgroundService mBackgroundService = new BackgroundService();
	private final BackgroundServiceRestarterBroadcastReceiver bgServiceRestarterBR = new BackgroundServiceRestarterBroadcastReceiver();
	private boolean receiversRegistered;

	@Override
	public void onCreateApplication(IRhoExtManager extManager) {
		Logger.I(LOG_TAG, "BGServiceRhoListener onCreateApplication");
		extManager.addRhoListener(this);
	}
	
	@Override
	public void onResume(RhodesActivity activity) {
		Logger.I(LOG_TAG, "BGServiceRhoListener onResume");
		if (!receiversRegistered) {
			RhodesActivity.getContext().registerReceiver(bgServiceRestarterBR, new IntentFilter("com.rho.bgservice.RestartBackgroundService"));
			receiversRegistered = true;
		}

		/*if (BGService.isMyServiceRunning(mBackgroundService.getClass())) {
			RhodesActivity.getContext().stopService(new Intent(RhodesActivity.getContext(), mBackgroundService.getClass()));
		}*/
	}

	@Override
	public void onPause(RhodesActivity activity) {
		Logger.I(LOG_TAG, "BGServiceRhoListener onPause");
		if (receiversRegistered) {
			RhodesActivity.getContext().unregisterReceiver(bgServiceRestarterBR);
			receiversRegistered = false;
		}

		try {
			RhodesActivity.getContext().unregisterReceiver(new ConnectionChangeReceiver());
		} catch (IllegalArgumentException e) {
			Logger.I(LOG_TAG, "ConnectionChangeReceiver is already unregistered");
		}

		

		/*if (!BGService.isMyServiceRunning(mBackgroundService.getClass())) {
			RhodesActivity.getContext().startService(new Intent(RhodesActivity.getContext(), mBackgroundService.getClass()));
		}*/
	}
}

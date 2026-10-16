package com.rho.bgservice;

import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.MethodResult;
import com.rhomobile.rhodes.util.ContextFactory;
import com.rhomobile.rhodes.Logger;

import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;

public class BGService extends BGServiceBase implements IBGService {
    private static final String LOG_TAG = BGService.class.getSimpleName();
    private Context context;
    private BackgroundService mBackgroundService;
    private Intent mServiceIntent;

    public BGService(String id) {
        super(id);
		context = ContextFactory.getUiContext();
		mBackgroundService = new BackgroundService();
		mServiceIntent = new Intent(context, mBackgroundService.getClass());
    }

	@Override
	public void startBackgroundService(String bgServiceRubyFunc, IMethodResult result) {
		if (!isMyServiceRunning(mBackgroundService.getClass())) {
			context.startService(mServiceIntent);
		}
	}

	@Override
	public void stopBackgroundService(IMethodResult result) {
		if (isMyServiceRunning(mBackgroundService.getClass())) {
			context.stopService(mServiceIntent);
		}
	}

	@Override
	public void checkBackgroundServiceStatus(IMethodResult result) {
		result.set(isMyServiceRunning(mBackgroundService.getClass())+"");
	}

	static boolean isMyServiceRunning(Class<?> serviceClass) {
		ActivityManager manager = (ActivityManager) ContextFactory.getUiContext().getSystemService(Context.ACTIVITY_SERVICE);
		for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
			if (serviceClass.getName().equals(service.service.getClassName())) {
				Logger.I(LOG_TAG,"isMyServiceRunning?"+true);
				return true;
			}
		}
		Logger.I(LOG_TAG,"isMyServiceRunning?"+false);
		return false;
	}
}
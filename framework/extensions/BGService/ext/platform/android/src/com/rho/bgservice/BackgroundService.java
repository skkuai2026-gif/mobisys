package com.rho.bgservice;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.support.annotation.Nullable;

import com.rhomobile.rhodes.Logger;

import java.util.Timer;
import java.util.TimerTask;


public class BackgroundService extends Service {
	public int counter=0;
	private static final String LOG_TAG = BackgroundService.class.getSimpleName();

	public BackgroundService() {
		super();
		Logger.I(LOG_TAG, "here I am!");
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		super.onStartCommand(intent, flags, startId);
		startTimer();
		return START_STICKY;
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		Logger.I(LOG_TAG, "ondestroy!");
		// sendBroadcast(new Intent("com.rho.bgservice.RestartBackgroundService"));
		stoptimertask();
	}

	private Timer timer;
	private TimerTask timerTask;
	long oldTime=0;
	public void startTimer() {
		//set a new Timer
		timer = new Timer();

		//initialize the TimerTask's job
		initializeTimerTask();

		//schedule the timer, to wake up every 1 second
		timer.schedule(timerTask, 1000, 1000); //
    }

	/**
	 * it sets the timer to print the counter every x seconds
	 */
	public void initializeTimerTask() {
		timerTask = new TimerTask() {
			public void run() {
				Logger.I(LOG_TAG, "in timer ++++  "+ (counter++));
			}
		};
	}

	/**
	 * not needed
	 */
	public void stoptimertask() {
		//stop the timer, if it's not already null
		if (timer != null) {
			timer.cancel();
			timer = null;
		}
	}

	@Nullable
	@Override
	public IBinder onBind(Intent intent) {
		return null;
	}
}
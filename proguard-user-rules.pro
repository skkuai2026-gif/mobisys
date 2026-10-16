-keep public class * implements android.hardware.SensorEventListener.onAccuracyChanged{*;}
-keep public interface android.hardware.SensorEventListener.onAccuracyChanged{*;}
-keepclasseswithmembers class * {
	public void onAccuracyChanged(android.hardware.Sensor, int);
}

-keep public class * implements android.hardware.SensorEventListener.onSensorChanged{*;}
-keep public interface android.hardware.SensorEventListener.onSensorChanged{*;}
-keepclasseswithmembers class * {
	public void onSensorChanged(android.hardware.SensorEvent);
}
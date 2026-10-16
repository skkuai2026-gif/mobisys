package com.rho.pdfgen;

// Rhodes packages
import com.rhomobile.rhodes.util.ContextFactory;

// Java packages
import java.util.HashMap;
import java.util.List;
import java.io.IOException;
import java.io.InputStream;

// Android packages
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Point;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;

public class ImageBaseClass_Android {
    private static final String LOG_TAG = "ImageBaseClass_Android";


    // Method to plot data on image
    public Bitmap mergeImageAndData(HashMap<String, List<String>> data, HashMap<String, List<Point>> points, List<Integer> colorsList, String fileName) {

        // Fetch background image from assets
        Bitmap backgroundImageBM = ((BitmapDrawable) getDrawableFromAssets(ContextFactory.getUiContext(), fileName)).getBitmap();

        Bitmap.Config bitmapConfig = backgroundImageBM.getConfig();
        // set default bitmap config if none
        if(bitmapConfig == null) {
            bitmapConfig = Bitmap.Config.ARGB_8888;
        }
        // resource bitmaps are imutable,
        // so we need to convert it to mutable one
        backgroundImageBM = backgroundImageBM.copy(bitmapConfig, true);

        // Create canvas to plot data and points
        Canvas canvas = new Canvas(backgroundImageBM);

        if(data != null && points != null && data.size() > 0 && points.size() > 0) {
            int dbColor;
            int lbColor;
            int timelineDataColor;
            int modelPremiumColor;

            if(colorsList.size() > 0) {
                dbColor = (Integer)colorsList.get(0);
                lbColor = (Integer)colorsList.get(1);
                timelineDataColor = (Integer)colorsList.get(2);
                modelPremiumColor = Color.rgb(73, 73, 73);
                if(colorsList.size() == 4) {
                    modelPremiumColor = (Integer)colorsList.get(3);
                }
            } else {
                dbColor = Color.rgb(255, 255, 255);
                lbColor = Color.rgb(255, 255, 255);
                timelineDataColor = Color.rgb(0, 85, 149);
                modelPremiumColor = Color.rgb(0, 85, 149);
            }

            List listStartingOfAge = (List)data.get("prospectInfoList");
            List listOfStartingAgePoints = (List)points.get("pointsForProspectInfo");

            for(int listPremiumDetails = 0; listPremiumDetails <= listOfStartingAgePoints.size() - 1; ++listPremiumDetails) {
                writeText(canvas, (String)listStartingOfAge.get(listPremiumDetails), ((Point)listOfStartingAgePoints.get(listPremiumDetails)).x, ((Point)listOfStartingAgePoints.get(listPremiumDetails)).y, timelineDataColor, 10);
            }

            List var28 = (List)data.get("premiumList");
            List listOfPremiumPoints = (List)points.get("pointsForPremiumInfo");

            for(int ageList = 0; ageList <= listOfPremiumPoints.size() - 1; ++ageList) {
                writeText(canvas, (String)var28.get(ageList), ((Point)listOfPremiumPoints.get(ageList)).x, ((Point)listOfPremiumPoints.get(ageList)).y, timelineDataColor, 10);
            }

            List var29 = (List)data.get("ageList");
            List agePointsList = (List)points.get("agePointsList");

            for(int listOfDeathBenefit = 0; listOfDeathBenefit <= agePointsList.size() - 1; ++listOfDeathBenefit) {
                writeText(canvas, (String)var29.get(listOfDeathBenefit), ((Point)agePointsList.get(listOfDeathBenefit)).x, ((Point)agePointsList.get(listOfDeathBenefit)).y, timelineDataColor, 10);
            }

            List var30 = (List)data.get("deathBenefitList");
            List listOfDeathBenefitPoints = (List)points.get("blueBarList");

            for(int listOfTotalFv = 0; listOfTotalFv <= listOfDeathBenefitPoints.size() - 1; ++listOfTotalFv) {
                writeText(canvas, (String)var30.get(listOfTotalFv), ((Point)listOfDeathBenefitPoints.get(listOfTotalFv)).x, ((Point)listOfDeathBenefitPoints.get(listOfTotalFv)).y, dbColor, 10);
            }

            List var31 = (List)data.get("totalFVList");
            List listOfTotalFvPoints = (List)points.get("yellowBarList");

            for(int listOfFunds = 0; listOfFunds <= listOfTotalFvPoints.size() - 1; ++listOfFunds) {
                writeText(canvas, (String)var31.get(listOfFunds), ((Point)listOfTotalFvPoints.get(listOfFunds)).x, ((Point)listOfTotalFvPoints.get(listOfFunds)).y, lbColor, 10);
            }

            List var32 = (List)data.get("fundDescList");
            List listOfFundPoints = (List)points.get("fundListPoints");

            for(int listOfFundAlloc = 0; listOfFundAlloc <= var32.size() - 1; ++listOfFundAlloc) {
                writeText(canvas, (String)var32.get(listOfFundAlloc), ((Point)listOfFundPoints.get(listOfFundAlloc)).x, ((Point)listOfFundPoints.get(listOfFundAlloc)).y, lbColor, 10);
            }

            List var33 = (List)data.get("fundAllocList");
            List listOfFundAllocPoints = (List)points.get("fundAllocListPoints");

            for(int listOfRiders = 0; listOfRiders <= var33.size() - 1; ++listOfRiders) {
                writeText(canvas, (String)var33.get(listOfRiders), ((Point)listOfFundAllocPoints.get(listOfRiders)).x, ((Point)listOfFundAllocPoints.get(listOfRiders)).y, lbColor, 10);
            }

            List var34 = (List)data.get("riderList");
            List listOfRiderPoints = (List)points.get("riderListPoints");

            for(int productNameList = 0; productNameList <= listOfRiderPoints.size() - 1; ++productNameList) {
                writeText(canvas, (String)var34.get(productNameList), ((Point)listOfRiderPoints.get(productNameList)).x, ((Point)listOfRiderPoints.get(productNameList)).y, lbColor, 10);
            }

            List var35 = (List)data.get("productNameList");
            List productNamePoints = (List)points.get("productNamePoints");

            for(int staticList = 0; staticList <= var35.size() - 1; ++staticList) {
                writeText(canvas, (String)var35.get(staticList), ((Point)productNamePoints.get(staticList)).x, ((Point)productNamePoints.get(staticList)).y, dbColor, 18);
            }

            List var36 = (List)data.get("staticDataList");
            List staticListPoints = (List)points.get("staticListPoints");

            for(int outputImage = 0; outputImage <= var36.size() - 1; ++outputImage) {
                writeText(canvas, (String)var36.get(outputImage), ((Point)staticListPoints.get(outputImage)).x, ((Point)staticListPoints.get(outputImage)).y, lbColor, 10);
            }
        }
        return backgroundImageBM;
    }


    // Method to write text on Canvas
    private Canvas writeText(Canvas canvas, String text, int x, int y, int color, int size) {
        Paint paint = new Paint(); 
        paint.setColor(color);
        paint.setTypeface(Typeface.create("Dialog",Typeface.BOLD));
        paint.setTextSize(size);
        canvas.drawText(text, x, y, paint);
        return canvas;
    }


    // Method to load image from assets i.e. public folder
    private Drawable getDrawableFromAssets(Context context, String url){
        Drawable drawable = null;
        InputStream inputStream = null;
        try {
            inputStream = context.getAssets().open(url);
            drawable = Drawable.createFromStream(inputStream, null);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if(inputStream != null) {
                try {
                    inputStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return drawable;
    }
}

package com.rho.pdfgen;

import com.rho.pdfgen.ImageBaseClass_Android;

// Java packages
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

// Android packages
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Point;

public class BHFP_BH_image1_Android {
    private static final String LOG_TAG = "BHFP_BH_image1_Android";

    public Bitmap generateGraph(HashMap<String, List<String>> data) {
        String fileName = "apps/public/images/outputimages/bh1_bh_image1.png";
        if(data.get("outputLanguage") != null && "EN".equals(data.get("outputLanguage"))) {
            fileName = fileName.replace("_bh_", "_en_");
        }

        List<Integer> listOfColors = new ArrayList();
        listOfColors.add(Color.rgb(255, 255, 255));
        listOfColors.add(Color.rgb(0, 0, 0));
        listOfColors.add(Color.rgb(0, 0, 0));
        listOfColors.add(Color.rgb(0, 0, 0));
        HashMap points = new HashMap();
        ArrayList pointsForProspectInfo = new ArrayList();
        pointsForProspectInfo.add(new Point(190,105));
        pointsForProspectInfo.add(new Point(190,125));
        pointsForProspectInfo.add(new Point(190,150));
        pointsForProspectInfo.add(new Point(190,172));
        pointsForProspectInfo.add(new Point(190,194));
        pointsForProspectInfo.add(new Point(190,212));
        pointsForProspectInfo.add(new Point(190,215));
        pointsForProspectInfo.add(new Point(190,238));
        pointsForProspectInfo.add(new Point(156,301));
        points.put("pointsForProspectInfo", pointsForProspectInfo);
        ArrayList pointsForPremiumInfo = new ArrayList();
        pointsForPremiumInfo.add(new Point(370,212));
        pointsForPremiumInfo.add(new Point(481,212));
        pointsForPremiumInfo.add(new Point(594,212));
        pointsForPremiumInfo.add(new Point(720,212));
        pointsForPremiumInfo.add(new Point(370,227));
        pointsForPremiumInfo.add(new Point(370,242));
        points.put("pointsForPremiumInfo", pointsForPremiumInfo);
        ArrayList pointsForYellowBars = new ArrayList();
        pointsForYellowBars.add(new Point(60,568));
        pointsForYellowBars.add(new Point(215,547));   
        pointsForYellowBars.add(new Point(361,526));
        pointsForYellowBars.add(new Point(520,502));
        pointsForYellowBars.add(new Point(673,390));
        points.put("yellowBarList", pointsForYellowBars);
        ArrayList pointsForBlueBars = new ArrayList();
        pointsForBlueBars.add(new Point(75,516));
        pointsForBlueBars.add(new Point(224,485));   
        pointsForBlueBars.add(new Point(379,461));
        pointsForBlueBars.add(new Point(534,438));
        pointsForBlueBars.add(new Point(690,331));
        points.put("blueBarList", pointsForBlueBars);
        ArrayList agePointsList = new ArrayList();
        agePointsList.add(new Point(100,665));
        agePointsList.add(new Point(260,665));
        agePointsList.add(new Point(400,665));
        agePointsList.add(new Point(550,665));
        agePointsList.add(new Point(710,665));
        points.put("agePointsList", agePointsList);
        ArrayList fundListPoints = new ArrayList();
        fundListPoints.add(new Point(65,350));
        fundListPoints.add(new Point(65,370));
        fundListPoints.add(new Point(65,390));
        fundListPoints.add(new Point(65,410));
        fundListPoints.add(new Point(65,430));
        points.put("fundListPoints", fundListPoints);
        ArrayList fundAllocListPoints = new ArrayList();
        fundAllocListPoints.add(new Point(215,350));
        fundAllocListPoints.add(new Point(215,370));
        fundAllocListPoints.add(new Point(215,390));
        fundAllocListPoints.add(new Point(215,410));
        fundAllocListPoints.add(new Point(215,430));
        points.put("fundAllocListPoints", fundAllocListPoints);
        ArrayList staticListPoints = new ArrayList();
        staticListPoints.add(new Point(35,665));
        staticListPoints.add(new Point(750,700));
        points.put("staticListPoints", staticListPoints);
        ArrayList productNamePoints = new ArrayList();
        productNamePoints.add(new Point(35,48));
        points.put("productNamePoints", productNamePoints);
        ArrayList riderListPoints = new ArrayList();
        riderListPoints.add(new Point(110,935));
        riderListPoints.add(new Point(280,935));
        riderListPoints.add(new Point(415,935));
        riderListPoints.add(new Point(550,935));
        riderListPoints.add(new Point(690,935));
        riderListPoints.add(new Point(110,1120));
        riderListPoints.add(new Point(280,1120));
        riderListPoints.add(new Point(415,1120));
        riderListPoints.add(new Point(550,1120));
        riderListPoints.add(new Point(690,1120));
        points.put("riderListPoints", riderListPoints);

        ImageBaseClass_Android ibca = new ImageBaseClass_Android();
        return ibca.mergeImageAndData(data, points, listOfColors, fileName);
    }
}

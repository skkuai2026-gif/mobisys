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

public class BH1_image1_Android {
    private static final String LOG_TAG = "BH1_image1_Android";

    public Bitmap generateGraph(HashMap<String, List<String>> data) {
        String fileName = "apps/public/images/outputimages/bh1_en_image1.png";

        List<Integer> listOfColors = new ArrayList();
        listOfColors.add(Color.rgb(255,255,255));
        listOfColors.add(Color.rgb(0,0,0));
        listOfColors.add(Color.rgb(255,255,255));
        listOfColors.add(Color.rgb(0,0,0));
        HashMap points = new HashMap();
        ArrayList pointsForProspectInfo = new ArrayList();
        pointsForProspectInfo.add(new Point(165,105));
        pointsForProspectInfo.add(new Point(165,125));
        pointsForProspectInfo.add(new Point(165,150));
        pointsForProspectInfo.add(new Point(165,170));
        pointsForProspectInfo.add(new Point(165,190));
        pointsForProspectInfo.add(new Point(165,212));
        pointsForProspectInfo.add(new Point(165,215));
        pointsForProspectInfo.add(new Point(165,260));
        points.put("pointsForProspectInfo", pointsForProspectInfo);
        ArrayList pointsForPremiumInfo = new ArrayList();
        pointsForPremiumInfo.add(new Point(370,212));
        pointsForPremiumInfo.add(new Point(510,212));
        pointsForPremiumInfo.add(new Point(620,212));
        pointsForPremiumInfo.add(new Point(720,212));
        pointsForPremiumInfo.add(new Point(383,230));
        pointsForPremiumInfo.add(new Point(376,260));
        points.put("pointsForPremiumInfo", pointsForPremiumInfo);
        ArrayList pointsForYellowBars = new ArrayList();
        pointsForYellowBars.add(new Point(75,570));
        pointsForYellowBars.add(new Point(230,544));   
        pointsForYellowBars.add(new Point(365,524));
        pointsForYellowBars.add(new Point(520,500));
        pointsForYellowBars.add(new Point(675,390));
        points.put("yellowBarList", pointsForYellowBars);
        ArrayList pointsForBlueBars = new ArrayList();
        pointsForBlueBars.add(new Point(85,516));
        pointsForBlueBars.add(new Point(240,485));   
        pointsForBlueBars.add(new Point(398,462));
        pointsForBlueBars.add(new Point(548,435));
        pointsForBlueBars.add(new Point(698,328));
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
        staticListPoints.add(new Point(35,565));
        staticListPoints.add(new Point(630,600));
        points.put("staticListPoints", staticListPoints);
        ArrayList productNamePoints = new ArrayList();
        productNamePoints.add(new Point(35,48));
        points.put("productNamePoints", productNamePoints);
        ArrayList riderListPoints = new ArrayList();
        riderListPoints.add(new Point(110,935));
        riderListPoints.add(new Point(270,935));
        riderListPoints.add(new Point(415,935));
        riderListPoints.add(new Point(550,935));
        riderListPoints.add(new Point(690,935));
        riderListPoints.add(new Point(110,1120));
        riderListPoints.add(new Point(270,1120));
        riderListPoints.add(new Point(415,1120));
        riderListPoints.add(new Point(550,1120));
        riderListPoints.add(new Point(690,1120));
        points.put("riderListPoints", riderListPoints);

        ImageBaseClass_Android ibca = new ImageBaseClass_Android();
        return ibca.mergeImageAndData(data, points, listOfColors, fileName);
    }
}

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

public class ABS_image1_Android {
    private static final String LOG_TAG = "ABS_image1_Android";

    public Bitmap generateGraph(HashMap<String, List<String>> data) {
        String fileName = "apps/public/images/outputimages/b1p_image1.png";

        List<Integer> listOfColors = new ArrayList();
        listOfColors.add(Color.rgb(0,0,0));
        listOfColors.add(Color.rgb(0,0,0));
        listOfColors.add(Color.rgb(0,0,0));
        listOfColors.add(Color.rgb(0,0,0));
        HashMap points = new HashMap();
        ArrayList pointsForProspectInfo = new ArrayList();
        pointsForProspectInfo.add(new Point(165,91));
        pointsForProspectInfo.add(new Point(165,105));
        pointsForProspectInfo.add(new Point(165,125));
        pointsForProspectInfo.add(new Point(165,150));
        pointsForProspectInfo.add(new Point(165,170));
        pointsForProspectInfo.add(new Point(165,186));
        pointsForProspectInfo.add(new Point(165,205));
        pointsForProspectInfo.add(new Point(165,224));
        points.put("pointsForProspectInfo", pointsForProspectInfo);
        ArrayList pointsForPremiumInfo = new ArrayList();
        pointsForPremiumInfo.add(new Point(330,186));
        pointsForPremiumInfo.add(new Point(433,186));
        pointsForPremiumInfo.add(new Point(530,186));
        pointsForPremiumInfo.add(new Point(630,186));
        pointsForPremiumInfo.add(new Point(342,205));
        pointsForPremiumInfo.add(new Point(335,224));
        points.put("pointsForPremiumInfo", pointsForPremiumInfo);
        ArrayList pointsForYellowBars = new ArrayList();
        pointsForYellowBars.add(new Point(53,486));
        pointsForYellowBars.add(new Point(186,467));   
        pointsForYellowBars.add(new Point(315,448));
        pointsForYellowBars.add(new Point(447,429));
        pointsForYellowBars.add(new Point(579,333));
        points.put("yellowBarList", pointsForYellowBars);
        ArrayList pointsForBlueBars = new ArrayList();
        pointsForBlueBars.add(new Point(70,440));
        pointsForBlueBars.add(new Point(195,416));   
        pointsForBlueBars.add(new Point(330,395));
        pointsForBlueBars.add(new Point(460,374));
        pointsForBlueBars.add(new Point(594,284));
        points.put("blueBarList", pointsForBlueBars);
        ArrayList agePointsList = new ArrayList();
        agePointsList.add(new Point(88,565));
        agePointsList.add(new Point(220,565));
        agePointsList.add(new Point(348,565));
        agePointsList.add(new Point(481,565));
        agePointsList.add(new Point(616,565));
        points.put("agePointsList", agePointsList);
        ArrayList fundListPoints = new ArrayList();
        fundListPoints.add(new Point(65,300));
        fundListPoints.add(new Point(65,320));
        fundListPoints.add(new Point(65,340));
        fundListPoints.add(new Point(65,360));
        fundListPoints.add(new Point(65,380));
        points.put("fundListPoints", fundListPoints);
        ArrayList fundAllocListPoints = new ArrayList();
        fundAllocListPoints.add(new Point(215,300));
        fundAllocListPoints.add(new Point(215,320));
        fundAllocListPoints.add(new Point(215,340));
        fundAllocListPoints.add(new Point(215,360));
        fundAllocListPoints.add(new Point(215,380));
        points.put("fundAllocListPoints", fundAllocListPoints);
        ArrayList staticListPoints = new ArrayList();
        staticListPoints.add(new Point(35,565));
        staticListPoints.add(new Point(630,600));
        points.put("staticListPoints", staticListPoints);
        ArrayList productNamePoints = new ArrayList();
        productNamePoints.add(new Point(35,48));
        points.put("productNamePoints", productNamePoints);
        ArrayList riderListPoints = new ArrayList();
        riderListPoints.add(new Point(105,935));
        riderListPoints.add(new Point(278,935));
        riderListPoints.add(new Point(415,935));
        riderListPoints.add(new Point(550,935));
        riderListPoints.add(new Point(690,935));
        riderListPoints.add(new Point(105,1120));
        riderListPoints.add(new Point(278,1120));
        riderListPoints.add(new Point(415,1120));
        riderListPoints.add(new Point(550,1120));
        riderListPoints.add(new Point(690,1120));
        points.put("riderListPoints", riderListPoints);

        ImageBaseClass_Android ibca = new ImageBaseClass_Android();
        return ibca.mergeImageAndData(data, points, listOfColors, fileName);
    }
}

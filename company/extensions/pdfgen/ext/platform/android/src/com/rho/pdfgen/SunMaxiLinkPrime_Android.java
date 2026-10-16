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

public class SunMaxiLinkPrime_Android {
    private static final String LOG_TAG = "SunMaxiLinkPrime_Android";

    public Bitmap generateGraph(HashMap<String, List<String>> data) {
        String fileName = "apps/public/images/outputimages/maxilinkprime_image1.png";

        List<Integer> listOfColors = new ArrayList();
        listOfColors.add(Color.rgb(255,255,255));
        listOfColors.add(Color.rgb(73,73,73));
        listOfColors.add(Color.rgb(0,85,149));
        listOfColors.add(Color.rgb(0,85,149));
        HashMap points = new HashMap();
        List<Point> listOfStartingAgePoints = new ArrayList<Point>();
        listOfStartingAgePoints.add(new Point(39,234));
        listOfStartingAgePoints.add(new Point(53,234));
        listOfStartingAgePoints.add(new Point(66,234));
        listOfStartingAgePoints.add(new Point(80,234));
        listOfStartingAgePoints.add(new Point(92,234));
        listOfStartingAgePoints.add(new Point(106,234));
        listOfStartingAgePoints.add(new Point(119,234));
        listOfStartingAgePoints.add(new Point(132,234));
        listOfStartingAgePoints.add(new Point(145,234));
        listOfStartingAgePoints.add(new Point(159,234));
        listOfStartingAgePoints.add(new Point(172,234));
        points.put("startingAgeList",listOfStartingAgePoints);
        List<Point> pointsAgeList = new ArrayList<Point>();
        pointsAgeList.add(new Point(224, 234));
        pointsAgeList.add(new Point(274, 234));
        pointsAgeList.add(new Point(325, 234));
        pointsAgeList.add(new Point(382, 234));
        pointsAgeList.add(new Point(479, 234));
        points.put("ageList", pointsAgeList);
        List<Point> pointsDeathBenefitList = new ArrayList<Point>();
        pointsDeathBenefitList.add(new Point(212, 128));
        pointsDeathBenefitList.add(new Point(253, 111));
        pointsDeathBenefitList.add(new Point(305, 92));
        pointsDeathBenefitList.add(new Point(342, 73));
        points.put("deathBenefitList", pointsDeathBenefitList);
        List<Point> pointsTotalFVList = new ArrayList<Point>();
        pointsTotalFVList.add(new Point(211, 161));
        pointsTotalFVList.add(new Point(252, 144));
        pointsTotalFVList.add(new Point(304, 125));
        pointsTotalFVList.add(new Point(341, 106));
        pointsTotalFVList.add(new Point(399, 39));
        points.put("totalFVList", pointsTotalFVList);
        List<Point> pointstotalPremiumList = new ArrayList<Point>();
        pointstotalPremiumList.add(new Point(42,162));
        pointstotalPremiumList.add(new Point(42,172));
        pointstotalPremiumList.add(new Point(42,182));
        points.put("totalPremiumList", pointstotalPremiumList);

        ImageBaseClass_Android ibca = new ImageBaseClass_Android();
        return ibca.mergeImageAndData(data, points, listOfColors, fileName);
    }
}

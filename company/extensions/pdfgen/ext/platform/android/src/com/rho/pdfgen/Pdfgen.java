package com.rho.pdfgen;

// Rhodes packages
import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.MethodResult;
import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.util.ContextFactory;

// Java packages
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.lang.reflect.Method;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

// Android packages
import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Environment;
import android.support.annotation.NonNull;
import android.view.View;
import android.widget.RelativeLayout;

// iText packages
import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.Element;
import com.itextpdf.text.ExceptionConverter;
import com.itextpdf.text.Font;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Rectangle;
import com.itextpdf.text.pdf.PdfName;
import com.itextpdf.text.pdf.PdfNumber;
import com.itextpdf.text.pdf.PdfPage;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfPageEventHelper;
import com.itextpdf.text.pdf.PdfWriter;
import com.itextpdf.tool.xml.NoCustomContextException;
import com.itextpdf.tool.xml.Tag;
import com.itextpdf.tool.xml.XMLWorker;
import com.itextpdf.tool.xml.XMLWorkerFontProvider;
import com.itextpdf.tool.xml.XMLWorkerHelper;
import com.itextpdf.tool.xml.WorkerContext;
import com.itextpdf.tool.xml.css.CssFile;
import com.itextpdf.tool.xml.css.StyleAttrCSSResolver;
import com.itextpdf.tool.xml.html.CssAppliers;
import com.itextpdf.tool.xml.html.CssAppliersImpl;
import com.itextpdf.tool.xml.html.TagProcessorFactory;
import com.itextpdf.tool.xml.html.Tags;
import com.itextpdf.tool.xml.html.AbstractTagProcessor;
import com.itextpdf.tool.xml.parser.XMLParser;
import com.itextpdf.tool.xml.pipeline.css.CSSResolver;
import com.itextpdf.tool.xml.pipeline.css.CssResolverPipeline;
import com.itextpdf.tool.xml.pipeline.end.PdfWriterPipeline;
import com.itextpdf.tool.xml.pipeline.html.HtmlPipeline;
import com.itextpdf.tool.xml.pipeline.html.HtmlPipelineContext;
import com.itextpdf.tool.xml.pipeline.ctx.MapContext;

// Jsoup packages
import org.jsoup.Jsoup;
import org.jsoup.parser.Parser;
import org.jsoup.select.Elements;

// MPAndroidChart packages
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;

// FlexJSON packages
import flexjson.JSONDeserializer;

public class Pdfgen extends PdfgenBase implements IPdfgen {
    private static final String LOG_TAG = "Html2Pdf";
    private static float headerHeight;

    public Pdfgen(String id) {
        super(id);
    }


    /* Android HTML to PDF generation graphing MPAndroidChart implementation */

    // Entry point for chart generation for Android HTML to PDF generation
    @Override
    public void generateAndroidPDFCharts(String chartJSON, String chartOutputFileName, String chartType, IMethodResult result) {

        try {
            if(chartJSON.length() == 0){
                chartJSON = "{\"issueAge\":0,\"listOfAge\":[\"50\",\"55\",\"60\",\"65\",\"88\"],\"data\":{\"totalPremiumList\":[\"Ps. 309,232\",\"Annual premium\",\"payable in 5 years\",\"[inclusive of riders]\"],\"ageList\":[\"50\",\"55\",\"60\",\"65\",\"88\"],\"deathBenefitList\":[\"37,701,281\",\"53,794,173\",\"77,600,333\",\"112,751,005\",\"650,507,691\"],\"totalFVList\":[\"33,701,281\",\"49,794,173\",\"73,600,333\",\"108,751,005\",\"Ps. 646,507,691\"],\"startingAgeList\":[0,1,2,3,4,5,6,7,8,9,10]},\"classToCall\":\"SunMaxiLinkBright_image1\"}";
            }

            HashMap inputHashMap = (HashMap)(new JSONDeserializer()).use((String)null, HashMap.class).deserialize(chartJSON);
            HashMap data = (HashMap)inputHashMap.get("data");
            String classToCall = "com.rho.pdfgen."+(String)inputHashMap.get("classToCall")+"_Android";

            if(chartType.equals("timeline")){
                timelineIllustrationGenerator(data, chartOutputFileName, classToCall);
            }
            else {
                createLineChart(data, chartOutputFileName);
            }
        } catch (Exception e) {
            e.printStackTrace();
            Logger.I(LOG_TAG, "in generateAndroidPDFCharts catch block----"+e);
        }
        result.set("Android");  
    }


    // Method to generate Timeline Illustration Graph
    private void timelineIllustrationGenerator(HashMap data, final String outputFilePath, String classToCall) throws Exception{

        // Call graph plotting class
        Class<?> graphClass = Class.forName(classToCall);
        Method generateGraphMethod = graphClass.getDeclaredMethod("generateGraph", new Class[]{HashMap.class});
        Object graphDO = graphClass.newInstance();
        Bitmap chartBitmap = (Bitmap)generateGraphMethod.invoke(graphDO, new Object[]{data});

        // Save the bitmap as image
        FileOutputStream out = new FileOutputStream(outputFilePath);
        chartBitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
    }


    // Method to generate MPAndroid Line chart
    private void createLineChart(HashMap data, final String outputFilePath) throws Exception{
        View rootView = ((Activity)ContextFactory.getUiContext()).getWindow().getDecorView().findViewById(android.R.id.content);
        final LineChart chart = new LineChart(ContextFactory.getUiContext());

        RelativeLayout.LayoutParams Lparams = new RelativeLayout.LayoutParams(827,1164);
        chart.setLayoutParams(Lparams);
        chart.setVisibility(View.INVISIBLE);

        ((Activity)ContextFactory.getUiContext()).addContentView(chart,Lparams); // add the programmatically created chart




        // List<Entry> entries = new ArrayList<Entry>();
        // entries.add(new Entry(1, 10));
        // entries.add(new Entry(2, 20));
        // entries.add(new Entry(3, 30));
        // entries.add(new Entry(4, 40));
        // entries.add(new Entry(5, 50));
        // LineDataSet dataSet = new LineDataSet(entries, "DataSet 1"); // add entries to dataset

        ArrayList<Entry> values = new ArrayList<Entry>();
        // for (int i = 0; i < 45; i++) {
        //     // int val = (Math.random() * 100) + 3.0;
        //     int val = ThreadLocalRandom.current().nextInt(1, 100);
            values.add(new Entry(50.0f, 50));
        // }
        LineDataSet dataSet = new LineDataSet(values, "DataSet 1"); // add entries to dataset
        // dataSet.setDrawIcons(false);









        // set the line to be drawn like this "- - - - - -"
        dataSet.enableDashedLine(10f, 5f, 0f);
        dataSet.enableDashedHighlightLine(10f, 5f, 0f);
        dataSet.setColor(Color.BLACK);
        dataSet.setCircleColor(Color.BLACK);
        dataSet.setLineWidth(1f);
        dataSet.setCircleRadius(3f);
        dataSet.setDrawCircleHole(false);
        dataSet.setValueTextSize(9f);
        dataSet.setDrawFilled(true);
        dataSet.setFillColor(Color.BLACK);


        LineData scatterData = new LineData();
        scatterData.addDataSet(dataSet);
        chart.setData(scatterData);
        chart.invalidate(); // refresh

        rootView.post(new Runnable() {
            @Override
            public void run() {
                saveChartToPath(chart, outputFilePath);
            }
        });
    }


    // Method to save MPAndroid chart as image
    private boolean saveChartToPath(Chart chart, String filePath) {
        int quality = 100;
        Bitmap.CompressFormat format = Bitmap.CompressFormat.JPEG;
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(filePath);
            Bitmap b = chart.getChartBitmap();
            b.compress(format, quality, out);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
        finally {
            try {
                out.flush();
                out.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return true;
    }




    /* Android HTML to PDF generation iText implementation */
    
    // Entry point for Android HTML to PDF generation
    @Override
    public void generateAndroidPDF(String inputHTMLFileName, String orientation, String isSinglePDFRequired, String password, IMethodResult result) {
        String outputPDFFile = inputHTMLFileName.replace(".html",".pdf");

        Logger.I(LOG_TAG, "java create pdf from html called");
        Logger.I(LOG_TAG, "inputHTMLFileName: " + inputHTMLFileName);
        Logger.I(LOG_TAG, "outputPDFFile: " + outputPDFFile);
        Logger.I(LOG_TAG, "orientation: " + orientation);
        Logger.I(LOG_TAG, "isSinglePDFRequired: " + isSinglePDFRequired);
        Logger.I(LOG_TAG, "password: " + password);

        try {
            if ("YES".equals(isSinglePDFRequired)){
                // copyFontFiles();
                createPdf(outputPDFFile, cleanXmlAndRemoveUnwantedTags(convertStreamToString(new FileInputStream(inputHTMLFileName))), "PORTRAIT", "A4", "c2lbiz", password);
            }
        } catch (Exception e) {
            e.printStackTrace();
            Logger.I(LOG_TAG, "in catch block----"+e);
        }
        result.set("Android");  
    }


    // Main method to trigger iText HTML to PDF conversion
    private void createPdf(String file, String inputContent, String orientation, String pageSize, String masterPassword, String customPassword) throws IOException, DocumentException {
        // FontFactory.registerDirectory(getFilesDir().getAbsolutePath());

        // Initialize objects
        Document document = new Document();
        PdfWriter writer = PdfWriter.getInstance(document, new FileOutputStream(file));

        // PDF encryption with password
        if(!masterPassword.equals("") && !customPassword.equals("")) {
            writer.setEncryption(masterPassword.getBytes(), customPassword.getBytes(), PdfWriter.ALLOW_PRINTING, PdfWriter.ENCRYPTION_AES_128 | PdfWriter.DO_NOT_ENCRYPT_METADATA);
        }

        // Set Page Size
        if(pageSize.equals("LETTER")){
            document.setPageSize(PageSize.LETTER);
        }
        else if(pageSize.equals("A3")){
            document.setPageSize(PageSize.A3);
        }
        else{
            document.setPageSize(PageSize.A4);
        }

        // Change orientation
        Rotate event = new Rotate();
        writer.setPageEvent(event);
        if(orientation.equals("LANDSCAPE")) {
            event.setOrientation(PdfPage.LANDSCAPE);
        }

        document.open();

        // Custom CSS
        CSSResolver cssResolver = new StyleAttrCSSResolver();
        CssFile cssFile = XMLWorkerHelper.getCSS(new FileInputStream(Environment.getExternalStorageDirectory() + File.separator + "style.css"));
        cssResolver.addCss(cssFile);

        // Custom Fonts
        XMLWorkerFontProvider fontProvider = new XMLWorkerFontProvider(XMLWorkerFontProvider.DONTLOOKFORFONTS);
        /*String[] assetFontFileList = copyFontFiles();
        for(String fileName:assetFontFileList){
            fontProvider.register(getFilesDir()+File.separator+fileName);
        }*/
        CssAppliers cssAppliers = new CssAppliersImpl(fontProvider);
        HtmlPipelineContext htmlContext = new HtmlPipelineContext(cssAppliers);

        // Custom Tags
        TagProcessorFactory factory = Tags.getHtmlTagProcessorFactory();
        factory.addProcessor(
            new HeaderTagProcessor(),
            "pd4ml_page_header"
        );
        factory.addProcessor(
            new FooterTagProcessor(),
            "pd4ml_page_footer"
        );
        factory.addProcessor(
            new MainBodyTagProcessor(),
            "main_body"
        );
        htmlContext.setTagFactory(factory);
        htmlContext.autoBookmark(false);

        // Pipelines
        PdfWriterPipeline pdf = new PdfWriterPipeline(document, writer);
        HtmlPipeline html = new HtmlPipeline(htmlContext, pdf);
        CssResolverPipeline css = new CssResolverPipeline(cssResolver, html);

        // XML Worker
        XMLWorker worker = new XMLWorker(css, true);
        XMLParser p = new XMLParser(worker);
        p.parse(new ByteArrayInputStream(inputContent.getBytes(StandardCharsets.UTF_8)), Charset.forName("UTF-8"));

        document.close();
    }


    // Method to clean up malformed HTML and make it XML compatible
    private String cleanXmlAndRemoveUnwantedTags(String textToEscape) throws IOException{
        // Sanitize pd4ml tags
        textToEscape = textToEscape.replaceAll("pd4ml:page.header","pd4ml_page_header");
        textToEscape = textToEscape.replaceAll("pd4ml:page.footer","pd4ml_page_footer");
        textToEscape = textToEscape.replaceAll("<pd4ml:page.break>","<div style=\"page-break-after: always;\">&nbsp;</div>");

        // Use JSOUP XML Parser to convert HTML code to XML
        org.jsoup.nodes.Document doc = Jsoup.parse(textToEscape, "", Parser.xmlParser());

        // Move embedded style tags to a separate CSS file
        Elements styleTagList = doc.select("style");
        StringBuilder styleTagBuffer = new StringBuilder();
        for (org.jsoup.nodes.Element styleTag: styleTagList) {
            styleTagBuffer.append(styleTag.text());
        }
        FileOutputStream fOut = new FileOutputStream(new File(Environment.getExternalStorageDirectory() + File.separator + "style.css"));
        OutputStreamWriter myOutWriter = new OutputStreamWriter(fOut);
        myOutWriter.append(styleTagBuffer.toString());
        myOutWriter.close();
        fOut.flush();
        fOut.close();

        return doc.outerHtml();
    }


    // Method to convert InputStream to String
    @NonNull
    private String convertStreamToString(InputStream is) {
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder sb = new StringBuilder();

        String line;
        try {
            while ((line = reader.readLine()) != null) {
                sb.append(line).append('\n');
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                is.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return sb.toString();
    }


    // iText page orientation change implementation
    private class Rotate extends PdfPageEventHelper {
        private PdfNumber orientation = PdfPage.PORTRAIT;

        private void setOrientation(PdfNumber orientation) {
            this.orientation = orientation;
        }

        @Override
        public void onStartPage(PdfWriter writer, Document document) {
            writer.addPageDictEntry(PdfName.ROTATE, orientation);
        }
    }


    // iText page header tag processor
    private class HeaderTagProcessor extends AbstractTagProcessor {
        public HeaderTagProcessor() {
        }

        public List<Element> content(WorkerContext ctx, Tag tag, String content) {
            return this.textContent(ctx, tag, content);
        }

        public List<Element> end(WorkerContext ctx, Tag tag, List<Element> currentContent) {
            List<Element> returnList = this.currentContentToParagraph(currentContent, false, true, tag, ctx);

            if (returnList.size()>0) {
                MapContext mc;
                try {
                    mc = (MapContext)ctx.get("com.itextpdf.tool.xml.pipeline.end.PdfWriterPipeline");
                } catch (NoCustomContextException ex) {
                    throw new ExceptionConverter(ex);
                }
                PdfWriter writer = (PdfWriter) mc.get("WRITER");
                writer.setPageEvent(new Header(returnList));
            }
            returnList = new ArrayList<Element>(1);
            return returnList;
        }

        public boolean isStackOwner() {
            return true;
        }
    }


    // iText page header implementation
    private class Header extends PdfPageEventHelper {
        protected List<Element> header;
        protected PdfPTable headerTable;

        public Header(List<Element> header) {
            this.header = header;
            this.headerTable = new PdfPTable(1);
            headerTable.setLockedWidth(true);
            PdfPCell cell = new PdfPCell();
            for (Element e : header) {
                cell.addElement(e);
            }
            cell.setBorder(Rectangle.NO_BORDER);
            headerTable.addCell(cell);
        }

        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            try {
                headerTable.setTotalWidth(document.getPageSize().getWidth());
                Pdfgen.headerHeight = headerTable.getTotalHeight();
                headerTable.writeSelectedRows(0, -1, 0, document.getPageSize().getHeight(), writer.getDirectContent());
                headerTable = new PdfPTable(1);
                header = new ArrayList<Element>(1);
            } catch (Exception e) {
                e.printStackTrace();
                Logger.I(LOG_TAG, "in Header onEndPage catch block----"+e);
            }
        }
    }


    // iText page footer tag processor    
    private class FooterTagProcessor extends AbstractTagProcessor {
        public FooterTagProcessor() {
        }

        public List<Element> content(WorkerContext ctx, Tag tag, String content) {
            return this.textContent(ctx, tag, content);
        }

        public List<Element> end(WorkerContext ctx, Tag tag, List<Element> currentContent) {
            List<Element> returnList = this.currentContentToParagraph(currentContent, false, true, tag, ctx);

            if (returnList.size()>0) {
                MapContext mc;
                try {
                    mc = (MapContext)ctx.get("com.itextpdf.tool.xml.pipeline.end.PdfWriterPipeline");
                } catch (NoCustomContextException ex) {
                    throw new ExceptionConverter(ex);
                }
                PdfWriter writer = (PdfWriter) mc.get("WRITER");
                writer.setPageEvent(new Footer(returnList));
            }
            returnList = new ArrayList<Element>(1);
            return returnList;
        }

        public boolean isStackOwner() {
            return true;
        }
    }


    // iText page footer implementation
    private class Footer extends PdfPageEventHelper {
        protected List<Element> footer;
        protected PdfPTable footerTable;

        public Footer(List<Element> footer) {
            this.footer = footer;
            this.footerTable = new PdfPTable(1);
            footerTable.setLockedWidth(true);
            PdfPCell cell = new PdfPCell();
            for (Element e : footer) {
                cell.addElement(e);
            }
            cell.setBorder(Rectangle.NO_BORDER);
            footerTable.addCell(cell);
        }

        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            try {
                footerTable.setTotalWidth(document.getPageSize().getWidth());
                footerTable.writeSelectedRows(0, -1, 0, footerTable.getTotalHeight(), writer.getDirectContent());
                footerTable = new PdfPTable(1);
                footer = new ArrayList<Element>(1);
            } catch (Exception e) {
                e.printStackTrace();
                Logger.I(LOG_TAG, "in Footer onEndPage catch block----"+e);
            }
        }
    }


    // iText main body tag processor    
    private class MainBodyTagProcessor extends AbstractTagProcessor {
        public MainBodyTagProcessor() {
        }

        public List<Element> content(WorkerContext ctx, Tag tag, String content) {
            return this.textContent(ctx, tag, content);
        }

        public List<Element> end(WorkerContext ctx, Tag tag, List<Element> currentContent) {
            List<Element> returnList = this.currentContentToParagraph(currentContent, false, true, tag, ctx);

            if (returnList.size()>0) {
                MapContext mc;
                try {
                    mc = (MapContext)ctx.get("com.itextpdf.tool.xml.pipeline.end.PdfWriterPipeline");
                } catch (NoCustomContextException ex) {
                    throw new ExceptionConverter(ex);
                }
                PdfWriter writer = (PdfWriter) mc.get("WRITER");
                writer.setPageEvent(new MainBody(returnList));
            }
            returnList = new ArrayList<Element>(1);
            return returnList;
        }

        public boolean isStackOwner() {
            return true;
        }
    }


    // iText main body implementation
    private class MainBody extends PdfPageEventHelper {
        protected List<Element> mainBody;
        protected PdfPTable mainBodyTable;

        public MainBody(List<Element> mainBody) {
            this.mainBody = mainBody;
            this.mainBodyTable = new PdfPTable(1);
            mainBodyTable.setLockedWidth(true);
            PdfPCell cell = new PdfPCell();
            for (Element e : mainBody) {
                cell.addElement(e);
            }
            cell.setBorder(Rectangle.NO_BORDER);
            mainBodyTable.addCell(cell);
        }

        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            try {
                mainBodyTable.setTotalWidth(document.getPageSize().getWidth());
                mainBodyTable.writeSelectedRows(0, -1, 0, document.getPageSize().getHeight()-Pdfgen.headerHeight, writer.getDirectContent());
                mainBodyTable = new PdfPTable(1);
            } catch (Exception e) {
                e.printStackTrace();
                Logger.I(LOG_TAG, "in MainBody onEndPage catch block----"+e);
            }
        }
    }


    /*public String[] copyFontFiles() throws IOException{
        FileOutputStream fos = null;
        String [] assetFontFileList = null;
        try {
            assetFontFileList = getAssets().list("fonts");
            for(String fileName:assetFontFileList){
                InputStream is = getAssets().open("fonts"+File.separator+fileName);
                byte[] data = new byte[2048];
                int nbread = 0;
                fos = openFileOutput(fileName, MODE_PRIVATE);
                while((nbread=is.read(data))>-1){
                    fos.write(data,0,nbread);
                }
            }
        }
        catch (Exception ex) {
            Log.e("Exception",ex.getMessage());
        }
        finally{
            if (fos!=null){
                fos.close();
            }
        }
        return assetFontFileList;
    }*/





    @Override
    public void generateIOSPDF(String htmlContent, String targetFilePath, IMethodResult result) {
    }

    @Override
    public void mergeIOSPDF(String listOfPaths, String targetFilePath, String password, IMethodResult result) {
    }
}
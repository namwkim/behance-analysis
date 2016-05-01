package com.nam;



import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.util.Map;
import java.awt.Point;
import com.google.common.base.Stopwatch;
import com.googlecode.javacv.cpp.opencv_core.CvScalar;
import org.sikuli.design.color.ColorAnalyzer;
import javax.activation.MimetypesFileTypeMap;
import org.sikuli.design.color.NamedColor;
import org.sikuli.design.color.StandardColors;
import org.sikuli.design.QuadtreeFeatureComputer;
import org.sikuli.design.quadtree.ColorEntropyDecompositionStrategy;
import org.sikuli.design.quadtree.IntensityEntropyDecompositionStrategy;
import org.sikuli.design.quadtree.QuadTreeDecomposer;
import org.sikuli.design.quadtree.Quadtree;

public class Main {
    public static void main(String[] args) {
    	// load images
        File folder = new File("../images");
        File[] files = folder.listFiles();

        try {
            FileWriter writer = new FileWriter("../project-props.csv");//project-props.csv");
            // headers for colors
            writer.append("filename,width,height,hue,saturation,value,");
            StandardColors colorNames = new StandardColors();
            for (NamedColor c : colorNames) {
                writer.append(c.getName() + ",");
            }
            writer.append("colorfulness1,colorfulness2\n");
            // headers for quad-tree
//            writer.append("colEq,colHorSym,colVerSym,colHorBal,colVerBal,");
//            writer.append("intEq,intHorSym,intVerSym,intHorBal,intVerBal,");
//            writer.append("colNumLeaves,intNumLeaves\n");

            Stopwatch timer = new Stopwatch();
            timer.start();

            for (int i=0; i<files.length; i++) {
                File f = files[i];
                System.out.println("Processing" + "(" + i+"/"+files.length+"): " + f.getName());


                String mimetype = new MimetypesFileTypeMap().getContentType(f);
                String type = mimetype.split("/")[0];
                if(type.equals("image")==false){
                    continue;
                }

                try {
                    BufferedImage input = ImageIO.read(f);
                    //1. filename
                    writer.append( f.getName() + ",");
                    //2. width, height
                    int height = input.getHeight();
                    int width = input.getWidth();

                    ////*************** Colors ***************

                    writer.append( width + "," + height  + ",");
                    //3. hue, saturation, value (brightness)
                    CvScalar avg = ColorAnalyzer.computeAverageHueSaturationValue(input);
                    writer.append(avg.getVal(0) + "," + avg.getVal(1) + "," + avg.getVal(2) + ",");
                    //4. web colors
                    Map<NamedColor, Double> d = ColorAnalyzer.computeColorDistribution(input);
                    for (NamedColor c : colorNames){
                        writer.append(d.get(c) + ",");
                    }
                    //5. colorfulness
                    writer.append(ColorAnalyzer.computeColorfulness(input) + ",");
                    writer.append(ColorAnalyzer.computeColorfulness2(input) + "");

                    ////*************** Quad Trees ***************

//                    IntensityEntropyDecompositionStrategy iStrategy = new IntensityEntropyDecompositionStrategy();
//                    ColorEntropyDecompositionStrategy cStrategy = new ColorEntropyDecompositionStrategy();
//
//                    QuadTreeDecomposer cDecomposer = new QuadTreeDecomposer(cStrategy);
//                    Quadtree cRoot = cDecomposer.decompose(input);
//
//                    QuadTreeDecomposer iDecomposer = new QuadTreeDecomposer(iStrategy);
//                    Quadtree iRoot = iDecomposer.decompose(input);
//
//                    Point centerOfImage = new Point(input.getWidth()/2,input.getHeight()/2);
//                    double colorEquilibrium = QuadtreeFeatureComputer
//                            .computeEquilibrium(cRoot, centerOfImage);
//                    double intensityEquilibrium = QuadtreeFeatureComputer
//                            .computeEquilibrium(iRoot, centerOfImage);
//                    double colorHorizontalSymmetry = QuadtreeFeatureComputer
//                            .computeHorizontalSymmetry(cRoot);
//                    double colorVerticalSymmetry = QuadtreeFeatureComputer
//                            .computeVerticalSymmetry(cRoot);
//                    double colorHorizontalBalance = QuadtreeFeatureComputer
//                            .computeHorizontalBalance(cRoot);
//                    double colorVerticalBalance = QuadtreeFeatureComputer
//                            .computeVerticalBalance(cRoot);
//
//                    double intensityHorizontalSymmetry = QuadtreeFeatureComputer
//                            .computeHorizontalSymmetry(iRoot);
//                    double intensityVerticalSymmetry = QuadtreeFeatureComputer
//                            .computeVerticalSymmetry(iRoot);
//                    double intensityHorizontalBalance = QuadtreeFeatureComputer
//                            .computeHorizontalBalance(iRoot);
//                    double intensityVerticalBalance = QuadtreeFeatureComputer
//                            .computeVerticalBalance(iRoot);
//                    int colorNumQuadTreeLeaves = cRoot.countLeaves()/4;
//                    int intensityNumQuadTreeLeaves = iRoot.countLeaves()/4;
//
//                    writer.append(colorNumQuadTreeLeaves + "," +
//                            intensityNumQuadTreeLeaves + "," +
//                            colorHorizontalSymmetry + "," +
//                            colorVerticalSymmetry + "," +
//                            colorHorizontalBalance + "," +
//                            colorVerticalBalance + "," +
//                            intensityHorizontalSymmetry + "," +
//                            intensityVerticalSymmetry + "," +
//                            intensityHorizontalBalance + "," +
//                            intensityVerticalBalance + "," +
//                            colorEquilibrium + "," +
//                            intensityEquilibrium);

                } catch (IOException ioe) {
                    System.out.println("Failed processing: " + f.getName()
                            + ". Error: " + ioe.getMessage());
                    writer.append("io_failed_"+ f.getName() + ",N/A,N/A");
                } catch (Exception e) {
                    System.out.println("Failed processing: " + f.getName()
                            + ". Error: " + e.getMessage());
                    writer.append("io_failed_"+ f.getName() + ",N/A,N/A");
                }

                writer.append("\n");
            }
            timer.stop();
            System.out.println("Time span: " + timer);

            writer.flush();
            writer.close();
        }catch (IOException ioe){

        }

    }
}


import org.gicentre.geomap.*; //<>// //<>// //<>//
import org.gicentre.geomap.io.*;
import org.gicentre.utils.colour.*;
import org.gicentre.utils.move.*;
import org.gicentre.utils.stat.*;
import java.util.ArrayList;
import controlP5.*;
import grafica.*;
import java.time.Duration;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

// Classes to control interactivity with map
ControlP5 cp5;
RadioButton rbLocation;
CheckBox cbWeekDay;
CheckBox cbMonth;

float loc, loc2, sliderHeight, sliderLocY, sliderWidth, sliderLocX;
boolean allowed, locAllowed, loc2Allowed;
LocalTime minTime, maxTime;

// Allows zooming into the map
ZoomPan zoomer;

// 2-D plot of data
GPlot distancePlot;
GPlot durationPlot;
GraphBoxes distanceBoxes;
GraphBoxes durationBoxes;
String [] distanceLabels;
String [] durationLabels;

boolean startCheck;
ArrayList<String> days;
ArrayList<String> months;

// Handles drawing map
GeoMap geoMap;
// Hash to get coordinates from object ID
Map<Integer,Feature> mapFeatures;
// Table used to get object ID from centerline
Table mapAttributes;

ScooterData scooterData;
// List which holds the streets that have trips which need to be drawn with objectID key
HashMap<Integer,Street> allStreets;

HashMap<Integer,Integer> gbsid2id;

int maxTrips;

PFont f;

ColourTable colours;
int circleColor;

void setup() {
  // Arbitrary for now
  size(1300,900);
  //size(1900, 1000);
  
  zoomer = new ZoomPan(this);
  zoomer.setMouseMask(SHIFT);
  
  // Loads in shapefile of Minneapolis streets
  geoMap = new GeoMap(3,90,700,800,this);
  geoMap.readFile("MPLS_Centerline");
  
  // Loads scooter trip data
  scooterData = new ScooterData();
  scooterData.loadFromFile("Motorized_Foot_Scooter_Trips_2021.csv");
  
  // Features have coordinates for each road in the city, indexed by id
  mapFeatures = geoMap.getFeatures();
  // Attributes have info for each street, including centerline
  mapAttributes = geoMap.getAttributeTable();
  
  gbsid2id = new HashMap<Integer,Integer>(mapFeatures.size());
  
  // Color table
  colours = new ColourTable();
  colours.addDiscreteColourRule(1, 143,184,134);
  colours.addDiscreteColourRule(2, 255,142,153);
  colours.addDiscreteColourRule(3, 142,39,84);
  //colours.addDiscreteColourRule(2, 255,155,150);
  //colours.addDiscreteColourRule(3, 116,93,132);
  circleColor = colours.findColour(1);
  f = createFont("Arial",10);
  
  // Create hash of all streets that have a scooter trip to/from them
  int startID,endID; // id corresponds to geomap id
  maxTrips = 0;
  Feature startFeat,endFeat;
  allStreets = new HashMap<Integer,Street>(scooterData.getNumTrips());
  for (ScooterTrip trip : scooterData.getAllTrips()) {
    try {
      startID = mapAttributes.findRow(str(trip.getStartLoc()),"GBSID").getInt("id");
      if (!allStreets.containsKey(startID)) {
        gbsid2id.putIfAbsent(trip.getStartLoc(), startID);
        startFeat = mapFeatures.get(startID);
        if (startFeat.getType() == FeatureType.LINE) {
          Street newStreet = new Street((Line)startFeat);
          newStreet.addTripStart(trip);
          allStreets.put(startID,newStreet);
        }
      }
      else {
        allStreets.get(startID).addTripStart(trip);
        if (allStreets.get(startID).getNumTripStarts()>maxTrips) {
          maxTrips=allStreets.get(startID).getNumTripStarts();
        }
      }
      
      endID = mapAttributes.findRow(str(trip.getEndLoc()),"GBSID").getInt("id");
      if (!allStreets.containsKey(endID)) {
        gbsid2id.putIfAbsent(trip.getEndLoc(), endID);
        endFeat = mapFeatures.get(endID);
        if (endFeat.getType() == FeatureType.LINE) {
          Street newStreet = new Street((Line)endFeat);
          newStreet.addTripEnd(trip);
          allStreets.put(endID,newStreet);
        }
      }
      else {
        allStreets.get(endID).addTripEnd(trip);
        if(allStreets.get(endID).getNumTripEnds()>maxTrips) {
          maxTrips=allStreets.get(endID).getNumTripEnds();
        }
      }
    } catch (NullPointerException e) {}
  }
  
  // Create objects to handle plotting of trip distances and durations
  distancePlot = new GPlot(this, 700, 60, 300, 300);
  distancePlot.setBgColor(250);
  //distancePlot.getHistogram().setLineColors(new int[] {color(0,0,0)});
  distancePlot.getTitle().setText("Scooter Trip Distance");
  distancePlot.getTitle().setTextAlignment(LEFT);
  distancePlot.getTitle().setRelativePos(0);
  distancePlot.getYAxis().getAxisLabel().setText("Number of Scooter Trips");
  distancePlot.getYAxis().getAxisLabel().setTextAlignment(RIGHT);
  distancePlot.getYAxis().getAxisLabel().setRelativePos(1);
  distancePlot.startHistograms(GPlot.VERTICAL);
  distancePlot.getHistogram().setDrawLabels(true);
  distancePlot.getHistogram().setRotateLabels(true);
  distanceLabels = new String [] {"< 1km", "1km-2km", "2km-3km", "3km-4km", "4km-5km",
                    "5km-6km", "6km-7km", "7km-8km", "8km-9km", "9km-10km",
                    "10km-11km", "11km-12km", "12km-13km", "13km-14km", "> 14km"};
  
  
  durationPlot = new GPlot(this, 1000, 60, 300, 300);
  durationPlot.setBgColor(250);
  //durationPlot.getHistogram().setLineColors(new int[] {color(0,0,0)});
  durationPlot.getTitle().setText("Scooter Trip Duration");
  durationPlot.getTitle().setTextAlignment(LEFT);
  durationPlot.getTitle().setRelativePos(0);
  durationPlot.getYAxis().getAxisLabel().setText("Number of Scooter Trips");
  durationPlot.getYAxis().getAxisLabel().setTextAlignment(RIGHT);
  durationPlot.getYAxis().getAxisLabel().setRelativePos(1);
  durationPlot.startHistograms(GPlot.VERTICAL);
  durationPlot.getHistogram().setDrawLabels(true);
  durationPlot.getHistogram().setRotateLabels(true);
  durationLabels = new String [] {"< 5 min", "5-10 min", "10-15 min", "15-20 min", "20-25 min",
                    "25-30 min", "30-35 min", "35-40 min", "40-45 min", "45-50 min",
                    "50-55 min", "55-60 min", "60-65 min", "65-70 min", "> 70 min"};
  
  
  sliderLocX = 750;
  sliderWidth = 500;
  loc = sliderLocX + 10;
  loc2 = sliderLocX + sliderWidth - 10;
  sliderHeight = 5;
  sliderLocY = 50;
  
  textSize(12);
  drawSlider();
  
  //Controller for all interactivity
  cp5 = new ControlP5(this);
  
  //set font for buttons
  
  cp5.setFont(f);
  
  startCheck = true;
  days = new ArrayList<String>(Arrays.asList(DayOfWeek.SUNDAY.toString(), DayOfWeek.MONDAY.toString(),
              DayOfWeek.TUESDAY.toString(), DayOfWeek.WEDNESDAY.toString(), DayOfWeek.THURSDAY.toString(),
              DayOfWeek.FRIDAY.toString(), DayOfWeek.SATURDAY.toString()));
  months = new ArrayList<String>(Arrays.asList(Month.APRIL.toString(), Month.MAY.toString(), Month.JUNE.toString(),
              Month.JULY.toString(), Month.AUGUST.toString(), Month.SEPTEMBER.toString(), Month.OCTOBER.toString(),
              Month.NOVEMBER.toString(), Month.DECEMBER.toString()));
  
  rbLocation = cp5.addRadioButton("radioButton")
         .setPosition(775,425)
         .setSize(50,30)
         .setColorForeground(color(120))
         .setColorBackground(color(202, 205, 230))
         .setColorActive(color(0, 7, 66))
         .setColorLabel(color(0))
         .setItemsPerRow(3)
         .setSpacingColumn(130)
         .addItem("Trip Start Point",0)
         .addItem("Trip End Point",1)
         .addItem("Trip Pairs", 2)
         .activate(0)
         .deactivate(1)
         .deactivate(2)
         .toUpperCase(true);
         
  cbWeekDay = cp5.addCheckBox("checkBoxWeekDay")
                  .setPosition(785, 522)
                  .setSize(30, 30)
                  .setItemsPerRow(4)
                  .setSpacingColumn(70)
                  .setSpacingRow(10)
                  .setColorForeground(color(120))
                  .setColorBackground(color(202, 205, 230))
                  .setColorActive(color(0, 7, 66))
                  .setColorLabel(color(0))
                  .addItem("SUNDAY", 0)
                  .addItem("MONDAY", 1)
                  .addItem("TUESDAY", 2)
                  .addItem("WEDNESDAY", 3)
                  .addItem("THURSDAY", 4)
                  .addItem("FRIDAY", 5)
                  .addItem("SATURDAY", 6)
                  .activateAll() 
                  ;
                  
  cbMonth = cp5.addCheckBox("checkBoxMonth")
                .setPosition(775, 655)
                .setSize(30, 30)
                .setItemsPerRow(5)
                .setSpacingColumn(70)
                .setSpacingRow(10)
                .setColorForeground(color(120))
                .setColorBackground(color(202, 205, 230))
                .setColorActive(color(0, 7, 66))
                .setColorLabel(color(0))
                .addItem("APRIL",0)
                .addItem("MAY",1)
                .addItem("JUNE", 2)
                .addItem("JULY", 3)
                .addItem("AUGUST", 4)
                .addItem("SEPTEMBER", 5)
                .addItem("OCTOBER", 6)
                .addItem("NOVEMBER", 7)
                .addItem("DECEMBER", 8)
                .activateAll()
                ;
                

}

void drawTrips(HashMap<Integer,Street> streetsToDraw) {
  pushMatrix(); 
  Street currStreet;
  for (int streetID : streetsToDraw.keySet()) {
    currStreet = streetsToDraw.get(streetID);

    //selects start or end points based on filter
    // shows points with at least 10 rides starting/ending from it - 
    // Idea: change this so point is shown if number of rides starting/ending 
    // from it is above the average number of rides?
    if((int(rbLocation.getArrayValue()[0]) == 1) && (currStreet.getNumTripStarts() > 2)){
      // Trip Starts
      pushMatrix();
      circleColor = colours.findColour(1);
      fill(circleColor);
      circle(currStreet.getX(), currStreet.getY(),map(currStreet.getNumTripStarts(),2,maxTrips,3,30));
      popMatrix();
    }
    else if((int(rbLocation.getArrayValue()[1]) == 1) && (currStreet.getNumTripEnds() > 2)){
      // Trip Ends
      pushMatrix();
      circleColor = colours.findColour(2);
      fill(circleColor);
      circle(currStreet.getX(), currStreet.getY(),map(currStreet.getNumTripEnds(),2,maxTrips,3,30));
      popMatrix();
    }
    else if((int(rbLocation.getArrayValue()[2]) == 1)) {
      // Connect trip starts and ends
      pushMatrix();
      circleColor = colours.findColour(3);
      fill(circleColor);
      
      if (currStreet.getNumTripStarts() > 0) {
        circle(currStreet.getX(), currStreet.getY(),4);
      }
      else if (currStreet.getNumTripEnds() > 0) {
        circle(currStreet.getX(), currStreet.getY(),4);
      }
      
      stroke(circleColor);
      strokeWeight(2);
      // arrow
      Street start, end;
      for (ScooterTrip trip : currStreet.getTripStarts().getVisibleTrips().getAllTrips()) {
        start = streetsToDraw.get(gbsid2id.get(trip.getStartLoc()));
        end = streetsToDraw.get(gbsid2id.get(trip.getEndLoc()));
        if (start != null && end != null) {
          drawArrow(start.getVector(), end.getVector());
        }
      }
      stroke(0);
      strokeWeight(1);
      popMatrix();
    }
  }
  
  // Adjust color of graph to match circle colors
  int [] plotColors = new int[15];
  int [] lineColors = new int[15];
  for (int i=0; i<plotColors.length; i++) {
    plotColors[i] = circleColor;
    lineColors[i] = color(100,100,100);
  }
  distancePlot.getHistogram().setBgColors(plotColors);
  distancePlot.getHistogram().setLineColors(lineColors);
  durationPlot.getHistogram().setBgColors(plotColors);
  durationPlot.getHistogram().setLineColors(lineColors);
  
  popMatrix();
}

void drawArrow(PVector startVec, PVector endVec) {
  float a = dist(startVec.x, startVec.y, endVec.x, endVec.y) / 50;
  pushMatrix();
  translate(endVec.x, endVec.y);
  rotate(atan2(endVec.y-startVec.y, endVec.x-startVec.x));
  triangle(-a*2, -a, 0, 0, -a*2, a);
  popMatrix(); //<>//
  line(startVec.x,startVec.y,endVec.x,endVec.y);
}

// TODO: if want to resize the maximum trips on a street can do that here
void updateVisibility() {
  durationBoxes = new GraphBoxes();

  distanceBoxes = new GraphBoxes();
  
  Street currStreet;
  maxTrips = 0;
  for (int streetID : allStreets.keySet()) {
    int tempMaxTrips = 0;
    currStreet = allStreets.get(streetID);
    
    for (ScooterTrip trip : currStreet.getTripStarts().getAllTrips()) {
      // check if trip start day is in the "days" and "months" array lists //<>//
        if(days.contains(trip.getStartTime().getDayOfWeek().toString()) &&
            months.contains(trip.getStartTime().getMonth().toString()) &&
            trip.getStartTime().toLocalTime().isAfter(minTime) &&
            trip.getStartTime().toLocalTime().isBefore(maxTime)
            ) {
              
          trip.setVisible(true); 
          
          // put trip into 5 minute increment box
          int durationBox = (int)Math.floor((trip.getDuration()/60)/5) < 15 ? 
                          (int)Math.floor((trip.getDuration()/60)/5) : 14;   
          durationBoxes.addTrip(trip, durationBox, durationLabels[durationBox]);
          
          // put trip into 1km increment box
          int distanceBox = (int)Math.floor((trip.getDistance()/1000)) < 15 ?
                          (int)Math.floor((trip.getDistance()/1000)) : 14;
          distanceBoxes.addTrip(trip, distanceBox, distanceLabels[distanceBox]);
          
          tempMaxTrips++;
        }
      
      else {
        trip.setVisible(false); 
      } //<>//
    }
    if (tempMaxTrips > maxTrips) {
      maxTrips = tempMaxTrips;
    }
  }
  int [] plotColors = new int [15];
  for (int i=0; i<plotColors.length; i++) {
    plotColors[i] = circleColor;
  }
  durationPlot.setPoints(durationBoxes.getPointsArray()); //<>//
  distancePlot.setPoints(distanceBoxes.getPointsArray());
}

/////////////////////////////////////////////////////////////////////////
// Class which keeps track of scooter trips in each graph box
/////////////////////////////////////////////////////////////////////////
public class GraphBoxes {
  GPointsArray points;
  ArrayList<ScooterData> tripsBox;
  public GraphBoxes() {
    this.points = new GPointsArray(15);
    for (int i=0; i<15; i++) {
      this.points.add(i,i,0);
    }
    this.tripsBox = new ArrayList<ScooterData>(15);
    for (int i=0; i<15; i++) {
      this.tripsBox.add(i, new ScooterData());
    }
  }
  
  public void addTrip(ScooterTrip trip, int box, String label) {
    this.points.set(box,box,this.points.getY(box)+1, label);
    tripsBox.get(box).addTrip(trip); //<>//
  }
  
  public GPointsArray getPointsArray() {
    return this.points;
  }
  
  public String displayNumTripsInMonth(int box, String month) {
    int numTrips = this.tripsBox.get(box).getNumTripsInMonth(month);
    
    return month + ": " + str(numTrips);
  }
  
  public String displayNumTripsOnDay(int box, String day) {
    int numTrips = this.tripsBox.get(box).getNumTripsOnDay(day);
    
    return day + ": " + str(numTrips);
  }
}

void draw() {
  background(250);
  
  pushMatrix();
  zoomer.transform();
  //zoomer.addZoomPanListener(new MyListener());
  geoMap.draw();
  this.drawTrips(allStreets);
  popMatrix();
  
  pushMatrix();
  fill(250);
  noStroke();
  rect(690,0,613,900);
  stroke(0);
  popMatrix();
  
  textFont(f,10);
 
  distancePlot.beginDraw();
  distancePlot.drawBackground();
  distancePlot.drawBox();
  distancePlot.drawYAxis();
  distancePlot.drawTitle();
  distancePlot.drawHistograms();
  distancePlot.endDraw();
  
  durationPlot.beginDraw();
  durationPlot.drawBackground();
  durationPlot.drawBox();
  durationPlot.drawYAxis();
  durationPlot.drawTitle();
  durationPlot.drawHistograms();
  durationPlot.endDraw();
  
  pushMatrix();
  
  // Show information when mousing over plot
  fill(255);
  textAlign(LEFT); //<>//
  if (distancePlot.isOverPlot(mouseX, mouseY)) {
    float [] tp = distancePlot.getValueAt(mouseX, mouseY);
    int box = (int)Math.floor(tp[0]+0.5);
    if (box >= 0 && box < 15) {
      int i = 0;
      int leftRight = mouseX + 200 > width ? -200 : 0;
      
      pushMatrix();
      fill(color(0,0,0,150));
      int rectHeight = days.size() > months.size() ? days.size() : months.size();
      rect(mouseX+leftRight,mouseY-10,205 ,textAscent()*rectHeight+5);
      popMatrix();
      
      pushMatrix();
      fill(255);
      for (String month : months) {
        text(distanceBoxes.displayNumTripsInMonth(
            box, month), mouseX+5+leftRight, mouseY+textAscent()*i);
        i++;
      }
      int j = 0;
      for (String day : days) {
        text(distanceBoxes.displayNumTripsOnDay(
            box, day), mouseX+110+leftRight, mouseY+textAscent()*j);
        j++;
      }
      popMatrix();

    }
  }
  else if (durationPlot.isOverPlot(mouseX, mouseY)) {
    float [] tp = durationPlot.getValueAt(mouseX, mouseY);
    int box = (int)Math.floor(tp[0]+0.5);
    if (box >= 0 && box < 15) {
      int i = 0;
      int leftRight = mouseX + 200 > width ? -200 : 0;
      
      pushMatrix();
      fill(color(0,0,0,150));
      int rectHeight = days.size() > months.size() ? days.size() : months.size();
      rect(mouseX+leftRight,mouseY-10,205 ,textAscent()*rectHeight+5);
      popMatrix();
      
      pushMatrix();
      fill(255);
      for (String month : months) {
        text(durationBoxes.displayNumTripsInMonth(
            box, month), mouseX+5+leftRight, mouseY+textAscent()*i);
        i++;
      }
      i = 0;
      for (String day : days) {
        text(durationBoxes.displayNumTripsOnDay(
            box, day), mouseX+110+leftRight, mouseY+textAscent()*i);
        i++;
      }
      popMatrix();
    }
  }
  popMatrix();
  
  textSize(12);
  drawSlider();
  
  pushMatrix();
  fill(250);
  noStroke();
  rect(0,0,700,90);
  stroke(0);
  popMatrix();
  
  // Draw reference circle which shows max size and how many trips that represents
  pushMatrix();
  fill(circleColor);
  circle(705,500,30);
  fill(0);
  textSize(14);
  textAlign(LEFT);
  text("= " + str(maxTrips) + " Scooter Trips",733,505);
  popMatrix();
  
  //set visualization title
  textAlign(LEFT);
  textSize(35);
  fill(0);
  text("Visualizing Trends in Electric Scooter Rides Around Minneapolis", 50, 50);
  
  //labels
  textAlign(CENTER);
  textSize(20);
  fill(0);
  text("Trip Location", 1000, 405);
  text("Week Day", 1000, 502);
  text("Month", 1000, 635);
  text("Time", 1000, 775);
} //<>//

/////////////////////////////////////////////////////////////////////////
// Class which keeps track of scooter trips and amount on each street
/////////////////////////////////////////////////////////////////////////
public class Street {
  private ScooterData tripStarts;
  private ScooterData tripEnds;
  PVector screenCoords;
  
  public Street(Line streetData) {
    this.tripStarts = new ScooterData();
    this.tripEnds = new ScooterData();
    this.screenCoords = geoMap.geoToScreen(streetData.getXCoords()[streetData.getXCoords().length/2],
              streetData.getYCoords()[streetData.getYCoords().length/2]);
  }
  
  public ScooterData getTripStarts() {
    return tripStarts;
  }
   //<>//
  public ScooterData getTripEnds() {
    return tripEnds;
  }
  
  public float getX() {
    return screenCoords.x;
  }
  
  public float getY() {
    return screenCoords.y;
  }
  
  public PVector getVector() {
    return screenCoords; 
  }
  
  public void addTripStart(ScooterTrip trip) {
    tripStarts.addTrip(trip);
  }
  
  public void addTripEnd(ScooterTrip trip) {
    tripEnds.addTrip(trip);
  }
  
  public int getNumTripStarts() {
    return tripStarts.getNumVisibleTrips();
  }
  
  public int getNumTripEnds() {
    return tripEnds.getNumVisibleTrips();
  }
}


//ensures at least one location button is selected
void controlEvent(ControlEvent theEvent) {
  if(theEvent.isFrom(rbLocation)) {
    if ((int(theEvent.getGroup().getArrayValue()[0]) == 0) && 
          (int(theEvent.getGroup().getArrayValue()[1]) == 0) && 
          (int(theEvent.getGroup().getArrayValue()[2]) == 0)){
      rbLocation.activate(0);
    }
  }
  
  else if (theEvent.isFrom(cbWeekDay)) {
    for (int i=0; i < cbWeekDay.getArrayValue().length; i++) {
      if((int) cbWeekDay.getArrayValue()[i] == 1) {
        if(!days.contains(cbWeekDay.getItem(i).getName())) {
          days.add(cbWeekDay.getItem(i).getName());
        }
      }
      else if((int) cbWeekDay.getArrayValue()[i] == 0) {
        if(days.contains(cbWeekDay.getItem(i).getName())) {
          days.remove(cbWeekDay.getItem(i).getName());
        }
      }
    }
  }
  else if (theEvent.isFrom(cbMonth)) {
    for (int i=0; i < cbMonth.getArrayValue().length; i++) {
      if((int) cbMonth.getArrayValue()[i] == 1) {
        if(!months.contains(cbMonth.getItem(i).getName())) {
          months.add(cbMonth.getItem(i).getName());
        }
      }
      else if((int) cbMonth.getArrayValue()[i] == 0) {
        if(months.contains(cbMonth.getItem(i).getName())) {
          months.remove(cbMonth.getItem(i).getName());
        }
      }
    }
  }
  this.updateVisibility();
}



void drawSlider() {
  float sliderBottom = 885;
  minTime = LocalTime.MIN.plus(Duration.ofMinutes((long) 
             map(loc, sliderLocX + 10, sliderLocX + sliderWidth-10, 0, 24*60-1)));
  maxTime = LocalTime.MIN.plus(Duration.ofMinutes((long) 
             map(loc2, sliderLocX + 10, sliderLocX + sliderWidth-10, 0, 24*60-1)));
  
  fill(250);
  rect(sliderLocX-20, sliderBottom-(sliderLocY*2), sliderWidth + 40, sliderLocY*2); 
  
  fill(202, 205, 230);
  rect(sliderLocX + 10, sliderBottom-sliderLocY, sliderWidth-20, sliderHeight); 
  
  fill(0, 7, 66);
  rect(loc, sliderBottom-sliderLocY, loc2-loc, sliderHeight); 
  
  fill(0);
  ellipse(loc, sliderBottom-sliderLocY+(sliderHeight/2), 15, 15);
  ellipse(loc2, sliderBottom-sliderLocY+(sliderHeight/2), 15, 15);
  
  textAlign(CENTER);
  
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern("hh:mm a");
  
  text(minTime.format(formatter), loc, sliderBottom-sliderLocY+20);
  text(maxTime.format(formatter), loc2, sliderBottom-sliderLocY+20);
  text("12:00 AM", sliderLocX + 10, sliderBottom-sliderLocY+40);
  text("11:59 PM", sliderLocX + sliderWidth-10, sliderBottom-sliderLocY+40);
} 

void mousePressed() {
  if (mouseY > height-(sliderLocY*2)) allowed = true;  
  if (mouseX > loc-5 && mouseX < loc+5){
    locAllowed = true;
  }
  else if (mouseX > loc2-5 && mouseX < loc2+5){
    loc2Allowed = true;
  }
}

void mouseReleased() {
  allowed = false;
  locAllowed = false;
  loc2Allowed = false;
  this.updateVisibility();
}  

void mouseDragged() {
  if (mousePressed){
    if (allowed && locAllowed) {
      if (mouseX < loc2){
        loc = mouseX;
        if (loc < sliderLocX + 10) loc = sliderLocX + 10;
        if (loc > sliderLocX + sliderWidth-10) loc = sliderLocX + sliderWidth-10;
      }
    }
    
    else if (allowed && loc2Allowed) {
      if (mouseX > loc){
        loc2 = mouseX;
        if (loc2 < sliderLocX + 10) loc2 = sliderLocX + 10;
        if (loc2 > sliderLocX + sliderWidth-10) loc2 = sliderLocX + sliderWidth-10;
      }
    }
  }
  //this.updateVisibility();
}

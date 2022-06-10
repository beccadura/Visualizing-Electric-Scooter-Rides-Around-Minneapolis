// Helper class to parse electric scooter data from the city of Minneapolis

import java.util.*;
import java.lang.*;
import java.time.*;
import java.time.format.*;
import java.util.ArrayList;

// Class which stores data for a single scooter trip
public class ScooterTrip {
  // Fields from the input csv
  private int objectID;
  private int tripID;
  private int duration;
  private int distance;
  private LocalDateTime startTime;
  private LocalDateTime endTime;
  private int startLoc;
  private String startType;
  private int endLoc;
  private String endType;
  
  // Field which determines whether this trip is visible or not
  private boolean visible;
  
  // Constructor
  public ScooterTrip(int objectID, int tripID, int duration, int distance, LocalDateTime startTime, LocalDateTime endTime, int startLoc, String startType, int endLoc, String endType) {
    this.objectID = objectID;
    this.tripID = tripID;
    this.duration = duration;
    this.distance = distance;
    this.startTime = startTime;
    this.endTime = endTime;
    this.startLoc = startLoc;
    this.startType = startType;
    this.endLoc = endLoc;
    this.endType = endType;
    
    this.visible = true;
  }
  
  public int getObjectID() {
    return this.objectID;
  }
  
  public int getTripID() {
    return this.tripID;
  }
  
  public int getDuration() {
    return this.duration;
  }
  
  public int getDistance() {
    return this.distance;
  }
  
  public LocalDateTime getStartTime() {
    return this.startTime;
  }
  
  public LocalDateTime getEndTime() {
    return this.endTime;
  }
  
  public int getStartLoc() {
    return this.startLoc;
  }
  
  public String getStartType() {
    return this.startType;
  }
  
  public int getEndLoc() {
    return this.endLoc;
  }
  
  public String getEndType() {
    return this.endType;
  }
  
  public boolean isVisible() {
    return this.visible;
  }
  
  public void setVisible(boolean visible) {
    this.visible = visible;
  }
  
}

// Holds ArrayList of all scooter trips taken.
// TODO: can implement methods to return certain subset of trips for different interactive purposes
public class ScooterData {
  
  private ArrayList<ScooterTrip> scooterTrips;
  
  // Constructor when loading in data from the file
  public ScooterData() {
    scooterTrips = new ArrayList<ScooterTrip>();
  }
  
  // Constructor when creating subset of scooter trips
  public ScooterData(ArrayList<ScooterTrip> scooterTrips) {
    this.scooterTrips = scooterTrips;
  }
  
  // Load each trip into the ArrayList
  public void loadFromFile(String fileName) {
    Table rawData = loadTable(fileName, "header");
    
    // Put start and end times into LocalDateTime class format
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ssx");
    
    for (TableRow rawRow : rawData.rows()) {
      int objectID = rawRow.getInt("ObjectId");
      int tripID = rawRow.getInt("TripID");
      int duration = rawRow.getInt("TripDuration");
      int distance = rawRow.getInt("TripDistance");
      LocalDateTime startTime = LocalDateTime.parse(rawRow.getString("StartTime"),formatter);
      LocalDateTime endTime = LocalDateTime.parse(rawRow.getString("EndTime"),formatter);
      String startType = rawRow.getString("StartCenterlineType");
      String endType = rawRow.getString("EndCenterlineType");
      
      // Right now only worrying about street data. Trails deal with another map data set which may complicate things
      if (startType.equals("street") && endType.equals("street")) {
        int startLoc = (int) rawRow.getFloat("StartCenterlineID"); // if trail it's not a float
        int endLoc = (int) rawRow.getFloat("EndCenterlineID");
        scooterTrips.add(new ScooterTrip(objectID, tripID, duration, distance, 
                startTime, endTime, startLoc, startType, endLoc, endType));
      }
      
    }
  }
  
  public ArrayList<ScooterTrip> getAllTrips() 
  {
    return this.scooterTrips;
  }
  
  public int getNumTrips()
  {
    return scooterTrips.size();
  }
  
  public int getNumVisibleTrips() {
    int numVis = 0;
    for (ScooterTrip trip : scooterTrips) {
      if (trip.isVisible()) {
        numVis++;
      }
    }
    
    return numVis;
  }
  
  public ScooterData getVisibleTrips() {
    ScooterData visTrips = new ScooterData();
    for (ScooterTrip trip : scooterTrips) {
      if (trip.isVisible()) {
        visTrips.addTrip(trip);
      }
    }
    return visTrips;
  }
  
  public void addTrip(ScooterTrip trip)
  {
    this.scooterTrips.add(trip);
  }
  
  public int getNumTripsInMonth(String month) {
    int numTrips = 0;
    for (ScooterTrip trip : scooterTrips) {
      if (trip.getStartTime().getMonth().toString().equalsIgnoreCase(month)) {
        numTrips++;
      }
    }
    return numTrips;
  }
  
  public int getNumTripsOnDay(String day) {
    int numTrips = 0;
    for (ScooterTrip trip : scooterTrips) {
      if (trip.getStartTime().getDayOfWeek().toString().equalsIgnoreCase(day)) {
        numTrips++;
      }
    }
    return numTrips;
  }
}

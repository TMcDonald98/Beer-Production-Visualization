
import java.util.*;
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.interactions.*;
import de.fhpotsdam.unfolding.mapdisplay.*;
import de.fhpotsdam.unfolding.mapdisplay.shaders.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.texture.*;
import de.fhpotsdam.unfolding.tiles.*;
import de.fhpotsdam.unfolding.ui.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.utils.*;


final int[] COLORS = {#e6194b, #3cb44b, #ffe119, #4363d8, #f58231, #911eb4, #46f0f0, #f032e6, 
  #bcf60c, #fabebe, #008080, #e6beff, #9a6324, #fffac8, #800000, #aaffc3, #808000, #ffd8b1, 
  #000075, #FFFFFF, #660066, #663300, #666633, #003300, #993300, #ccffff, #339966, #ff0000, 
  #99ff99, #00264d};
  
Table beerData;
PFont Font1;
List<Feature> states;
List<Marker>stateMarkers;
UnfoldingMap map;
//DebugDisplay detailedViz;

int currentYear = 2011;

// Sets up the canvas and loads in the csv document
void setup() {
    map = new UnfoldingMap(this);
    
    map.setBackgroundColor(240);
    MapUtils.createDefaultEventDispatcher(this, map);
    Location USAlocation = new Location(39.8f, -98.58f);
    float maxPanningDistance = 0;
    
    size(1600, 1200, P2D);
    Font1 = createFont("Arial Bold", 18);
    
    map.zoomAndPanTo(USAlocation, 5);
    MapUtils.createDefaultEventDispatcher(this, map);
    map.setPanningRestriction(USAlocation, maxPanningDistance);
    map.setZoomRange(4, 5);
    
    //detailedViz = new DebugDisplay(this, map, 10,10);
    
    // Load in beer data
    beerData = loadTable("beer_states.csv", "header");
    
    // Load in state data
    states = GeoJSONReader.loadData(this, "usStates.geo.json");
    stateMarkers = MapUtils.createSimpleMarkers(states);
    map.addMarkers(stateMarkers);
    Iterable<TableRow> beerDataCurrentYear = beerData.findRows(Integer.toString(currentYear), "year");
    colorStates(states, beerDataCurrentYear);

}




void draw() {
    map.draw();
    Location location = map.getLocation(mouseX, mouseY);
    fill(0,0,0);
    textSize(12);
    text(location.getLat() + ", " + location.getLon(), mouseX, mouseY);
    
    textFont(Font1);
    textSize(48);
    text(currentYear, 704.0, 100.0);
    for(Marker marker : map.getMarkers()){
      if (marker.isSelected()) {
        drawStateDetails(marker);
        break;
      }
    }

    color c1 = color(255, scaleColor(1,0), scaleColor(1,0));
    color c2 = color(255, scaleColor(1,1), scaleColor(1,1));
    textSize(22);
    text("Number of Barrels Brewed", 57, height - 120);
    textSize(18);
    text("0", 40, height - 20);
    text("Most Barrels Brewed By a State for Current Year", 150, height - 20);
    setGradient(40, height - 100, 300, 60, c1, c2, 2);

    
}
//when a state is selected this method draws the facts for the state.
void drawStateDetails(Marker marker){
    fill(#FFFFFF);
    rect(width - 600, 50, 515, 200, 7);
    String stateName = marker.getStringProperty("name");
    float premises = 0;
    float bottles = 0;
    float kegs = 0;
    for(TableRow tb : beerData.rows()){
        if(tb.getString("state").equals(stateName) && tb.getInt("year") == currentYear){
            if(!tb.getString("barrels").equals("NA")){          
                if(tb.getString("type").equals("On Premises"))
                    premises = tb.getFloat("barrels");
                else if(tb.getString("type").equals("Bottles and Cans"))
                    bottles = tb.getFloat("barrels");
                else if(tb.getString("type").equals("Kegs and Barrels"))
                    kegs = tb.getFloat("barrels");               
            }
        }
    }
    //graphs pi chart and circles for key
    float total = premises + bottles + kegs;
    float lastAngle = 0;
    fill(COLORS[0]);
    circle(width - 570, 128, 18);
    arc(width - 190, 150, 180, 180, lastAngle,radians(premises/total*360));
    lastAngle += radians(premises/total*360);
    fill(COLORS[1]);
    circle(width - 570, 173, 18);
    arc(width - 190, 150, 180, 180, lastAngle, lastAngle + radians(bottles/total*360));
    lastAngle += radians(bottles/total*360);
    fill(COLORS[2]);
    circle(width - 570, 218, 18);
    arc(width - 190, 150,180, 180, lastAngle, lastAngle + radians(kegs/total*360));
    lastAngle += radians(kegs/total*360);
    
    //rect(width - 600, 50, 550, 200, 7);
    //Adds labels
    fill(0);
    textSize(32);
    text(stateName, width - 575, 90);
    textSize(22);
    text("Barrels of Beer", width - 475, 75);
    text("Produced (31 gal)", width - 475, 100);
    textSize(18);
    text("On Premises: " + premises, width - 550, 135);
    text("Bottles and Cans: " + bottles, width - 550, 180);
    text("Kegs and Barrels: " + kegs, width - 550, 225);
    
}

// Need to figure out a color scheme so that no two colors are adjacent
void colorStates(List<Feature> states, Iterable<TableRow> stateBeerCurrentYear){
    float maxBeer = findMax();
    for (Marker marker : stateMarkers){
      String stateName = marker.getStringProperty("name");
      if (!stateName.equals("total")){
        float currentStateBeer = findTotalBarrels(stateBeerCurrentYear, stateName);
        float scaledColor = scaleColor(maxBeer, currentStateBeer);
        marker.setColor(color(255, scaledColor, scaledColor));
      }
    }
}


// There are 3 different types of production listed per year for each state 
// This method sums and returns all 3 for a given state
float findTotalBarrels(Iterable<TableRow> stateBeerCurrentYear, String state){
  float totalBarrels = 0;
  for (TableRow row : stateBeerCurrentYear){
     String temp = row.getString("state");
     if (temp.equals(state)){
       totalBarrels += row.getFloat("barrels"); 
     }
  }
  return totalBarrels;
}

float findMax(){
    float maxBeer = 0;
    for (int i = 2008; i < 2020; i++){
        Iterable<TableRow> stateBeerCurrentYear = beerData.findRows(Integer.toString(i), "year");
        for (TableRow row : stateBeerCurrentYear){
        if (!row.getString("state").equals("total")){
          float currentBeer;
          try{
             currentBeer = findTotalBarrels(stateBeerCurrentYear, row.getString("state"));
          } catch (Exception e){
            currentBeer = 0;
          }
          if (currentBeer > maxBeer){
             maxBeer = currentBeer;
          }
        }
     }    
    }
     return maxBeer;
}

float scaleColor(float maxBeer, float currentStateBeer){
    float scaledColor = 0;
    if (!Float.isNaN(currentStateBeer)){
      scaledColor = map((float)Math.cbrt(currentStateBeer), 0.0, (float)Math.cbrt(maxBeer), 0.0, 255.0);
    }
    
    return 255 - scaledColor;
}

public void mouseClicked() {
    Location mouseLocation = map.getLocation(mouseX, mouseY);
    List<Marker>stateMarkers = MapUtils.createSimpleMarkers(states);
    MarkerManager<Marker> stateManager = new MarkerManager<Marker>();
    stateManager.addMarkers(stateMarkers);
    Marker selectedMarker = map.getFirstHitMarker(mouseX, mouseY);
    for (Marker marker : map.getMarkers()) {
            marker.setStrokeWeight(1);
            marker.setSelected(false);
        }
    if (selectedMarker != null) {
       selectedMarker.setStrokeWeight(4);
       selectedMarker.setSelected(true);
    }
}

// Changes the year based on arrow pressed
void keyPressed(){
  if (key == CODED){
    if (keyCode == LEFT){
      if (currentYear == 2008){
        currentYear = 2019;
        Iterable<TableRow> beerDataCurrentYear = beerData.findRows(Integer.toString(currentYear), "year");
        colorStates(states, beerDataCurrentYear);
      }
      else currentYear -= 1;
    }
    else if (keyCode == RIGHT){
      if (currentYear == 2019){
        currentYear = 2008;
        Iterable<TableRow> beerDataCurrentYear = beerData.findRows(Integer.toString(currentYear), "year");
        colorStates(states, beerDataCurrentYear);
      }
      else currentYear +=1;
    }
  }
}

//method taken from Processing api example
void setGradient(int x, int y, float w, float h, color c1, color c2, int axis ) {

  noFill();

  for (int i = x; i <= x+w; i++) {
    float inter = map(i, x, x+w, 0, 1);
    color c = lerpColor(c1, c2, inter);
    stroke(c);
    line(i, y, i, y+h);
  }
}

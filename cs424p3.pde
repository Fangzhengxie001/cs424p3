import org.khelekore.prtree.*;

View rootView;

PFont font;
PFont font2;
  
HBar hbar;
HBar hbar2;
Animator settingsAnimator;
Animator detailsAnimator;

PApplet papplet;
MapView mapv;
GraphContainer graphContainer;
GraphView graphView;
Button graphButton;
ListBox graphModeList;
boolean graphOn;
SettingsView settingsView;
SightingDetailsView sightingDetailsView;

DateFormat dateTimeFormat= new SimpleDateFormat("EEEE, MMMM dd, yyyy HH:mm");
DateFormat dateFormat= new SimpleDateFormat("EEEE, MMMM dd, yyyy");
DateFormat shortDateFormat= new SimpleDateFormat("MM/dd/yyyy HH:mm");
DateFormat dbDateFormat= new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

color backgroundColor = 0;
color textColor = 255;
color boldTextColor = #FFFF00;
color titleTextColor = 0;
color viewBackgroundColor = #2D2A36;
color airportAreaColor = #FFA500;
color militaryBaseColor = #CC0000;
color weatherStationColor = #FFFF00;
color infoBoxBackground = #000000;
//color[] UFOColors = {#FFFF00,#00FF00,#00FFFF,#FF8000,#800FFF,#FF0000,};
color[] UFOColors = {#0000FF,#FF6600,#00FFFF,#FF0000,#FFFF00,#00FF00,#800FFF};

int normalFontSize = 13;
int smallFontSize = 10 ;
int largeFontSize = 15;

String[] monthLabelsToPrint = {"January","February","March","April","May","June","July","August","September","October","November","December"};
String[] monthLabels = {"01","02","03","04","05","06","07","08","09","10","11","12"};
String[] yearLabels = {"'00","'01","'02","'03","'04","'05","'06","'07","'08","'09","'10","'11"};
String[] yearLabelsToPrint = {"2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011"};
String[] timeLabels = {"00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"};
String[] UFOTypeLabels = {"UFOType 1","UFOType 2","UFOType 3","UFOType 4","UFOType 5","UFOType 6","UFOType 7"};
String[] UFOImages = {"blue.png","green.png","star.png","orange.png","purple.png","red.png","yellow.png"};


PImage airplaneImage;
PImage militaryBaseImage;
PImage weatherStationImage;

Map<Integer,SightingType> sightingTypeMap = new LinkedHashMap<Integer, SightingType>();
Map<Integer,State> stateMap = new HashMap<Integer,State>();
Map<Integer,Place> cityMap = new HashMap<Integer,Place>();
Map<Integer,Place> airportMap = new HashMap<Integer,Place>();
Map<Integer,Place> militaryBaseMap = new HashMap<Integer,Place>();
Map<Integer,Place> weatherStationMap = new HashMap<Integer,Place>();
PRTree<Place> cityTree;
PRTree<Place> airportTree;
PRTree<Place> militaryBaseTree;
PRTree<Place> weatherStationTree;

Map<SightingType, Checkbox> typeCheckboxMap;

Sighting clickedSighting;
Boolean showAirports=false;
Boolean showMilitaryBases = false;
Boolean showWeatherStation = false;
Boolean showByStates = true;
Boolean btwMonths = false;
Boolean btwTime = false;
String byType = "";
Boolean isDragging = false;


SightingsFilter activeFilter;

DataSource data;
boolean playing = false;
Player player;

void setup()
{
  size(1000, 700);  // OPENGL seems to be slower than the default
//  setupG2D();
  
  papplet = this;
  
  smooth();

  /* load data */
  if (sketchPath == null)  // applet
    data = new WebDataSource("http://young-mountain-2805.heroku.com/");  //dataPath("jsontest")
  else  // application
    data = new SQLiteDataSource();  
  
  data.loadSightingTypes();
  activeFilter = new SightingsFilter();
  data.loadStates();
  data.loadCities();
  data.loadAirports();
  data.loadMilitaryBases();
  data.loadWeatherStations();
  data.reloadCitySightingCounts();
  data.loadCityDistances();
  updateStateSightingCounts();
  
  buildPlaceTree();
  
  /* setup UI */
  rootView = new View(0, 0, width, height);
  font = loadFont("Helvetica-20.vlw");
  font2 = loadFont("Courier-20.vlw");
  
  airplaneImage = loadImage("plane.png");
  militaryBaseImage = loadImage("militars.png");
  weatherStationImage = loadImage("irkickflash2.png");
  
  mapv = new MapView(0,0,width,height);
  rootView.subviews.add(mapv);
  
  settingsView = new SettingsView(0,-80,width,125);
  rootView.subviews.add(settingsView);
  
  sightingDetailsView = new SightingDetailsView(0,height,width,200);
  rootView.subviews.add(sightingDetailsView);

  settingsAnimator = new Animator(settingsView.y);
  detailsAnimator = new Animator(sightingDetailsView.y);
  
  // I want to add true multitouch support, but let's have this as a stopgap for now
  addMouseWheelListener(new java.awt.event.MouseWheelListener() {
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) {
      rootView.mouseWheel(mouseX, mouseY, evt.getWheelRotation());
    }
  });

  graphContainer = new GraphContainer(0, 20, width, height-20); 
  
  graphButton = new Button(0, 0, width, 20, "Click here to show the Graphs");
  rootView.subviews.add(graphButton);
  graphOn = false;
}

void buttonClicked(Button button)
{
  if (button == graphButton) {
    graphOn = !graphOn;
    if (graphOn){ 
      rootView.subviews.add(graphContainer);
      button.label = "Click here to show the Map";
      graphContainer.updateValuesGraph();  
      
    }
    else{
      rootView.subviews.remove(graphContainer);
      button.label = "Click here to show the Graphs";
    }
  }
}

void buttonClicked(Checkbox button)
{
  if (graphOn)
     graphContainer.updateValuesMap(); 
     
  for (Entry<SightingType, Checkbox> entry : typeCheckboxMap.entrySet()) {
    entry.getKey().setActive(entry.getValue().value);
  }
  btwTime = settingsView.timeCheckbox.value;
  btwMonths = settingsView.monthCheckbox.value;
  
  updateFilter();
  
  if (showAirports != settingsView.showAirportCB.value || showMilitaryBases !=  settingsView.showMilitaryBasesCB.value 
      || showWeatherStation != settingsView.showWeatherStationCB.value || showByStates != settingsView.showByStatesCB.value){
    showAirports = settingsView.showAirportCB.value;
    showMilitaryBases = settingsView.showMilitaryBasesCB.value;
    showWeatherStation = settingsView.showWeatherStationCB.value;
    showByStates = settingsView.showByStatesCB.value;
    mapv.rebuildOverlay();
  }
  
  if (showByStates)
      detailsAnimator.target(height);
}

void listClicked(ListBox lb, int index, Object item)
{
  if (lb == graphModeList) {
    graphView.setActiveMode((String)item);
    String _item = (String)item;
    if (!_item.equals("Year") && !_item.equals("Season")  && !_item.equals("Month") && !_item.equals("Time of day")){
        graphContainer.graphAnimator.target(graphContainer.h-120);
    }
    else{
       graphContainer.graphAnimator.target(graphContainer.h-5);
    }
    
  }
}

void startPlaying()
{
  playing = true;
  player = new Player();
  settingsView.playBarAnimator.target(100);
}

void stopPlaying()
{
  playing = false;
  player = null;
  settingsView.playBarAnimator.target(0);
}

void draw()
{
  background(backgroundColor); 
  Animator.updateAll();
  
  settingsView.y = settingsAnimator.value;
  sightingDetailsView.y = detailsAnimator.value;
  settingsView.playBar.w = settingsView.playBarAnimator.value;
  
  rootView.draw(); 
}

void mousePressed()
{
  rootView.mousePressed(mouseX, mouseY);
}

void mouseDragged()
{
  isDragging = true;
  rootView.mouseDragged(mouseX, mouseY);
}

void mouseClicked()
{
  rootView.mouseClicked(mouseX, mouseY);
}

/* returns true if filter changed */
boolean updateFilter()
{
  SightingsFilter newFilter = new SightingsFilter();
  newFilter.viewMinYear = 2000 + settingsView.yearSlider.minIndex();
  newFilter.viewMaxYear = 2000 + settingsView.yearSlider.maxIndex();
  if (btwMonths) {
    newFilter.viewMinMonth =  1 + settingsView.monthSlider.minIndex();
    newFilter.viewMaxMonth =  1 + settingsView.monthSlider.maxIndex();
  }
  if (btwTime) {
    newFilter.viewMinHour =  settingsView.timeSlider.minIndex();
    newFilter.viewMaxHour =  settingsView.timeSlider.maxIndex();
  }
  
  Set<SightingType> activeTypes = new HashSet<SightingType>();
  for (SightingType type : sightingTypeMap.values()) {
    if (type.active) activeTypes.add(type);
  }
  newFilter.activeTypes = activeTypes;
  
  if (!newFilter.equals(activeFilter)) {
    println(activeFilter + " -> " + newFilter);
    boolean reload = !newFilter.equalsIgnoringTypes(activeFilter);
    activeFilter = newFilter;
    if (reload) {
      data.reloadCitySightingCounts();
      updateStateSightingCounts();
    } else {
      println("recomputing totals");
      updateCitySightingTotals();
      updateStateSightingTotals();
    }
    mapv.rebuildOverlay();
    detailsAnimator.target(height);
    return true;
  }
  else return false;
}

void mouseReleased(){
  if (isDragging) {
    updateFilter();
  }
  isDragging = false;
}


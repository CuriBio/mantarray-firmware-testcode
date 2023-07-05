public class SensorPageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  
  ControlGroup initialPositionsConfigurator;
  List<Textfield> magnetometerRegisterFields = new ArrayList<Textfield>();
  //List<Button> magnetometerTypes = new ArrayList<Button>();
  //List<Button> magnetometerSimpleSelector = new ArrayList<Button>();
  Button sensorConfigurationBack;
  Button sensorConfigurationSubmit;
  
  int magnetometerRegisterFieldNums = 4;
  String[] magnetometerRegisterFieldStrings = {"Initial X", "Initial Y", "Initial Z", "Initial Remnance"};
  String[] magnetometerRegisterFieldJSON = {"Initial_X", "Initial_Y", "Initial_Z", "Initial_Remnance"};
  
  private SensorPageControllers(PApplet p_){
    //sets the processing applet to be that of the main file, mantarray_utility_tool
    p = p_;                        
    if (cp5 == null) {
      cp5 = new ControlP5(p);
    }
    
    int configuratorWidth = 500;
    int configuratorHeight = 500;
    
    initialPositionsConfigurator = cp5.addGroup("initialPositionsConfigurator")
        .setPosition(100, 50)
        .setSize(configuratorWidth, configuratorHeight)
        .setBackgroundColor(color(255))
        .hideBar()
        .hide();
        
    int configuratorTextBoxX = configuratorWidth / 10;
    int configuratorTextBoxFontSize = 20;
    int configuratorTextBoxHeight = configuratorTextBoxFontSize * 3/2;
    int configuratorTextBoxHeightBuffer = configuratorTextBoxHeight/2;
    int configuratorTextBoxWidth = configuratorWidth / 6;
    for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
      magnetometerRegisterFields.add(cp5.addTextfield(magnetometerRegisterFieldStrings[textBoxNum])
        .setPosition(configuratorTextBoxX, 
                    (configuratorTextBoxHeightBuffer * (textBoxNum + 1)) + (configuratorTextBoxHeight * textBoxNum))
        .setSize(configuratorTextBoxWidth, configuratorTextBoxHeight)
        .setFont(createFont("arial", configuratorTextBoxFontSize))
        .setColor(0)
        .setColorBackground(color(255))
        .setColorForeground(color(0))
        .setAutoClear(false)
        .setText(String.format("%d", settingsJSON.getInt(magnetometerRegisterFieldJSON[textBoxNum])))
        .moveTo(initialPositionsConfigurator));
      magnetometerRegisterFields.get(textBoxNum).getCaptionLabel().setText(magnetometerRegisterFieldStrings[textBoxNum]).setColor(0).setFont(createFont("arial", configuratorTextBoxFontSize)).align(LEFT, CENTER).toUpperCase(false).getStyle().setMarginLeft(configuratorTextBoxWidth + 20);
    }
        
    int configuratorBottomBarHeight = configuratorHeight / 7;
    int configuratorBottomBarWidth = configuratorWidth;
    int configuratorBottomBarButtonHeight = configuratorBottomBarHeight * 2/3;  
    
    int configuratorBottomBarY = configuratorHeight - configuratorBottomBarHeight;
    int configuratorBottomBarProgressButtonWidth = configuratorBottomBarWidth / 3;
    int configuratorBottomBarProgressButtonBufferWidth = (configuratorBottomBarWidth - (2 * configuratorBottomBarProgressButtonWidth)) / 3;
    sensorConfigurationBack = cp5.addButton("sensorConfigurationBack")
      .setPosition(configuratorBottomBarProgressButtonBufferWidth * 1, 
                   configuratorBottomBarY)
      .setSize(configuratorBottomBarProgressButtonWidth, configuratorBottomBarButtonHeight)
      .moveTo(initialPositionsConfigurator);
    sensorConfigurationBack.getCaptionLabel().setText("Back").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
    
    sensorConfigurationSubmit = cp5.addButton("sensorConfigurationSubmit")
      .setPosition(configuratorBottomBarProgressButtonBufferWidth * 2 + configuratorBottomBarProgressButtonWidth * 1, 
                   configuratorBottomBarY)
      .setSize(configuratorBottomBarProgressButtonWidth, configuratorBottomBarButtonHeight)
      .moveTo(initialPositionsConfigurator);
    sensorConfigurationSubmit.getCaptionLabel().setText("Submit").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
    
    cp5.addListener(this);
  }
  
  public void  controlEvent(ControlEvent theEvent) {
    String controllerName = theEvent.getName();
    if (controllerName.equals("sensorConfigurationSubmit")){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        settingsJSON.setString(magnetometerRegisterFieldJSON[textBoxNum], magnetometerRegisterFields.get(textBoxNum).getText());
      }
      saveJSONObject(settingsJSON, topSketchPath+"/config/config.json");
      Packet initialPositionsPacket = new Packet();
      byte[] initialPositionsPacketConverted = initialPositionsPacket.initialPositionConfig(settingsJSON);
      serialPort.write(initialPositionsPacketConverted);
      initialPositionsConfigurator.hide();
      thisHomePageControllers.homePage.show();
      thisHomePageControllers.logDisplay.append("Sensor Configuration Set\n");
      logLog.println("Sensor configuration set");
    }
    if (controllerName.equals("sensorConfigurationBack")){
      initialPositionsConfigurator.hide();
      thisHomePageControllers.homePage.show();
    }
  }
}

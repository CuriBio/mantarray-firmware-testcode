public class SensorPageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  
  ControlGroup magnetometerRegisterConfigurator;
  List<Textfield> magnetometerRegisterFields = new ArrayList<Textfield>();
  List<Button> magnetometerTypes = new ArrayList<Button>();
  List<Button> magnetometerSimpleSelector = new ArrayList<Button>();
  Button sensorConfigurationBack;
  Button sensorConfigurationSubmit;
  
  int magnetometerTypeNums = 3;
  String[] magnetometerTypeStrings = {"MMC5983", "LIS3MDL", "TBD"};
  int magnetometerSimpleSelectorNums = 4;
  String[] magnetometerRegisterSimpleStrings = {"Period>=20ms", "20ms>Period>=10ms", "10ms>Period>=5ms", "5ms>Period>=2ms"};
  String[] magnetometerRegisterSimpleConfig0Strings = {"00000000","00000000","00000000","00000000"};
  String[] magnetometerRegisterSimpleConfig1Strings = {"00000000","00000001","00000000","00000000"};
  String[] magnetometerRegisterSimpleConfig2Strings = {"00000000","00000010","00000000","00000000"};
  String[] magnetometerRegisterSimpleConfig3Strings = {"00000000","00000011","00000000","00000000"};
  int magnetometerRegisterFieldNums = 4;
  String[] magnetometerRegisterFieldStrings = {"Internal Control 0", "Internal Control 1", "Internal Control 2", "Internal Control 3"};
  String[] magnetometerRegisterFieldJSON = {"Internal_Control_0", "Internal_Control_1", "Internal_Control_2", "Internal_Control_3"};
  
  private SensorPageControllers(PApplet p_){
    //sets the processing applet to be that of the main file, mantarray_utility_tool
    p = p_;                        
    if (cp5 == null) {
      cp5 = new ControlP5(p);
    }
    
    int configuratorWidth = 500;
    int configuratorHeight = 500;
    
    magnetometerRegisterConfigurator = cp5.addGroup("magnetometerRegisterConfigurator")
        .setPosition(100, 50)
        .setSize(configuratorWidth, configuratorHeight)
        .setBackgroundColor(color(255))
        .hideBar()
        .hide();
        
    int configuratorTextBoxX = configuratorWidth / 10;
    int configuratorTextBoxFontSize = 20;
    int configuratorTextBoxHeight = configuratorTextBoxFontSize * 3/2;
    int configuratorTextBoxHeightBuffer = configuratorTextBoxHeight/2;
    int configuratorTextBoxWidth = configuratorWidth / 3;
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
        .setText(settingsJSON.getString(magnetometerRegisterFieldJSON[textBoxNum]))
        .moveTo(magnetometerRegisterConfigurator));
      magnetometerRegisterFields.get(textBoxNum).getCaptionLabel().setText(magnetometerRegisterFieldStrings[textBoxNum]).setColor(0).setFont(createFont("arial", configuratorTextBoxFontSize)).align(CENTER, CENTER).toUpperCase(false).getStyle().setMarginLeft(configuratorTextBoxWidth);
    }
        
    int configuratorBottomBarHeight = configuratorHeight / 7;
    int configuratorBottomBarWidth = configuratorWidth;
    int configuratorBottomBarButtonHeight = configuratorBottomBarHeight * 2/3;
    
    int configuratorBottomBarSimpleSelectorY = configuratorHeight - 3 * configuratorBottomBarHeight;
    int configuratorBottomBarSimpleSelectorButtonWidth = configuratorBottomBarWidth / (magnetometerSimpleSelectorNums + 1);
    int configuratorBottomBarSimpleSelectorButtonBufferWidth = (configuratorBottomBarWidth - (magnetometerSimpleSelectorNums * configuratorBottomBarSimpleSelectorButtonWidth)) / (magnetometerSimpleSelectorNums + 1);  
    for (int simpleSelectorButtonNum = 0; simpleSelectorButtonNum < magnetometerSimpleSelectorNums; simpleSelectorButtonNum++){
      magnetometerSimpleSelector.add(cp5.addButton(magnetometerRegisterSimpleStrings[simpleSelectorButtonNum])
        .setPosition((configuratorBottomBarSimpleSelectorButtonBufferWidth * (simpleSelectorButtonNum + 1)) + (configuratorBottomBarSimpleSelectorButtonWidth * simpleSelectorButtonNum), 
                     configuratorBottomBarSimpleSelectorY)
        .setSize(configuratorBottomBarSimpleSelectorButtonWidth, configuratorBottomBarButtonHeight)
        .moveTo(magnetometerRegisterConfigurator));
      magnetometerSimpleSelector.get(simpleSelectorButtonNum).getCaptionLabel().setText(magnetometerRegisterSimpleStrings[simpleSelectorButtonNum]).setColor(255).setFont(createFont("arial", 10)).align(CENTER, CENTER).toUpperCase(false);
    }    
    
    int configuratorBottomBarChipSelectorY = configuratorHeight - 2 * configuratorBottomBarHeight;
    int configuratorBottomBarChipSelectorButtonWidth = configuratorBottomBarWidth / 4;
    int configuratorBottomBarChipSelectorButtonBufferWidth = (configuratorBottomBarWidth - (3 * configuratorBottomBarChipSelectorButtonWidth)) / 4;
    for (int bottomBarButtonNum = 0; bottomBarButtonNum < magnetometerTypeNums; bottomBarButtonNum++){
      magnetometerTypes.add(cp5.addButton(magnetometerTypeStrings[bottomBarButtonNum])
        .setPosition((configuratorBottomBarChipSelectorButtonBufferWidth * (bottomBarButtonNum + 1)) + (configuratorBottomBarChipSelectorButtonWidth * bottomBarButtonNum), 
                     configuratorBottomBarChipSelectorY)
        .setSize(configuratorBottomBarChipSelectorButtonWidth, configuratorBottomBarButtonHeight)
        .moveTo(magnetometerRegisterConfigurator));
      magnetometerTypes.get(bottomBarButtonNum).getCaptionLabel().setText(magnetometerTypeStrings[bottomBarButtonNum]).setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
    }
    
    int configuratorBottomBarY = configuratorHeight - configuratorBottomBarHeight;
    int configuratorBottomBarProgressButtonWidth = configuratorBottomBarWidth / 3;
    int configuratorBottomBarProgressButtonBufferWidth = (configuratorBottomBarWidth - (2 * configuratorBottomBarProgressButtonWidth)) / 3;
    sensorConfigurationBack = cp5.addButton("sensorConfigurationBack")
      .setPosition(configuratorBottomBarProgressButtonBufferWidth * 1, 
                   configuratorBottomBarY)
      .setSize(configuratorBottomBarProgressButtonWidth, configuratorBottomBarButtonHeight)
      .moveTo(magnetometerRegisterConfigurator);
    sensorConfigurationBack.getCaptionLabel().setText("Back").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
    
    sensorConfigurationSubmit = cp5.addButton("sensorConfigurationSubmit")
      .setPosition(configuratorBottomBarProgressButtonBufferWidth * 2 + configuratorBottomBarProgressButtonWidth * 1, 
                   configuratorBottomBarY)
      .setSize(configuratorBottomBarProgressButtonWidth, configuratorBottomBarButtonHeight)
      .moveTo(magnetometerRegisterConfigurator);
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
      Packet sensorConfigurationPacket = new Packet();
      byte[] sensorConfigurationPacketConverted = sensorConfigurationPacket.sensorConfig(settingsJSON);
      serialPort.write(sensorConfigurationPacketConverted);
      magnetometerRegisterConfigurator.hide();
      thisHomePageControllers.homePage.show();
      thisHomePageControllers.logDisplay.append("Sensor Configuration Set\n");
      logLog.println("Sensor configuration set");
      sensorConfigSet = true;
    }
    if (controllerName.equals("sensorConfigurationBack")){
      magnetometerRegisterConfigurator.hide();
      thisHomePageControllers.homePage.show();
    }
    if (controllerName.equals("Period>=20ms")){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).setText(magnetometerRegisterSimpleConfig0Strings[textBoxNum]);
      }
    }
    if (controllerName.equals("20ms>Period>=10ms")){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).setText(magnetometerRegisterSimpleConfig1Strings[textBoxNum]);
      }
    }
    if (controllerName.equals("10ms>Period>=5ms")){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).setText(magnetometerRegisterSimpleConfig2Strings[textBoxNum]);
      }
    }
    if (controllerName.equals("5ms>Period>=2ms")){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).setText(magnetometerRegisterSimpleConfig3Strings[textBoxNum]);
      }
    }
    if (controllerName.equals(magnetometerTypeStrings[0])){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).show();
      }
    }
    if (controllerName.equals(magnetometerTypeStrings[1])){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).hide();
      }
    }
    if (controllerName.equals(magnetometerTypeStrings[2])){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        magnetometerRegisterFields.get(textBoxNum).hide();
      }
    }
  }
}

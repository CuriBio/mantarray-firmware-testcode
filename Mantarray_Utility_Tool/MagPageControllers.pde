public class MagPageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  
  //*************************************************************BOARD CONFIGURATION DEFINES*******************************************************************************  
  ControlGroup magnetometerSelector;
  Toggle useSetReset;
  List<Textlabel> magSensorLabels = new ArrayList<Textlabel>();
  List<List<List<Toggle>>> magSensorSelector = new ArrayList<List<List<Toggle>>>();
  Textfield samplingRate;
  List<Button> magnetometerSelectorButtonList = new ArrayList<Button>();
  int NUM_BUTTONS = 18;
  //**********************************************************BOARD CONFIGURATION DEFINES /END******************************************************************************  
  
  private MagPageControllers(PApplet p_){
    //sets the processing applet to be that of the main file, mantarray_utility_tool
    p = p_;                        
    if (cp5 == null) {
      cp5 = new ControlP5(p);
    }
    
    //*************************************************************BOARD CONFIGURATION PAGE*********************************************************************************
    int magConfigPageWidth = (int)(.9 * width);
    int magConfigPageHeight = (int)(.75 * height);
    int magConfigPageX = (int)(.05 * width);
    int magConfigPageY = (int)(.125 * height);
    
    magnetometerSelector = cp5.addGroup("magnetometerSelector")
        .setPosition(magConfigPageX, magConfigPageY)
        .setSize(magConfigPageWidth, magConfigPageHeight)
        .setBackgroundColor(color(255))
        .hideBar()
        .hide();
    
    int magConfigBlockWidth = (int)(.85 * magConfigPageWidth);
    int magConfigBlockHeight = magConfigPageHeight;
    int magConfigBarWidth = magConfigPageWidth - magConfigBlockWidth;
    int magConfigBarHeight = magConfigBlockHeight;
    
    int magConfigBarBufferWidth = magConfigBarWidth/10;
    int magConfigBarBufferHeight = magConfigBarWidth/30;
    int magConfigBarButtonWidth = magConfigBarWidth - 2 * magConfigBarBufferWidth;
    int magConfigBarButtonHeight = (magConfigBarHeight - (NUM_BUTTONS + 2) * magConfigBarBufferHeight) / (NUM_BUTTONS + 1);
    
    useSetReset = cp5.addToggle("useSetReset")
      .setPosition(magConfigBlockWidth + magConfigBarBufferWidth + (2 * magConfigBarButtonWidth) / 3, -6*(magConfigBarBufferHeight))
      .setSize(magConfigBarButtonWidth/3, magConfigBarButtonHeight)
      .setMode(ControlP5.SWITCH)
      .setColorBackground(color(3,252,3))
      .setColorActive(color(80, 80, 80))
      //.setState(true)
      .moveTo(magnetometerSelector);
    useSetReset.getCaptionLabel().setText("Use Set/Reset:").setColor(0).setFont(createFont("arial", magConfigBarBufferWidth)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(-(int)(.6 * magConfigBarButtonWidth));
    
    samplingRate = cp5.addTextfield("samplingRate")
        .setPosition(magConfigBlockWidth + magConfigBarBufferWidth + (2 * magConfigBarButtonWidth) / 3, (magConfigBarBufferHeight))
        .setSize(magConfigBarButtonWidth/3, magConfigBarButtonHeight)
        .setFont(createFont("arial", magConfigBarBufferWidth))
        .setColor(0)
        .setColorBackground(color(255))
        .setColorForeground(color(0))
        .setAutoClear(false)
        .setText(String.valueOf(1000))
        .moveTo(magnetometerSelector);
    samplingRate.getCaptionLabel().setText("Sampling Period (ms):").setColor(0).setFont(createFont("arial", magConfigBarBufferWidth)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(-(int)(.8 * magConfigBarButtonWidth));
    
    String[] buttonNames = {"selectAllX", "selectAllY", "selectAllZ", "selectAllS1", "selectAllS2", "selectAllS3", 
      "selectAllRowA", "selectAllRowB", "selectAllRowC", "selectAllRowD", 
      "selectAllCol1", "selectAllCol2", "selectAllCol3", "selectAllCol4", "selectAllCol5", "selectAllCol6", 
      "selectAll", "boardConfigurationSubmit"};
    String[] labelNames = {"Select All X", "Select All Y", "Select All Z", "Select All S1", "Select All S2", "Select All S3", 
      "Select Row A", "Select Row B", "Select Row C", "Select Row D", 
      "Select Column 1", "Select Column 2", "Select Column 3", "Select Column 4", "Select Column 5", "Select Column 6", 
      "Select All", "Submit"};
    
    for (int buttonNum = 1; buttonNum < NUM_BUTTONS + 1; buttonNum++){
      Button thisButton = cp5.addButton(buttonNames[buttonNum - 1])
      .setPosition(magConfigBlockWidth + magConfigBarBufferWidth, ((1 + buttonNum) * magConfigBarBufferHeight) + (buttonNum * magConfigBarButtonHeight))
      .setSize(magConfigBarButtonWidth, magConfigBarButtonHeight)
      .moveTo(magnetometerSelector);
      thisButton.getCaptionLabel().setText(labelNames[buttonNum - 1]).setColor(255).setFont(createFont("arial", magConfigBarBufferWidth)).align(CENTER, CENTER).toUpperCase(false);
      magnetometerSelectorButtonList.add(thisButton);
    }
    
    int magConfigPageCellWidth = magConfigBlockWidth / 6;
    int magConfigPageCellHeight = magConfigBlockHeight / 4;
    int magConfigSensorWidth = magConfigPageCellWidth / 3;
    int magConfigSensorHeight = magConfigPageCellHeight / 3;
    int magConfigButtonAx = (magConfigPageCellWidth / 2) - magConfigSensorWidth;
    int magConfigButtonAy = magConfigPageCellHeight / 4;
    int magConfigButtonBx = magConfigPageCellWidth / 2;
    int magConfigButtonBy = magConfigButtonAy;
    int magConfigButtonCx = magConfigPageCellWidth / 2 - magConfigSensorWidth / 2;
    int magConfigButtonCy = magConfigPageCellHeight / 2;
    int[] magConfigButtonSensorx = {magConfigButtonAx, magConfigButtonBx, magConfigButtonCx};
    int[] magConfigButtonSensory = {magConfigButtonAy, magConfigButtonBy, magConfigButtonCy};
    
    int magConfigAxisBufferWidth = magConfigSensorWidth / 6;
    int magConfigAxisBufferHeight = magConfigSensorHeight / 6;
    int magConfigAxisWidth = magConfigSensorWidth / 3;
    int magConfigAxisHeight = magConfigSensorHeight / 3;
    int magConfigButtonXx = magConfigAxisBufferWidth;
    int magConfigButtonXy = magConfigAxisBufferHeight;
    int magConfigButtonYx = magConfigSensorWidth - magConfigAxisWidth - magConfigAxisBufferWidth;
    int magConfigButtonYy = magConfigButtonXy;
    int magConfigButtonZx = (magConfigSensorWidth / 2) - magConfigAxisWidth / 2;
    int magConfigButtonZy = magConfigSensorHeight - magConfigAxisHeight - magConfigAxisBufferHeight;
    int[] magConfigButtonAxisx = {magConfigButtonXx, magConfigButtonYx, magConfigButtonZx};
    int[] magConfigButtonAxisy = {magConfigButtonXy, magConfigButtonYy, magConfigButtonZy};
    
    int magConfigWellLabelFont = magConfigAxisHeight/2;
    
    for (int wellNum = 0; wellNum < NUM_WELLS; wellNum++){      
      magSensorSelector.add(new ArrayList<List<Toggle>>());
      
      magSensorLabels.add(cp5.addTextlabel("magSensorLabel" + wellNames[wellNum] + sensorNames[0] + axesNames[0])
        .setText(wellNames[wellNum])
        .setPosition((magConfigPageCellWidth) * (wellNum%6) + magConfigPageCellWidth / 8,
                     (magConfigPageCellHeight) * ((wellNum/6)+1) - magConfigPageCellHeight/2)
        .setColor(color(0))
        .setFont(createFont("arial", magConfigPageCellHeight/4))
        .moveTo(magnetometerSelector));
        
      for (int sensorNum = 0; sensorNum < NUM_SENSORS; sensorNum++)
      {
        magSensorSelector.get(wellNum).add(new ArrayList<Toggle>());
        for (int axisNum = 0; axisNum < NUM_AXES; axisNum++)
        {
          magSensorSelector.get(wellNum).get(sensorNum).add(cp5.addToggle("magSensorSelector" + wellNames[wellNum] + sensorNames[sensorNum] + axesNames[axisNum])
            .moveTo(magnetometerSelector)
            .setPosition((magConfigPageCellWidth) * (wellNum%6) + magConfigButtonSensorx[sensorNum] + magConfigButtonAxisx[axisNum],
                         (magConfigPageCellHeight) * (wellNum/6) + magConfigButtonSensory[sensorNum] + magConfigButtonAxisy[axisNum])
            .setColorBackground(color(230))
            .setColorActive(color(100))
            .setColorLabel(0)
            .setSize(magConfigAxisWidth, magConfigAxisHeight)
            .toggle()
            .moveTo(magnetometerSelector));
          String thisLabel = sensorNames[sensorNum] + '.' + axesNames[axisNum];
          magSensorSelector.get(wellNum).get(sensorNum).get(axisNum).getCaptionLabel().setText(thisLabel).setColor(0).setFont(createFont("arial", magConfigWellLabelFont)).align(CENTER, CENTER).toUpperCase(false);
        }
      }
    }
    
    for (int wellNum = 0; wellNum < NUM_WELLS; wellNum++){
      magnetometerConfigurationArray.add(new ArrayList<List<Integer>>());
      for (int sensorNum = 0; sensorNum < NUM_SENSORS; sensorNum++){
        magnetometerConfigurationArray.get(wellNum).add(new ArrayList<Integer>());
        for (int axisNum = 0; axisNum < NUM_AXES; axisNum++){
          magnetometerConfigurationArray.get(wellNum).get(sensorNum).add(1);
        }
      }
    }
    //**************************************************************BOARD CONFIGURATION PAGE /END****************************************************************************
    //SUPER IMPORTANT.  Controllers will not have control events if this line isn't included to implement the inherited class ControlListener
    cp5.addListener(this);
  }
  
  public void  controlEvent(ControlEvent theEvent) {
    String controllerName = theEvent.getName();
    if (theEvent.isAssignableFrom(Button.class)){
      if (controllerName.equals("selectAllX")){
        toggleBulk(NUM_WELLS, NUM_SENSORS, 1, 0, 0, 0, 1);
      }
      if (controllerName.equals("selectAllY")){
        toggleBulk(NUM_WELLS, NUM_SENSORS, 1, 0, 0, 1, 1);
      }
      if (controllerName.equals("selectAllZ")){
        toggleBulk(NUM_WELLS, NUM_SENSORS, 1, 0, 0, 2, 1);
      }
      if (controllerName.equals("selectAllS1")){
        toggleBulk(NUM_WELLS, 1, NUM_AXES, 0, 0, 0, 1);
      }
      if (controllerName.equals("selectAllS2")){
        toggleBulk(NUM_WELLS, 1, NUM_AXES, 0, 1, 0, 1);
      }
      if (controllerName.equals("selectAllS3")){
        toggleBulk(NUM_WELLS, 1, NUM_AXES, 0, 2, 0, 1);
      }
      if (controllerName.equals("selectAllRowA")){
        toggleBulk(6, NUM_SENSORS, NUM_AXES, 0, 0, 0, 1);
      }
      if (controllerName.equals("selectAllRowB")){
        toggleBulk(6, NUM_SENSORS, NUM_AXES, 6, 0, 0, 1);
      }
      if (controllerName.equals("selectAllRowC")){
        toggleBulk(6, NUM_SENSORS, NUM_AXES, 12, 0, 0, 1);
      }
      if (controllerName.equals("selectAllRowD")){
        toggleBulk(6, NUM_SENSORS, NUM_AXES, 18, 0, 0, 1);
      }
      if (controllerName.equals("selectAllCol1")){
        toggleBulk(4, NUM_SENSORS, NUM_AXES, 0, 0, 0, 6);
      }
      if (controllerName.equals("selectAllCol2")){
        toggleBulk(4, NUM_SENSORS, NUM_AXES, 1, 0, 0, 6);
      }
      if (controllerName.equals("selectAllCol3")){
        toggleBulk(4, NUM_SENSORS, NUM_AXES, 2, 0, 0, 6);
      }
      if (controllerName.equals("selectAllCol4")){
        toggleBulk(4, NUM_SENSORS, NUM_AXES, 3, 0, 0, 6);
      }
      if (controllerName.equals("selectAllCol5")){
        toggleBulk(4, NUM_SENSORS, NUM_AXES, 4, 0, 0, 6);
      }
      if (controllerName.equals("selectAllCol6")){
        toggleBulk(4, NUM_SENSORS, NUM_AXES, 5, 0, 0, 6);
      }
      if (controllerName.equals("selectAll")){
        toggleBulk(NUM_WELLS, NUM_SENSORS, NUM_AXES, 0, 0, 0, 1);
      }
      if (controllerName.equals("boardConfigurationSubmit")){
        magConfigurationByteArray = configDataGenerator();
        thisMagPageControllers.magnetometerSelector.hide(); //<>//
        homePage.show();
        Packet magConfig = new Packet();
        byte[] magConfigConverted = magConfig.MagnetometerConfiguration();
        serialPort.write(magConfigConverted);
        logDisplay.append("Board Configuration Set\n");
        logLog.println("Board configuration set");
        boardConfigSet = true;
      }
    } else if (theEvent.isAssignableFrom(Toggle.class)) {
      if (controllerName.equals("useSetReset")){
        if (useSetReset.getState()){
          useSetReset.setColorBackground(color(252,3,3));
        } else {
          useSetReset.setColorBackground(color(3,252,3));
        }
      }
    }
  }
  
  void toggleBulk(int totWells, 
              int totSensors, 
              int totAxes, 
              int startWell, 
              int startSensor, 
              int startAxis,
              int wellInc){
  
    boolean allTrue = true;
    for (int wellNum = startWell; wellNum < startWell + (totWells * wellInc); wellNum+=wellInc)
    {
      for (int sensorNum = startSensor; sensorNum < startSensor + totSensors; sensorNum++)
      {
        for (int axisNum = startAxis; axisNum < startAxis + totAxes; axisNum++)
        {
          if (!magSensorSelector.get(wellNum).get(sensorNum).get(axisNum).getState())
          {
            magSensorSelector.get(wellNum).get(sensorNum).get(axisNum).toggle();
            allTrue = false;
          }
        }
      }
    }
    if (allTrue)
    {
      for (int wellNum = startWell; wellNum < startWell + (totWells * wellInc); wellNum+=wellInc)
      {
        for (int sensorNum = startSensor; sensorNum < startSensor + totSensors; sensorNum++)
        { 
          for (int axisNum = startAxis; axisNum < startAxis + totAxes; axisNum++)
          { 
            magSensorSelector.get(wellNum).get(sensorNum).get(axisNum).toggle();
          }
        }
      }
    }
    return;
  }
  
  List<Byte> configDataGenerator ()
  {
    List<Byte> dataConfig = new ArrayList<Byte>();
    int microSamplingRate = Integer.valueOf(samplingRate.getText());
    dataConfig.add((byte) (microSamplingRate & 0xFF));
    dataConfig.add((byte) (microSamplingRate>>8 & 0xFF));
    //HARDWARE TEST uncomment this line if you want to use set/reset commands
    //Make sure the packet length is changed in Packet.pde and the input parser is updated in Communicator.c
    /*if (useSetReset.getState()){
      dataConfig.add((byte) 0);
    } else {
      dataConfig.add((byte) 1);
    }*/
    
    for (int wellNum = 0; wellNum < NUM_WELLS; wellNum++)
    {
      dataConfig.add((byte)(wellNum+1));
      int bitMask = 0;
      for (int sensorNum = 0; sensorNum < NUM_SENSORS; sensorNum++)
      { 
        for (int axisNum = 0; axisNum < NUM_AXES; axisNum++)
        { 
          if (magSensorSelector.get(wellNum).get(sensorNum).get(axisNum).getState())
          {
            magnetometerConfigurationArray.get(wellNum).get(sensorNum).set(axisNum, 1);
            bitMask += 1<<(sensorNum * NUM_SENSORS + axisNum);
          }
          else
          {
            magnetometerConfigurationArray.get(wellNum).get(sensorNum).set(axisNum, 0);
          }
        }
      }
      dataConfig.add((byte) (bitMask & 0xFF));
      dataConfig.add((byte) ((bitMask & 0x100)>>8));
    }
    //print (dataConfig);
    return dataConfig;
  }
}

public class HomePageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  ControlGroup homePage;
  Button loadMainFirmwareButton;
  Textfield mainMajorVersion;
  Textfield mainMinorVersion;
  Textfield mainRevisionVersion;
  Button loadChannelFirmwareButton;
  Textfield channelMajorVersion;
  Textfield channelMinorVersion;
  Textfield channelRevisionVersion;
  Button startButtonMags;
  Button stopButtonMags;
  Button startButtonStims;
  Button stopButtonStims;
  Button setStimConfigButton;
  Textfield setSensorRateField;
  Button setSensorRateButton;
  Button setInitialPositions;
  Button saveAndQuitButton;
  Textarea logDisplay;
  Button runStimCheck;
  Button StartBarcodeTune;
  Button StimLoopTest;
  
  Textfield setDeviceSerialNumberField;
  Button setDeviceSerialNumber;
  Textfield setDeviceNicknameField;
  Button setDeviceNickname;
  Button isMantarray;
  Button isStingray;
  
  Textfield magnetometerScheduleDelay;
  Textfield magnetometerScheduleHold;
  Textfield magnetometerScheduleDuration;
  Button startMagnetometerSchedule;
  Button stopMagnetometerSchedule;
  final Timer magnetometerTimer;
  
  //*************************************************************BOARD CONFIGURATION DEFINES*******************************************************************************  
  ControlGroup magnetometerSelector;
  Toggle useSetReset;
  List<Textlabel> magSensorLabels = new ArrayList<Textlabel>();
  List<List<List<Toggle>>> magSensorSelector = new ArrayList<List<List<Toggle>>>();
  Textfield samplingRate;
  List<Button> magnetometerSelectorButtonList = new ArrayList<Button>();
  int NUM_BUTTONS = 18;
  //**********************************************************BOARD CONFIGURATION DEFINES /END******************************************************************************  
  
  private HomePageControllers(PApplet p_){
    //sets the processing applet to be that of the main file, mantarray_utility_tool
    p = p_;                        
    if (cp5 == null) {
      cp5 = new ControlP5(p);
    }
    
    magnetometerTimer = new Timer("magnetometerTimer", true);
    
    homePage = cp5.addGroup("homePage")
      .setPosition(0, 0)
      .setSize(1000, 600)
      .setBackgroundColor(color(255))
      .hideBar();
        
    loadChannelFirmwareButton = cp5.addButton("loadChannelFirmwareButton")
      .setPosition(75, 70)
      .setSize(125, 30)
      .moveTo(homePage);
    loadChannelFirmwareButton.getCaptionLabel().setText("Load Channel").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    channelMajorVersion = cp5.addTextfield("channelMajorVersion")
      .setPosition(220, 70)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(1))
      .moveTo(homePage);
    channelMajorVersion.getCaptionLabel().setText("v").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-12);
    
    channelMinorVersion = cp5.addTextfield("channelMinorVersion")
      .setPosition(255, 70)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(0))
      .moveTo(homePage);
    channelMinorVersion.getCaptionLabel().setText(".").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-8);
    
    channelRevisionVersion = cp5.addTextfield("channelRevisionVersion")
      .setPosition(290, 70)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(0))
      .moveTo(homePage);
    channelRevisionVersion.getCaptionLabel().setText(".").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-8);
    
    loadMainFirmwareButton = cp5.addButton("loadMainFirmwareButton")
      .setPosition(75, 110)
      .setSize(125, 30)
      .moveTo(homePage);
    loadMainFirmwareButton.getCaptionLabel().setText("Load Main").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    mainMajorVersion = cp5.addTextfield("mainMajorVersion")
      .setPosition(220, 110)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(1))
      .moveTo(homePage);
    mainMajorVersion.getCaptionLabel().setText("v").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-12);
    
    mainMinorVersion = cp5.addTextfield("mainMinorVersion")
      .setPosition(255, 110)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(0))
      .moveTo(homePage);
    mainMinorVersion.getCaptionLabel().setText(".").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-8);
    
    mainRevisionVersion = cp5.addTextfield("mainRevisionVersion")
      .setPosition(290, 110)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(0))
      .moveTo(homePage);
    mainRevisionVersion.getCaptionLabel().setText(".").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-8);
    
    startButtonMags = cp5.addButton("startButtonMags")
      .setPosition(75, 330)
      .setSize(120, 30)
      .moveTo(homePage);
    startButtonMags.getCaptionLabel().setText("Start Mags").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopButtonMags = cp5.addButton("stopButtonMags")
      .setPosition(205, 330)
      .setSize(120, 30)
      .moveTo(homePage);
    stopButtonMags.getCaptionLabel().setText("Stop Mags").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    startButtonStims = cp5.addButton("startButtonStims")
      .setPosition(75, 370)
      .setSize(120, 30)
      .moveTo(homePage);
    startButtonStims.getCaptionLabel().setText("Start Stims").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopButtonStims = cp5.addButton("stopButtonStims")
      .setPosition(205, 370)
      .setSize(120, 30)
      .moveTo(homePage);
    stopButtonStims.getCaptionLabel().setText("Stop Stims").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setStimConfigButton = cp5.addButton("setStimConfigButton")
      .setPosition(75, 150)
      .setSize(250, 50)
      .moveTo(homePage);
    setStimConfigButton.getCaptionLabel().setText("Set Stimulator Configuration").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setInitialPositions = cp5.addButton("setInitialPositions")
      .setPosition(75, 270)
      .setSize(250, 50)
      .moveTo(homePage);
    setInitialPositions.getCaptionLabel().setText("Set Pulse3D Initial Positions").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setSensorRateField = cp5.addTextfield("setSensorRateField")
      .setPosition(75, 222)
      .setSize(25, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText("10")
      .moveTo(homePage);
    
    setSensorRateButton = cp5.addButton("setSensorRateButton")
      .setPosition(110, 210)
      .setSize(220, 50)
      .moveTo(homePage);
    setSensorRateButton.getCaptionLabel().setText("Set Sensor Sampling Rate").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
 
    saveAndQuitButton = cp5.addButton("saveAndQuitButton")
      .setPosition(75, 410)
      .setSize(250, 50)
      .moveTo(homePage);
    saveAndQuitButton.getCaptionLabel().setText("Save and Quit").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    runStimCheck = cp5.addButton("runStimCheck")
      .setPosition(370, 80)
      .setSize(400, 25)
      .moveTo(homePage);
    runStimCheck.getCaptionLabel().setText("Run Stim Check").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    StartBarcodeTune = cp5.addButton("StartBarcodeTune")
      .setPosition(370, 120)
      .setSize(400, 25)
      .moveTo(homePage);
    StartBarcodeTune.getCaptionLabel().setText("Start Barcode Tuning Sequence").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    StimLoopTest = cp5.addButton("StimLoopTest")
      .setPosition(370, 160)
      .setSize(400, 25)
      .moveTo(homePage);
    StimLoopTest.getCaptionLabel().setText("Perform Stim Loop Test").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    magnetometerScheduleDelay = cp5.addTextfield("magnetometerScheduleDelay")
      .setPosition(370, 200)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(20))
      .moveTo(homePage);
    magnetometerScheduleDelay.getCaptionLabel().setText("Magnetometer Schedule Duration Between Readings (mins)").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(60);
    
    magnetometerScheduleHold = cp5.addTextfield("magnetometerScheduleHold")
      .setPosition(370, 235)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(60))
      .moveTo(homePage);
    magnetometerScheduleHold.getCaptionLabel().setText("Magnetometer Schedule Capture Duration (secs)").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(60);
    
    magnetometerScheduleDuration = cp5.addTextfield("magnetometerScheduleDuration")
      .setPosition(370, 270)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(48))
      .moveTo(homePage);
    magnetometerScheduleDuration.getCaptionLabel().setText("Magnetometer Schedule Total Duration (hrs)").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(60);
    
    startMagnetometerSchedule = cp5.addButton("startMagnetometerSchedule")
      .setPosition(400, 305)
      .setSize(200, 30)
      .moveTo(homePage);
    startMagnetometerSchedule.getCaptionLabel().setText("Begin Schedule").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopMagnetometerSchedule = cp5.addButton("stopMagnetometerSchedule")
      .setPosition(620, 305)
      .setSize(200, 30)
      .moveTo(homePage);
    stopMagnetometerSchedule.getCaptionLabel().setText("Stop Schedule").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
        
    setDeviceSerialNumberField = cp5.addTextfield("setDeviceSerialNumberField")
      .setPosition(370, 350)
      .setSize(150, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText("MA2201300001")
      .moveTo(homePage);
    
    setDeviceSerialNumber = cp5.addButton("setDeviceSerialNumber")
      .setPosition(550, 350)
      .setSize(200, 25)
      .moveTo(homePage);
    setDeviceSerialNumber.getCaptionLabel().setText("Set Serial Number").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setDeviceNicknameField = cp5.addTextfield("setDeviceNicknameField")
      .setPosition(370, 380)
      .setSize(150, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText("Mantarray2.2 ")
      .moveTo(homePage);
    
    setDeviceNickname = cp5.addButton("setDeviceNickname")
      .setPosition(550, 380)
      .setSize(200, 25)
      .moveTo(homePage);
    setDeviceNickname.getCaptionLabel().setText("Set Device Nickname").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    isMantarray = cp5.addButton("isMantarray")
      .setPosition(770, 350)
      .setSize(150, 25)
      .moveTo(homePage);
    isMantarray.getCaptionLabel().setText("Set as Mantarray").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    isStingray = cp5.addButton("isStingray")
      .setPosition(770, 380)
      .setSize(150, 25)
      .moveTo(homePage);
    isStingray.getCaptionLabel().setText("Set as Stingray").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
      
    logDisplay = cp5.addTextarea("logDisplay")
      .setPosition(400, 420)
      .setColorBackground(color(255))
      .setSize(500, 150)
      .setFont(createFont("arial", 16))
      .setLineHeight(20)
      .setColor(color(0))
      .setText("Starting utility tool\n")
      .moveTo(homePage);
          
    cp5.addListener(this);
  }
  
  public void  controlEvent(ControlEvent theEvent) {
    String controllerName = theEvent.getName();
    if (theEvent.isAssignableFrom(Button.class)){
      if (controllerName.equals("loadChannelFirmwareButton")){
        selectInput("Select a file to load as channel microcontroller firmware:", "LoadChannelFirmware");
      }
      else if (controllerName.equals("loadMainFirmwareButton")){
        selectInput("Select a file to load as main microcontroller firmware:", "LoadMainFirmware");
      }
      if (controllerName.equals("startButtonMags")){
        if (boardConfigSet && !magCaptureInProgress){
          c = Calendar.getInstance(TimeZone.getTimeZone("PST"));
          dataLog = createWriter(String.format("./data/%04d-%02d-%02d_%02d-%02d-%02d_data.txt", c.get(Calendar.YEAR), c.get(Calendar.MONTH)+1, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE), c.get(Calendar.SECOND))); 
          dataLog.println(Arrays.toString(magnetometerConfigurationArray.toArray()).replace("[", "").replace("]", ""));
          magCaptureInProgress = true;
          Packet magStart = new Packet();
          byte[] magStartConverted = magStart.MagnetometerDataCaptureBegin();
          serialPort.write(magStartConverted);
          logDisplay.append("Starting Data Capture\n");
          logLog.println("Starting data capture");
        }
        else if (magCaptureInProgress){
          logDisplay.append("There is already a magnetometer data capture running\n");
          logLog.println("There is already a magnetometer data capture running");
        } else {
          logDisplay.append("Please set a board configuration before beginning a data capture\n");
          logLog.println("Please set a board configuration before beginning a data capture");
        }
      }
      if (controllerName.equals("stopButtonMags")){
        if (magCaptureInProgress){
          Packet magStop = new Packet();
          byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
          serialPort.write(magStopConverted);
          magCaptureInProgress = false;
          dataLog.flush();
          dataLog.close();
          logDisplay.append("Stopping Data Capture\n");
          logLog.println("Stopping data capture");
        } else {
          logDisplay.append("No magnetometer data capture currently running to stop\n");
          logLog.println("No magnetometer data capture currently running to stop");
        }
      }
      if (controllerName.equals("startButtonStims")){
        if (thisStimPageControllers.stimConfigSet && !stimulationInProgress){
          stimulationInProgress = true;
          Packet startStimulatorPacket = new Packet();
          byte[] startStimulatorPacketConverted = startStimulatorPacket.StimulatorBegin();
          serialPort.write(startStimulatorPacketConverted);
          logDisplay.append("Starting Stimulator\n");
          logLog.println("Starting stimulator");
        }
        else if (stimulationInProgress){
          logDisplay.append("There is already a stimulation process running\n");
          logLog.println("There is already a stimulation process running");
        } else {
          logDisplay.append("Please set a stimulator configuration before starting the stimulator\n");
          logLog.println("Please set a stimulator configuration before starting the stimulator");
        }
        
      }
      if (controllerName.equals("stopButtonStims")){
        if (stimulationInProgress) {
          stimulationInProgress = false;
          Packet stopStimulatorPacket = new Packet();
          byte[] stopStimulatorPacketConverted = stopStimulatorPacket.StimulatorEnd();
          serialPort.write(stopStimulatorPacketConverted);
          logDisplay.append("Stopping Data Capture\n");
          logLog.println("Stopping data capture");
        } else {
          logDisplay.append("No stimulation process currently running to stop\n");
          logLog.println("No stimulation process currently running to stop");
        }
      }
      if (controllerName.equals("setSensorRateButton")){
        Packet magConfig = new Packet();
        byte[] magConfigConverted = magConfig.MagnetometerConfiguration();
        serialPort.write(magConfigConverted);
        thisHomePageControllers.logDisplay.append("Board Configuration Set\n");
        logLog.println("Board configuration set");
        boardConfigSet = true;
      }
      /*if (controllerName.equals("setBoardConfigButton")){
        thisMagPageControllers.magnetometerSelector.show();
        homePage.hide();
      }*/
      if (controllerName.equals("setInitialPositions")){
        thisSensorPageControllers.initialPositionsConfigurator.show();
        homePage.hide();
      }
      if (controllerName.equals("setStimConfigButton")){
        thisStimPageControllers.stimWindow.show();
        homePage.hide();
      }
      if (controllerName.equals("saveAndQuitButton")){
        if (magCaptureInProgress) {
          Packet magStop = new Packet();
          byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
          serialPort.write(magStopConverted);
          dataLog.flush();
          dataLog.close();
        }
        if (stimulationInProgress) {
          Packet stopStimulatorPacket = new Packet();
          byte[] stopStimulatorPacketConverted = stopStimulatorPacket.StimulatorEnd();
          serialPort.write(stopStimulatorPacketConverted);
        }
        logLog.flush();
        logLog.close();
        exit();
      }
      
      if (controllerName.equals("runStimCheck")){
        Packet BeginStimCheckPacket = new Packet();
        byte[] BeginStimCheckPacketConverted = BeginStimCheckPacket.BeginStimCheck();
        serialPort.write(BeginStimCheckPacketConverted);
        logDisplay.append("Stim Check Beginning\n");
        logLog.println("Stim Check Beginning");
      }
      if (controllerName.equals("StartBarcodeTune")){
        Packet StartBarcodeTunePacket = new Packet();
        byte[] StartBarcodeTunePacketConverted = StartBarcodeTunePacket.StartBarcodeTune();
        serialPort.write(StartBarcodeTunePacketConverted);
        logDisplay.append("Barcode tuning sequence begun\n");
        logLog.println("Barcode tuning sequence begun");
      }
      if (controllerName.equals("StimLoopTest")){
        //selectInput("Select a file to load as channel microcontroller firmware:", "PerformStimTest");
        int[] this_config = {1, 0, 1, 0, 1, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 232, 3, 0, 0, 1, 1, 2, 3, 0, 0, 0, 1, 2, 3, 0, 0, 0, 0, 1, 232, 3, 0, 0, 16, 39, 208, 7, 0, 0, 0, 0, 184, 11, 0, 0, 240, 216, 160, 15, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 1, 0, 3, 64, 156, 0, 0, 228, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 13, 3, 0, 0, 0, 10, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 184, 11, 0, 0, 1, 2, 0, 23};
        List<Byte> this_config_Byte = new ArrayList<Byte>();
        for (int i = 0; i < this_config.length; i++){
          this_config_Byte.add(uint2byte(this_config[i]));
        }
        Packet stimConfig = new Packet();
        byte[] stimConfigConverted = stimConfig.TrueStimulatorConfiguration(this_config_Byte);
        serialPort.write(stimConfigConverted);
        logDisplay.append("Sending stimulation schedule\n");
        logLog.println("Sending stimulation schedule");
        Packet stimBegin = new Packet();
        byte[] stimBeginConverted = stimBegin.TrueStimulatorBegin();
        serialPort.write(stimBeginConverted);
      }
      if (controllerName.equals("startMagnetometerSchedule")){
        if (magnetometerScheduleComplete == false){
          magnetometerScheduleIsRunning = true;
          float valueOfMagnetometerScheduleDuration = Float.valueOf(thisHomePageControllers.magnetometerScheduleDuration.getText()) * 60 * 60 * 1000;
          float valueOfMagnetometerScheduleDelay = Float.valueOf(thisHomePageControllers.magnetometerScheduleDelay.getText()) * 60 * 1000;
          float valueOfMagnetometerScheduleHold = Float.valueOf(thisHomePageControllers.magnetometerScheduleHold.getText()) * 1000;
          int totalNumberOfScheduledCaptures = floor(valueOfMagnetometerScheduleDuration / (valueOfMagnetometerScheduleDelay + valueOfMagnetometerScheduleHold));
          //logDisplay.append(String.format("Duration: %f, Delay: %f, Hold: %f, Num Iterations: %d\n", valueOfMagnetometerScheduleDuration, valueOfMagnetometerScheduleDelay, valueOfMagnetometerScheduleHold, totalNumberOfScheduledCaptures));
          logDisplay.append("Starting new magnetometer data capture schedule\n");
          logLog.println("Starting new magnetometer data capture schedule");
          MagnetometerScheduler(totalNumberOfScheduledCaptures, (int)valueOfMagnetometerScheduleHold, (int)valueOfMagnetometerScheduleDelay);
        }
        else {
          logDisplay.append("Please restart the utility tool to re-run a magnetometer schedule\n");
          logLog.println("Please restart the utility tool to re-run a magnetometer schedule");
        }
      }
      if (controllerName.equals("stopMagnetometerSchedule")){
        if (magnetometerScheduleIsRunning == true) {
          magnetometerScheduleComplete = true;
          magnetometerScheduleIsRunning = false;
          magnetometerTimer.cancel();
          magnetometerTimer.purge();
          if (magCaptureInProgress){
            Packet magStop = new Packet();
            byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
            serialPort.write(magStopConverted);
          }
          logDisplay.append("Magnetometer data capture schedule ended prematurely\n");
          logLog.println("Magnetometer data capture schedule ended prematurely");
          dataLog.flush();
          dataLog.close();
        }
        else {
          logDisplay.append("No magnetometer schedule currently running\n");
          logLog.println("No magnetometer schedule currently running");
        }
      }
      
      if (controllerName.equals("setDeviceSerialNumber")){
        Packet newDeviceSerialNumberPacket = new Packet();
        byte[] newDeviceSerialNumberPacketConverted = newDeviceSerialNumberPacket.SetSerialNumber();
        serialPort.write(newDeviceSerialNumberPacketConverted);
        logDisplay.append("New device serial number sent\n");
        logLog.println("New device serial number sent");
      }

      if (controllerName.equals("setDeviceNickname")){
        Packet newDeviceNicknamePacket = new Packet();
        byte[] newDeviceNicknamePacketConverted = newDeviceNicknamePacket.SetNickname();
        serialPort.write(newDeviceNicknamePacketConverted);
        logDisplay.append("New device nickname sent\n");
        logLog.println("New device nickname sent");
      }
      
      if (controllerName.equals("isMantarray")){
        Packet setDeviceTypePacket = new Packet();
<<<<<<< HEAD
        byte[] setDeviceTypePacketConverted = setDeviceTypePacket.SetDeviceType(1);
=======
        byte[] setDeviceTypePacketConverted = setDeviceTypePacket.SetDeviceType(0);
>>>>>>> e25f26d7fbd2f7efdcda7d06d9ad9758ae332ba5
        serialPort.write(setDeviceTypePacketConverted);
        logDisplay.append("Device Type Set as Mantarray\n");
        logLog.println("Device Type Set as Mantarray");
      }
      
      if (controllerName.equals("isStingray")){
        Packet setDeviceTypePacket = new Packet();
        byte[] setDeviceTypePacketConverted = setDeviceTypePacket.SetDeviceType(1);
        serialPort.write(setDeviceTypePacketConverted);
        logDisplay.append("Device Type Set as Stingray\n");
        logLog.println("Device Type Set as Stingray");
      }
    }
  }
  

  void MagnetometerScheduler(final int totalCaptures, final int holdTime, long delayInBetween){
    TimerTask periodicCapture = new TimerTask() {
      int numCaptures = 0;
      public void run() {
        if (numCaptures >= totalCaptures) {
          magnetometerTimer.cancel();
          logDisplay.append("Magnetometer data capture schedule complete\n");
          logLog.println("Magnetometer data capture schedule complete");
        } else {
          if (!magCaptureInProgress){
            c = Calendar.getInstance(TimeZone.getTimeZone("PST"));
            dataLog = createWriter(String.format("./data/%04d-%02d-%02d_%02d-%02d-%02d_data.txt", c.get(Calendar.YEAR), c.get(Calendar.MONTH)+1, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE), c.get(Calendar.SECOND))); 
            dataLog.println(Arrays.toString(magnetometerConfigurationArray.toArray()).replace("[", "").replace("]", ""));
            magCaptureInProgress = true;
            Packet magStart = new Packet();
            byte[] magStartConverted = magStart.MagnetometerDataCaptureBegin();
            serialPort.write(magStartConverted);
            logDisplay.append("Starting Data Capture\n");
            logLog.println("Starting data capture");
          } else {
            logDisplay.append("There is already a magnetometer data capture running\n");
            logLog.println("There is already a magnetometer data capture running");
          }
          
          delay(holdTime);
          
          if (magCaptureInProgress){
            Packet magStop = new Packet();
            byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
            serialPort.write(magStopConverted);
            magCaptureInProgress = false;
            logDisplay.append("Stopping Data Capture\n");
            logLog.println("Stopping data capture");
            dataLog.flush();
            dataLog.close();
          } else {
            logDisplay.append("No magnetometer data capture currently running to stop\n");
            logLog.println("No magnetometer data capture currently running to stop");
          }
          numCaptures++;
        }
      }
    };
  
    magnetometerTimer.schedule(periodicCapture, 0, delayInBetween);
  }
}

 public class HomePageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  ControlGroup homePage;
  
  //Left Column
  Button loadMainFirmwareButton;
  Textfield mainMajorVersion;
  Textfield mainMinorVersion;
  Textfield mainRevisionVersion;
  Button loadChannelFirmwareButton;
  Textfield channelMajorVersion;
  Textfield channelMinorVersion;
  Textfield channelRevisionVersion;
  Button setStimConfigButton;
  Button startButtonMags;
  Button stopButtonMags;
  Button startButtonStims;
  Button stopButtonStims;
  Button startButtonHeadless;
  Button stopButtonHeadless;
  Button errorStatsButton;
  Button clearErrorButton;
  Button runStimCheck;
  Button scanBarcodeButton;
  Button saveAndQuitButton;
  
  Textfield setDeviceSerialNumberField;
  Button setDeviceSerialNumber;
  Textfield setDeviceNicknameField;
  Button setDeviceNickname;
  Button isMantarray;
  Button isStingray;
  Button setInitialPositions;
  Button StartBarcodeTune;
  Textfield magnetometerScheduleDelay;
  Textfield magnetometerScheduleHold;
  Textfield magnetometerScheduleDuration;
  Button startMagnetometerSchedule;
  Button stopMagnetometerSchedule;
 
  Textarea logDisplay;
  Button testButton;
  
  Textfield sextantRuntime;
  Textfield sextantDelay;
  Button runSextant;
  
  Textfield setSensorRateField;
  
  final Timer magnetometerTimer;
  final Timer statsTimer;
  
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
    statsTimer = new Timer("statsTimer", true);
    
    homePage = cp5.addGroup("homePage")
      .setPosition(0, 0)
      .setSize(1000, 600)
      .setBackgroundColor(color(255))
      .hideBar();
        
    //*************************** LEFT SIDE *****************************
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
      .setText(String.format("%d", settingsJSON.getInt("Channel_Major")))
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
      .setText(String.format("%d", settingsJSON.getInt("Channel_Minor")))
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
      .setText(String.format("%d", settingsJSON.getInt("Channel_Revision")))
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
      .setText(String.format("%d", settingsJSON.getInt("Main_Major")))
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
      .setText(String.format("%d", settingsJSON.getInt("Main_Minor")))
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
      .setText(String.format("%d", settingsJSON.getInt("Main_Revision")))
      .moveTo(homePage);
    mainRevisionVersion.getCaptionLabel().setText(".").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(-8);
    
    setStimConfigButton = cp5.addButton("setStimConfigButton")
      .setPosition(75, 150)
      .setSize(250, 30)
      .moveTo(homePage);
    setStimConfigButton.getCaptionLabel().setText("Set Stimulator Configuration").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
   
    startButtonMags = cp5.addButton("startButtonMags")
      .setPosition(75, 190)
      .setSize(120, 30)
      .moveTo(homePage);
    startButtonMags.getCaptionLabel().setText("Start Mags").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopButtonMags = cp5.addButton("stopButtonMags")
      .setPosition(205, 190)
      .setSize(120, 30)
      .moveTo(homePage);
    stopButtonMags.getCaptionLabel().setText("Stop Mags").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    startButtonStims = cp5.addButton("startButtonStims")
      .setPosition(75, 230)
      .setSize(120, 30)
      .moveTo(homePage);
    startButtonStims.getCaptionLabel().setText("Start Stims").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopButtonStims = cp5.addButton("stopButtonStims")
      .setPosition(205, 230)
      .setSize(120, 30)
      .moveTo(homePage);
    stopButtonStims.getCaptionLabel().setText("Stop Stims").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    startButtonHeadless = cp5.addButton("startButtonHeadless")
      .setPosition(75, 270)
      .setSize(120, 30)
      .moveTo(homePage);
    startButtonHeadless.getCaptionLabel().setText("Start Headless").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopButtonHeadless = cp5.addButton("stopButtonHeadless")
      .setPosition(205, 270)
      .setSize(120, 30)
      .moveTo(homePage);
    stopButtonHeadless.getCaptionLabel().setText("Stop Headless").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    errorStatsButton = cp5.addButton("errorStatsButton")
      .setPosition(75, 310)
      .setSize(250, 30)
      .moveTo(homePage);
    errorStatsButton.getCaptionLabel().setText("Send Error Stats").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    clearErrorButton = cp5.addButton("clearErrorButton")
      .setPosition(75, 350)
      .setSize(250, 30)
      .moveTo(homePage);
    clearErrorButton.getCaptionLabel().setText("Clear Error Codes").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    runStimCheck = cp5.addButton("runStimCheck")
      .setPosition(75, 390)
      .setSize(250, 30)
      .moveTo(homePage);
    runStimCheck.getCaptionLabel().setText("Run Stim Check").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    scanBarcodeButton = cp5.addButton("scanBarcodeButton")
      .setPosition(75, 430)
      .setSize(250, 30)
      .moveTo(homePage);
    scanBarcodeButton.getCaptionLabel().setText("Scan Barcode").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
 
    saveAndQuitButton = cp5.addButton("saveAndQuitButton")
      .setPosition(75, 470)
      .setSize(250, 50)
      .moveTo(homePage);
    saveAndQuitButton.getCaptionLabel().setText("Save and Quit").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    //*************************** RIGHT SIDE *****************************
    setDeviceSerialNumberField = cp5.addTextfield("setDeviceSerialNumberField")
      .setPosition(370, 70)
      .setSize(150, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(settingsJSON.getString("Serial_Number"))
      .moveTo(homePage);
    
    setDeviceSerialNumber = cp5.addButton("setDeviceSerialNumber")
      .setPosition(550, 70)
      .setSize(220, 30)
      .moveTo(homePage);
    setDeviceSerialNumber.getCaptionLabel().setText("Set Serial Number").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setDeviceNicknameField = cp5.addTextfield("setDeviceNicknameField")
      .setPosition(370, 110)
      .setSize(150, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(settingsJSON.getString("Nickname"))
      .moveTo(homePage);
    
    setDeviceNickname = cp5.addButton("setDeviceNickname")
      .setPosition(550, 110)
      .setSize(220, 30)
      .moveTo(homePage);
    setDeviceNickname.getCaptionLabel().setText("Set Device Nickname").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setInitialPositions = cp5.addButton("setInitialPositions")
      .setPosition(370, 150)
      .setSize(400, 30)
      .moveTo(homePage);
    setInitialPositions.getCaptionLabel().setText("Set Pulse3D Initial Positions").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    isMantarray = cp5.addButton("isMantarray")
      .setPosition(370, 190)
      .setSize(175, 30)
      .moveTo(homePage);
    isMantarray.getCaptionLabel().setText("Set as Mantarray").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    isStingray = cp5.addButton("isStingray")
      .setPosition(595, 190)
      .setSize(175, 30)
      .moveTo(homePage);
    isStingray.getCaptionLabel().setText("Set as Stingray").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    StartBarcodeTune = cp5.addButton("StartBarcodeTune")
      .setPosition(370, 230)
      .setSize(400, 30)
      .moveTo(homePage);
    StartBarcodeTune.getCaptionLabel().setText("Start Barcode Tuning Sequence").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    magnetometerScheduleDelay = cp5.addTextfield("magnetometerScheduleDelay")
      .setPosition(370, 270)
      .setSize(50, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(20))
      .moveTo(homePage);
    magnetometerScheduleDelay.getCaptionLabel().setText("Magnetometer Schedule Duration Between Readings (mins)").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(60);
    
    magnetometerScheduleHold = cp5.addTextfield("magnetometerScheduleHold")
      .setPosition(370, 310)
      .setSize(50, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(60))
      .moveTo(homePage);
    magnetometerScheduleHold.getCaptionLabel().setText("Magnetometer Schedule Capture Duration (secs)").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(60);
    
    magnetometerScheduleDuration = cp5.addTextfield("magnetometerScheduleDuration")
      .setPosition(370, 350)
      .setSize(50, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(48))
      .moveTo(homePage);
    magnetometerScheduleDuration.getCaptionLabel().setText("Magnetometer Schedule Total Duration (hrs)").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(60);
    
    startMagnetometerSchedule = cp5.addButton("startMagnetometerSchedule")
      .setPosition(400, 390)
      .setSize(200, 30)
      .moveTo(homePage);
    startMagnetometerSchedule.getCaptionLabel().setText("Begin Schedule").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    stopMagnetometerSchedule = cp5.addButton("stopMagnetometerSchedule")
      .setPosition(620, 390)
      .setSize(200, 30)
      .moveTo(homePage);
    stopMagnetometerSchedule.getCaptionLabel().setText("Stop Schedule").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
        

    logDisplay = cp5.addTextarea("logDisplay")
      .setPosition(350, 420)
      .setColorBackground(color(255))
      .setSize(550, 150)
      .setFont(createFont("arial", 16))
      .setLineHeight(20)
      .setColor(color(0))
      .setText("Starting utility tool\n")
      .moveTo(homePage);
    
    testButton = cp5.addButton("testButton")
      .setPosition(800, 70)
      .setSize(100, 100)
      .moveTo(homePage);
    testButton.getCaptionLabel().setText("TEST").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    sextantRuntime = cp5.addTextfield("sextantRuntime")
      .setPosition(800, 180)
      .setSize(70, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(10000))
      .moveTo(homePage);
    sextantRuntime.getCaptionLabel().setText("Sextant Runtime (ms)").setColor(0).setFont(createFont("arial", 12)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(75);
    
    sextantDelay = cp5.addTextfield("sextantDelay")
      .setPosition(800, 210)
      .setSize(70, 30)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(10000))
      .moveTo(homePage);
    sextantDelay.getCaptionLabel().setText("Sextant Delay (ms)").setColor(0).setFont(createFont("arial", 12)).toUpperCase(false).align(LEFT, CENTER).getStyle().setMarginLeft(75);
    
    runSextant = cp5.addButton("runSextant")
      .setPosition(800, 240)
      .setSize(180, 30)
      .moveTo(homePage);
    runSextant.getCaptionLabel().setText("Run Sextant Stimulation").setColor(255).setFont(createFont("arial", 16)).align(CENTER, CENTER).toUpperCase(false);
     
    cp5.addListener(this);
  }
  
  public void  controlEvent(ControlEvent theEvent) {
    String controllerName = theEvent.getName();
    if (theEvent.isAssignableFrom(Button.class)){
      if (controllerName.equals("loadChannelFirmwareButton")){
        selectInput("Select a file to load as channel microcontroller firmware:", "LoadChannelFirmware");
        settingsJSON.setString("Channel_Major", channelMajorVersion.getText());
        settingsJSON.setString("Channel_Minor", channelMinorVersion.getText());
        settingsJSON.setString("Channel_Revision", channelRevisionVersion.getText());
        saveJSONObject(settingsJSON, topSketchPath+"/config/config.json");
      }
      else if (controllerName.equals("loadMainFirmwareButton")){
        selectInput("Select a file to load as main microcontroller firmware:", "LoadMainFirmware");
        settingsJSON.setString("Main_Major", mainMajorVersion.getText());
        settingsJSON.setString("Main_Minor", mainMinorVersion.getText());
        settingsJSON.setString("Main_Revision", mainRevisionVersion.getText());
        saveJSONObject(settingsJSON, topSketchPath+"/config/config.json");
      }
      if (controllerName.equals("startButtonMags")){
        if (!magCaptureInProgress){
          inst_time = Calendar.getInstance(TimeZone.getTimeZone("PST"));
          dataLog = createWriter(String.format("./data/%04d-%02d-%02d_%02d-%02d-%02d_data.txt", inst_time.get(Calendar.YEAR), inst_time.get(Calendar.MONTH)+1, inst_time.get(Calendar.DAY_OF_MONTH), inst_time.get(Calendar.HOUR_OF_DAY), inst_time.get(Calendar.MINUTE), inst_time.get(Calendar.SECOND))); 
          dataLog.println(Arrays.toString(magnetometerConfigurationArray.toArray()).replace("[", "").replace("]", ""));
          magCaptureInProgress = true;
          Packet magStart = new Packet();
          byte[] magStartConverted = magStart.MagnetometerDataCaptureBegin();
          serialPort.write(magStartConverted);
          logDisplay.append("Starting Data Capture\n");
          logLog.println("Starting data capture");
        }
        else {
          logDisplay.append("There is already a magnetometer data capture running\n");
          logLog.println("There is already a magnetometer data capture running");
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
        //Packet stimEnd = new Packet();
        //byte[] stimEndConverted = stimEnd.TrueStimulatorEnd();
        //serialPort.write(stimEndConverted);
        if (stimulationInProgress) {
          stimulationInProgress = false;
          Packet stopStimulatorPacket = new Packet();
          byte[] stopStimulatorPacketConverted = stopStimulatorPacket.StimulatorEnd();
          serialPort.write(stopStimulatorPacketConverted);
          logDisplay.append("Stopping Stimulator\n");
          logLog.println("Stopping Stimulator");
        } else {
          logDisplay.append("No stimulation process currently running to stop\n");
          logLog.println("No stimulation process currently running to stop");
        }
        
      }
      if (controllerName.equals("startButtonHeadless")){
        Packet startHeadlessPacket = new Packet();
        byte[] startHeadlessPacketConverted = startHeadlessPacket.StartHeadless();
        serialPort.write(startHeadlessPacketConverted);
        logDisplay.append("Initiating Headless Mode\n");
        logLog.println("Initiating Headless Mode");
      }
      if (controllerName.equals("stopButtonHeadless")){
        Packet stopHeadlessPacket = new Packet();
        byte[] stopHeadlessPacketConverted = stopHeadlessPacket.StopHeadless();
        serialPort.write(stopHeadlessPacketConverted);
        logDisplay.append("Terminating Headless Mode\n");
        logLog.println("Terminating Headless Mode");
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
        memLog.flush();
        memLog.close();
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
      if (controllerName.equals("testButton")){
        //selectInput("Select a file to load as channel microcontroller firmware:", "PerformStimTest");
        //500:    {244, 1}
        //1000:   {232, 3}
        //1500:   {220, 5}
        //2000:   {208, 7}
        //-2000:  {48, 248}
        //2500:   {196, 9}
        //4000:   {160, 15}
        //-4000:  {96, 240}
        //6000:   {112, 23}
        //-6000:  {144, 232}
        //8000:   {64, 31}
        //-8000:  {192, 224}
        //10000:  {16, 39}
        //-10000: {240, 216}
        //int[] this_config_40mA = {1, 0, 0, 0, 1, 4, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 0, 1, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 2, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 3, 20, 20, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 96, 240, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 0, 5, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        //int[] this_config_60mA = {1, 0, 0, 0, 1, 4, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 0, 1, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 2, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 3, 20, 20, 0, 0, 112, 23, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 144, 232, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 0, 5, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        //int[] this_config_80mA = {1, 0, 0, 0, 1, 4, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 0, 1, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 2, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 3, 20, 20, 0, 0, 64, 31, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 192, 224, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 0, 5, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        /*int[] this_config_20mA = {1, 0, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 224, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 1, 208, 7, 0, 0, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 20, 20, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 48, 248, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        int[] this_config_40mA = {1, 0, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 1, 208, 7, 0, 0, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 20, 20, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 96, 240, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        int[] this_config_60mA = {1, 0, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 1, 208, 7, 0, 0, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 20, 20, 0, 0, 112, 23, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 144, 232, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        int[] this_config_80mA = {1, 0, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 1, 208, 7, 0, 0, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 20, 20, 0, 0, 64, 31, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 192, 224, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        int[] this_config_100mA = {1, 0, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 1, 208, 7, 0, 0, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 20, 20, 0, 0, 16, 39, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 240, 216, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        */
        /*int[] this_config = {1, 0, 1, 0, 1, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 232, 3, 0, 0, 1, 1, 2, 3, 0, 0, 0, 1, 2, 3, 0, 0, 0, 0, 1, 232, 3, 0, 0, 16, 39, 208, 7, 0, 0, 0, 0, 184, 11, 0, 0, 240, 216, 160, 15, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 1, 0, 3, 64, 156, 0, 0, 228, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 13, 3, 0, 0, 0, 10, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 184, 11, 0, 0, 1, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
        //int[] this_config = {1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 196, 9, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 60, 246, 117, 6, 5, 0, 0, 0, 180, 0, 0, 0, 0, 1, 0};
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
        serialPort.write(stimBeginConverted);*/
        //Packet stimCal = new Packet();
        //byte[] stimCalConverted = stimCal.StimulatorCalibration();
        //serialPort.write(stimCalConverted);
        /*if (statsScheduleIsRunning == false){
          Packet memStats = new Packet();
          byte[] memStatsConverted = memStats.SendMemoryStats();
          serialPort.write(memStatsConverted);
          statsScheduleIsRunning = true;
          MemoryStatsScheduler(100, 2000);
        }*/
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
        settingsJSON.setString("Nickname", setDeviceNicknameField.getText());
        saveJSONObject(settingsJSON, topSketchPath+"/config/config.json");
      }
      
      if (controllerName.equals("isMantarray")){
        Packet setDeviceTypePacket = new Packet();
        byte[] setDeviceTypePacketConverted = setDeviceTypePacket.SetDeviceType(0);
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
      
      if (controllerName.equals("errorStatsButton")){
        Packet errorStatsPacket = new Packet();
        byte[] errorStatsPacketConverted = errorStatsPacket.ErrorStats();
        serialPort.write(errorStatsPacketConverted);
        logDisplay.append("Requesting Error Statistics\n");
        logLog.println("Requesting Error Statistics");
      }
      
      if (controllerName.equals("clearErrorButton")){
        Packet clearErrorPacket = new Packet();
        byte[] clearErrorPacketConverted = clearErrorPacket.ErrorAck();
        serialPort.write(clearErrorPacketConverted);
        logDisplay.append("Clearing error from system\n");
        logLog.println("Clearing error from system");
      }
      
      if (controllerName.equals("scanBarcodeButton")){
        Packet scanBarcodePacket = new Packet();
        byte[] scanBarcodePacketConverted = scanBarcodePacket.ScanBarcode();
        serialPort.write(scanBarcodePacketConverted);
      }
      
      if (controllerName.equals("runSextant")){
        Packet StartSextantStimulationPacket = new Packet();
        byte[] StartSextantStimulationPacketConverted = StartSextantStimulationPacket.StartSextantStimulation();
        serialPort.write(StartSextantStimulationPacketConverted);
        logDisplay.append("Starting sextant-based stimulation\n");
        logLog.println("Starting sextant-based stimulation");
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
            inst_time = Calendar.getInstance(TimeZone.getTimeZone("PST"));
            dataLog = createWriter(String.format("./data/%04d-%02d-%02d_%02d-%02d-%02d_data.txt", inst_time.get(Calendar.YEAR), inst_time.get(Calendar.MONTH)+1, inst_time.get(Calendar.DAY_OF_MONTH), inst_time.get(Calendar.HOUR_OF_DAY), inst_time.get(Calendar.MINUTE), inst_time.get(Calendar.SECOND)));
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
  
  void MemoryStatsScheduler(final int totalIterations, long delayInBetween){
    TimerTask periodicPacketBurst = new TimerTask() {
      int numCaptures = 0;
      public void run() {
        if (numCaptures >= totalIterations) {
          statsTimer.cancel();
          statsScheduleIsRunning = false;
          logDisplay.append("Memory stats schedule complete\n");
          logLog.println("Memory stats schedule complete");
        } else {
          logDisplay.append("Beginning next command burst for memory stats\n");
          logLog.println("Beginning next command burst for memory stats");
          //Start a stim schedule and magnetometers
          //Packet BeginStimCheckPacket = new Packet();
          //byte[] BeginStimCheckPacketConverted = BeginStimCheckPacket.BeginStimCheck();
          //serialPort.write(BeginStimCheckPacketConverted);
          int[] config = {1, 0, 0, 0, 1, 4, 1, 0, 0, 0, 0, 0, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 0, 1, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 112, 58, 15, 0, 0, 0, 60, 0, 0, 0, 0, 1, 3, 60, 0, 0, 0, 0, 2, 208, 7, 0, 0, 208, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 109, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 3, 20, 20, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 20, 20, 0, 0, 96, 240, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 3, 0, 0, 1, 0, 5, 208, 7, 0, 0, 160, 15, 0, 0, 0, 0, 0, 0, 208, 7, 0, 0, 96, 240, 160, 50, 15, 0, 0, 0, 60, 0, 0, 0, 0, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
          List<Byte> this_config_Byte = new ArrayList<Byte>();
          for (int i = 0; i < config.length; i++){
            this_config_Byte.add(uint2byte(config[i]));
          }
          Packet stimConfig = new Packet();
          byte[] stimConfigConverted = stimConfig.TrueStimulatorConfiguration(this_config_Byte);
          serialPort.write(stimConfigConverted);
          Packet stimBegin = new Packet();
          byte[] stimBeginConverted = stimBegin.TrueStimulatorBegin();
          serialPort.write(stimBeginConverted);
          Packet magStart = new Packet();
          byte[] magStartConverted = magStart.MagnetometerDataCaptureBegin();
          serialPort.write(magStartConverted);
          
          delay(1000);
          //Stop the stim schedule and magnetometers, return and log memory stats
          Packet magStop = new Packet();
          byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
          serialPort.write(magStopConverted);
          Packet stimEnd = new Packet();
          byte[] stimEndConverted = stimEnd.TrueStimulatorEnd();
          serialPort.write(stimEndConverted);
          Packet memStats = new Packet();
          byte[] memStatsConverted = memStats.SendMemoryStats();
          serialPort.write(memStatsConverted);
          
          numCaptures++;
        }
      }
    };
  
    statsTimer.schedule(periodicPacketBurst, 0, delayInBetween);
  }
}

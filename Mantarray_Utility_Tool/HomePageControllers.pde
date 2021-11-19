public class HomePageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  ControlGroup homePage;
  Button loadMainFirmwareButton;
  Button loadChannelFirmwareButton;
  Button startButtonMags;
  Button stopButtonMags;
  Button startButtonStims;
  Button stopButtonStims;
  Button setStimConfigButton;
  Button setBoardConfigButton;
  Button setSensorConfigButton;
  Button saveAndQuitButton;
  Textarea logDisplay;
  Textfield I2CAddressField;
  Textfield I2CInputField;
  Button I2CSendCommand;
  Textfield I2CSetAddressOld;
  Textfield I2CSetAddressNew;
  Button I2CSetAddress;
  
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
      .setSize(250, 30)
      .moveTo(homePage);
    loadChannelFirmwareButton.getCaptionLabel().setText("Load Channel Micro Firmware").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    loadMainFirmwareButton = cp5.addButton("loadMainFirmwareButton")
      .setPosition(75, 110)
      .setSize(250, 30)
      .moveTo(homePage);
    loadMainFirmwareButton.getCaptionLabel().setText("Load Main Micro Firmware").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
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
    
    setSensorConfigButton = cp5.addButton("setSensorConfigButton")
      .setPosition(75, 270)
      .setSize(250, 50)
      .moveTo(homePage);
    setSensorConfigButton.getCaptionLabel().setText("Set Sensor Configuration").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    setBoardConfigButton = cp5.addButton("setBoardConfigButton")
      .setPosition(75, 210)
      .setSize(250, 50)
      .moveTo(homePage);
    setBoardConfigButton.getCaptionLabel().setText("Set Board Configuration").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    saveAndQuitButton = cp5.addButton("saveAndQuitButton")
      .setPosition(75, 410)
      .setSize(250, 50)
      .moveTo(homePage);
    saveAndQuitButton.getCaptionLabel().setText("Save and Quit").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    I2CAddressField = cp5.addTextfield("I2CAddressField")
      .setPosition(370, 80)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(100))
      .moveTo(homePage);
    I2CAddressField.getCaptionLabel().setText("Address").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-25);
  
    I2CInputField = cp5.addTextfield("I2CInputField")
      .setPosition(480, 80)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(0))
      .moveTo(homePage);
    I2CInputField.getCaptionLabel().setText("Command").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-25);
    
    I2CSendCommand = cp5.addButton("I2CSendCommand")
      .setPosition(570, 80)
      .setSize(200, 25)
      .moveTo(homePage);
    I2CSendCommand.getCaptionLabel().setText("Send I2C Command").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    I2CSetAddressOld = cp5.addTextfield("I2CSetAddressOld")
      .setPosition(370, 135)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(1))
      .moveTo(homePage);
    I2CSetAddressOld.getCaptionLabel().setText("Old Addr.").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-25);
  
    I2CSetAddressNew = cp5.addTextfield("I2CSetAddressNew")
      .setPosition(480, 135)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(1))
      .moveTo(homePage);
    I2CSetAddressNew.getCaptionLabel().setText("New Addr.").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-25);
    
    I2CSetAddress = cp5.addButton("I2CSetAddress")
      .setPosition(570, 135)
      .setSize(200, 25)
      .moveTo(homePage);
    I2CSetAddress.getCaptionLabel().setText("Set New Address").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
    
    magnetometerScheduleDelay = cp5.addTextfield("magnetometerScheduleDelay")
      .setPosition(370, 200)
      .setSize(50, 25)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(.05))
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
      .setText(String.valueOf(1))
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
      .setText(String.valueOf(.0027))
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
      if (controllerName.equals("setBoardConfigButton")){
        thisMagPageControllers.magnetometerSelector.show();
        homePage.hide();
      }
      if (controllerName.equals("setSensorConfigButton")){
        thisSensorPageControllers.magnetometerRegisterConfigurator.show();
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
      
      if (controllerName.equals("I2CSendCommand")){
        Packet I2CCommandPacket = new Packet();
        byte[] I2CCommandPacketConverted = I2CCommandPacket.I2CCommand();
        serialPort.write(I2CCommandPacketConverted);
        logDisplay.append("I2C Command Sent\n");
        logLog.println("I2C command sent");
      }
      if (controllerName.equals("I2CSetAddress")){
        Packet I2CNewAddressPacket = new Packet();
        byte[] I2CNewAddressPacketConverted = I2CNewAddressPacket.I2CAddressNew();
        serialPort.write(I2CNewAddressPacketConverted);
        logDisplay.append("New I2C address set\n");
        logLog.println("New I2C address set");
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
          logDisplay.append("Magnetometer data capture schedule ended prematurely\n");
          logLog.println("Magnetometer data capture schedule ended prematurely");
        }
        else {
          logDisplay.append("No magnetometer schedule currently running\n");
          logLog.println("No magnetometer schedule currently running");
        }
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

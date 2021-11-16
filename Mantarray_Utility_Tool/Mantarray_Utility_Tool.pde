import processing.serial.*;
import controlP5.*;
import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;
import java.util.Collections;
import java.util.zip.Checksum;
import java.util.zip.CRC32;
import java.io.InputStream;
import java.io.FileInputStream;
import com.google.common.primitives.Bytes;
import java.util.Calendar;
import java.util.TimeZone;

Serial serialPort;
boolean noBeacon = false;
Calendar c;
PrintWriter dataLog;
PrintWriter logLog;

int MAG_TIMESTAMP_LENGTH;
int MAGIC_WORD_LENGTH = 8;
int CRC_LENGTH = 4;
int TIMESTAMP_LENGTH = 8;
int PACKETLENGTH_LENGTH = 2;
int PRE_PACKET_LENGTH = 10;
int BASE_PACKET_LENGTH = 10;
int BASE_PACKET_LENGTH_PLUS_CRC = 14;
int MIN_PACKET_LENGTH_MINUS_MAGIC_WORD = 16;
int MIN_TOTAL_PACKET_LENGTH = 24;
int MAX_DATA_SIZE = 65000;
int MAX_PACKET_SIZE = 65546;
int NUM_WELLS = 24;
int NUM_SENSORS = 3;
int NUM_AXES = 3;
String[] wellNames = {"A1", "A2", "A3", "A4", "A5", "A6", 
  "B1", "B2", "B3", "B4", "B5", "B6", 
  "C1", "C2", "C3", "C4", "C5", "C6", 
  "D1", "D2", "D3", "D4", "D5", "D6"};
String[] sensorNames = {"S1", "S2", "S3"};
String[] axesNames = {"X", "Y", "Z"};

int MIN_PACKET_LENGTH = 16;
byte[] MAGIC_WORD = new byte[]{67, 85, 82, 73, 32, 66, 73, 79};

List<Packet> packetList = new ArrayList<Packet>();
List<List<List<Integer>>> magnetometerConfigurationArray = new ArrayList<List<List<Integer>>>();
List<Byte> magConfigurationByteArray = new ArrayList<Byte>();
boolean magCaptureInProgress = false;
boolean stimulationInProgress = false;
boolean boardConfigSet = false;
boolean sensorConfigSet = false;
boolean mantarrayDeviceFound = false;
boolean runReadThread = false;
boolean beaconRecieved = false;
Checksum crc32 = new CRC32();

Packet IAmHerePacket = new Packet();
byte[] IAmHereConverted;

int numMessagesOut = 0;
int numMessagesIn = 0;

long nanoStart;
int start;
int stop;

//********************************************************************HOME PAGE DEFINES*******************************************************************************
public ControlP5 cp5;
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

Textfield allStimulatorCurrentField;
Button setAllStimulatorCurrent;
Textfield allStimulatorVoltageField;
Button setAllStimulatorVoltage;
//***************************************************************HOME PAGE DEFINES /END**********************************************************************************
  
//*************************************************************SENSOR CONFIGURATION DEFINES*******************************************************************************  
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

public JSONObject settingsJSON;
public String topSketchPath = "";
//**********************************************************SENSOR CONFIGURATION DEFINES /END*****************************************************************************

MagPageControllers thisMagPageControllers;
StimPageControllers thisStimPageControllers;

public void setup() {
  size(1000, 600);  
  frameRate(60);
  cp5 = new ControlP5(this);
  
  //********************************************************************HOME PAGE*****************************************************************************************
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
    .setPosition(370, 120)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(100))
    .moveTo(homePage);
  I2CAddressField.getCaptionLabel().setText("Address").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);

  I2CInputField = cp5.addTextfield("I2CInputField")
    .setPosition(480, 120)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(0))
    .moveTo(homePage);
  I2CInputField.getCaptionLabel().setText("Command").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);
  
  I2CSendCommand = cp5.addButton("I2CSendCommand")
    .setPosition(570, 120)
    .setSize(200, 50)
    .moveTo(homePage);
  I2CSendCommand.getCaptionLabel().setText("Send I2C Command").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
  
  I2CSetAddressOld = cp5.addTextfield("I2CSetAddressOld")
    .setPosition(370, 200)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(1))
    .moveTo(homePage);
  I2CSetAddressOld.getCaptionLabel().setText("Old Addr.").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);

  I2CSetAddressNew = cp5.addTextfield("I2CSetAddressNew")
    .setPosition(480, 200)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(1))
    .moveTo(homePage);
  I2CSetAddressNew.getCaptionLabel().setText("New Addr.").setColor(0).setFont(createFont("arial", 18)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);
  
  I2CSetAddress = cp5.addButton("I2CSetAddress")
    .setPosition(570, 200)
    .setSize(200, 50)
    .moveTo(homePage);
  I2CSetAddress.getCaptionLabel().setText("Set New Address").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
  
  /*allStimulatorCurrentField = cp5.addTextfield("allStimulatorCurrentField")
    .setPosition(370, 280)
    .setSize(150, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.format ("%.3f", 75.000))
    .moveTo(homePage);
  allStimulatorCurrentField.getCaptionLabel().setText("Stimulator Amplitude (mA)").setColor(0).setFont(createFont("arial", 15)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);
  
  setAllStimulatorCurrent = cp5.addButton("setAllStimulatorCurrent")
    .setPosition(570, 280)
    .setSize(200, 50)
    .moveTo(homePage);
  setAllStimulatorCurrent.getCaptionLabel().setText("Set Stimulator Current").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);
  
  allStimulatorVoltageField = cp5.addTextfield("allStimulatorVoltageField")
    .setPosition(370, 360)
    .setSize(150, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.format ("%.3f", 2.000))
    .moveTo(homePage);
  allStimulatorVoltageField.getCaptionLabel().setText("Stimulator Amplitude (V)").setColor(0).setFont(createFont("arial", 15)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);
  
  setAllStimulatorVoltage = cp5.addButton("setAllStimulatorVoltage")
    .setPosition(570, 360)
    .setSize(200, 50)
    .moveTo(homePage);
  setAllStimulatorVoltage.getCaptionLabel().setText("Set Stimulator Voltage").setColor(255).setFont(createFont("arial", 18)).align(CENTER, CENTER).toUpperCase(false);*/
  
  logDisplay = cp5.addTextarea("logDisplay")
      .setPosition(400, 420)
      .setColorBackground(color(255))
      .setSize(500, 150)
      .setFont(createFont("arial", 16))
      .setLineHeight(20)
      .setColor(color(0))
      .setText("Starting utility tool\n")
      .moveTo(homePage);
  //******************************************************************HOME PAGE /END**************************************************************************************
  
  //****************************************************************SENSOR CONFIGURATION PAGE******************************************************************************
  topSketchPath = sketchPath();
  settingsJSON = loadJSONObject(topSketchPath+"/config/config.json");
  
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
  //****************************************************************SENSOR CONFIGURATION PAGE /END***************************************************************************
  
  thisMagPageControllers = new MagPageControllers(this);
  
  thisStimPageControllers = new StimPageControllers(this);
  
  c = Calendar.getInstance(TimeZone.getTimeZone("PST"));
  logLog = createWriter(String.format("./log/%04d-%02d-%02d_%02d-%02d-%02d_log.txt", c.get(Calendar.YEAR), c.get(Calendar.MONTH)+1, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE), c.get(Calendar.SECOND))); 
  
  nanoStart = System.nanoTime();
  start = millis();
  String[] serialPorts = Serial.list();
  if (serialPorts.length == 0){
    logDisplay.append("No serial port found\n");
    logLog.println("No serial port found");
    print("No serial port found");
  } else {
    for (int thisSerialPortIndex = 0; thisSerialPortIndex < serialPorts.length; thisSerialPortIndex++){
      String serialPortName = serialPorts[thisSerialPortIndex];
      try {
        runReadThread = true;
        serialPort = new Serial(this, serialPortName, 5000000);
        thread("readPackets");
        println("Testing serial device " + serialPortName);
        logLog.println("Testing serial device " + serialPortName);
        delay(5000);
        if (beaconRecieved){
          IAmHereConverted = IAmHerePacket.IAmHere();
          serialPort.write(IAmHereConverted);
          mantarrayDeviceFound = true;
        } else {
          runReadThread = false;
          println(serialPortName + " failed");
          logLog.println(serialPortName + " failed");
        }
      } catch (Exception e) {
        runReadThread = false;
        println(serialPortName + " failed");
        logLog.println(serialPortName + " failed");
      }
      if (mantarrayDeviceFound){
        break;
      }
    }
  }
  if (mantarrayDeviceFound){
    logDisplay.append("Connected to Mantarray\n");
    logLog.println("Connected to Mantarray");
    println("Connected to Mantarray");
  } else {
    noBeacon = true;
    logDisplay.append("No Mantarray Detected\n");
    logLog.println("No Mantarray Detected");
    println("No Mantarray Detected");
  }
  logDisplay.append("Setup Complete\n");
  logLog.println("Setup Complete");
  println("Setup Complete");
}

public void draw() {
  background(255);
  if (thisStimPageControllers.stimWindow.isVisible()){
    //Build the pulse that will be visualized based off of the textvalues from each text field controller on the thiStimPage class
    List<Float> pulse = new ArrayList<Float>();
    //The beginning and the end of the pulse is always 1/8 of the total x limit
    pulse.add(thisStimPageControllers.pulseXLim/8.0);
    pulse.add(thisStimPageControllers.pulseHighAmpText);
    pulse.add(thisStimPageControllers.pulseHighDelayText);
    pulse.add(thisStimPageControllers.pulseMidDelayText);
    pulse.add(thisStimPageControllers.pulseLowAmpText);
    pulse.add(thisStimPageControllers.pulseLowDelayText);
    //plot the pulse in the edit window
    PulsePlotter (pulse, thisStimPageControllers);
  }
  long temp = ((System.nanoTime() - nanoStart)/1000);
  if (temp - IAmHerePacket.timeStamp > 5000000 && !noBeacon)
  {
    IAmHereConverted = IAmHerePacket.IAmHere();
    serialPort.write(IAmHereConverted);
    numMessagesOut++;
    println(String.format("Handshake %d Sent:", numMessagesOut));
  }
}

public void PulsePlotter(List<Float> pulse, StimPageControllers thisStimPageControllers) {
  int graphWidth = thisStimPageControllers.stimWindowWidth;
  int graphHeight = thisStimPageControllers.stimWindowHeight;
  int graphX = thisStimPageControllers.stimWindowX;
  int graphY = thisStimPageControllers.stimWindowY;
  //Calculates the height and width of the axes in pixels
  int pulseYAxisHeight = (3*graphHeight)/8;
  int pulseXAxisLength = (5*graphWidth)/6;
  //The beginning and end of the pulse are always 1/8 of the axes lengths
  int beginningAndEndLength = thisStimPageControllers.pulseXLim/8;
  //Figure out conversion ratio between axes limits and pixels
  float pulseScaleHeight = 1.0*pulseYAxisHeight/thisStimPageControllers.pulseYLim;
  float pulseScaleWidth = 1.0*pulseXAxisLength/thisStimPageControllers.pulseXLim;
  //Black medium thickness lines.  Draw axes
  stroke(0); 
  strokeWeight(2);
  pushMatrix();
  //Begin drawing at upper left point of graph starting point
  translate(graphX, graphY);
  translate(graphWidth/12, graphHeight/8);
  line(0, 0, 0, (6*graphHeight)/8);
  line(0, 0, 10, 10);
  line(0, 0, -10, 10);
  translate(0, (6*graphHeight)/8);
  line(0, 0, 10, -10);
  line(0, 0, -10, -10);
  translate((10*graphWidth)/12, -(3*graphHeight)/8);
  line(0, 0, -(10*graphWidth)/12, 0);
  line(0, 0, -10, 10);
  line(0, 0, -10, -10);
  popMatrix();

  pushMatrix();
  //Begin drawing at upper left point of graph starting point
  translate(graphX, graphY);
  translate(graphWidth/12, graphHeight/2);

  //Check whether to draw constant current or constant voltage colors
  if (thisStimPageControllers.isConstantCurrent)
    stroke(thisStimPageControllers.constantCurrentColor);
  else
    stroke(thisStimPageControllers.constantVoltageColor);

  //double the line thickness and draw the pulse
  strokeWeight(4);
  line(0, 0, beginningAndEndLength*pulseScaleWidth, 0);
  translate(beginningAndEndLength*pulseScaleWidth, 0);

  line(0, 0, 0, -pulse.get(1)*pulseScaleHeight);
  translate(0, -pulse.get(1)*pulseScaleHeight);

  line(0, 0, pulse.get(2)*pulseScaleWidth, 0);
  translate(pulse.get(2)*pulseScaleWidth, 0);

  line(0, 0, 0, pulse.get(1)*pulseScaleHeight);
  translate(0, pulse.get(1)*pulseScaleHeight);

  line(0, 0, pulse.get(3)*pulseScaleWidth, 0);
  translate(pulse.get(3)*pulseScaleWidth, 0);

  line(0, 0, 0, -pulse.get(4)*pulseScaleHeight);
  translate(0, -pulse.get(4)*pulseScaleHeight);

  line(0, 0, pulse.get(5)*pulseScaleWidth, 0);
  translate(pulse.get(5)*pulseScaleWidth, 0);

  line(0, 0, 0, pulse.get(4)*pulseScaleHeight);
  translate(0, pulse.get(4)*pulseScaleHeight);

  line(0, 0, beginningAndEndLength*pulseScaleWidth, 0);
  popMatrix();
}

void sendIAmHerePacket(){
  Packet thisPacket = new Packet();
  println(String.format("Message %d Sent:", numMessagesOut));
  thisPacket.IAmHere();
  byte[] thisPacketConverted = thisPacket.toByte();
  serialPort.write(thisPacketConverted);
  numMessagesOut++;
}

int byte2uint(byte thisByte){
  int byteAsInt = thisByte;
  if (byteAsInt < 0){
    byteAsInt+=256;
  }
  return byteAsInt;
}

int uint16_2_int16(int thisInt){
  if (thisInt > 32767){
    thisInt -= 65536;
  }
  return thisInt;
}

long byte2long(byte thisByte){
  long byteAsLong = thisByte;
  if (byteAsLong < 0){
    byteAsLong+=256;
  }
  return byteAsLong;
}

public void controlEvent(ControlEvent theEvent) {
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
      magnetometerRegisterConfigurator.show();
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
    if (controllerName.equals("setAllStimulatorCurrent")){
      //Packet setAllStimulatorCurrentPacket = new Packet();
      //byte[] setAllStimulatorCurrentPacketConverted = setAllStimulatorCurrentPacket.SetStimulatorAtConstantCurrent();
      //serialPort.write(setAllStimulatorCurrentPacketConverted);
      logDisplay.append("This process is still in development\n");
      logLog.println("This process is still in development");
    }
    if (controllerName.equals("setAllStimulatorVoltage")){
      //Packet setAllStimulatorVoltagePacket = new Packet();
      //byte[] setAllStimulatorVoltagePacketConverted = setAllStimulatorVoltagePacket.SetStimulatorAtConstantVoltage();
      //serialPort.write(setAllStimulatorVoltagePacketConverted);
      logDisplay.append("This process is still in development\n");
      logLog.println("This process is still in development");
    }
    
    if (controllerName.equals("sensorConfigurationSubmit")){
      for (int textBoxNum = 0; textBoxNum < magnetometerRegisterFieldNums; textBoxNum++){
        settingsJSON.setString(magnetometerRegisterFieldJSON[textBoxNum], magnetometerRegisterFields.get(textBoxNum).getText());
      }
      saveJSONObject(settingsJSON, topSketchPath+"/config/config.json");
      Packet sensorConfigurationPacket = new Packet();
      byte[] sensorConfigurationPacketConverted = sensorConfigurationPacket.sensorConfig(settingsJSON);
      serialPort.write(sensorConfigurationPacketConverted);
      magnetometerRegisterConfigurator.hide();
      homePage.show();
      logDisplay.append("Sensor Configuration Set\n");
      logLog.println("Sensor configuration set");
      sensorConfigSet = true;
    }
    if (controllerName.equals("sensorConfigurationBack")){
      magnetometerRegisterConfigurator.hide();
      homePage.show();
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

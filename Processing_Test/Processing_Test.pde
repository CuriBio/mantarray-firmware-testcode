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
int MAX_DATA_SIZE = 65524;
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
Checksum crc32 = new CRC32();

Packet IAmHerePacket = new Packet();
byte[] IAmHereConverted;

int numMessagesOut = 0;
int numMessagesIn = 0;

long nanoStart;
int start;
int stop;

public ControlP5 cp5;
Button loadFirmwareButton;
Button startButton;
Button stopButton;
Button setConfigButton;
Button saveAndQuitButton;

Textfield I2CAddressField;
Textfield I2CInputField;
Button I2CSendCommand;
Textfield I2CSetAddressOld;
Textfield I2CSetAddressNew;
Button I2CSetAddress;

ControlGroup magnetometerSelector;
List<Textlabel> magSensorLabels = new ArrayList<Textlabel>();
List<List<List<Toggle>>> magSensorSelector = new ArrayList<List<List<Toggle>>>();
Textfield samplingRate;

List<Button> magnetometerSelectorButtonList = new ArrayList<Button>();
int NUM_BUTTONS = 18;
String[] buttonNames = {"selectAllX", "selectAllY", "selectAllZ", "selectAllS1", "selectAllS2", "selectAllS3", 
  "selectAllRowA", "selectAllRowB", "selectAllRowC", "selectAllRowD", 
  "selectAllCol1", "selectAllCol2", "selectAllCol3", "selectAllCol4", "selectAllCol5", "selectAllCol6", 
  "selectAll", "submitConfiguration"};
String[] labelNames = {"Select All X", "Select All Y", "Select All Z", "Select All S1", "Select All S2", "Select All S3", 
  "Select Row A", "Select Row B", "Select Row C", "Select Row D", 
  "Select Column 1", "Select Column 2", "Select Column 3", "Select Column 4", "Select Column 5", "Select Column 6", 
  "Select All", "Submit"};

public void setup() {
  size(1920, 1000);  
  frameRate(60);
  cp5 = new ControlP5(this);
  loadFirmwareButton = cp5.addButton("loadFirmwareButton")
    .setPosition(100, 50)
    .setSize(200, 200);
  loadFirmwareButton.getCaptionLabel().setText("Load Firmware").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
  startButton = cp5.addButton("startButton")
    .setPosition(75, 340)
    .setSize(100, 50);
  startButton.getCaptionLabel().setText("Start").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
  stopButton = cp5.addButton("stopButton")
    .setPosition(225, 340)
    .setSize(100, 50);
  stopButton.getCaptionLabel().setText("Stop").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
  setConfigButton = cp5.addButton("setConfigButton")
    .setPosition(75, 270)
    .setSize(250, 50);
  setConfigButton.getCaptionLabel().setText("Set Configuration").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
  saveAndQuitButton = cp5.addButton("saveAndQuitButton")
    .setPosition(75, 410)
    .setSize(250, 50);
  saveAndQuitButton.getCaptionLabel().setText("Save and Quit").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
  I2CAddressField = cp5.addTextfield("I2CAddressField")
    .setPosition(370, 120)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(100));
  I2CAddressField.getCaptionLabel().setText("Address").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);

  I2CInputField = cp5.addTextfield("I2CInputField")
    .setPosition(480, 120)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(0));
  I2CInputField.getCaptionLabel().setText("Command").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);
  
  I2CSendCommand = cp5.addButton("I2CSendCommand")
    .setPosition(570, 120)
    .setSize(200, 50);
  I2CSendCommand.getCaptionLabel().setText("Send I2C Command").setColor(255).setFont(createFont("arial", 20)).align(CENTER, CENTER).toUpperCase(false);
  
  I2CSetAddressOld = cp5.addTextfield("I2CSetAddressOld")
    .setPosition(370, 200)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(1));
  I2CSetAddressOld.getCaptionLabel().setText("Old Addr.").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);

  I2CSetAddressNew = cp5.addTextfield("I2CSetAddressNew")
    .setPosition(480, 200)
    .setSize(50, 50)
    .setFont(createFont("arial", 20))
    .setColor(0)
    .setColorBackground(color(255))
    .setColorForeground(color(0))
    .setAutoClear(false)
    .setText(String.valueOf(1));
  I2CSetAddressNew.getCaptionLabel().setText("New Addr.").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-40);
  
  I2CSetAddress = cp5.addButton("I2CSetAddress")
    .setPosition(570, 200)
    .setSize(200, 50);
  I2CSetAddress.getCaptionLabel().setText("Set New Address").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
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
  samplingRate.getCaptionLabel().setText("Sampling Rate:").setColor(0).setFont(createFont("arial", magConfigBarBufferWidth)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(-(int)(.65 * magConfigBarButtonWidth));
  
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
  
  c = Calendar.getInstance(TimeZone.getTimeZone("PST"));
  logLog = createWriter(String.format("./log/%d-%d-%d_%d-%d-%d_log.txt", c.get(Calendar.MONTH)+1, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.YEAR), c.get(Calendar.HOUR), c.get(Calendar.MINUTE), c.get(Calendar.SECOND))); 
  
  String serialPortName = Serial.list() [0] ; //"/dev/tty.usbmodem1411";
  serialPort = new Serial(this, serialPortName, 5000000);
  thread("readPackets");
  start = millis();
  nanoStart = System.nanoTime();
  IAmHerePacket.IAmHere();
  IAmHereConverted = IAmHerePacket.toByte();
}

public void draw() {
  rect(0,0,1920, 1000);
  long temp = ((System.nanoTime() - nanoStart)/1000);
  if (temp - IAmHerePacket.timeStamp > 5000000)
  {
    IAmHerePacket.IAmHere();
    IAmHereConverted = IAmHerePacket.toByte();
    serialPort.write(IAmHereConverted);
    numMessagesOut++;
    println(String.format("Handshake %d Sent:", numMessagesOut));
  }
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
    if (controllerName.equals("loadFirmwareButton")){
      selectInput("Select a file to load as channel microcontroller firmware:", "LoadFirmware");
    }
    if (controllerName.equals("startButton")){
      c = Calendar.getInstance(TimeZone.getTimeZone("PST"));
      dataLog = createWriter(String.format("./data/%d-%d-%d_%d-%d-%d_data.txt", c.get(Calendar.MONTH)+1, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.YEAR), c.get(Calendar.HOUR), c.get(Calendar.MINUTE), c.get(Calendar.SECOND))); 
      dataLog.println(magnetometerConfigurationArray);
      magCaptureInProgress = true;
      Packet magStart = new Packet();
      byte[] magStartConverted = magStart.MagnetometerDataCaptureBegin();
      serialPort.write(magStartConverted);
    }
    if (controllerName.equals("stopButton")){
      Packet magStop = new Packet();
      byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
      serialPort.write(magStopConverted);
      magCaptureInProgress = false;
      dataLog.flush();
      dataLog.close();
    }
    if (controllerName.equals("setConfigButton")){
      magnetometerSelector.show();
    }
    if (controllerName.equals("saveAndQuitButton")){
      if (magCaptureInProgress)
      {
        Packet magStop = new Packet();
        byte[] magStopConverted = magStop.MagnetometerDataCaptureEnd();
        serialPort.write(magStopConverted);
        dataLog.flush();
        dataLog.close();
      }
      logLog.flush();
      logLog.close();
      exit();
    }
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
    if (controllerName.equals("submitConfiguration")){
      magConfigurationByteArray = configDataGenerator();
      magnetometerSelector.hide();
      Packet magConfig = new Packet();
      byte[] magConfigConverted = magConfig.MagnetometerConfiguration();
      serialPort.write(magConfigConverted);
    }
    if (controllerName.equals("I2CSendCommand")){
        Packet I2CCommandPacket = new Packet();
        byte[] I2CCommandPacketConverted = I2CCommandPacket.I2CCommand();
        serialPort.write(I2CCommandPacketConverted);
    }
    if (controllerName.equals("I2CSetAddress")){
        Packet I2CNewAddressPacket = new Packet();
        byte[] I2CNewAddressPacketConverted = I2CNewAddressPacket.I2CAddressNew();
        serialPort.write(I2CNewAddressPacketConverted);
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

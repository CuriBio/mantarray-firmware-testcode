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
import java.util.Scanner;
import java.io.InputStream;
import java.io.FileInputStream;
import com.google.common.primitives.Bytes;
import java.util.Calendar;
import java.util.TimeZone;
import java.util.TimerTask;
import java.util.Timer;
import java.nio.charset.StandardCharsets;

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
int BASE_PACKET_LENGTH_PLUS_CRC = 13;
int MIN_PACKET_LENGTH_MINUS_MAGIC_WORD = 15;
int MIN_TOTAL_PACKET_LENGTH = 23;
int MAX_FIRMWARE_DATA_IN_SINGLE_PACKET = 19995;
int MAX_PACKET_SIZE = 20019;
int NUM_WELLS = 24;
int NUM_SENSORS = 3;
int NUM_AXES = 3;
String[] wellNames = {"A1", "A2", "A3", "A4", "A5", "A6", 
  "B1", "B2", "B3", "B4", "B5", "B6", 
  "C1", "C2", "C3", "C4", "C5", "C6", 
  "D1", "D2", "D3", "D4", "D5", "D6"};
String[] sensorNames = {"S1", "S2", "S3"};
String[] axesNames = {"X", "Y", "Z"};
String[] statusConversions = {"Good", "Open", "Error"};

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
boolean magnetometerScheduleIsRunning = false;
boolean magnetometerScheduleComplete = false;
Checksum crc32 = new CRC32();

Packet IAmHerePacket = new Packet();
byte[] IAmHereConverted;

int numMessagesOut = 0;
int numMessagesIn = 0;

long nanoStart;
int start;
int stop;

public ControlP5 cp5;  
public JSONObject settingsJSON;
public String topSketchPath = "";

MagPageControllers thisMagPageControllers;
StimPageControllers thisStimPageControllers;
HomePageControllers thisHomePageControllers;
SensorPageControllers thisSensorPageControllers;

public void setup() {
  size(1000, 600);  
  frameRate(60);
  cp5 = new ControlP5(this);
  topSketchPath = sketchPath();
  settingsJSON = loadJSONObject(topSketchPath+"/config/config.json");
  
  thisHomePageControllers = new HomePageControllers(this);
  
  thisSensorPageControllers = new SensorPageControllers(this);
  
  thisMagPageControllers = new MagPageControllers(this);
  
  thisStimPageControllers = new StimPageControllers(this);
  
  c = Calendar.getInstance(TimeZone.getTimeZone("PST"));
  logLog = createWriter(String.format("./log/%04d-%02d-%02d_%02d-%02d-%02d_log.txt", c.get(Calendar.YEAR), c.get(Calendar.MONTH)+1, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE), c.get(Calendar.SECOND))); 
  
  nanoStart = System.nanoTime();
  start = millis();
  
  String[] serialPorts = Serial.list();
  if (serialPorts.length == 0){
    thisHomePageControllers.logDisplay.append("No serial port found\n");
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
    thisHomePageControllers.logDisplay.append("Connected to Mantarray\n");
    logLog.println("Connected to Mantarray");
    println("Connected to Mantarray");
    Packet newFetchMetadataPacket = new Packet();
    byte[] newFetchMetadataPacketConverted = newFetchMetadataPacket.FetchMetadata();
    serialPort.write(newFetchMetadataPacketConverted);
  } else {
    noBeacon = true;
    thisHomePageControllers.logDisplay.append("No Mantarray Detected\n");
    logLog.println("No Mantarray Detected");
    println("No Mantarray Detected");
  }
  thisHomePageControllers.logDisplay.append("Setup Complete\n");
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
    thisStimPageControllers.PulsePlotter (pulse, thisStimPageControllers);
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

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

Serial serialPort;

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

int MIN_PACKET_LENGTH = 16;
byte[] MAGIC_WORD = new byte[]{67, 85, 82, 73, 32, 66, 73, 79};

List<Packet> packetList = new ArrayList<Packet>();
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

public void setup() {
  size(400, 400);  
  frameRate(60);
  cp5 = new ControlP5(this);
  loadFirmwareButton = cp5.addButton("loadFirmwareButton")
    .setPosition(100, 100)
    .setSize(200, 200);
  loadFirmwareButton.getCaptionLabel().setText("Load Firmware").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);
  
  String serialPortName = Serial.list() [0] ; //"/dev/tty.usbmodem1411";
  serialPort = new Serial(this, serialPortName, 4000000);
  thread("readPackets");
  start = millis();
  nanoStart = System.nanoTime();
  IAmHerePacket.IAmHere();
  IAmHereConverted = IAmHerePacket.toByte();
}



public void draw() {
  long temp = ((System.nanoTime() - nanoStart)/1000);
  if (temp - IAmHerePacket.timeStamp > 5000000)
  {
    IAmHerePacket.IAmHere();
    IAmHereConverted = IAmHerePacket.toByte();
    serialPort.write(IAmHereConverted);
    numMessagesOut++;
    println(String.format("Handshake %d Sent:", numMessagesOut));
  }
    
  if(numMessagesOut == 10000){
    stop = millis();
    delay(2000);
    println(String.format("Elapsed time: %d seconds", (stop - start)/1000));
    println(String.format("Num packets sent out: %d", numMessagesOut));
    println(String.format("Num packets received: %d", numMessagesIn));
    if (numMessagesOut == numMessagesIn){
      println("Test succeeded!!!");
    }
    noLoop();
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
  }
}

import processing.serial.*;
import java.util.Arrays;
import java.nio.charset.StandardCharsets;

Serial serialPort;
PrintWriter dataLog;
int start;
int stop;
int now;

public void setup() {
  serialPort = new Serial(this, Serial.list()[0], 1000000); //<>//
  dataLog = createWriter("testData.txt");
  start = millis();
  stop = 300000;
  serialPort.readBytes();
}


public void draw() {
  now = millis();
  if (now - start > stop){
    dataLog.flush();
    dataLog.close();
    exit();
  }
  byte bulkReading[] = serialPort.readBytes();
  if (bulkReading != null){
    dataLog.print(Arrays.toString(bulkReading).replace("[", "").replace("]", "") + ", ");
  }
  delay(10);
}

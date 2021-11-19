void readPackets(){
  println("Beginning to read from serial port");
  logLog.println("Beginning to read from serial port");
  List<Byte> aggregate = new ArrayList<Byte>();
  int magicWordContent = 0;
  int scanner = 0;
  serialPort.readBytes();
  while(runReadThread){
    while (aggregate.size() < BASE_PACKET_LENGTH){ //There is a slight delay built into this loop so that it can operate in a psuedo-sleep mode so this thread will not take up resources when not needed
      aggregate = performReading(aggregate);
    }
    
    scanner = 0;
    magicWordContent = 0;
    while(aggregate.size() - scanner > 2) //Make sure there are at least 2 more bytes to read packet length after detecting a magic word
    {
      //print( " ", byte2uint(aggregate.get(scanner)));
      if (byte2uint(aggregate.get(scanner))==MAGIC_WORD[magicWordContent]){ //If the next character in the magic word is detected, keep track of that
        scanner++;
        magicWordContent++;
      }
      else 
      {
        //This is no good, it means there is either noise on the line or it dropped a packet because a byte that doesn't belong to a magic word has been detected
        //Either way, it means trouble.  Keep track of when this happens.
        aggregate.subList(0,scanner+1).clear();
        magicWordContent = 0;
        scanner = 0;
        println("Dropped bytes, there may be an issue");
      }
      if (magicWordContent==8){ //If an entire magic word has been detected, parse it
        Parse(aggregate, scanner);
        scanner = 0;
        magicWordContent = 0;
      } //if (magicWordContent==8)
    } //(aggregate.size() - scanner > 2)
  } //while(true)
}

void test(){
  
}

void Parse (List <Byte> thisAggregate, int thisScanner)
{
  int thisPacketLength = byte2uint(thisAggregate.get(thisScanner));
  //print( " ", byte2long(aggregate.get(index)));
  thisScanner++;
  thisPacketLength += 256*byte2uint(thisAggregate.get(thisScanner));
  //print( " ", byte2long(aggregate.get(index)));
  thisScanner++;
  while (thisAggregate.size() < thisPacketLength + PRE_PACKET_LENGTH){ //Wait around until the rest of the bytes show up
    thisAggregate = performReading(thisAggregate);
  }        
  
  Packet newPacket = new Packet();
  newPacket.timeStamp = 0;
  for (int j = 0; j < TIMESTAMP_LENGTH; j++){
    newPacket.timeStamp+=(long)Math.pow(256,j)*byte2long(thisAggregate.get(thisScanner));
    //print( " ", byte2long(aggregate.get(index)));
    thisScanner++;
  }
  newPacket.packetLength = thisPacketLength;
  newPacket.moduleID = byte2uint(thisAggregate.get(thisScanner));
  //print( " ", byte2long(aggregate.get(index)));
  thisScanner++;
  newPacket.packetType = byte2uint(thisAggregate.get(thisScanner));
  //print( " ", byte2long(aggregate.get(index)));
  thisScanner++;
  newPacket.data = new ArrayList<Byte>(thisAggregate.subList(thisScanner, thisScanner + thisPacketLength - BASE_PACKET_LENGTH_PLUS_CRC));
  thisScanner += thisPacketLength - BASE_PACKET_LENGTH_PLUS_CRC;
  newPacket.CRC = 0;
  for (int j = 0; j < CRC_LENGTH; j++){
    newPacket.CRC+=(long)Math.pow(256,j)*byte2long(thisAggregate.get(thisScanner));
    //print( " ", byte2long(aggregate.get(index)));
    thisScanner++;
  }
  packetList.add(newPacket);

  if (newPacket.packetType==1)
  {
    PrintDataToFile(newPacket.data);
  }
  else
  {
    logLog.print(String.format("%d %d %d %d ", newPacket.packetLength, newPacket.timeStamp, newPacket.moduleID, newPacket.packetType));
    print(String.format("%d %d %d %d ", newPacket.packetLength, newPacket.timeStamp, newPacket.moduleID, newPacket.packetType));
    logLog.print(newPacket.data);
    print(newPacket.data);
    logLog.println();
    println();
    switch (newPacket.packetType){
    case 0:
      //logDisplay.append("Beacon Recieved\n");
      logLog.println("Beacon Recieved");
      beaconRecieved = true;
      break;
    case 4:
      //logDisplay.append("Command Response Recieved\n");
      logLog.println("Command Response Recieved");
      break;
    }
  }
  
  thisAggregate.subList(0,thisScanner).clear();
}

void PrintDataToFile(List<Byte> thisPacketData){
  try
  {
    int packetScanner = 0;
    long initialTimestamp = byte2uint(thisPacketData.get(packetScanner)) + 
                            (byte2uint(thisPacketData.get(packetScanner + 1))<<8) + 
                            (byte2uint(thisPacketData.get(packetScanner + 2))<<16) + 
                            (byte2uint(thisPacketData.get(packetScanner + 3))<<24) + 
                            (byte2uint(thisPacketData.get(packetScanner + 4))<<32);
    packetScanner+=8;
    List<Long> dataList = new ArrayList<Long>();
    for (int wellNum = 0; wellNum < NUM_WELLS; wellNum++){
      for (int sensorNum = 0; sensorNum < NUM_SENSORS; sensorNum++){
        if (magnetometerConfigurationArray.get(wellNum).get(sensorNum).contains(1))
        {
          dataList.add(initialTimestamp - (byte2uint(thisPacketData.get(packetScanner)) + (byte2uint(thisPacketData.get(packetScanner + 1))<<8)));
          packetScanner+=2;
          for (int axisNum = 0; axisNum < NUM_AXES; axisNum++){
            if (magnetometerConfigurationArray.get(wellNum).get(sensorNum).get(axisNum) == 1)
            {
              dataList.add((long)(byte2uint(thisPacketData.get(packetScanner)) + (byte2uint(thisPacketData.get(packetScanner + 1))<<8)));
              packetScanner+=2;
            }
          }
        }
      }
    }
    dataLog.print(Arrays.toString(dataList.toArray()).replace("[", "").replace("]", ""));
    dataLog.println();
    //print(thisPacketData);
    //println();
  }
  catch (Exception E)
  {
    println("Error parsing magnetometer data");
    println(E);
    logLog.print("Error parsing magnetometer data");
  }
}
    
List <Byte> performReading(List <Byte> aggregate){
  if (serialPort.available() > 0){
    byte bulkReading[] = serialPort.readBytes();
    List<Byte> bulkReadingAsList = Bytes.asList(bulkReading);
    aggregate.addAll(bulkReadingAsList);
  }
  delay(1);
  return aggregate;
}

void LoadChannelFirmware(File firmwareFile) {
  try {
    InputStream fileReader = new FileInputStream(firmwareFile);
    List<byte[]> firmwareBytes = new ArrayList<byte[]>();
    
    long fileSize = firmwareFile.length(); //<>// //<>// //<>// //<>//
    int numFullPackets = (int)fileSize / MAX_DATA_SIZE;
    int remainderBytes = (int)fileSize % MAX_DATA_SIZE;
    
    for (int i = 0; i < numFullPackets; i++){
      byte[] buffer = new byte[MAX_DATA_SIZE];
      fileReader.read(buffer);
      firmwareBytes.add(buffer);
    }
    
    byte[] buffer = new byte[remainderBytes];
    fileReader.read(buffer);
    firmwareBytes.add(buffer);
    
    fileReader.close();
    thisHomePageControllers.logDisplay.append("Channel firmware file opened successfully\n");
    logLog.println("Channel firmware file opened successfully");
  
    Packet packetBegin = new Packet();
    packetBegin.FirmwareUpdateBegin((int)fileSize, 1);
    byte[] packetBeginConverted = packetBegin.toByte();
    serialPort.write(packetBeginConverted);
    thisHomePageControllers.logDisplay.append("Beginning channel firmware update\n");
    logLog.println("Beginning channel firmware update");  
    
    for (int i = 0; i < firmwareBytes.size(); i++){
      Packet data = new Packet();
      data.FirmwareUpdate(firmwareBytes.get(i), i);
      byte[] thisPacketConverted = data.toByte();
      serialPort.write(thisPacketConverted);
      thisHomePageControllers.logDisplay.append(String.format("Firmware packet %d sent\n", i+1));
      logLog.println(String.format("Firmware packet %d sent", i+1));    
      delay(2000);
    }
    
    Packet packetEnd = new Packet();
    packetEnd.FirmwareUpdateEnd(123123123);
    byte[] packetEndConverted = packetEnd.toByte();
    serialPort.write(packetEndConverted);
    thisHomePageControllers.logDisplay.append("New channel firmware finished sending to Mantarray\n");
    logLog.println("New channel firmware finished sending to Mantarray");  
    
  } catch (Exception e){
    println("File Not Found");
  }
}

void LoadMainFirmware(File firmwareFile) {
  try {
    InputStream fileReader = new FileInputStream(firmwareFile);
    List<byte[]> firmwareBytes = new ArrayList<byte[]>();
    
    long fileSize = firmwareFile.length(); //<>// //<>//
    int numFullPackets = (int)fileSize / MAX_DATA_SIZE;
    int remainderBytes = (int)fileSize % MAX_DATA_SIZE;
    
    for (int i = 0; i < numFullPackets; i++){
      byte[] buffer = new byte[MAX_DATA_SIZE];
      fileReader.read(buffer);
      firmwareBytes.add(buffer);
    }
    
    byte[] buffer = new byte[remainderBytes];
    fileReader.read(buffer);
    firmwareBytes.add(buffer);
    
    fileReader.close();
    thisHomePageControllers.logDisplay.append("Main firmware file opened successfully\n");
    logLog.println("Main firmware file opened successfully");
  
    Packet packetBegin = new Packet();
    packetBegin.FirmwareUpdateBegin((int)fileSize, 0);
    byte[] packetBeginConverted = packetBegin.toByte();
    serialPort.write(packetBeginConverted);
    thisHomePageControllers.logDisplay.append("Beginning main firmware update\n");
    logLog.println("Beginning main firmware update");  
    
    for (int i = 0; i < firmwareBytes.size(); i++){
      Packet data = new Packet();
      data.FirmwareUpdate(firmwareBytes.get(i), i);
      byte[] thisPacketConverted = data.toByte();
      serialPort.write(thisPacketConverted);
      thisHomePageControllers.logDisplay.append(String.format("Firmware packet %d sent\n", i+1));
      logLog.println(String.format("Firmware packet %d sent", i+1));    
      delay(25);
    }
    
    Packet packetEnd = new Packet();
    packetEnd.FirmwareUpdateEnd(123123123);
    byte[] packetEndConverted = packetEnd.toByte();
    serialPort.write(packetEndConverted);
    thisHomePageControllers.logDisplay.append("New main firmware finished sending to Mantarray\n");
    logLog.println("New main firmware finished sending to Mantarray");  
    
  } catch (Exception e){
    println("File Not Found");
  }
}

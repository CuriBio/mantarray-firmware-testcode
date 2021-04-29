void readPackets(){
  println("Thread started");
  List<Byte> aggregate = new ArrayList<Byte>();
  int magicWordContent = 0;
  int scanner = 0;
  serialPort.readBytes();
  while(true){
    while (aggregate.size() < BASE_PACKET_LENGTH){ //There is a slight delay built into this loop so that it can operate in a psuedo-sleep mode so this thread will not take up resources when not needed
      aggregate = performReading(aggregate);
    }
    
    scanner = 0;
    magicWordContent = 0;
    while(aggregate.size() - scanner > 2) //Make sure there are at least 2 more bytes to read packet length after detecting a magic word
    {
      if (byte2uint(aggregate.get(scanner))==MAGIC_WORD[magicWordContent]){ //If the next character in the magic word is detected, keep track of that
        //print( " ", byte2long(aggregate.get(i)));
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
  if (thisScanner > 226)
  {
    print(thisAggregate);
  }
  newPacket.data = new ArrayList<Byte>(thisAggregate.subList(thisScanner, thisScanner + thisPacketLength - BASE_PACKET_LENGTH_PLUS_CRC));
  thisScanner += thisPacketLength - BASE_PACKET_LENGTH_PLUS_CRC;
  newPacket.CRC = 0;
  for (int j = 0; j < CRC_LENGTH; j++){
    newPacket.CRC+=(long)Math.pow(256,j)*byte2long(thisAggregate.get(thisScanner));
    //print( " ", byte2long(aggregate.get(index)));
    thisScanner++;
  }
  packetList.add(newPacket);
  if (newPacket.packetLength==26){
    numMessagesIn++;
  }
  println(String.format("%d %d %d %d ", newPacket.packetLength, newPacket.timeStamp, newPacket.moduleID, newPacket.packetType));
  if (newPacket.packetType==4){
    long returnTimestamp = 0;
    for (int j = 0; j < TIMESTAMP_LENGTH; j++){
      returnTimestamp+=(long)Math.pow(256,j)*byte2long(newPacket.data.get(j));
    }
    print(String.format("%d ", returnTimestamp));
    for (int j = 0; j < newPacket.data.size()-8; j++){
      print(String.format("%d ", newPacket.data.get(j+8)));
    }
  } else {
    //println(newPacket.data);
  }
  thisAggregate.subList(0,thisScanner).clear();
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

void LoadFirmware(File firmwareFile) {
  try {
    InputStream fileReader = new FileInputStream(firmwareFile);
    List<byte[]> firmwareBytes = new ArrayList<byte[]>();
    
    long fileSize = firmwareFile.length();
    int numFullPackets = (int)fileSize / 65532;
    int remainderBytes = (int)fileSize % 65532;
    
    for (int i = 0; i < numFullPackets; i++){
      byte[] buffer = new byte[65532];
      fileReader.read(buffer);
      firmwareBytes.add(buffer);
    }
    
    byte[] buffer = new byte[remainderBytes];
    fileReader.read(buffer);
    firmwareBytes.add(buffer);
    
    fileReader.close();
    
    Packet packetBegin = new Packet();
    packetBegin.ChannelFirmwareUpdateBegin(numFullPackets + 1, (int)fileSize);
    byte[] packetBeginConverted = packetBegin.toByte();
    serialPort.write(packetBeginConverted);
    
    for (int i = 0; i < firmwareBytes.size(); i++){
      Packet data = new Packet();
      data.ChannelFirmwareUpdate(firmwareBytes.get(i));
      byte[] thisPacketConverted = data.toByte();
      serialPort.write(thisPacketConverted);
    }
    
    Packet packetEnd = new Packet();
    packetEnd.ChannelFirmwareUpdateEnd(123123123);
    byte[] packetEndConverted = packetEnd.toByte();
    serialPort.write(packetEndConverted);
    
  } catch (Exception e){
    println("File Not Found");
  }
}

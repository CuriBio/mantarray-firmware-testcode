void readPackets(){
  println("Thread started");
  List<Byte> aggregate = new ArrayList<Byte>();
  int magicWordContent = 0;
  while(true){
    while (aggregate.size() < MIN_TOTAL_PACKET_LENGTH){
      delay(1);
      aggregate = performReading(aggregate);
    }

    magicWordContent = 0;
    for (int i = 0; i < MAGIC_WORD_LENGTH; i++){
      if (byte2uint(aggregate.get(i))==MAGIC_WORD[magicWordContent]){
        //print( " ", byte2long(aggregate.get(i)));
        magicWordContent++;
      } else {
        magicWordContent = 0;
        aggregate.subList(0,i).clear();
        break;
      }
      if (magicWordContent==8){
        int index = magicWordContent;
        int thisPacketLength = byte2uint(aggregate.get(index));
        //print( " ", byte2long(aggregate.get(index)));
        index++;
        thisPacketLength += 256*byte2uint(aggregate.get(index));
        //print( " ", byte2long(aggregate.get(index)));
        index++;
        while (aggregate.size() < thisPacketLength + PRE_PACKET_LENGTH){
          aggregate = performReading(aggregate);
        }        
        
        Packet newPacket = new Packet();
        newPacket.timeStamp = 0;
        for (int j = 0; j < TIMESTAMP_LENGTH; j++){
          newPacket.timeStamp+=(long)Math.pow(256,j)*byte2long(aggregate.get(index));
          //print( " ", byte2long(aggregate.get(index)));
          index++;
        }
        newPacket.packetLength = thisPacketLength;
        newPacket.moduleID = byte2uint(aggregate.get(index));
        //print( " ", byte2long(aggregate.get(index)));
        index++;
        newPacket.packetType = byte2uint(aggregate.get(index));
        //print( " ", byte2long(aggregate.get(index)));
        index++;
        newPacket.data = new ArrayList<Byte>();
        for (int j = 0; j < thisPacketLength - BASE_PACKET_LENGTH_PLUS_CRC; j++){
          newPacket.data.add(aggregate.get(index));
          //print( " ", byte2long(aggregate.get(index)));
          index++;
        }
        newPacket.CRC = 0;
        for (int j = 0; j < CRC_LENGTH; j++){
          newPacket.CRC+=(long)Math.pow(256,j)*byte2long(aggregate.get(index));
          //print( " ", byte2long(aggregate.get(index)));
          index++;
        }
        packetList.add(newPacket);
        if (newPacket.packetLength==26){
          numMessagesIn++;
        }
        //println();
        print(String.format("%d %d %d %d ", newPacket.packetLength, newPacket.timeStamp, newPacket.moduleID, newPacket.packetType));
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
          for (int j = 0; j < newPacket.data.size(); j++){
            print(String.format("%d ", newPacket.data.get(j)));
          }
        }
        println(String.format("%d", newPacket.CRC));
        
        aggregate.subList(0,index).clear();
        
        //CRC not implemented, but now would be the time to do another check to see if the CRC is intact
      }
    }
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

class Packet{
  byte[] MAGIC_WORD = new byte[]{67, 85, 82, 73, 32, 66, 73, 79};
  long timeStamp;
  int moduleID;
  int packetType;
  int packetLength;
  long CRC;
  List<Byte> data;
  
  
  //int TIData;
  //int STX;
  //int STY;
  //int STZ;
  
  Packet(){
    
  }

  void IAmHere(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 4;
    this.packetLength = 14;
    this.CRC = 123123123;
  }
  
  void ChannelFirmwareUpdateBegin(int howManyFirmwarePackets, int totalNumberOfBytes){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 0;
    this.packetLength = 19;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(9);
    this.data.add(uint2byte(howManyFirmwarePackets));
    for (int i = 0; i < 4; i++){
      this.data.add(uint2byte((int)(totalNumberOfBytes>>(8*i) & 0x000000ff)));
    }
  }
  
  void ChannelFirmwareUpdate(byte[] firmware){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 1;
    this.packetLength = firmware.length + 14;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(firmware.length + 4);
    for (int i = 0; i < firmware.length; i++){
      this.data.add(firmware[i]);
    }
  }
  
  void ChannelFirmwareUpdateEnd(int firmwareCRC){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 2;
    this.packetLength = 18;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(8);
    for (int i = 0; i < 4; i++){
      this.data.add(uint2byte((int)(firmwareCRC>>(8*i) & 0x000000ff)));
    }
  }
  
  byte[] MagnetometerConfiguration(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 3;
    this.packetLength = 89;
    this.CRC = 123123123;
    this.data = magConfigurationByteArray;
    this.data.add(0, (byte)1);
    return this.toByte();
  }
  
  byte[] MagnetometerDataCaptureBegin(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 3;
    this.packetLength = 15;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(1);
    this.data.add((byte)2);
    return this.toByte();
  }
  
  byte[] MagnetometerDataCaptureEnd(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.moduleID = 0;
    this.packetType = 3;
    this.packetLength = 15;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(1);
    this.data.add((byte)3);
    return this.toByte();
  }
  
  byte[] testPacket(int i){
        this.timeStamp = (System.nanoTime() - nanoStart)/1000;
        this.moduleID = 0;
        this.packetType = 3;
        this.packetLength = 15;
        this.CRC = 123123123;
        this.data = magConfigurationByteArray;
        this.data.add(0, (byte)i);
        return this.toByte();
  }
  
  byte[] toByte(){
    int arrayLength = this.packetLength + 10;
    byte[] thisByteArray = new byte[arrayLength];
    for (int i = 0; i < 8; i++){
      thisByteArray[i] = this.MAGIC_WORD[i];
    }
    
    int byteArrayIndex = 8;
    thisByteArray[byteArrayIndex] = uint2byte(this.packetLength & 0x00ff);
    byteArrayIndex++;
    thisByteArray[byteArrayIndex] = uint2byte(this.packetLength>>8 & 0x00ff);
    byteArrayIndex++;
    int thisByte = 0;
    for (int i = 0; i < 8; i++){
      thisByte = (int)(this.timeStamp>>(8*i) & 0x00000000000000ff);
      thisByteArray[byteArrayIndex] = uint2byte(thisByte);
      byteArrayIndex++;
    }
    thisByteArray[byteArrayIndex] = uint2byte(this.moduleID);
    byteArrayIndex++;
    thisByteArray[byteArrayIndex] = uint2byte(this.packetType);
    byteArrayIndex++;
    for (int i = 0; i < packetLength - 14; i++){
      thisByteArray[byteArrayIndex] = this.data.get(i);
      //thisByteArray[byteArrayIndex] = uint2byte(thisByte);
      byteArrayIndex++;
    }
    for (int i = 0; i < 4; i++){
      thisByte = (int)(this.CRC>>(8*i) & 0x000000ff);
      thisByteArray[byteArrayIndex] = uint2byte(thisByte);
      byteArrayIndex++;
    }
    
    //For more verbose output, uncomment these lines
    /*
    for (int i = 0; i < arrayLength-1;i++){
      print(String.format("%d ", thisByteArray[i]));
    }
    println(String.format("%d ", thisByteArray[arrayLength-1]));
    */
    return thisByteArray;
  }
}

byte uint2byte(int thisByte){
  if (thisByte > 127){
    thisByte -= 256;
  }
  return (byte)thisByte;
}

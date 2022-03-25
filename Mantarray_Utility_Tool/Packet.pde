class Packet{
  byte[] MAGIC_WORD = new byte[]{67, 85, 82, 73, 32, 66, 73, 79};
  long timeStamp;
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

  byte[] IAmHere(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 4;
    this.packetLength = 13;
    this.CRC = 123123123;
    return this.toByte();
  }
  
  void FirmwareUpdateBegin(int totalNumberOfBytes, int whichFirmware){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 70;
    this.packetLength = 21;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(12);
    this.data.add((byte)whichFirmware);
    if (whichFirmware == 0){
      this.data.add((byte)uint2byte(Integer.valueOf(thisHomePageControllers.mainMajorVersion.getText())));
      this.data.add((byte)uint2byte(Integer.valueOf(thisHomePageControllers.mainMinorVersion.getText())));
      this.data.add((byte)uint2byte(Integer.valueOf(thisHomePageControllers.mainRevisionVersion.getText())));
    } else {
      this.data.add((byte)uint2byte(Integer.valueOf(thisHomePageControllers.channelMajorVersion.getText())));
      this.data.add((byte)uint2byte(Integer.valueOf(thisHomePageControllers.channelMinorVersion.getText())));
      this.data.add((byte)uint2byte(Integer.valueOf(thisHomePageControllers.channelRevisionVersion.getText())));
    }
    for (int i = 0; i < 4; i++){
      this.data.add(uint2byte((int)(totalNumberOfBytes>>(8*i) & 0x000000ff)));
    }
  }
  
  void FirmwareUpdate(byte[] firmware, int packetNum){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 71;
    this.packetLength = firmware.length + 14;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(firmware.length + 5);
    this.data.add((byte) packetNum);
    for (int i = 0; i < firmware.length; i++){
      this.data.add(firmware[i]);
    }
  }
  
  void FirmwareUpdateEnd(int firmwareCRC){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 72;
    this.packetLength = 17;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(8);
    for (int i = 0; i < 4; i++){
      this.data.add(uint2byte((int)(firmwareCRC>>(8*i) & 0x000000ff)));
    }
  }
  
  byte[] MagnetometerConfiguration(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 50;
    //HARDWARE TEST uncomment this line if you want to use set/reset commands
    //Make sure the configuration generator is changed in MagPageControllers.pde and the input parser is updated in Communicator.c
    //this.packetLength = 90;
    this.packetLength = 15;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>(6);
    int samplingRate = (Integer.valueOf(thisHomePageControllers.setSensorRateField.getText()))*1000;
    this.data.add(0, uint2byte((samplingRate>>8) & 0x000000ff));
    this.data.add(0, uint2byte(samplingRate & 0x000000ff));
    return this.toByte();
  }
  
  byte[] MagnetometerDataCaptureBegin(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 52;
    this.packetLength = 13;
    this.CRC = 123123123;
    return this.toByte();
  }
  
  byte[] MagnetometerDataCaptureEnd(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 53;
    this.packetLength = 13;
    this.CRC = 123123123;
    return this.toByte();
  }
  
  byte[] StimulatorBegin(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 25;
    this.packetLength = 13;
    this.CRC = 123123123;
    return this.toByte();
  }
  
  byte[] StimulatorEnd(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 26;
    this.packetLength = 13;
    this.CRC = 123123123;
    return this.toByte();
  }
  
  byte[] I2CCommand(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 100;
    this.packetLength = 15; //<>//
    this.CRC = 123123123; //<>// //<>//
    this.data = new ArrayList<Byte>();
    this.data.add(0, Byte.valueOf(thisHomePageControllers.I2CAddressField.getText()));
    this.data.add(1, uint2byte(Integer.valueOf(thisHomePageControllers.I2CInputField.getText())));
    return this.toByte();
  }
  
  byte[] I2CAddressNew(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 101;
    this.packetLength = 15;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>();
    this.data.add(0, Byte.valueOf(thisHomePageControllers.I2CSetAddressOld.getText()));
    this.data.add(1, Byte.valueOf(thisHomePageControllers.I2CSetAddressNew.getText()));
    return this.toByte();
  }
   //<>//
  byte[] sensorConfig(JSONObject settingsJSON){ //<>//
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 102;
    this.packetLength = 17;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>();
    this.data.add(0, uint2byte(Integer.valueOf(settingsJSON.getString("Internal_Control_0"), 2)));
    this.data.add(1, uint2byte(Integer.valueOf(settingsJSON.getString("Internal_Control_1"), 2)));
    this.data.add(2, uint2byte(Integer.valueOf(settingsJSON.getString("Internal_Control_2"), 2)));
    this.data.add(3, uint2byte(Integer.valueOf(settingsJSON.getString("Internal_Control_3"), 2)));
    return this.toByte();
  }
  
  byte[] StimulatorConfiguration(List<Byte> timeAmplitudePairs, byte stimulationMode){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 24;
    this.packetLength = 39;
    this.CRC = 123123123;
    this.data = timeAmplitudePairs;
    this.data.add(0, stimulationMode);
    return this.toByte();
  }
  
  byte[] FetchMetadata(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 60;
    this.packetLength = 13;
    this.CRC = 123123123;
    return this.toByte();
  }
  
  byte[] SetSerialNumber(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 61;
    this.packetLength = 25;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>();
    String thisString = thisHomePageControllers.setDeviceSerialNumberField.getText();
    byte[] thisByteArray = thisString.getBytes(StandardCharsets.US_ASCII);
    List<Byte> thisByteArrayList = Bytes.asList(thisByteArray);
    this.data.addAll(thisByteArrayList);
    return this.toByte();
  }
  
  byte[] SetNickname(){
    this.timeStamp = (System.nanoTime() - nanoStart)/1000;
    this.packetType = 62;
    this.packetLength = 26;
    this.CRC = 123123123;
    this.data = new ArrayList<Byte>();
    String thisString = thisHomePageControllers.setDeviceNicknameField.getText();
    byte[] thisByteArray = thisString.getBytes(StandardCharsets.US_ASCII);
    List<Byte> thisByteArrayList = Bytes.asList(thisByteArray);
    this.data.addAll(thisByteArrayList);
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
    thisByteArray[byteArrayIndex] = uint2byte(this.packetType);
    byteArrayIndex++;
    for (int i = 0; i < packetLength - 13; i++){
      thisByteArray[byteArrayIndex] = this.data.get(i);
      byteArrayIndex++;
    }
    for (int i = 0; i < 4; i++){
      thisByte = (int)(this.CRC>>(8*i) & 0x000000ff);
      thisByteArray[byteArrayIndex] = uint2byte(thisByte);
      byteArrayIndex++;
    }
    
    return thisByteArray;
  }
}

byte uint2byte(int thisByte){
  if (thisByte > 127){
    thisByte -= 256;
  }
  return (byte)thisByte;
}

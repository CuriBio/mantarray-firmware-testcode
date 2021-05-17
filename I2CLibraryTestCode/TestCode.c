//>>Communicator.c
//void StartParseInput(void *argument)
    //switch(ph_this_communicator->h_parse_input_state)
    //case STATE_PARSE_INPUT_INTERPRET:
        //switch (incomingPacket.packetType)
        //case COMMUNICATOR_INTYPE_INSTRUCTION:
            //switch (incomingPacket.data[0])
            
            case COMMUNICATOR_COMMANDINID_TestCase1:
                osEventFlagsSet(efid_SystemEvents, FLAGS_SYSTEM_TestEvent1);
            break;
            case COMMUNICATOR_COMMANDINID_TestCase2:
                osEventFlagsSet(efid_SystemEvents, FLAGS_SYSTEM_TestEvent2);
            break;
            case COMMUNICATOR_COMMANDINID_TestCase3:
                osEventFlagsSet(efid_SystemEvents, FLAGS_SYSTEM_TestEvent3);
            break;
            case COMMUNICATOR_COMMANDINID_TestCase4:
                osEventFlagsSet(efid_SystemEvents, FLAGS_SYSTEM_TestEvent4);
            break;

    //case STATE_PARSE_INPUT_COMMAND_RESPONSE:
        //switch (incomingPacket.packetType)
        //case COMMUNICATOR_INTYPE_INSTRUCTION:
            //switch (incomingPacket.data[0])

            case COMMUNICATOR_COMMANDINID_TestCase1:
                p_producer_address->packetLength = COMMUNICATOR_LENGTH_COMMAND_RESPONSE + 1;
                p_producer_address->data[TIMESTAMP_LENGTH] = 5;
            break;
            //switch (incomingPacket.data[0])------------------------------------------------------------------------
            case COMMUNICATOR_COMMANDINID_TestCase2:
                p_producer_address->packetLength = COMMUNICATOR_LENGTH_COMMAND_RESPONSE + 1;
                p_producer_address->data[TIMESTAMP_LENGTH] = 6;
            break;
            //switch (incomingPacket.data[0])------------------------------------------------------------------------
            case COMMUNICATOR_COMMANDINID_TestCase3:
                p_producer_address->packetLength = COMMUNICATOR_LENGTH_COMMAND_RESPONSE + 1;
                p_producer_address->data[TIMESTAMP_LENGTH] = 7;
            break;
            //switch (incomingPacket.data[0])------------------------------------------------------------------------
            case COMMUNICATOR_COMMANDINID_TestCase4:
                p_producer_address->packetLength = COMMUNICATOR_LENGTH_COMMAND_RESPONSE + 1;
                p_producer_address->data[TIMESTAMP_LENGTH] = 8;
            break;

//>>Communicaotr.h
//Test command ID's
#define COMMUNICATOR_COMMANDINID_TestCase1				0x0A
#define COMMUNICATOR_COMMANDINID_TestCase2	     		0x0B
#define COMMUNICATOR_COMMANDINID_TestCase3		    	0x0C
#define COMMUNICATOR_COMMANDINID_TestCase4		    	0x0D

//>>system.c
//void StartSystem(void *argument)
    //switch(MantarraySystem.state)
    //case MANTARRAY_SYSTEM_STATUS_IDLE:
        //Test code for testing I2C boot low command
        if (osEventFlagsGet(efid_SystemEvents) & FLAGS_SYSTEM_TestEvent1)
        {
            I2C_command(100, I2C_COMMAND_BOOTLOW);
            osEventFlagsClear(efid_SystemEvents, FLAGS_SYSTEM_TestEvent1);
        }
        //Test code for testing I2C boot high command
        if (osEventFlagsGet(efid_SystemEvents) & FLAGS_SYSTEM_TestEvent2)
        {
            I2C_command(100, I2C_COMMAND_BOOTHIGH);
            osEventFlagsClear(efid_SystemEvents, FLAGS_SYSTEM_TestEvent2);
        }
        //Test code for testing I2C reset low command
        if (osEventFlagsGet(efid_SystemEvents) & FLAGS_SYSTEM_TestEvent3)
        {
            I2C_command(100, I2C_COMMAND_RESETLOW);
            osEventFlagsClear(efid_SystemEvents, FLAGS_SYSTEM_TestEvent3);
        }
        //Test code for testing I2C reset high command
        if (osEventFlagsGet(efid_SystemEvents) & FLAGS_SYSTEM_TestEvent4)
        {
            I2C_command(100, I2C_COMMAND_RESETHIGH);
            osEventFlagsClear(efid_SystemEvents, FLAGS_SYSTEM_TestEvent4);
        }

//>>system.h
#define FLAGS_SYSTEM_TestEvent1             0x00010000
#define FLAGS_SYSTEM_TestEvent2             0x00020000
#define FLAGS_SYSTEM_TestEvent3             0x00040000
#define FLAGS_SYSTEM_TestEvent4             0x00080000
#define FLAGS_SYSTEM_ALL_Commands	FLAGS_SYSTEM_Reboot | FLAGS_SYSTEM_MagConfig | FLAGS_SYSTEM_MagStreamOn |\
									FLAGS_SYSTEM_MagStreamOff | FLAGS_SYSTEM_TempStreamOn | FLAGS_SYSTEM_TempStreamOff |\
									FLAGS_SYSTEM_Metadata | FLAGS_SYSTEM_DumpEEPROM | FLAGS_SYSTEM_RetrieveTime |\
									FLAGS_SYSTEM_SetNickname | FLAGS_SYSTEM_Write_Channel_Firmware |\
									FLAGS_SYSTEM_TestEvent1 | FLAGS_SYSTEM_TestEvent2 | FLAGS_SYSTEM_TestEvent3 | FLAGS_SYSTEM_TestEvent4

//>>Processing_Test.pde
Button testButton1;
Button testButton2;
Button testButton3;
Button testButton4;

//public void setup() {
    testButton1 = cp5.addButton("testButton1")
    .setPosition(350, 200)
    .setSize(200, 50);
    testButton1.getCaptionLabel().setText("Set Boot Low").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);

    testButton2 = cp5.addButton("testButton2")
    .setPosition(350, 270)
    .setSize(200, 50);
    testButton2.getCaptionLabel().setText("Set Boot High").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);

    testButton3 = cp5.addButton("testButton3")
    .setPosition(350, 340)
    .setSize(200, 50);
    testButton3.getCaptionLabel().setText("Set Reset Low").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);

    testButton4 = cp5.addButton("testButton4")
    .setPosition(350, 410)
    .setSize(200, 50);
    testButton4.getCaptionLabel().setText("Set Reset High").setColor(255).setFont(createFont("arial", 25)).align(CENTER, CENTER).toUpperCase(false);

//public void controlEvent(ControlEvent theEvent) {
    if (controllerName.equals("testButton1")){
        Packet testPacket1 = new Packet();
        byte[] testPacket1Converted = testPacket1.testPacket(10);
        serialPort.write(testPacket1Converted);
    }
    if (controllerName.equals("testButton2")){
        Packet testPacket2 = new Packet();
        byte[] testPacket2Converted = testPacket2.testPacket(11);
        serialPort.write(testPacket2Converted);
    }
    if (controllerName.equals("testButton3")){
        Packet testPacket3 = new Packet();
        byte[] testPacket3Converted = testPacket3.testPacket(12);
        serialPort.write(testPacket3Converted);
    }
    if (controllerName.equals("testButton4")){
        Packet testPacket4 = new Packet();
        byte[] testPacket4Converted = testPacket4.testPacket(13);
        serialPort.write(testPacket4Converted);
    }

//>>Packet.pde
//class Packet{
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
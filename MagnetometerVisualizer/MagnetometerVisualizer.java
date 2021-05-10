package MagnetometerVisualizer;
import java.util.ArrayList;
import java.util.List;

public class MagnetometerVisualizer{
  int NUM_WELLS = 24;
  int NUM_SENSORS = 3;
  int NUM_AXES = 3;
  List<List<List<Toggle>>> magSensorSelector = new ArrayList<List<List<Toggle>>>();

  void main(){
    //For all of a x-axis
    toggleBulk(NUM_WELLS, NUM_SENSORS, 1, 0, 0, 0, 1);
    //For all of a y-axis
    toggleBulk(NUM_WELLS, NUM_SENSORS, 1, 0, 0, 1, 1);
    //For all of a z-axis
    toggleBulk(NUM_WELLS, NUM_SENSORS, 1, 0, 0, 2, 1);
    //For all of a sensor 1
    toggleBulk(NUM_WELLS, 1, NUM_AXES, 0, 0, 0, 1);
    //For all of a sensor 2
    toggleBulk(NUM_WELLS, 1, NUM_AXES, 0, 1, 0, 1);
    //For all of a sensor 3
    toggleBulk(NUM_WELLS, 1, NUM_AXES, 0, 2, 0, 1);
    //For all of a row 1
    toggleBulk(6, NUM_SENSORS, NUM_AXES, 0, 0, 0, 1);
    //For all of a row 2
    toggleBulk(6, NUM_SENSORS, NUM_AXES, 6, 0, 0, 1);
    //For all of a row 3
    toggleBulk(6, NUM_SENSORS, NUM_AXES, 12, 0, 0, 1);
    //For all of a row 4
    toggleBulk(6, NUM_SENSORS, NUM_AXES, 18, 0, 0, 1);
    //For all of a col 1
    toggleBulk(4, NUM_SENSORS, NUM_AXES, 0, 0, 0, 6);
    //For all of a col 2
    toggleBulk(4, NUM_SENSORS, NUM_AXES, 1, 0, 0, 6);
    //For all of a col 3
    toggleBulk(4, NUM_SENSORS, NUM_AXES, 2, 0, 0, 6);
    //For all of a col 4
    toggleBulk(4, NUM_SENSORS, NUM_AXES, 3, 0, 0, 6);
    //For all of a col 5
    toggleBulk(4, NUM_SENSORS, NUM_AXES, 4, 0, 0, 6);
    //For all of a col 6
    toggleBulk(4, NUM_SENSORS, NUM_AXES, 5, 0, 0, 6);
  }

  void toggleBulk(int totWells, 
            int totSensors, 
            int totAxes, 
            int startWell, 
            int startSensor, 
            int startAxis,
            int wellInc){

    boolean allTrue = true;
    for (int wellNum = startWell; wellNum < totWells; wellNum+=wellInc)
    {
      for (int sensorNum = startSensor; sensorNum < totSensors; sensorNum++)
      {
        for (int axisNum = startAxis; axisNum < totAxes; axisNum++)
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
      for (int wellNum = startWell; wellNum < totWells; wellNum+=wellInc)
      {
        for (int sensorNum = startSensor; sensorNum < totSensors; sensorNum++)
        { 
          for (int axisNum = startAxis; axisNum < totAxes; axisNum++)
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
    for (int wellNum = 0; wellNum < NUM_WELLS; wellNum++)
    {
      dataConfig.add((byte)wellNum);
      int bitMask = 0;
      for (int sensorNum = 0; sensorNum < NUM_SENSORS; sensorNum++)
      { 
        for (int axisNum = 0; axisNum < NUM_AXES; axisNum++)
        { 
          bitMask += 1<<(sensorNum * NUM_SENSORS + axisNum);
        }
      }
      dataConfig.add((byte) (bitMask & 0xFF));
      dataConfig.add((byte) (bitMask & 0x100));
    }
    return dataConfig;
  }
}

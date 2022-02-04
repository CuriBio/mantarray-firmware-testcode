public class StimPageControllers implements ControlListener {
  private ControlP5 cp5;  /*!< The library filled with the variety of controllers used thorughout the tool*/
  private PApplet p;  /*!< The Processing applet that the controllers should be running on*/
  
  private float pulseFreqText;  /*!< */
  private float pulseHighAmpText;  /*!< */
  private float pulseHighDelayText;  /*!< */
  private float pulseMidDelayText;  /*!< */
  private float pulseLowAmpText;  /*!< */
  private float pulseLowDelayText;  /*!< */
  private int pulseXLimVolt;  /*!< */
  private int pulseYLimVolt;  /*!< */
  private int pulseXLimCurr;  /*!< */
  private int pulseYLimCurr;  /*!< */
  private int pulseXLim;  /*!< */
  private int pulseYLim;  /*!< */
  
  private List<Float> defaultPulseCurrent = new ArrayList<Float>();  /*!< Data Structure using an arrayList of floats to make the "default" pulse*/
  private List<Float> defaultPulseVoltage = new ArrayList<Float>();  /*!< Data Structure using an arrayList of floats to make the "default" pulse*/
  
  private ControlGroup stimWindow;
  List<Button> stimWindowButtonList = new ArrayList<Button>();
  private Textfield pulseXLimIn;  /*!< */
  private Textfield pulseYLimIn;  /*!< */
  private Textfield pulseFreq;  /*!< */
  private Button pulseFreqUp;  /*!< */
  private Button pulseFreqDown;  /*!< */
  private Textfield pulseHighAmp;  /*!< */
  private Button pulseHighAmpUp;  /*!< */
  private Button pulseHighAmpDown;  /*!< */
  private Textfield pulseHighDelay;  /*!< */
  private Button pulseHighDelayUp;  /*!< */
  private Button pulseHighDelayDown;  /*!< */
  private Textfield pulseMidDelay;  /*!< */
  private Button pulseMidDelayUp;  /*!< */
  private Button pulseMidDelayDown;  /*!< */
  private Textfield pulseLowAmp;  /*!< */
  private Button pulseLowAmpUp;  /*!< */
  private Button pulseLowAmpDown;  /*!< */
  private Textfield pulseLowDelay;  /*!< */
  private Button pulseLowDelayUp;  /*!< */
  private Button pulseLowDelayDown;  /*!< */
  
  private color constantVoltageColor = #0f0f96;  /*!< The color for constant voltage pulse plots*/
  private color constantCurrentColor = #b01010;  /*!< The color for constant current pulse plots*/
  boolean isConstantCurrent = true;
  boolean stimConfigSet = false;
  String[] stimWindowButtonNames = {"stimWindowBack", "stimWindowReset", "stimWindowSubmit", "constantSelector"};
  String[] stimWindowLabelNames = {"Back", "Reset", "Submit", "Constant Current"};
  
  int stimWindowWidth = (int)(.9 * width);
  int stimWindowTotHeight = (int)(.75 * height);
  int stimWindowHeight = (stimWindowTotHeight * 5) / 6;
  int stimWindowX = (int)(.05 * width);
  int stimWindowY = (int)(.125 * height);
  int imageSize = 17;
  int textSize = stimWindowWidth / 50;
  int textBoxWidth = textSize * 4;
  int textBoxHeight = textSize * 2;
  int edgeBuffer = 5;

  /*!
  Upon call, builds all of the controllers necessary for stimulator visualization and editing.  This package on controllers is quite large and could be split into
  generic stimulator page items and editing items, although the latter contains ~90% of all the controllers in this Class bundle. The instance of the tool's toolbar is also
  passed into this class as many of those items play a significant role in how the stimulator page is constructed
  */
  private StimPageControllers(PApplet p_){
    //sets the processing applet to be that of the main file, mantarray_utility_tool
    p = p_;                        
    if (cp5 == null) {
      cp5 = new ControlP5(p);
    }
    
    JSONObject defaultPulseVoltageJSON = settingsJSON.getJSONObject("defaultPulseVoltage");
    defaultPulseVoltage = retrievePulseFromSettings(defaultPulseVoltageJSON);
    pulseXLimVolt = int(2*(defaultPulseVoltage.get(2) + defaultPulseVoltage.get(3) + defaultPulseVoltage.get(5)));
    pulseYLimVolt = int(Math.max(defaultPulseVoltage.get(1), defaultPulseVoltage.get(4))/.8);
    
    JSONObject defaultPulseCurrentJSON = settingsJSON.getJSONObject("defaultPulseCurrent");
    defaultPulseCurrent = retrievePulseFromSettings(defaultPulseCurrentJSON);
    pulseXLimCurr = int(2*(defaultPulseCurrent.get(2) + defaultPulseCurrent.get(3) + defaultPulseCurrent.get(5)));
    pulseYLimCurr = int(Math.max(defaultPulseCurrent.get(1), defaultPulseCurrent.get(4))/.8);
  
    List<Float> initialDefaultPulse = new ArrayList<Float>();
    if (settingsJSON.getBoolean("defaultConstantVoltage")) {
      stimWindowLabelNames[3] = "Constant Voltage";
      isConstantCurrent = false;
      initialDefaultPulse = defaultPulseVoltage;
      pulseXLim = pulseXLimVolt;
      pulseYLim = pulseYLimVolt;  
    }
    else {
      initialDefaultPulse = defaultPulseCurrent;
      pulseXLim = pulseXLimCurr;
      pulseYLim = pulseYLimCurr;
    }
    pulseFreqText = initialDefaultPulse.get(0);
    pulseHighAmpText = initialDefaultPulse.get(1);
    pulseHighDelayText = initialDefaultPulse.get(2);
    pulseMidDelayText = initialDefaultPulse.get(3);
    pulseLowAmpText = initialDefaultPulse.get(4);
    pulseLowDelayText = initialDefaultPulse.get(5);
    
    stimWindow = cp5.addGroup("stimWindow")
      .setPosition(stimWindowX, stimWindowY)
      .setSize(stimWindowWidth, stimWindowTotHeight)
      .setBackgroundColor(color(255, 0))
      .hideBar()
      .hide();
      
    int numButtons = 4;
    int bottomBarWidth = (stimWindowWidth);
    int bottomBarHeight = stimWindowTotHeight / 6;
    
    int bottomBarBufferWidth = bottomBarWidth / 20;
    int bottomBarBufferHeight = bottomBarHeight / 6;
    int bottomBarButtonWidth = (bottomBarWidth - ((numButtons + 1) * bottomBarBufferWidth)) / numButtons;
    int bottomBarButtonHeight = bottomBarHeight - 2 * bottomBarBufferHeight;
    
    for (int buttonNum = 0; buttonNum < numButtons; buttonNum++){
      Button thisButton = cp5.addButton(stimWindowButtonNames[buttonNum])
      .setPosition((bottomBarBufferWidth * (buttonNum + 1)) + (bottomBarButtonWidth * buttonNum),
                   stimWindowTotHeight - bottomBarHeight + bottomBarBufferHeight)
      .setSize(bottomBarButtonWidth, bottomBarButtonHeight)
      .moveTo(stimWindow);
      thisButton.getCaptionLabel().setText(stimWindowLabelNames[buttonNum]).setColor(255).setFont(createFont("arial", stimWindowWidth/50)).align(CENTER, CENTER).toUpperCase(false);
      stimWindowButtonList.add(thisButton);
    }
    
    if (isConstantCurrent){
      stimWindowButtonList.get(3).setColorBackground(constantCurrentColor);
    } else {
      stimWindowButtonList.get(3).setColorBackground(constantVoltageColor);
    }
  
    //Pulse editor
    int pulseYAxisHeight = (3*stimWindowHeight)/8;
    int pulseXAxisLength = (5*stimWindowWidth)/6;
    int beginningAndEndLength = pulseXLim/8;
    float pulseScaleHeight = 1.0*pulseYAxisHeight/pulseYLim;
    float pulseScaleWidth = 1.0*pulseXAxisLength/pulseXLim;

    int pulseBeginning = stimWindowWidth/12;
    int pulseFreqX = stimWindowWidth/2;
    int pulseFreqY = 0;
    int pulseHighAmpX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + edgeBuffer;
    int pulseHighAmpY = stimWindowHeight/2 - imageSize - textBoxHeight - edgeBuffer;
    int pulseHighDelayX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + edgeBuffer + imageSize;
    int pulseHighDelayY = stimWindowHeight/2 - int(pulseHighAmpText*pulseScaleHeight) - edgeBuffer - textBoxHeight;
    int pulseMidDelayX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + edgeBuffer + imageSize;
    int pulseMidDelayY = stimWindowHeight - edgeBuffer - textBoxHeight;
    int pulseLowAmpX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + int(pulseMidDelayText*pulseScaleWidth) - edgeBuffer - textBoxWidth;
    int pulseLowAmpY = stimWindowHeight/2 + edgeBuffer + imageSize;
    int pulseLowDelayX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + int(pulseMidDelayText*pulseScaleWidth) + edgeBuffer + imageSize;
    int pulseLowDelayY = stimWindowHeight/2 - int(pulseLowAmpText*pulseScaleHeight) + edgeBuffer;
    int pulseYLimInX = stimWindowWidth/12 - textBoxWidth/2;
    int pulseYLimInY = stimWindowHeight/8 - textBoxHeight;
    int pulseXLimInX = (23*stimWindowWidth)/24 - textBoxWidth/2;
    int pulseXLimInY = stimWindowHeight/2 - textBoxHeight/2;
  
    pulseYLimIn = cp5.addTextfield("pulseYLimIn")
      .setPosition(pulseYLimInX, pulseYLimInY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(pulseYLim))
      .moveTo(stimWindow);
    pulseYLimIn.getCaptionLabel().setText("Y Lim (mA):").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, BOTTOM).getStyle().setMarginTop(-textBoxHeight + edgeBuffer);
  
    pulseXLimIn = cp5.addTextfield("pulseXLimIn")
      .setPosition(pulseXLimInX, pulseXLimInY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.valueOf(pulseXLim))
      .moveTo(stimWindow);
    pulseXLimIn.getCaptionLabel().setText("X Lim (ms):").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, BOTTOM).getStyle().setMarginTop(-textBoxHeight + edgeBuffer);
  
    pulseFreq = cp5.addTextfield("pulseFreq")
      .setPosition(pulseFreqX, pulseFreqY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(0)
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.format ("%.1f", pulseFreqText))
      .moveTo(stimWindow);
    pulseFreq.getCaptionLabel().setText("Frequency (Hz)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-20);
  
    pulseFreqUp = cp5.addButton("pulseFreqUp")
      .setPosition(pulseFreqX + textBoxWidth, pulseFreqY + textBoxHeight/4)
      .setImage(loadImage("./assets/Right-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseFreqDown = cp5.addButton("pulseFreqDown")
      .setPosition(pulseFreqX - imageSize, pulseFreqY + textBoxHeight/4)
      .setImage(loadImage("./assets/Left-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseHighAmp = cp5.addTextfield("pulseHighAmp")
      .setPosition(pulseHighAmpX, pulseHighAmpY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(color(0))
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.format ("%.3f", pulseHighAmpText))
      .moveTo(stimWindow);
    pulseHighAmp.getCaptionLabel().setText("High Amplitude (mA)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(75);
  
    pulseHighAmpUp = cp5.addButton("pulseHighAmpUp")
      .setPosition(pulseHighAmpX + textBoxWidth/4, pulseHighAmpY - imageSize)
      .setImage(loadImage("./assets/Up-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseHighAmpDown = cp5.addButton("pulseHighAmpDown")
      .setPosition(pulseHighAmpX + textBoxWidth/4, pulseHighAmpY + textBoxHeight)
      .setImage(loadImage("./assets/Down-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseHighDelay = cp5.addTextfield("pulseHighDelay")
      .setPosition(pulseHighDelayX, pulseHighDelayY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(color(0))
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.format ("%.3f", pulseHighDelayText))
      .moveTo(stimWindow);
    pulseHighDelay.getCaptionLabel().setText("High Delay (ms)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-20);
  
    pulseHighDelayUp = cp5.addButton("pulseHighDelayUp")
      .setPosition(pulseHighDelayX + textBoxWidth, pulseHighDelayY + textBoxHeight/4)
      .setImage(loadImage("./assets/Right-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseHighDelayDown = cp5.addButton("pulseHighDelayDown")
      .setPosition(pulseHighDelayX - imageSize, pulseHighDelayY + textBoxHeight/4)
      .setImage(loadImage("./assets/Left-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseMidDelay = cp5.addTextfield("pulseMidDelay")
      .setPosition(pulseMidDelayX, pulseMidDelayY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(color(0))
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.format ("%.3f", pulseMidDelayText))
      .moveTo(stimWindow);
    pulseMidDelay.getCaptionLabel().setText("Mid Delay (ms)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(-20);
  
    pulseMidDelayUp = cp5.addButton("pulseMidDelayUp")
      .setPosition(pulseMidDelayX + textBoxWidth, pulseMidDelayY + textBoxHeight/4)
      .setImage(loadImage("./assets/Right-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseMidDelayDown = cp5.addButton("pulseMidDelayDown")
      .setPosition(pulseMidDelayX - imageSize, pulseMidDelayY + textBoxHeight/4)
      .setImage(loadImage("./assets/Left-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseLowAmp = cp5.addTextfield("pulseLowAmp")
      .setPosition(pulseLowAmpX, pulseLowAmpY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(color(0))
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.format ("%.3f", pulseLowAmpText))
      .moveTo(stimWindow);
    pulseLowAmp.getCaptionLabel().setText("Low Amplitude (mA)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(-85);
  
    pulseLowAmpUp = cp5.addButton("pulseLowAmpUp")
      .setPosition(pulseLowAmpX + textBoxWidth/4, pulseLowAmpY - imageSize)
      .setImage(loadImage("./assets/Up-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseLowAmpDown = cp5.addButton("pulseLowAmpDown")
      .setPosition(pulseLowAmpX + textBoxWidth/4, pulseLowAmpY + textBoxHeight)
      .setImage(loadImage("./assets/Down-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseLowDelay = cp5.addTextfield("pulseLowDelay")
      .setPosition(pulseLowDelayX, pulseLowDelayY)
      .setSize(textBoxWidth, textBoxHeight)
      .setFont(createFont("arial", 20))
      .setColor(color(0))
      .setColorBackground(color(255))
      .setColorForeground(color(255))
      .setColorCursor(color(0))
      .setAutoClear(false)
      .setText(String.format ("%.3f", pulseLowDelayText))
      .moveTo(stimWindow);
    pulseLowDelay.getCaptionLabel().setText("Low Delay (ms)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginTop(20);
  
    pulseLowDelayUp = cp5.addButton("pulseLowDelayUp")
      .setPosition(pulseLowDelayX + textBoxWidth, pulseLowDelayY + textBoxHeight/4)
      .setImage(loadImage("./assets/Right-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
  
    pulseLowDelayDown = cp5.addButton("pulseLowDelayDown")
      .setPosition(pulseLowDelayX - imageSize, pulseLowDelayY + textBoxHeight/4)
      .setImage(loadImage("./assets/Left-Button.png"))
      .setSize(imageSize, imageSize)
      .moveTo(stimWindow);
    
    //SUPER IMPORTANT.  Controllers will not have control events if this line isn't included to implement the inherited class ControlListener
    cp5.addListener(this);
  }
  
  public void PulsePlotter(List<Float> pulse, StimPageControllers thisStimPageControllers) {
    int graphWidth = thisStimPageControllers.stimWindowWidth;
    int graphHeight = thisStimPageControllers.stimWindowHeight;
    int graphX = thisStimPageControllers.stimWindowX;
    int graphY = thisStimPageControllers.stimWindowY;
    //Calculates the height and width of the axes in pixels
    int pulseYAxisHeight = (3*graphHeight)/8;
    int pulseXAxisLength = (5*graphWidth)/6;
    //The beginning and end of the pulse are always 1/8 of the axes lengths
    int beginningAndEndLength = thisStimPageControllers.pulseXLim/8;
    //Figure out conversion ratio between axes limits and pixels
    float pulseScaleHeight = 1.0*pulseYAxisHeight/thisStimPageControllers.pulseYLim;
    float pulseScaleWidth = 1.0*pulseXAxisLength/thisStimPageControllers.pulseXLim;
    //Black medium thickness lines.  Draw axes
    stroke(0); 
    strokeWeight(2);
    pushMatrix();
    //Begin drawing at upper left point of graph starting point
    translate(graphX, graphY);
    translate(graphWidth/12, graphHeight/8);
    line(0, 0, 0, (6*graphHeight)/8);
    line(0, 0, 10, 10);
    line(0, 0, -10, 10);
    translate(0, (6*graphHeight)/8);
    line(0, 0, 10, -10);
    line(0, 0, -10, -10);
    translate((10*graphWidth)/12, -(3*graphHeight)/8);
    line(0, 0, -(10*graphWidth)/12, 0);
    line(0, 0, -10, 10);
    line(0, 0, -10, -10);
    popMatrix();
  
    pushMatrix();
    //Begin drawing at upper left point of graph starting point
    translate(graphX, graphY);
    translate(graphWidth/12, graphHeight/2);
  
    //Check whether to draw constant current or constant voltage colors
    if (thisStimPageControllers.isConstantCurrent)
      stroke(thisStimPageControllers.constantCurrentColor);
    else
      stroke(thisStimPageControllers.constantVoltageColor);
  
    //double the line thickness and draw the pulse
    strokeWeight(4);
    line(0, 0, beginningAndEndLength*pulseScaleWidth, 0);
    translate(beginningAndEndLength*pulseScaleWidth, 0);
  
    line(0, 0, 0, -pulse.get(1)*pulseScaleHeight);
    translate(0, -pulse.get(1)*pulseScaleHeight);
  
    line(0, 0, pulse.get(2)*pulseScaleWidth, 0);
    translate(pulse.get(2)*pulseScaleWidth, 0);
  
    line(0, 0, 0, pulse.get(1)*pulseScaleHeight);
    translate(0, pulse.get(1)*pulseScaleHeight);
  
    line(0, 0, pulse.get(3)*pulseScaleWidth, 0);
    translate(pulse.get(3)*pulseScaleWidth, 0);
  
    line(0, 0, 0, -pulse.get(4)*pulseScaleHeight);
    translate(0, -pulse.get(4)*pulseScaleHeight);
  
    line(0, 0, pulse.get(5)*pulseScaleWidth, 0);
    translate(pulse.get(5)*pulseScaleWidth, 0);
  
    line(0, 0, 0, pulse.get(4)*pulseScaleHeight);
    translate(0, pulse.get(4)*pulseScaleHeight);
  
    line(0, 0, beginningAndEndLength*pulseScaleWidth, 0);
    popMatrix();
  }
  
  /*!
  Handles all of the events passing through the stimulator page and forwards them to the main Processing applet.  Figures out the
  name of the controller that was activated by the user and passes it though a series of if statements to determine which action to take
  */
  public void  controlEvent(ControlEvent theEvent) {
    String controllerName = theEvent.getName();
    if (theEvent.isAssignableFrom(Textfield.class)){
      try {
        float numValue = Float.parseFloat(theEvent.getStringValue());          
        if (controllerName.equals("pulseXLimIn")){
          if (pulseHighDelayText + pulseLowDelayText + pulseMidDelayText + numValue/4 > numValue) {
            thisHomePageControllers.logDisplay.append("Input is too small for set values\n");
            pulseXLimIn.setText(String.valueOf(pulseXLim));
          }
          pulseXLim = (int)numValue;
        }
        else if (controllerName.equals("pulseYLimIn")){
          if (Math.max(pulseHighAmpText, pulseLowAmpText) > numValue) {
            thisHomePageControllers.logDisplay.append("Input is too small for set values\n");
            pulseYLimIn.setText(String.valueOf(pulseYLim));
          }
          pulseYLim = (int)numValue;
        }
        else if (controllerName.equals("pulseFreq")){
          if (200 < numValue) {
            thisHomePageControllers.logDisplay.append("That's way too high, are you crazy???\n");
            pulseFreq.setText(String.format ("%.1f", pulseFreqText));
          } else
            pulseFreqText = numValue;
        }
        else if (controllerName.equals("pulseHighAmp")){
          if (pulseYLim < numValue) {
            thisHomePageControllers.logDisplay.append("Input is too large for scale");
            pulseHighAmp.setText(String.format ("%.3f", pulseHighAmpText));
          } else
            pulseHighAmpText = numValue;
        }
        else if (controllerName.equals("pulseHighDelay")){
          if (numValue + pulseLowDelayText + pulseMidDelayText > (3*pulseXLim)/4) {
            thisHomePageControllers.logDisplay.append("Input is too large for scale");
            pulseHighDelay.setText(String.format ("%.3f", pulseHighDelayText));
          } else
            pulseHighDelayText = numValue;
        }
        else if (controllerName.equals("pulseMidDelay")){
          if (pulseHighDelayText + pulseLowDelayText + numValue > (3*pulseXLim)/4) {
            thisHomePageControllers.logDisplay.append("Input is too large for scale");
            pulseMidDelay.setText(String.format ("%.3f", pulseMidDelayText));
          } else
            pulseMidDelayText = numValue;
        }
        else if (controllerName.equals("pulseLowAmp")){
          if (pulseYLim < numValue) {
            thisHomePageControllers.logDisplay.append("Input is too large for scale");
            pulseLowAmp.setText(String.format ("%.3f", pulseLowAmpText));
          } else
            pulseLowAmpText = numValue;
        }
        else if (controllerName.equals("pulseLowDelay")){
          if (pulseHighDelayText + pulseMidDelayText + numValue > (3*pulseXLim)/4) {
            thisHomePageControllers.logDisplay.append("Input is too large for scale");
            pulseLowDelay.setText(String.format ("%.3f", pulseLowDelayText));
          } else
            pulseLowDelayText = numValue;
        }
        resetStimControllerPositions();
      } catch (Exception e){
        thisHomePageControllers.logDisplay.append("Error Reading Input Number");
      }
    } else if (theEvent.isAssignableFrom(Button.class)){
      if (controllerName.equals("constantSelector")){
        if (isConstantCurrent){
          isConstantCurrent = false;
          stimWindowButtonList.get(3).setColorBackground(constantVoltageColor);
          stimWindowButtonList.get(3).getCaptionLabel().setText("Constant Voltage").setColor(255).setFont(createFont("arial", stimWindowWidth/50)).align(CENTER, CENTER).toUpperCase(false);
          pulseHighAmp.getCaptionLabel().setText("High Amplitude (V)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(75);
          pulseLowAmp.getCaptionLabel().setText("Low Amplitude (V)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(-85);
          pulseYLimIn.getCaptionLabel().setText("Y Lim (V):").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, BOTTOM).getStyle().setMarginTop(-textBoxHeight + edgeBuffer);
          List<Float> thisDefaultPulse = CheckDefaultPulse();
          SetPulseAsDefault(thisDefaultPulse);
          pulseXLimCurr = pulseXLim;
          pulseYLimCurr = pulseYLim;
          pulseXLim = pulseXLimVolt;
          pulseYLim = pulseYLimVolt;
          WritePulseText();
          resetStimControllerPositions();
        } else {
          isConstantCurrent = true;
          stimWindowButtonList.get(3).setColorBackground(constantCurrentColor);
          stimWindowButtonList.get(3).getCaptionLabel().setText("Constant Current").setColor(255).setFont(createFont("arial", stimWindowWidth/50)).align(CENTER, CENTER).toUpperCase(false);
          pulseHighAmp.getCaptionLabel().setText("High Amplitude (mA)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(75);
          pulseLowAmp.getCaptionLabel().setText("Low Amplitude (mA)").setColor(0).setFont(createFont("arial", 10)).toUpperCase(false).align(CENTER, CENTER).getStyle().setMarginLeft(-85);
          pulseYLimIn.getCaptionLabel().setText("Y Lim (mA):").setColor(0).setFont(createFont("arial", 20)).toUpperCase(false).align(CENTER, BOTTOM).getStyle().setMarginTop(-textBoxHeight + edgeBuffer);
          List<Float> thisDefaultPulse = CheckDefaultPulse();
          SetPulseAsDefault(thisDefaultPulse);
          pulseXLimVolt = pulseXLim;
          pulseYLimVolt = pulseYLim;
          pulseXLim = pulseXLimCurr;
          pulseYLim = pulseYLimCurr;
          WritePulseText();
          resetStimControllerPositions();
        }
      }
      else if (controllerName.equals("stimWindowBack")){
        stimWindow.hide();
        thisHomePageControllers.homePage.show();
      } else if (controllerName.equals("stimWindowReset")){
        List<Float> thisDefaultPulse = CheckDefaultPulse();
        SetPulseAsDefault(thisDefaultPulse);
        WritePulseText();
        resetStimControllerPositions();
      } else if (controllerName.equals("stimWindowSubmit")){
        List<Byte> timeValuePairs = new ArrayList<Byte>();
        String defaultPulseString = "defaultPulseCurrent";
        int amplitudeModifier = 100;
        byte stimulatorMode = 1;
        if (!isConstantCurrent){
          amplitudeModifier = 1000;
          stimulatorMode = 0;
          defaultPulseString = "defaultPulseVoltage";
        }
        
        int thisByte = 0;
        int cumulativeTime = 0;
        //First time value pair
        int timeDelayInMicroseconds = (int)(pulseHighDelayText*1000);
        cumulativeTime += timeDelayInMicroseconds;
        for (int j = 0; j < 4; j++){
          thisByte = (timeDelayInMicroseconds>>(8*j) & 0x000000ff);
          timeValuePairs.add(uint2byte(thisByte));
        }
        int amplitudeInNewUnit = (int)(pulseHighAmpText*amplitudeModifier);
        for (int j = 0; j < 2; j++){
          thisByte = (amplitudeInNewUnit>>(8*j) & 0x000000ff);
          timeValuePairs.add(uint2byte(thisByte));
        }
        
        //Second time value pair
        timeDelayInMicroseconds = (int)(pulseMidDelayText*1000);
        cumulativeTime += timeDelayInMicroseconds;
        for (int j = 0; j < 4; j++){
          thisByte = (timeDelayInMicroseconds>>(8*j) & 0x000000ff);
          timeValuePairs.add(uint2byte(thisByte));
        }
        timeValuePairs.add((byte)0);
        timeValuePairs.add((byte)0);
        
        //Third time value pair
        timeDelayInMicroseconds = (int)(pulseLowDelayText*1000);
        cumulativeTime += timeDelayInMicroseconds;
        for (int j = 0; j < 4; j++){
          thisByte = (timeDelayInMicroseconds>>(8*j) & 0x000000ff);
          timeValuePairs.add(uint2byte(thisByte));
        }
        amplitudeInNewUnit = (int)(pulseLowAmpText*amplitudeModifier);
        for (int j = 0; j < 2; j++){
          thisByte = (amplitudeInNewUnit>>(8*j) & 0x000000ff);
          timeValuePairs.add(uint2byte(thisByte));
        }
        
        //Fourth time value pair
        timeDelayInMicroseconds = (int)(((1 / pulseFreqText) * 1000000) - cumulativeTime);
        for (int j = 0; j < 4; j++){
          thisByte = (timeDelayInMicroseconds>>(8*j) & 0x000000ff);
          timeValuePairs.add(uint2byte(thisByte));
        }
        timeValuePairs.add((byte)0);
        timeValuePairs.add((byte)0);
        
        Packet stimConfig = new Packet();
        byte[] stimConfigConverted = stimConfig.StimulatorConfiguration(timeValuePairs, stimulatorMode);
        serialPort.write(stimConfigConverted);
        
        JSONObject defaultPulseJSON = settingsJSON.getJSONObject(defaultPulseString);
        defaultPulseJSON = setPulseToSettings(defaultPulseJSON);
        settingsJSON.setJSONObject(defaultPulseString, defaultPulseJSON);
        saveJSONObject(settingsJSON, topSketchPath+"/config/config.json");
        List<Float> thisDefaultPulse = CheckDefaultPulse();
        thisDefaultPulse = WritePulse(thisDefaultPulse);
        
        stimConfigSet = true;
        stimWindow.hide();
        thisHomePageControllers.homePage.show();
      } else if (controllerName.equals("pulseFreqUp")){
        if (pulseFreqText + .1<=6) {
          pulseFreqText += .1;
          pulseFreq.setText(String.format ("%.1f", pulseFreqText));
        }
      } else if (controllerName.equals("pulseFreqDown")){
        if (pulseFreqText - .1>0) {
          pulseFreqText -= .1;
          pulseFreq.setText(String.format ("%.1f", pulseFreqText));
        }
      } else if (controllerName.equals("pulseHighAmpUp")){
        if (pulseHighAmpText+.1<=pulseYLim) {
          pulseHighAmpText += .1;
          pulseHighAmp.setText(String.format ("%.3f", pulseHighAmpText));
        }
      } else if (controllerName.equals("pulseHighAmpDown")){
        if (pulseHighDelayText-.1>=-pulseYLim) {
          pulseHighAmpText -=.1;
          pulseHighAmp.setText(String.format ("%.3f", pulseHighAmpText));
        }
      } else if (controllerName.equals("pulseHighDelayUp")){
        if (pulseHighDelayText + pulseLowDelayText + pulseMidDelayText + 1 <= (6*pulseXLim)/8) {
          pulseHighDelayText += 1;
          pulseHighDelay.setText(String.format ("%.3f", pulseHighDelayText));
        }
      } else if (controllerName.equals("pulseHighDelayDown")){
        if (pulseHighDelayText - 1 >= 0) {
          pulseHighDelayText -= 1;
          pulseHighDelay.setText(String.format ("%.3f", pulseHighDelayText));
        }
      } else if (controllerName.equals("pulseMidDelayUp")){
        if (pulseHighDelayText + pulseLowDelayText + pulseMidDelayText + 1 <= (6*pulseXLim)/8) {
          pulseMidDelayText += 1;
          pulseMidDelay.setText(String.format ("%.3f", pulseMidDelayText));
        }
      } else if (controllerName.equals("pulseMidDelayDown")){
        if (pulseMidDelayText - 1 >= 0) {
          pulseMidDelayText -= 1;
          pulseMidDelay.setText(String.format ("%.3f", pulseMidDelayText));
        }
      } else if (controllerName.equals("pulseLowAmpUp")){
        if (pulseLowAmpText+.1<=pulseYLim) {
          pulseLowAmpText += .1;
          pulseLowAmp.setText(String.format ("%.3f", pulseLowAmpText));
        }
      } else if (controllerName.equals("pulseLowAmpDown")){
        if (pulseLowAmpText-.1>=-pulseYLim) {
          pulseLowAmpText -= .1;
          pulseLowAmp.setText(String.format ("%.3f", pulseLowAmpText));
        }
      } else if (controllerName.equals("pulseLowDelayUp")){
        if (pulseHighDelayText + pulseLowDelayText + pulseMidDelayText + 1 <= (6*pulseXLim)/8) {
          pulseLowDelayText += 1;
          pulseLowDelay.setText(String.format ("%.3f", pulseLowDelayText));
        }
      } else if (controllerName.equals("pulseLowDelayDown")){
        if (pulseLowDelayText - 1 >= 0) {
          pulseLowDelayText -= 1;
          pulseLowDelay.setText(String.format ("%.3f", pulseLowDelayText));
        }
      }
      resetStimControllerPositions();
    }
  } 
  
  /*!
  Checks whether constant current or constant voltage is selected by user and returns the appropriate corresponding default pulse array list
  */
  private List<Float> CheckDefaultPulse() {
    List<Float> thisPulse = new ArrayList<Float>();
    if (isConstantCurrent)
      thisPulse = defaultPulseCurrent;    
    else 
      thisPulse = defaultPulseVoltage;
    return thisPulse;
  }
  
  /*!
  Writes the default pulse arrayList passed into this function to the displayed pulse in the waveform editing window
  */
  private void SetPulseAsDefault(List<Float> defaultPulse) {
    pulseFreqText = defaultPulse.get(0);
    pulseHighAmpText = defaultPulse.get(1);
    pulseHighDelayText = defaultPulse.get(2);
    pulseMidDelayText = defaultPulse.get(3);
    pulseLowAmpText = defaultPulse.get(4);
    pulseLowDelayText = defaultPulse.get(5);
  }
  
  /*!
  Writes the displayed pulse in the waveform editing window to the pulse arrayList passed into this function
  */
  private List<Float> WritePulse(List<Float> thisPulse) {
    thisPulse.set(0, pulseFreqText);
    thisPulse.set(1, pulseHighAmpText);
    thisPulse.set(2, pulseHighDelayText);
    thisPulse.set(3, pulseMidDelayText);
    thisPulse.set(4, pulseLowAmpText);
    thisPulse.set(5, pulseLowDelayText);
    return thisPulse;
  }
  
  /*!
  Given a specific JSON object from the config file, retrieve a breakdown of each of it's pulse components using specific keys
  */
  private JSONObject setPulseToSettings(JSONObject source){
    source.setFloat("pulseFreq", pulseFreqText);
    source.setFloat("pulseHighAmp", pulseHighAmpText);
    source.setFloat("pulseHighDelay", pulseHighDelayText);
    source.setFloat("pulseMidDelay", pulseMidDelayText);
    source.setFloat("pulseLowAmp", pulseLowAmpText);
    source.setFloat("pulseLowDelay", pulseLowDelayText);
    return source;
  }
  
  /*!
  Writes the curent values stored in the data objects to the GUI objects
  */
  private void WritePulseText() {
    pulseFreq.setText(String.format ("%.1f", pulseFreqText));
    pulseHighAmp.setText(String.format ("%.3f", pulseHighAmpText));
    pulseHighDelay.setText(String.format ("%.3f", pulseHighDelayText));
    pulseMidDelay.setText(String.format ("%.3f", pulseMidDelayText));
    pulseLowAmp.setText(String.format ("%.3f", pulseLowAmpText));
    pulseLowDelay.setText(String.format ("%.3f", pulseLowDelayText));
    pulseXLimIn.setText(String.valueOf(pulseXLim));
    pulseYLimIn.setText(String.valueOf(pulseYLim));
  }
  
  /*!
  Given a specific JSON object from the config file, retrieve a breakdown of each of it's pulse components using specific keys
  */
  private List<Float> retrievePulseFromSettings(JSONObject source){
    List<Float> thisPulse = new ArrayList<Float>();
    thisPulse.add(source.getFloat("pulseFreq"));
    thisPulse.add(source.getFloat("pulseHighAmp"));
    thisPulse.add(source.getFloat("pulseHighDelay"));
    thisPulse.add(source.getFloat("pulseMidDelay"));
    thisPulse.add(source.getFloat("pulseLowAmp"));
    thisPulse.add(source.getFloat("pulseLowDelay"));
    return thisPulse;
  }
  
  
   
  /*!
  After every time a stim waveform piece has been edited, shift the location of the controllers within the edit waveform panel to match the new waveform shape
  */
  private void resetStimControllerPositions() {
    int pulseYAxisHeight = (3*stimWindowHeight)/8;
    int pulseXAxisLength = (5*stimWindowWidth)/6;
    
    float pulseScaleHeight = 1.0*pulseYAxisHeight/pulseYLim;
    float pulseScaleWidth = 1.0*pulseXAxisLength/pulseXLim;
    
    int beginningAndEndLength = pulseXLim/8;
    
    int pulseBeginning = stimWindowWidth/12;
    int pulseFreqX = stimWindowWidth/2;
    int pulseFreqY = 0;
    int pulseHighAmpX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + edgeBuffer;
    int pulseHighAmpY = stimWindowHeight/2 - imageSize - textBoxHeight - edgeBuffer;
    int pulseHighDelayX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + edgeBuffer + imageSize;
    int pulseHighDelayY = stimWindowHeight/2 - int(pulseHighAmpText*pulseScaleHeight) - edgeBuffer - textBoxHeight;
    int pulseMidDelayX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + edgeBuffer + imageSize;
    int pulseMidDelayY = stimWindowHeight - edgeBuffer - textBoxHeight;
    int pulseLowAmpX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + int(pulseMidDelayText*pulseScaleWidth) - edgeBuffer - textBoxWidth;
    int pulseLowAmpY = stimWindowHeight/2 + edgeBuffer + imageSize;
    int pulseLowDelayX = pulseBeginning + int(beginningAndEndLength*pulseScaleWidth) + int(pulseHighDelayText*pulseScaleWidth) + int(pulseMidDelayText*pulseScaleWidth) + edgeBuffer + imageSize;
    int pulseLowDelayY = stimWindowHeight/2 - int(pulseLowAmpText*pulseScaleHeight) + edgeBuffer;
    
    pulseFreq.setPosition(pulseFreqX, pulseFreqY);
    pulseFreqUp.setPosition(pulseFreqX + textBoxWidth, pulseFreqY + textBoxHeight/4);
    pulseFreqDown.setPosition(pulseFreqX - imageSize, pulseFreqY + textBoxHeight/4);
    pulseHighAmp.setPosition(pulseHighAmpX, pulseHighAmpY);
    pulseHighAmpUp.setPosition(pulseHighAmpX + textBoxWidth/4, pulseHighAmpY - imageSize);
    pulseHighAmpDown.setPosition(pulseHighAmpX + textBoxWidth/4, pulseHighAmpY + textBoxHeight);
    pulseHighDelay.setPosition(pulseHighDelayX, pulseHighDelayY);
    pulseHighDelayUp.setPosition(pulseHighDelayX + textBoxWidth, pulseHighDelayY + textBoxHeight/4);
    pulseHighDelayDown.setPosition(pulseHighDelayX - imageSize, pulseHighDelayY + textBoxHeight/4);
    pulseMidDelay.setPosition(pulseMidDelayX, pulseMidDelayY);
    pulseMidDelayUp.setPosition(pulseMidDelayX + textBoxWidth, pulseMidDelayY + textBoxHeight/4);
    pulseMidDelayDown.setPosition(pulseMidDelayX - imageSize, pulseMidDelayY + textBoxHeight/4);
    pulseLowAmp.setPosition(pulseLowAmpX, pulseLowAmpY);
    pulseLowAmpUp.setPosition(pulseLowAmpX + textBoxWidth/4, pulseLowAmpY - imageSize);
    pulseLowAmpDown.setPosition(pulseLowAmpX + textBoxWidth/4, pulseLowAmpY + textBoxHeight);
    pulseLowDelay.setPosition(pulseLowDelayX, pulseLowDelayY);
    pulseLowDelayUp.setPosition(pulseLowDelayX + textBoxWidth, pulseLowDelayY + textBoxHeight/4);
    pulseLowDelayDown.setPosition(pulseLowDelayX - imageSize, pulseLowDelayY + textBoxHeight/4);
  }
}

int dim_cell = 8;
//int width = 15*dim_cell;

// loom set-up
int shafts = 4;
int treadles = 6;
int DEFAULT_WARPS = 100;
int DEFAULT_PICKS = 60;

// pattern data
int [][] stitches;
Threading TX;
Treadling TL;
boolean [][] tieUp;
boolean [][] drawdown;

// tracking user input
int threadingCount = 0;
int treadleCount = 0;
int currentShaft = 0; // cycle through shafts 0-3 in pattern

int warpInputs = 0; // warpInputs % numShafts = currentShaft
int pickInputs = 0;
int[] threadingInputs;
int[] treadleInputs;

boolean editThreading = true; // if true, editing tie-up in tieUpInputs
  //if false, editing treadles instead
//int[] command;
boolean ctrlPressed = false;
String error;

// graphics set-up
int xo;
int yo;

// initializing bools for walkthrough steps
boolean inputOnThreading = false;
boolean switchedDirection = false;
boolean switchedToTreadling = false;
boolean inputOnTreadling = false;

void setup() {
  println("setup");
  
  // Width = warps * dim_cell
  size(900, 640);
  background(255);
  xo = dim_cell;
  yo = 14*dim_cell;
  
  error = "";
  //command = new int[2];
  
  tieUp = new boolean[][] 
            {{false, true, true, true, false, true},
             {true, true, true, false, true, false},
             {true, true, false, true, false, true},
             {true, false, true, true, true, false}};
            //new boolean[shafts][treadles];
  TX = new Threading(shafts, DEFAULT_WARPS);
  TL = new Treadling(treadles, DEFAULT_PICKS);
  drawdown = new boolean[TL.picks][TX.warps];
}

void draw() {
  background(255);
  
  // display input mode and error messages
  fill(0);
  noStroke();
  textSize(12);
  // instruction text
  if (inputOnThreading) {
    text("Press '1', '3', or '5' to add a threading block of that width. Press 'r' to reverse pattern direction.", xo, 3*dim_cell);
  } else { text("Press '1', '3', or '5' to add a threading block of that width.", xo, 3*dim_cell); }
  if (switchedDirection) {
    text("Press 't' to switch to editing treadles (or to switch back to threading).", xo, 3*dim_cell+15);
  }
  if (switchedToTreadling) {
    text("    Press a key '1' to '6' to add a treadling block.", xo, 3*dim_cell+30);
    text("    Blocks 1-4 are woven as overshot, so tabby rows are automatically inserted before each pattern pick.", xo, 3*dim_cell+45);
  }
  if (inputOnTreadling) {
    text("Press backspace to delete the most recent treadling or threading block.", xo, 3*dim_cell+60);
  }
  
  // status text
  text("threading: "+TX.threadingCount+" / "+ TX.warps+ " ends", xo, yo-dim_cell/2);
  String dir = new String();
  if (TX.direction) {
    dir = "1-2-3-4";
  } else { dir = "4-3-2-1"; }
  text("direction: "+dir, xo+200, yo-dim_cell/2);
  
   // println(code+" "+pw);
  fill(255, 0, 0);
  noStroke();
  textSize(12);
  text(error, xo, yo-14-dim_cell/2); 
  
  stroke(0);
  // DRAW THREADING
  for (int i = 0; i < TX.shafts; i++) { // Y coord (row) //<>//
    for (int j = 0; j < TX.warps; j++) { // X coord (col)
      if (TX.displayData[i][j]) fill(0);
      else if (editThreading && TX.profileView) {
        fill(0, 255, 0);
      } else if (editThreading) {
        fill(255, 255, 0);
      } else if (!editThreading && TX.profileView) {
        fill(200, 200, 200);
      } else {
        fill(255);
      }
      int dispX = TX.warps-1-j;
      int dispY = TX.shafts-1-i;
      rect(dispX*dim_cell+xo, dispY*dim_cell+yo, dim_cell, dim_cell);
    }
  }
  
  // DRAW TIE UP
  for (int i = 0; i < shafts; i++) { //<>//
    for (int j = 0; j < treadles; j++) {
      if (tieUp[i][j]) fill(0);
      else fill(255);
      rect((j+TX.warps+1)*dim_cell+xo, i*dim_cell+yo, dim_cell, dim_cell);
    }
  }
  
  // DRAW TREADLING
  for (int i = 0; i < TL.picks; i++) { //<>//
    for (int j = 0; j < treadles; j++) {
      if (TL.displayData[i][j]) fill(0);
      else if (!editThreading && TL.profileView) {
        fill(0, 255, 0);
      } else if (!editThreading) {
        fill(255, 255, 0);
      } else if (editThreading && TL.profileView) {
        fill(200, 200, 200);
      } else { fill(255); }
      rect((j+TX.warps+1)*dim_cell+xo, (i+shafts+1)*dim_cell+yo, dim_cell, dim_cell);
    }
  }
  
  // DRAWDOWN
  for (int i = 0; i < TL.picks; i++) {
    for (int j = 0; j < TX.warps; j++) {
      if (drawdown[i][j]) fill(0);
      else fill(255);
      int dispX = TX.warps-1-j;
      rect(dispX*dim_cell+xo, (i+shafts+1)*dim_cell+yo, dim_cell, dim_cell);
    }
  }
}

void updateDrawdown() {
  drawdown = new boolean[TL.picks][TX.warps];
  boolean[] updatedRow;
  // each i-th row of the drawdown:
  // i-th treadling row -> which treadle was pressed?
  // on that treadle, what does that column of tie-up look like?
  // if cell in that column, then OR to make the row
  
  // for each row
  for (int row = 0; row < TL.picks; row++) {
    updatedRow = new boolean[TX.warps];
    int whichTreadle = -1;
    for (int treadle = 0; treadle < treadles; treadle++) {
      if (TL.displayData[row][treadle]) {
        whichTreadle = treadle;
        break;
      }
    }
    //println("Row", row, "uses treadle", whichTreadle);
    
    for (int col = 0; col < TX.warps; col++) {
      if (whichTreadle == -1) {
          // no treadle on this row, row should be empty
          //println("empty row");
          updatedRow[col] = false;
        } else {
          for (int shaft = 0; shaft < shafts; shaft++) {
            updatedRow[col] |= tieUp[shaft][whichTreadle] && TX.displayData[shaft][col];
        }
      }
    }
    // copy updated row into drawndown
    for (int col = 0; col < TX.warps; col++) {
      drawdown[row][col] = updatedRow[col];
    }
  }
}

void mouseClicked() {
  // determine where mouse was clicked
  //println(mouseX, mouseY);
  // in threading rectangle
  if (mouseX > xo && mouseX < (dim_cell*TX.warps + xo) && 
      mouseY > yo && mouseY < (dim_cell*shafts+yo)) {
    int gridX = TX.warps-1-(mouseX - xo)/dim_cell;
    int gridY = shafts-1-(mouseY - yo)/dim_cell;
    println("mapping to", gridX, gridY);
    // only one black square per column allowed
    if (!TX.threading[gridY][gridX]) {
      for (int i = 0; i < shafts; i++) {
        // clear any black squares in the column before flipping square
        TX.threading[i][gridX] = false;
      }
    }
    TX.threading[gridY][gridX] = !TX.threading[gridY][gridX];
  }
  // in tie-up rectangle
  if (mouseX > (dim_cell*TX.warps + xo) && mouseX < (dim_cell*(TX.warps+1+treadles) + xo) &&
      mouseY > yo && mouseY < (dim_cell*shafts+yo)) {
    int gridX = (mouseX - xo - (TX.warps + 1)*dim_cell)/dim_cell;
    int gridY = (mouseY - yo)/dim_cell;
    tieUp[gridY][gridX] = !tieUp[gridY][gridX];
  }
  // in treadling rectangle
  if (mouseX > (dim_cell*TX.warps + xo) && mouseX < (dim_cell*(TX.warps+1+treadles) + xo) &&
      mouseY > (dim_cell*shafts + yo) && mouseY < (dim_cell*(shafts+1+TL.picks)+yo)) {
    int gridX = (mouseX - xo - (TX.warps + 1)*dim_cell)/dim_cell;
    int gridY = (mouseY - yo - (shafts + 1)*dim_cell)/dim_cell;
    // only one treadle allowed per row (why would I do multiple treadles no)
    if (!TL.treadling[gridY][gridX]) {
      for (int i = 0; i < treadles; i++) {
        // clear any black squares in the row before flipping square
        TL.treadling[gridY][i] = false;
      }
    }
    TL.treadling[gridY][gridX] = !TL.treadling[gridY][gridX];
  }
  updateDrawdown();
}

void keyPressed() {
  // only use for prolonged presses like CTRL or SHIFT
  if (key == CODED) {
    if (keyCode == CONTROL) {
      println("CTRL pressed");
      ctrlPressed = true;
    } 
    if (keyCode == LEFT) {
      xo--;
    }
    if (keyCode == RIGHT) {
      xo++;
    }
  }
  // use numeric commands for editing tie-up and treadling
  if (key >= '0' && key <= '9') {
    int numKey = Character.getNumericValue(key);
    // for tie-up: only 1, 3, 5 are valid (lengths of overshot floats)
    if (editThreading) {
      if (!inputOnThreading) {
        inputOnThreading = true;
      }
      // after an input, increment (or decrement) currentShaft
      //addTieUp(key);
      if (key == '1') {
        TX.pushBlock(1);
        error = "";
      } else if (key == '3') {
        TX.pushBlock(3);
        error = "";
      } else if (key == '5') {
        TX.pushBlock(5);
        error = "";
      } else {
        println(numKey, "invalid tie-up command");
        error = "invalid tie-up command: "+key;
      }
    } else {
      // for treadling: accepts 1-6 for treadle number
      if (!inputOnTreadling) {
        inputOnTreadling = true;
      }
      if (numKey >= 1 && numKey <=6) {
        TL.pushBlock(numKey-1);
        error = "";
      } else {
        println(numKey, "invalid treadle command");
        error = "invalid treadle command: "+key;
      }
    }
  }
  
  // deleting
  if (key == BACKSPACE) {
    if (editThreading) {
      TX.popBlock();
    } else { TL.popBlock(); }
  }
  
  // resizing
  if (key == '=') { //<>//
    if (editThreading) {
      TX.addWarp();
      updateDrawdown();
    } else {
      TL.addPick();
    }
  } 
  
  if (key == '-') {
    if (editThreading) {
      TX.delWarp();
    } else {
      TL.delPick();
    }
  }
  updateDrawdown(); //<>//
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == CONTROL) {
      println("CTRL released");
      ctrlPressed = false;
    }
  }
  
  // backspace
  // 't' to toggle tie-up / treadling keyboard input
  if (key == 't') {
    if (!switchedToTreadling) {
      switchedToTreadling = true;
    }
    editThreading = !editThreading;
  }
  
  if (key == 'r') {
    if (!switchedDirection) {
      switchedDirection = true;
    }
    TX.reverse();
  }
  
  // zoom in/out
  if (key == '_') {
    //println("zooming out");
    dim_cell--;
  }
  if (key == '+') {
    //println("zooming in");
    dim_cell++;
  }
  
  // profile view
  if (key == 'p') {
    if (editThreading) {
      TX.toggleProfile();
    } else {
      TL.toggleProfile();
    }
  }
  if (key == 'o') {
    TL.profileMode();
  }
  updateDrawdown();
}

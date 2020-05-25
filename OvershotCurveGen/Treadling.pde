// A Treadling object, representing treadling quadrant of a draft

class Treadling {
  // loom parameters
  int treadles;
  int TABBY_A = 4;
  int TABBY_B = 5;
  
  // pattern data
  int picks;
  boolean[][] treadling;
  boolean[][] profile;
  boolean[][] displayData;
  
  // track user inputs
  boolean tabbyRow = false; //alternates between true and false for 2 rows of tabby
  boolean profileView = false;
  boolean profileMode = false; // if false, will show pattern blocks as 2 rows; if true, shows as 1 and drawdown height must be updated
  int pickCount = 0;
  int treadleInputs = 0; // also the number of pattern picks
  int[] treadlingInputs; 
  
  // contructor, equiv to setup()
  Treadling(int t, int p) {
    treadles = t;
    picks = p;
    
    treadling = new boolean[picks][treadles];
    treadlingInputs = new int[picks];
    displayData = treadling;
  }
  
  // functionality
  void display() {
    // equiv to draw(), leave empty for pure data object
  }
  
  void updateDisplay() {
    if (profileView) {
      displayData = profile;
    } else {
      displayData = treadling;
    }
  }
  
  void addPick() {
    // add 1 warp
    picks++;
    
    // make new larger arrays to prepare for copying
    boolean[][] newTreadling = new boolean[picks][treadles];
    int[] newTInputs = new int[picks];
    
    // copy old arrays into new resized arrays
    for (int i = 0; i < picks-1; i++) {
      for (int t = 0; t < treadles; t++) {
        newTreadling[i][t] = treadling[i][t];
      }
      newTInputs[i] = treadlingInputs[i];
    }
    
    treadling = newTreadling;
    treadlingInputs = newTInputs;
    updateDisplay();
  }
  
  void delPick() {
    picks--;
    // check if you're cutting into an existing block
    if (picks < pickCount) {
      popBlock();
    }
    
    // make new smaller arrays to prepare for copying
    boolean[][] newTreadling = new boolean[picks][treadles];
    int[] newTInputs = new int[picks];
    
    // copy old arrays into new resized arrays
    for (int i = 0; i < picks; i++) {
      for (int t = 0; t < treadles; t++) {
        newTreadling[i][t] = treadling[i][t];
      }
      newTInputs[i] = treadlingInputs[i];
    }
    
    treadling = newTreadling;
    treadlingInputs = newTInputs;
    updateDisplay();
  }
  
  boolean pushBlock(int treadle) {
    // println("tabby row:", tabbyRow);
    // add a treadling block of specified treadle to draft
    if (treadle > 5 || treadle < 0) {
      return false; // error, treadle needs to be 0-5
    }
    // must have enough empty warps left for the block
    if (pickCount + 2 > picks) {
      return false;
    }
    // update treadlingInputs (push treadle to array)
    treadlingInputs[treadleInputs] = treadle;
    // update treadling array
    // add tabby pick no matter what, forcing tabby pattern
    if (tabbyRow) {
        treadling[pickCount][TABBY_A] = true;
      } else {
        treadling[pickCount][TABBY_B] = true;
      }
    // treadles 0-3: overshot pattern
    if (treadle >= 0 && treadle <= 3) {      
      treadling[pickCount+1][treadle] = true; // add pattern pick
      pickCount += 2; // overshot picks always come with: 1 tabby, 1 pattern
    }
    // treadles 4-5: tabby
    else { // if (treadle == TABBY_A || treadle == TABBY_B) 
      pickCount++;    
    }
    treadleInputs++;
    tabbyRow = !tabbyRow;
    if (profileView) {
      updateProfile();
    }
    return true;
  }
  
  boolean popBlock() {
    // remove the last treadle input
    if (treadleInputs == 0) {
      // if there are no treadles inputted, we're done
      return true;
    }
    tabbyRow = !tabbyRow;
    treadleInputs--;
    int treadle = treadlingInputs[treadleInputs];
    if (treadle > 5 || treadle < 0) {
      return false; // error, treadle needs to be 0-5
    }
    // remove pattern block
    if (treadle >= 0 && treadle <= 3) {
      pickCount -= 2;
      for (int t = 0; t < treadles; t++) {
        treadling[pickCount][t] = false;
        treadling[pickCount+1][t] = false;
      }
    } else {
      // remove tabby pick
      pickCount--;
      for (int t = 0; t < treadles; t++) {
        treadling[pickCount][t] = false;
      }
    }
    if (profileView) {
      updateProfile();
    }
    return true; // success
  }
  
  void toggleProfile() {
    profileView = !profileView;
    if (profileView) {
      updateProfile();
      displayData = profile;
    } else {displayData = treadling;}
  }
  
  void profileMode() {
    if (profileView) {
      profileMode = !profileMode;
      updateProfile();
    }
  }
  
  void updateProfile() {
    // convert threading draft to a profile draft
    // for each threading block,
    profile = new boolean[picks][treadles];
    int currentPick = 0;
    int currentRowInProfile = 0;
    for (int i = 0; i < treadleInputs; i++) {
      // find which treadle the current block is on
      int whichTreadle = -1;
      for (int t = 0; t < treadles; t++) {
        if (treadling[currentPick+1][t]) {
          whichTreadle = t;
          break;
        }
      }
      // update the profile array at the correct pick, with the correct size block
      println(i+", "+ treadlingInputs[i]+", "+whichTreadle);
      // for treadles 0-3, block size = 2; for treadles 4-5, block size = 1;
      if (whichTreadle >= 0 && whichTreadle <= 3) {
        profile[currentRowInProfile][whichTreadle] = true;
        if (profileMode) {
          currentRowInProfile++;
        } else {
          profile[currentRowInProfile+1][whichTreadle] = true;
          currentRowInProfile += 2;
        }
        currentPick += 2;
      } else {
        // just skip tabby picks
        currentPick++;
        currentRowInProfile++;
      }
    }
    updateDisplay();
  }
  
  String print() {
    // return a string/char[] for printing
    String str = new String();
    for (int p = 0; p < pickCount; p++) {
      for (int t = 0; t < treadles; t++) {
        if (treadling[p][t]) {
          str += '1';
        } else {
          str += '0';
        }
      }
      str += '\n';
    }
    return str; 
  }
}

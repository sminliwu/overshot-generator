// A Threading object, representing threading quadrant of a draft

class Threading {
  // loom parameters
  int shafts;
  int warps;
  
  // pattern data
  boolean[][] threading;
  boolean[][] profile;
  boolean[][] displayData;
  
  // track user inputs
  // DIRECTION: if true, pattern progresses thru shafts 1234
  // if false, progresses 4321
  boolean direction = true; 
  boolean profileView = false;
  int currentShaft = 0;
  int threadingCount = 0;
  int warpInputs = 0;
  int[] threadingInputs; 
  
  // contructor, equiv to setup()
  Threading(int s, int w) {
    shafts = s;
    warps = w;
    
    threading = new boolean[shafts][warps];
    profile = new boolean[shafts][warps];
    threadingInputs = new int[warps];
    displayData = threading;
  }
  
  // functionality
  void display() {
    // equiv to draw(), leave empty for pure data object
  }
  
  void updateDisplay() {
    if (profileView) {
      displayData = profile;
    } else {
      displayData = threading;
    }
  }
  
  void addWarp() { //<>//
    // add 1 warp
    warps++; //<>//
    
    // make new larger arrays to prepare for copying
    boolean[][] newThreading = new boolean[shafts][warps];
    int[] newTInputs = new int[warps];
    
    // copy old arrays into new resized arrays
    for (int i = 0; i < warps-1; i++) {
      for (int s = 0; s < shafts; s++) {
        newThreading[s][i] = threading[s][i];
      }
      newTInputs[i] = threadingInputs[i];
    }
    
    threading = newThreading;
    threadingInputs = newTInputs;
    updateDisplay();
  }
  
  void delWarp() { //<>//
    warps--;
    // check if you're cutting into an existing block
    if (warps < threadingCount) {
      popBlock();
    }
    
    // make new smaller arrays to prepare for copying
    boolean[][] newThreading = new boolean[shafts][warps];
    int[] newTInputs = new int[warps];
    
    // copy old arrays into new resized arrays
    for (int i = 0; i < warps; i++) {
      for (int s = 0; s < shafts; s++) {
        newThreading[s][i] = threading[s][i];
      }
      newTInputs[i] = threadingInputs[i]; //<>//
    }
    
    threading = newThreading;
    threadingInputs = newTInputs;
    updateDisplay();
  }
  
  boolean pushBlock(int size) {
    //println(currentShaft);
    // add a threading block of specified size (1, 3, 5) to draft
    if (size != 1 && size != 3 && size != 5) {
      return false; // error, size needs to be 1, 3, or 5
    }
    // must have enough empty warps left for the block
    if (threadingCount + size > warps) {
      return false;
    }
    // update threadingInputs (push size to array)
    threadingInputs[warpInputs] = size;
    // update threading array
    // size 1 block: true on currentShaft
    if (size == 1) {
      threading[currentShaft][threadingCount] = true;
    }
    // size 3 block: currentShaft, nextShaft, currentShaft
    else if (size == 3) {
      threading[currentShaft][threadingCount] = true;
      threading[next(currentShaft)][threadingCount+1] = true;
      threading[currentShaft][threadingCount+2] = true;
    }
    // size 5 block: current, next, current, next, current
    else if (size == 5) {
      threading[currentShaft][threadingCount] = true;
      threading[next(currentShaft)][threadingCount+1] = true;
      threading[currentShaft][threadingCount+2] = true;
      threading[next(currentShaft)][threadingCount+3] = true;
      threading[currentShaft][threadingCount+4] = true;
    }
    threadingCount += size;
    warpInputs++;
    
    if (direction) {
      currentShaft++;
    } else { currentShaft += shafts-1; }
    currentShaft %= shafts;
    if (profileView) {
      updateProfile();
    }
    return true;
  }
  
  boolean popBlock() {
    // removes the most recently-added threading block
    if (warpInputs == 0) {
      // if there are no threading blocks inputted, we're done
      return true;
    }
    if (direction) {
      currentShaft += shafts-1;
    } else { currentShaft++; }
    currentShaft %= shafts;
    
    warpInputs--;
    int size = threadingInputs[warpInputs];
    threadingCount -= size;
    if (size != 1 && size != 3 && size != 5) {
      return false; // error, size needs to be 1, 3, or 5
    }
    if (size == 1) {
      // remove block of size 1
      for (int s = 0; s < shafts; s++) {
        threading[s][threadingCount] = false;
      }
    } else if (size == 3) {
      // remove block of size 3
      for (int s = 0; s < shafts; s++) {
        threading[s][threadingCount] = false;
        threading[s][threadingCount+1] = false;
        threading[s][threadingCount+2] = false;
      }
    } else if (size == 5) {
      // remove block of size 5
      for (int s = 0; s < shafts; s++) {
        threading[s][threadingCount] = false;
        threading[s][threadingCount+1] = false;
        threading[s][threadingCount+2] = false;
        threading[s][threadingCount+3] = false;
        threading[s][threadingCount+4] = false;
      }
    }
    if (profileView) {
      updateProfile();
    }
    return true; // success
  }
  
  int next(int shaftNum) {
    // if you implement mirror/flipping shaft progression, handle +/- 1
    return (shaftNum+1)%shafts;
  }
  
  void reverse() {
    direction = !direction;
  }
  
  void toggleProfile() {
    profileView = !profileView;
    if (profileView) {
      updateProfile();
      displayData = profile;
    } else {displayData = threading;}
  }
  
  void updateProfile() {
    // convert threading draft to a profile draft
    // for each threading block,
    profile = new boolean[shafts][warps];
    int currentWarp = 0;
    for (int i = 0; i < warpInputs; i++) {
      // find which shaft the current block is on
      int whichShaft = -1;
      for (int s = 0; s < shafts; s++) {
        if (threading[s][currentWarp]) {
          whichShaft = s;
          break;
        }
      }
      // update the profile array at the correct shaft, with the correct size block
      // println(currentWarp+", "+threadingInputs[i]+", "+whichShaft);
      for (int w = 0; w < threadingInputs[i]; w++) {
        profile[whichShaft][currentWarp+w] = true;
      }
      currentWarp += threadingInputs[i];
    }
    updateDisplay();
    //println("done converting to profile draft");
    //println(printProfile());
  }
  
  String print() {
    // return a string/char[] for printing
    String str = new String();
    for (int s = 0; s < shafts; s++) {
      for (int w = 0; w < warps; w++) {
        if (threading[s][w]) {
          str += '1';
        } else {
          str += '0';
        }
      }
      str += '\n';
    }
    return str; 
  }
  
  String printProfile() {
    // return a string/char[] for printing
    String str = new String();
    for (int s = 0; s < shafts; s++) {
      for (int w = 0; w < warps; w++) {
        if (profile[s][w]) {
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

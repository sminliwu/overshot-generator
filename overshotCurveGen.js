// porting DrawdownEditor from Processing (Java) to P5.js
// really more of an overshot curve generator/visualizer
/* more on the interface and code organization:
	- this file has setup(), draw(), key and mouse events, updateDrawdown() -- handling user inputs and updating the display to respond
	- should this file also handle DOM events? try it, see if it's too messy; would be good to have it in the same file because DOM events may resize P5 canvas/shift canvas elements
		- showHideTutorial() - click button on sidebar, affects P5
		- showHideSidebar() - sidebar, re-render DOM but also expand canvas
		- download() - ????
		- 
*/
var dim_cell = 8;

// loom set-up
const DEFAULT_SHAFTS = 4;
const DEFAULT_TREADLES = 6;
const DEFAULT_WARPS = 80;
const DEFAULT_PICKS = 50;

// pattern data
let stitches;
let TX, TL;
let tieUp, drawdown;

// tracking user input
var editThreading = true; 	// if true, editing tie-up in tieUpInputs
  							//if false, editing treadles instead
var ctrlPressed = false;
let error;

// graphics set-up
const DIMCELL_DEFAULT = 8;
let xo, yo;
let tutHeight;

// initializing bools for walkthrough steps
var inputOnThreading = false;
var switchedDirection = false;
var switchedToTreadling = false;
var inputOnTreadling = false;
var tutorialList = [inputOnThreading, switchedDirection, switchedToTreadling, inputOnTreadling];

// command list HTML
var commandHTML = 
	'<p>'+key('t')+' - switch between editing treadles/threading.</p>' +
	'<p>'+key('backspace')+' - remove the most recent key input.</p>' +
	'<p>'+key('+')+'/'+key('-')+' - add/remove one warp (if editing threading) <i>OR</i> one pick/row (if editing treadling) to the draft.</p>'+
	'<p>'+key('Shift')+'+'+key('+')+'/'+key('Shift')+'+'+key('-')+' - zoom in/out.</p>'+
	'<h3>Threading Inputs</h3>'+
	'<p>'+key('1')+', '+key('3')+', '+key('5')+' - add a threading block of that width.</p>' +
	'<p>'+key('r')+' - reverse pattern progression</p>' +
	'<h3>Treadling Inputs</h3>'+
	'<p>'+key('1')+'-'+key('6')+' - add a treadling block on the corresponding treadle. '+key('1')+'-'+key('4')+' are woven as overshot, with tabby picks automatically inserted.</p>'+
	'<h3>Profile Mode</h3>'+
	'<p>'+key('p')+' - switch the current box between profile/normal view.</p>'+
	'<p>'+key('Shift')+'+'+key('p') + ' ('+key('P')+') - switch both threading and treadling between profile/normal views.</p>'+
	'<p>'+key('o')+' - switch profile mode of treadling between compact/expanded.</p>'
;

// element vars
var canvas, sidebar, hiddenSidebar;
var controlDiv, advancedDiv;
var ctrlVisButton, tutVisButton, sidebarVisButton;

// visibility status
var controlsVis = false;
var tutorialVis = true;
var sidebarVis = true;
var advancedVis = false;

/* page element display functions */

function toggleControls() {
	if (controlsVis) {
		ctrlVisButton.innerHTML = 'Show';
		controlDiv.innerHTML = '';
		sidebar.classList.remove('expanded-height');
		sidebar.classList.add('single-height');
		controlsVis = false;
	} else {
		ctrlVisButton.innerHTML = 'Hide';
		controlDiv.innerHTML = commandHTML;
		sidebar.classList.remove('single-height');
		sidebar.classList.add('expanded-height');
		controlsVis = true;
	}
}

function toggleTutorial() {
	if (tutorialVis) {
		tutVisButton.innerHTML = 'Show Tutorial';
		yo = 3*dim_cell;
		for (i = 0; i < tutorialList.length; i++) {
			tutorialList[i] = false;
		}
		tutorialVis = false;
	} else {
		tutVisButton.innerHTML = 'Hide Tutorial';
		yo = 14*dim_cell;
		for (i = 0; i < tutorialList.length; i++) {
			tutorialList[i] = true;
		}
		tutorialVis = true;
	}
}

function toggleSidebar() {
	if (sidebarVis) {
		sidebar.setAttribute("hidden", true);
		hiddenSidebar.removeAttribute("hidden");
  		document.getElementById('sketch').style.left = "5%";
		sidebarVis = false;
	} else {
		sidebar.removeAttribute("hidden");
		hiddenSidebar.setAttribute("hidden", true);
  		document.getElementById('sketch').style.left = "25%";
		sidebarVis = true;
	}
}

function toggleAdvanced() {
	if (advancedVis) {
		document.getElementById("advanced-vis").innerHTML = "Show";
		advancedDiv.setAttribute("hidden", true);
		advancedVis = false;
	} else {
		document.getElementById("advanced-vis").innerHTML = "Hide";
		advancedDiv.removeAttribute("hidden");
		advancedVis = true;
	}
}

function saveDesign() {
	var disabledTut = false;
	if (tutorialVis) {
		toggleTutorial();
		disabledTut = true;
	}
	saveCanvas();
	// if (disabledTut) {
	// 	toggleTutorial();
	// }
}

/* P5 FUNCTIONS START HERE */

function setup() {
	console.log("setup");
	canvas = createCanvas(0.7*windowWidth, 0.99*windowHeight);
	canvas.parent('sketch');

	sidebar = document.getElementById('sidebar');
	hiddenSidebar = document.getElementById('sidebar-hidden');

	controlDiv = document.getElementById('controls-list');
	controlDiv.innerHTML = '';

	advancedDiv = document.getElementById('adv-functions');

	ctrlVisButton = document.getElementById('ctrl-vis-button');
	tutVisButton = document.getElementById('tut-vis-button');
	sidebarVisButton = document.getElementById('sidebar-vis-button');

	xo = dim_cell;
	yo = 14*dim_cell;
  
  	error = "";

  	tieUp = [[false, true, true, true, false, true],
             [true, true, true, false, true, false],
             [true, true, false, true, false, true],
             [true, false, true, true, true, false]];
	        //new boolean[shafts][treadles];
	TX = new Threading(DEFAULT_SHAFTS, DEFAULT_WARPS);
	TL = new Treadling(DEFAULT_TREADLES, DEFAULT_PICKS);
	drawdown = new DraftContainer(TL.picks, TX.warps);
}

function draw() {
	background(255);
	// display input mode, instruction text, error messages
	fill(0);
	noStroke();
	textSize(12);
	// instruction text
	if (tutorialVis) {
		if (inputOnThreading) {
			text("Press '1', '3', or '5' to add a threading block of that width. Press 'r' to reverse pattern direction.", DIMCELL_DEFAULT, yo/4);
		} else { 
			text("Press '1', '3', or '5' to add a threading block of that width.", DIMCELL_DEFAULT, yo/4); 
		}
		if (switchedDirection) {	
			text("Press 't' to switch to editing treadles (or to switch back to threading).", DIMCELL_DEFAULT, yo/4+15);
		}
		if (switchedToTreadling) {
			text("    Press a key '1' to '6' to add a treadling block.", DIMCELL_DEFAULT, yo/4+30);
			text("    Blocks 1-4 are woven as overshot, so tabby rows are automatically inserted before each pattern pick.", DIMCELL_DEFAULT, yo/4+45);
		}
		if (inputOnTreadling) {
			text("Press backspace to delete the most recent treadling or threading block.", DIMCELL_DEFAULT, yo/4+60);
		}
	}

	// status text
	text("threading: "+TX.threadingCount+" / "+ TX.warps+ " ends", DIMCELL_DEFAULT, yo-4);
	var dir = new String();
	if (TX.direction) {
		dir = "1-2-3-4";
	} else { dir = "4-3-2-1"; }
	text("direction: "+dir, DIMCELL_DEFAULT+200, yo-4);

	// console.log(code+" "+pw);
	fill(255, 0, 0);
	noStroke();
	textSize(12);
	text(error, xo, yo-20); 

	stroke(0);
	// DRAW THREADING
	for (var i = 0; i < TX.shafts; i++) { // Y coord (row)
		for (var j = 0; j < TX.warps; j++) { // X coord (col)
			if (TX.displayData.getData(i,j)) { fill(0); }
			else if (editThreading && TX.profileView) {
				fill(0, 255, 0);
			} else if (editThreading) {
				fill(255, 255, 0);
			} else if (!editThreading && TX.profileView) {
				fill(200, 200, 200);
			} else {
				fill(255);
			}
			var dispX = TX.warps-1-j;
			var dispY = TX.shafts-1-i;
			rect(dispX*dim_cell+xo, dispY*dim_cell+yo, dim_cell, dim_cell);
		}
	}

	// DRAW TIE UP
	for (var i = 0; i < TX.shafts; i++) {
		for (var j = 0; j < TL.treadles; j++) {
	  		if (tieUp[i][j]) { fill(0); }
	  		else fill(255);
	  		rect((j+TX.warps+1)*dim_cell+xo, i*dim_cell+yo, dim_cell, dim_cell);
		}
	}

	// DRAW TREADLING
	for (var i = 0; i < TL.picks; i++) { //<>//
		for (var j = 0; j < TL.treadles; j++) {
		if (TL.displayData.getData(i,j)) fill(0);
		else if (!editThreading && TL.profileView) {
	    	fill(0, 255, 0);
	  	} else if (!editThreading) {
	    	fill(255, 255, 0);
	  	} else if (editThreading && TL.profileView) {
	    	fill(200, 200, 200);
	  	} else { fill(255); }
	  		rect((j+TX.warps+1)*dim_cell+xo, (i+TX.shafts+1)*dim_cell+yo, dim_cell, dim_cell);
		}
	}

	// DRAWDOWN
	for (var i = 0; i < TL.picks; i++) {
		for (var j = 0; j < TX.warps; j++) {
	  		if (drawdown.displayData.getData(i,j)) { fill(0); }
	 		else { fill(255); }
	  		var dispX = TX.warps-1-j;
	  		rect(dispX*dim_cell+xo, (i+TX.shafts+1)*dim_cell+yo, dim_cell, dim_cell);
		}
	}

	// keyboard events (commands valid for a key held down)
	// if (keyIsDown(LEFT_ARROW) && !keyIsDown(RIGHT_ARROW)) {
	// 	xo--;
	// }
	// if (keyIsDown(RIGHT_ARROW) && !keyIsDown(LEFT_ARROW)) {
	// 	xo++;
	// }

}

function mouseClicked() {
	// determine where mouse was clicked
	//console.log(mouseX, mouseY);
	// in threading rectangle
	if (mouseX > xo && mouseX < (dim_cell*TX.warps + xo) && 
	  mouseY > yo && mouseY < (dim_cell*TX.shafts+yo)) {
		var gridX = floor(TX.warps-(mouseX - xo)/dim_cell);
		var gridY = floor(TX.shafts-(mouseY - yo)/dim_cell);
		//console.log("mapping to", gridX, gridY);
		// only one black square per column allowed
		if (!TX.threading.getData(gridY,gridX)) {
      		for (var i = 0; i < TX.shafts; i++) {
        		// clear any black squares in the column before flipping square
	        	TX.threading.setData(i, gridX, false);
    		}
    	}
    	TX.threading.toggleCell(gridY, gridX);
	}
  	// in tie-up rectangle
  	if (mouseX > (dim_cell*TX.warps + xo) && mouseX < (dim_cell*(TX.warps+1+TL.treadles) + xo) &&
      mouseY > yo && mouseY < (dim_cell*TX.shafts+yo)) {
    	var gridX = floor((mouseX - xo - (TX.warps + 1)*dim_cell)/dim_cell);
    	var gridY = floor((mouseY - yo)/dim_cell);
    	tieUp[gridY][gridX] = !tieUp[gridY][gridX];
  	}
  	// in treadling rectangle
  	if (mouseX > (dim_cell*TX.warps + xo) && mouseX < (dim_cell*(TX.warps+1+TL.treadles) + xo) &&
      mouseY > (dim_cell*TX.shafts + yo) && mouseY < (dim_cell*(TX.shafts+1+TL.picks)+yo)) {
    	var gridX = floor((mouseX - xo - (TX.warps + 1)*dim_cell)/dim_cell);
    	var gridY = floor((mouseY - yo - (TX.shafts + 1)*dim_cell)/dim_cell);
    	// only one treadle allowed per row (why would I do multiple treadles no)
    	if (!TL.treadling.getData(gridY,gridX)) {
      		for (var i = 0; i < TL.treadles; i++) {
        	// clear any black squares in the row before flipping square
        		TL.treadling.setData(gridY, i, false);
      		}
    	}
    	TL.treadling.toggleCell(gridY, gridX);
  	}
  	updateDrawdown();
}

function updateDrawdown() {
  // each i-th row of the drawdown:
  // i-th treadling row -> which treadle was pressed?
  // on that treadle, what does that column of tie-up look like?
  // if cell in that column, then OR to make the row

  // for each row
  for (var row = 0; row < TL.picks; row++) {
    var updatedRow = [];
    var whichTreadle = -1;
    for (var t = 0; t < TL.treadles; t++) {
      if (TL.displayData.getData(row,t)) {
        whichTreadle = t;
        break;
      }
    }
    //console.log("Row", row, "uses treadle", whichTreadle);
    
    for (var col = 0; col < TX.warps; col++) {
      if (whichTreadle == -1) {
          // no treadle on this row, row should be empty
          //console.log("empty row");
          updatedRow[col] = false;
        } else {
          for (var s = 0; s < TX.shafts; s++) {
            updatedRow[col] |= tieUp[s][whichTreadle] && TX.displayData.getData(s,col);
        }
      }
    }
    //console.log(updatedRow);
    // copy updated row into drawdown
    for (var col = 0; col < TX.warps; col++) {
      drawdown.displayData.setData(row, col, updatedRow[col]);
    }
  }
  //console.log(drawdown.printData());
}

// handles single press (down and release) event
function keyPressed() {
  	// use numeric commands for editing tie-up and treadling
  	if (key >= '0' && key <= '9') {
    	var numKey = parseInt(key);
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
	        console.log(numKey, "invalid tie-up command");
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
	        console.log(numKey, "invalid treadle command");
	        error = "invalid treadle command: "+key;
	      }
	    }
	}
  
  	// deleting
  	if (keyCode === BACKSPACE) {
    	if (editThreading) {
      		TX.popBlock();
    	} else { TL.popBlock(); }
  	}

  	// look up keycodes at keycode.info
		// 't' to toggle tie-up / treadling keyboard input
		if (keyCode == 84) {
			if (!switchedToTreadling) {
	  		switchedToTreadling = true;
			}
			editThreading = !editThreading;
		}

		if (keyCode == 82) {
			if (!switchedDirection) {
	  		switchedDirection = true;
			}
			TX.reverse();
		}
	  
  	// profile view - 'p'
  	if (keyCode == 80 && !keyIsDown(16)) {
    	if (editThreading) {
      		TX.toggleProfile();
    	} else {
      		TL.toggleProfile();
    	}
  	} else if (keyCode == 80) { // SHIFT+'P' to toggle both
  		if (TX.profileView != TL.profileView) {
  			TL.toggleProfile();
  		} else {
  			TX.toggleProfile();
  			TL.toggleProfile();
  		}
  	}
  	// toggle profile mode of treadling - 'o'
  	if (keyCode == 79) {
    	TL.toggleProfMode();
  	}

  	// resizing
  	if (keyCode === 187 && !keyIsDown(16)) { // '=' key
    	if (editThreading) {
      		TX.addWarp();
      		drawdown.addCol();
    	} else {
      		TL.addPick();
      		drawdown.addRow();
    	}
  	} else if (keyCode === 187) { // zoom in with '+' or SHIFT, =
    	//console.log("zooming in");
    	dim_cell++;
  	}
  
  	if (keyCode === 189 && !keyIsDown(16)) { // '-' key
    	if (editThreading) {
      		TX.delWarp();
      		drawdown.delCol();
    	} else {
      		TL.delPick();
      		drawdown.delRow();
    	}
  	} else if (keyCode === 189) { // zoom out with SHIFT,-
    	//console.log("zooming out");
    	dim_cell--;	
  	}
  	updateDrawdown();
  	return false;
}

// HTML formatting helpers
function key(str) {
	return "<span class='key'>" + str + "</span>"
}
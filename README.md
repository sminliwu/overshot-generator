# Flowing Curves Overshot Generator

This repo also generates a webpage at <http://sminliwu.github.io/overshot-generator>, where you can use the generator in your browser without any other installation or set-up.

This is a P5/Processing sketch that allows someone to quickly make and edit a draft to produce a flowing, curving design using an overshot structure. For a weaving-centered explanation on why this produces a flowing overshot design, read [this article by Bonnie Inouye](http://www.weavezine.com/content/flowing-curves-part-1-overshot-and-weaving-overshot.html).

## How to Use
There is an interactive tutorial embedded in the generator that guides a user through the basic key commands. In the order that you'd see them, those instructions are:
1. Press '1', '3', or '5' to add a threading block of that width. Press 'r' to reverse pattern direction.
2. Press 't' to switch to editing treadles (or to switch back to threading).
   
   1. Press a key '1' to '6' to add a treadling block.
   
   2. Blocks 1-4 are woven as overshot, so tabby rows are automatically inserted before each pattern pick.

3. Press backspace to delete the most recent treadling or threading block.

### Other Controls
* `+`/`-` : adds/removes one warp (if editing threading) OR one pick/row (if editing treadling) to the draft.
* `Shift` `+`/`Shift` `-` : zooms in/zooms out.
* `p` : toggles the highlighted box (threading or treadling) between profile and normal modes.
* `Shift` `p` : toggles both threading and treadling between profile and normal modes.
* `o` : switches the profile mode of treadling.
* You can also click within the threading, tie-up, or treadling to manually edit those boxes. (use at your own risk)

## Files
* ORIG_overshotGenerator - Directory for the original overshot generator created by my advisor, which worked with a different type of overshot draft.
* OvershotCurveGen -  Directory for Processing (Java) code for the flowing curves overshot generator.
* index.html - HTML page that runs the P5.js generator.
* overshotCurveGen.js - P5.js code for the flowing curves overshot generator.
* Threading.js - Javascript class for the threading portion of the draft (top left quadrant)
* Treadling.js - Javascript class for the treadling portion of the draft. (bottom right quadrant)

## Features in Progress
* Sidebar that fully explains the controls like this readme does.
* Exporting the draft as an image.
* Exporting an abbreviated threading draft using my own notation of block lengths with the shaft numbers.
* Optimizing the P5 version using Javascript's ArrayBuffer or TypedArray structures, not the Array types that cause some inefficiencies and slowness in the current version.
* If you have suggestions for other features/modifications, contact me OR fork the repo to modify the tool!

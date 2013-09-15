/*******************************************************************
 *	VideoAlchemy "Juggling Molecules" Interactive Light Sculpture
 *	(c) 2011-2013 Jason Stephens & VideoAlchemy Collective
 *
 *	See `credits.txt` for base work and shouts out.
 *	Published under CC Attrbution-ShareAlike 3.0 (CC BY-SA 3.0)
 *		            http://creativecommons.org/licenses/by-sa/3.0/
 *******************************************************************/

import oscP5.*;	// TouchOSC
import netP5.*;
import processing.video.*;
import processing.opengl.*;
import javax.media.opengl.*;
import java.util.Iterator;

////////////////////////////////////////////////////////////
//	Global objects
////////////////////////////////////////////////////////////
	// TouchOSC controller
	OscP5 gTouchController;

	// TouchOSC device we're connecting to.
	// Set when we receive our first OscMessage in `touchOSC_controls::oscEvent()`.
	NetAddress 	gTouchControllerAddress;

	// Kinect helper
	Kinecter gKinecter;

	// OpticalFlow field which converts Kinect depth into a vector flow field
	OpticalFlow gFlowfield;

	// Particle manager which renders the flow field
	ParticleManager gParticleManager;

	// Configuration object, manipulated by TouchOSC and OmiCron
	MolecularConfig gConfig;


////////////////////////////////////////////////////////////
//	Screen setup (constant for all configs)
////////////////////////////////////////////////////////////
	// projector size
	int gWindowWidth = 1920;
	int gWindowHeight = 1200;

	// Drawing mode
	String gDrawMode = OPENGL;


////////////////////////////////////////////////////////////
//	Kinect setup (constant for all configs)
////////////////////////////////////////////////////////////
	// size of the kinect
	int   gKinectWidth=640, gKinectHeight = 480;		 // use by optical flow and particles
	float gInvKWidth = 1.0f/gKinectWidth;		 // inverse of screen dimensions
	float gInvKHeight = 1.0f/gKinectHeight;	 // inverse of screen dimensions
	float gKinectToWindowWidth	= ((float) gWindowWidth)	* gInvKWidth;		// multiplier for kinect size to window size
	float gKinectToWindowHeight = ((float) gWindowHeight) * gInvKHeight;	 // multiplier for kinect size to window size


// Initialize all of our global objects.
//
// NOTE: We want as much as possible to come from our gConfig object,
//		 which we can dynamically reload.  All config variables
//		 can be overridden except for the `setupXXX` items.
//
void setup() {
	// set up with OPENGL rendering context == faster
	size(gWindowWidth, gWindowHeight, gDrawMode);

	// Initialize TouchOSC control bridge and start it listening on port 8000
	gTouchController = new OscP5(this, 8000);

	// create the config object
	gConfig = new MolecularConfig();

	// set up display parametets
	background(gConfig.windowBgColor);
	frameRate(gConfig.setupFPS);

	// set up noise seed
	noiseSeed(gConfig.setupNoiseSeed);

	// helper class for kinect
	gKinecter = new Kinecter(this);

	// Create the particle manager.
	gParticleManager = new ParticleManager(gConfig);

	// Create the flowfield
	gFlowfield = new OpticalFlow(gConfig, gParticleManager);

	// Tell the particleManager about the flowfield
	gParticleManager.flowfield = gFlowfield;
}


// Our draw loop.
void draw() {
	pushStyle();
	pushMatrix();

	// partially fade the screen by drawing a semi-opaque rectangle over everything
	fadeScreen(gConfig.windowBgColor, gConfig.windowOverlayAlpha);

	// updates the kinect raw depth + gKinecter.depthImg
	gKinecter.updateKinectDepth(true);

	// update the optical flow vectors from the gKinecter depth image
	// NOTE: also draws the force vectors if `showFlowLines` is true
	gFlowfield.update();

	// show the flowfield particles
	if (gConfig.showParticles) gParticleManager.updateAndRender();

	// draw the depth image over the particles
	if (gConfig.showDepthImage) drawDepthImage();

	// display instructions for adjusting kinect depth image on top of everything else
	if (gConfig.showSettings) drawInstructionScreen();


	popStyle();
	popMatrix();
}


// That's all folks!
void stop() {
  gKinecter.quit();
  super.stop();
}


#import "MainViewController.h"

#import "HCIPlayerAppDelegate.h"
#import "VoiceRecognizer.h"
#import "Gestures.h"
#import "Commands.h"

#import <Celestial/Celestial.h>
#import <Tutorial.h>
#import <time.h>

#define SAY(str) [self.feedback SayText:@str]

@implementation Tutorial
tutorial_cmd_t cmd;
AudioFeedback *feedback;

-(id)init: (AudioFeedback*)feedback
{
	if (self = [super init])
	{
		self.feedback = feedback;
		self.cmd = TUT_OFF;
	}
	return self;
}

/**
 * Issue the corresponding command
 * Returns true if it was the expected command
 */
-(BOOL) issueCommand: (tutorial_cmd_t) command
{
	//If it's off and not to be started, just let it slide
	if(self.cmd == TUT_OFF && command != TUT_START)
		return true;

	if(self.cmd != TUT_OFF && command == TUT_OFF)
	{
		self.cmd = TUT_OFF;
		[self runCommand];
		return true;
	}
	if(self.cmd == command)
	{
		command++;
		[self runCommand];
		if(self.cmd == TUT_DONE)
			self.cmd == TUT_OFF;
		return true;
	} else if (self.cmd == TUT_OFF && command == TUT_START)
	{
		self.cmd = TUT_INTRO;
		[self runCommand];
	}
	return false;
}

/**
 * Run actions for whatever is the current command
 */
-(void) runCommand
{
	switch(self.cmd)
	{
		case TUT_OFF:
			SAY("Now exiting the tutorial");
			break;
		case TUT_INTRO:
			SAY("Hello, and welcome to the HCIplayer portable music player tutorial. At any time you can exit this tutorial with the voice command 'exit'.")
			SAY("We will now walk you through some of the basic operations of the player:");
		case TUT_TAP_ONCE:
			SAY("Tap the screen once to begin playback");
			break;
		case TUT_ADJUST_VOL:
			SAY("Pause the music again by tapping the screen again");
			break;
		case TUT_SAY_PLAY:
			SAY("Now hold a finger on the screen to issue the 'play' voice command. After a moment, you will feel a vibration, signalling for you to start speaking. When you are done speaking, release the screen. Issue the 'play' command");
			break;
		case TUT_SWIPE_NEXT:
			SAY("Now advance to the next track by swiping a finger to the right on the screen");
			break;
		case TUT_SWIPE_PREV:
			SAY("Try the reverse as well, swiping back to the left");
			break;
		case TUT_SAY_ARTIST:
			SAY("Now try selecting an artist to play. Issue a voice command like before, but this time say 'play artist tool'");
			break;
		case TUT_SAY_SONG:
			SAY("You can be more specific too. Try playing a particular song by saying 'play artist rage against the machine song bulls on parade'");
			break;
		case TUT_QUEUE_SONG:
			SAY("In addition to immediately playing a song, you can queue it for later. The 'queue' command works just like the 'play' command. Try to queue an album by saying 'queue artist coldplay album a rush of blood to the head'");
			break;
		case TUT_SAY_NEXT:
			SAY("Now try advancing to the next song with the voice command 'next'");
			break;
		case TUT_SEEK:
			SAY("Just like you used your finger to adjust the volume, you can seek through the current track by tapping, and then moving left and right. Try seeking forward a bit.");
			break;
		case TUT_REPLAY:
			SAY("You can easily return the beginning of a song by issuing the voice command, 'replay'. Try this now.");
			break;
		case TUT_SHUFFLE_ON:
			SAY("To adjust how the player advances through your playlist, you can enable shuffle. This randomizes the playback order. Try telling the player 'turn shuffle on'.");
			break;
		case TUT_SHUFFLE_OFF:
			SAY("You can turn it off by saying 'turn shuffle off'. Try this");
			break;
		case TUT_REPEAT_ON:
			SAY("Similarly, you can make the playlist repeat itself by saying 'turn repeat on'. Try it");
			break;
		case TUT_REPEAT_OFF:
			SAY("Now when all of your songs have played, it will start again at the beginning. Try turning this off, with 'turn repeat off'");
			break;
		case TUT_DONE:
			SAY("Congratulations! You have completed the HCIPlayer tutorial. We hope that this system is able to help you listen to music like never before!");
			break;
	}
}

@end

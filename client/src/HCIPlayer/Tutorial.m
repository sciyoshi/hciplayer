#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Tutorial.h"
#import "Gesture.h"
#import "MainViewController.h"

@implementation Tutorial

@synthesize cmd;
@synthesize state;
@synthesize feedback;

- (id) init: (AudioFeedback*) _feedback
{
	if (self = [super init]) {
		self.feedback = _feedback;
		self.state = TUT_OFF;
	}
	return self;
}

- (BOOL) compareCommand: (Command) command
{
	return self.cmd.type == command.type && (command.gesture == nil || command.gesture.state == UIGestureRecognizerStateRecognized);
}

/**
 * Issue the corresponding command
 * Returns true if it was the expected command
 */
-(BOOL) handleCommand: (Command) command
{
	// if it's off and not to be started, just let it slide
	if (self.state == TUT_OFF && command.type != COMMAND_TUTORIAL)
		return YES;

	if (self.state != TUT_OFF && command.type  == COMMAND_EXIT) {
		self.state = TUT_OFF;
		[self runCommand];
		return NO;
	}

	if (self.cmd.type == command.type) {
		if (command.gesture == nil || command.gesture.state == UIGestureRecognizerStateRecognized) {
			state++;
			[self runCommand];
		}
		return YES;
	} else if (self.state == TUT_INTRO || (self.state == TUT_OFF && command.type == COMMAND_TUTORIAL)) {
		self.state = TUT_INTRO;
		[self runCommand];
	} else if (self.cmd.type != command.type) {
		if (command.gesture == nil || command.gesture.state == UIGestureRecognizerStateRecognized) {
			return NO;
		}
	}
	return NO;
}

/**
 * Run actions for whatever is the current command
 */
-(void) runCommand
{
	switch (self.state)
	{
		case TUT_OFF:
			SAY(@"Now exiting the tutorial");
			break;
		case TUT_INTRO:
			SAY(@"Hello, and welcome to the H.C.I. portable music player tutorial. At any time you can exit this tutorial with the voice command 'exit'. \
			We will now walk you through some of the basic operations of the player: \
			Tap the screen once to begin playback");
			cmd.type = COMMAND_TAP;
			break;
		case TUT_ADJUST_VOL:
			SAY(@"Good! Now try adjusting the volume by dragging up or down on the screen.");
			cmd.type = COMMAND_SWIPE_UPDOWN;
			break;
		case TUT_TAP_AGAIN:
			SAY(@"Pause the music again by tapping the screen again");
			cmd.type = COMMAND_TAP;
			break;
		case TUT_SAY_PLAY:
			SAY(@"Now you will issue the voice command \"play\". To do this, you must hold your finger on the screen and wait until you feel a vibration, signalling for you to start speaking. When you are done speaking, release the screen.");
			cmd.type = COMMAND_PLAY;
			break;
		case TUT_SWIPE_NEXT:
			SAY(@"Now advance to the next track by swiping a finger to the right on the screen");
			cmd.type = COMMAND_SWIPE_RIGHT;
			break;
		case TUT_SWIPE_PREV:
			SAY(@"Try the reverse as well, swiping back to the left");
			cmd.type = COMMAND_SWIPE_LEFT;
			break;
		case TUT_SAY_ARTIST:
			SAY(@"Now try selecting an artist to play. Issue a voice command like before, but this time say 'play artist tool'");
			cmd.type = COMMAND_PLAY_ITEMS;
			break;
		case TUT_SAY_SONG:
			SAY(@"You can be more specific too. Try playing a particular song by saying 'play artist rage against the machine song bulls on parade'");
			cmd.type = COMMAND_PLAY_ITEMS;
			break;
		case TUT_QUEUE_SONG:
			SAY(@"In addition to immediately playing a song, you can queue it for later. The 'queue' command works just like the 'play' command. Try to queue an album by saying 'queue artist coldplay album a rush of blood to the head'");
			cmd.type = COMMAND_QUEUE_ITEMS;
			break;
		case TUT_SAY_NEXT:
			SAY(@"Now try advancing to the next song with the voice command 'next'");
			cmd.type = COMMAND_NEXT;
			break;
		case TUT_SEEK:
			SAY(@"Just like you used your finger to adjust the volume, you can seek through the current track by tapping, and then moving left and right. Try seeking forward a bit.");
			cmd.type = COMMAND_SWIPE_LEFTRIGHT;
			break;
		case TUT_REPLAY:
			SAY(@"You can easily return the beginning of a song by issuing the voice command, 'replay'. Try this now.");
			cmd.type = COMMAND_REPLAY;
			break;
		/*
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
		*/
		case TUT_DONE:
			SAY(@"Congratulations! You have completed the HCIPlayer tutorial. We hope that this system is able to help you listen to music like never before!");
			self.state = TUT_OFF;
			break;
	}
}

@end

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Commands.h"
#import "AudioFeedback.h"
#import "AudioController.h"

typedef enum {
	TUT_OFF,		//Message to bail, initial state
	TUT_START,
	TUT_INTRO,		//hello and welcome...we will now tap the screen once to begin playback
	TUT_ADJUST_VOL,	//tap once, followed by a gentle movement up or down
	TUT_TAP_AGAIN,
	TUT_SAY_PLAY,	//now hold a finger on the screen to issue a "play" command
	TUT_SWIPE_NEXT,	//Now advance to the next track by swiping
	TUT_SWIPE_PREV,	//Try the reverse as well
	TUT_SAY_ARTIST,	//Now try selecting an artist to play
	TUT_SAY_SONG,	//You can be more specific too. Try playing a particular song
	TUT_QUEUE_SONG,	//In addition to immediately playing a song, you can queue it for later
	TUT_SAY_NEXT,	//Now try advancing to the next song with the voice command 'next'
	TUT_SEEK ,		//Just like you used your finger to adjust the volume, you can seek through the current track
	TUT_REPLAY,	//You can easily return the beginning of a song by issuing the voice command, 'replay'
	//TUT_SHUFFLE_ON = 15,	//To adjust how the player advances through your playlist, you can enable shuffle
	//TUT_SHUFFLE_OFF = 16,	//You can turn it off by saying 'turn shuffle off'
	//TUT_REPEAT_ON = 17,	//Similarly, you can make the playlist repeat itself by saying 'turn repeat on'
	//TUT_REPEAT_OFF = 18,	//Now when all of your songs have played, it will start again at the beginning. Try turning this off
	TUT_DONE
} TutorialState;

@interface Tutorial : NSObject
{
	Command cmd;
	TutorialState state;
	AudioFeedback *feedback;
}

@property (assign) Command cmd;
@property (assign) TutorialState state;
@property (retain) AudioFeedback *feedback;

-(id) init: (AudioFeedback *) feedback;
-(BOOL) handleCommand: (Command) command;
-(void) runCommand;

@end



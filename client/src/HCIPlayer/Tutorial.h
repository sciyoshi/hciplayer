#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMusicPlayerController.h>

#import "AudioFeedback.h"
#import "AudioController.h"
#import "VoiceRecognizer.h"
#import "Tutorial.h"
#import "MainViewActionRep.h"

typedef enum {
	TUT_OFF = 0,		//Message to bail, initial state
	TUT_START = 1,
	TUT_INTRO = 2,		//hello and welcome...we will now
	TUT_TAP_ONCE = 3,	//tap the screen once to begin playback
	TUT_ADJUST_VOL = 4,	//tap once, followed by a gentle movement up or down
	TUT_SAY_PLAY = 5,	//now hold a finger on the screen to issue a "play" command
	TUT_SWIPE_NEXT = 6,	//Now advance to the next track by swiping
	TUT_SWIPE_PREV = 7,	//Try the reverse as well
	TUT_SAY_ARTIST = 8,	//Now try selecting an artist to play
	TUT_SAY_SONG = 9,	//You can be more specific too. Try playing a particular song
	TUT_QUEUE_SONG = 10,	//In addition to immediately playing a song, you can queue it for later
	TUT_SAY_NEXT = 11,	//Now try advancing to the next song with the voice command 'next'
	TUT_SEEK = 12,		//Just like you used your finger to adjust the volume, you can seek through the current track
	TUT_REPLAY = 13,	//You can easily return the beginning of a song by issuing the voice command, 'replay'
	TUT_SHUFFLE_ON = 14,	//To adjust how the player advances through your playlist, you can enable shuffle
	TUT_SHUFFLE_OFF = 15,	//You can turn it off by saying 'turn shuffle off'
	TUT_REPEAT_ON = 16,	//Similarly, you can make the playlist repeat itself by saying 'turn repeat on'
	TUT_REPEAT_OFF = 17,	//Now when all of your songs have played, it will start again at the beginning. Try turning this off
	TUT_DONE = 18
} tutorial_cmd_t;

@interface Tutorial

-(id)init: (AudioFeedback*)feedback;
-(BOOL) issueCommand: (tutorial_cmd_t) command;

@end



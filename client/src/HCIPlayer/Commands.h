#import <Foundation/Foundation.h>

#import <UIKit/UIView-UIViewGestures.h>

typedef enum {
	COMMAND_NONE,
	COMMAND_TAP
	COMMAND_SWIPE_RIGHT,
	COMMAND_SWIPE_LEFT,
	COMMAND_SWIPE_UPDOWN,
	COMMAND_SwIPE_LEFTRIGHT,
	COMMAND_PLAY,
	COMMAND_PAUSE,
	COMMAND_NEXT,
	COMMAND_PREVIOUS,
	COMMAND_REPLAY,
	COMMAND_INFO,
	COMMAND_HELP,
	COMMAND_EXIT,
	COMMAND_TUTORIAL,
	COMMAND_SHUFFLE,
	COMMAND_REPEAT,
	COMMAND_PLAY_ITEMS,
	COMMAND_QUEUE_ITEMS,
} CommandType;

typedef enum {
	COMMAND_TOGGLE,
	COMMAND_ON,
	COMMAND_OFF,
} CommandArg;

typedef struct {
	CommandType type;
	union {
		UIGestureRecognizer *gesture;
		CommandArg arg;
		NSString *title;
	}
	NSString *album;
	NSString *artist;
} Command;



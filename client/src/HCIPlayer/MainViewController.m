#import "MainViewController.h"

#import "HCIPlayerAppDelegate.h"
#import "VoiceRecognizer.h"
#import "Gestures.h"

#import <Celestial/Celestial.h>

#import <time.h>


@implementation MainViewController

@synthesize label;
@synthesize image;
@synthesize player;

@synthesize audio;
@synthesize voice;
@synthesize feedback;

/* Prototypes */
extern void * _CTServerConnectionCreate(CFAllocatorRef, int (*)(void *, CFStringRef, CFDictionaryRef, void *), int *);
extern int _CTServerConnectionSetVibratorState(int *, void *, int, float, float, float, float);

- (void) loadView
{
	UIView *view = self.view = [[GestureView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];

	self.image = [[UIImageView alloc] initWithFrame:CGRectInset([view bounds], 20, 20)];
	self.image.opaque = NO;
	self.image.clearsContextBeforeDrawing = NO;
	self.image.backgroundColor = [UIColor clearColor];
	self.image.contentMode = UIViewContentModeScaleAspectFit;
	self.image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	[view addSubview:self.image];

	CGRect rect = CGRectInset([view bounds], 20, 0);

	rect.origin.y += rect.size.height - 60.0;
	rect.size.height = 40.0;

	self.label = [[UILabel alloc] initWithFrame:rect];
	self.label.backgroundColor = [UIColor clearColor];
	self.label.opaque = NO;
	self.label.clearsContextBeforeDrawing = NO;
	self.label.textColor = [UIColor whiteColor];
	self.label.textAlignment = UITextAlignmentCenter;
	self.label.font = [UIFont systemFontOfSize:32.0];
	self.label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

	[view addSubview:self.label];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void) setImageForPlaybackState
{
	if (self.voice.recording) {
		self.image.image = recordImage;
	} else if ([player playbackState] == MPMusicPlaybackStatePlaying) {
		self.image.image = playImage;
	} else {
		self.image.image = pauseImage;
	}
}

- (void) voiceRecordingStopped: (VoiceRecognizer *) recognizer successfully: (BOOL) flag
{
	[self.player play];
	[self.audio finishRecording];
	[self setImageForPlaybackState];
}

typedef enum {
	COMMAND_NONE,
	COMMAND_HELP,
	COMMAND_INFO,
	COMMAND_PLAY,
	COMMAND_PAUSE,
	COMMAND_NEXT,
	COMMAND_PREVIOUS,
	COMMAND_REPLAY,
	COMMAND_SHUFFLE,
	COMMAND_SHUFFLE_ON,
	COMMAND_SHUFFLE_OFF,
	COMMAND_REPEAT,
	COMMAND_REPEAT_ON,
	COMMAND_REPEAT_OFF,
	COMMAND_LIST_PLAY,
	COMMAND_LIST_QUEUE,
} CommandType;

typedef struct {
	CommandType type;
	NSString *artist;
	NSString *album;
	NSString *title;
} Command;

- (void) commandHelp
{
	[self.feedback sayText:@"You can say things like, play, pause, repeat, \
	 next song, play previous, re-play track, and toggle mute. To play or \
	 queue a specific song, say 'play' or 'queue', followed by the artist \
	 name or song title. For example, try saying 'Play song Bulls on Parade'."];
}

- (void) commandInfo
{
	if ([self.player playbackState] == MPMusicPlaybackStatePlaying) {
		[self.feedback sayText:[NSString stringWithFormat:@"Now playing %@ by %@",
								[[self.player nowPlayingItem] valueForProperty:@"title"],
								[[self.player nowPlayingItem] valueForProperty:@"artist"]]];
	}
}

- (void) handleCommand: (Command) command
{
	if (command.type == COMMAND_HELP) {
		[self commandHelp];
	} else if (command.type == COMMAND_INFO) {
		[self commandInfo];
	}
}

#define MATCH(tp, str) if ([text isEqualToString:str]) { command.type = tp; return command; } 
#define MATCHP(tp, str) if ([text hasPrefix:str]) { command.type = tp; return command; }

- (Command) parseVoiceCommand: (NSString *) text
{
	Command command = { .type = COMMAND_NONE };

	MATCH(COMMAND_HELP, @"list available commands");
	MATCH(COMMAND_HELP, @"available commands");
	MATCH(COMMAND_HELP, @"what can i say");
	MATCHP(COMMAND_HELP, @"help");

	MATCH(COMMAND_INFO, @"what's playing");
	MATCH(COMMAND_INFO, @"what is playing");
	MATCH(COMMAND_INFO, @"now playing");
	MATCH(COMMAND_INFO, @"info");

	MATCH(COMMAND_PLAY, @"play");
	MATCH(COMMAND_PAUSE, @"pause");
	MATCH(COMMAND_PAUSE, @"stop");

	MATCHP(COMMAND_NEXT, @"next");
	MATCHP(COMMAND_NEXT, @"play next");

	MATCHP(COMMAND_PREVIOUS, @"previous");
	MATCHP(COMMAND_PREVIOUS, @"play previous");

	MATCHP(COMMAND_REPLAY, @"replay");
	
	MATCH(COMMAND_SHUFFLE, @"shuffle");
	MATCH(COMMAND_SHUFFLE, @"toggle shuffle");

	MATCH(COMMAND_SHUFFLE_ON, @"shuffle on");
	MATCH(COMMAND_SHUFFLE_ON, @"turn shuffle on");

	MATCH(COMMAND_SHUFFLE_OFF, @"shuffle off");
	MATCH(COMMAND_SHUFFLE_OFF, @"turn shuffle off");

	MATCH(COMMAND_REPEAT, @"repeat");
	MATCH(COMMAND_REPEAT, @"toggle repeat");
	
	MATCH(COMMAND_REPEAT_ON, @"repeat on");
	MATCH(COMMAND_REPEAT_ON, @"turn repeat on");

	MATCH(COMMAND_REPEAT_OFF, @"repeat off");
	MATCH(COMMAND_REPEAT_OFF, @"turn repeat off");

	if ([text hasPrefix:@"play"] || [text hasPrefix:@"queue"]) {
		NSArray *components = [text componentsSeparatedByString:@" "];

		if ([text hasPrefix:@"play"])
			command.type = COMMAND_LIST_PLAY;
		else
			command.type = COMMAND_LIST_QUEUE;
		
		NSString *first = [components objectAtIndex:1];
		
		if ([first isEqualToString:@"all"]) {
			
		} else if ([first isEqualToString:@"artist"]) {
			
		}
	}

	return command;
}

- (void) voiceRecognitionFinished: (VoiceRecognizer *) recognizer withText: (NSString *) text
{
	Command command = [self parseVoiceCommand:text];

	[self handleCommand:command];

	self.label.text = text;
}

int vibratecallback(void *connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
	return 1;
}

- (void) vibrate {
	AudioServicesPlaySystemSound(0xFFF);
}
- (void)setVibration:(BOOL)onoff intensity:(float)intensity duration:(float)duration{
	static NSMutableDictionary *dict;
	if (!dict) {
		dict = [NSMutableDictionary new];
	}
	[dict setObject:[NSNumber numberWithFloat:intensity] forKey:@"Intensity"];
	[dict setObject:[NSNumber numberWithFloat:0] forKey:@"OffDuration"];
	[dict setObject:[NSNumber numberWithFloat:duration] forKey:@"OnDuration"];
	[dict setObject:[NSNumber numberWithFloat:duration] forKey:@"TotalDuration"];	
	
	static AVController *avc;
	
	NSError *error = [NSError alloc];
	AVItem *avitem = [[AVItem alloc] initWithPath:@"/System/Library/CoreServices/SpringBoard.app/unlock.aiff" error:&error];
	AVQueue *avqueue = [AVQueue queueWithArray:[NSArray arrayWithObjects:avitem, nil] error:&error];
	avc = [AVController avControllerWithQueue:avqueue error:&error];
			

	[avc play:nil];
	[avc pause];
	[avc setVibrationPattern:dict];
	@synchronized(self){
		[avc setVibrationEnabled:TRUE];
		usleep(1000000);
	}
    NSLog ([NSString stringWithFormat:@"enabled: %i, pattern:%@", [avc vibrationEnabled], [avc vibrationPattern]]);
}

- (void) handleNowPlayingItemChanged: (id) notification
{
	self.label.text = [[self.player nowPlayingItem] valueForProperty:@"title"];
}

- (void) handlePlaybackStateChanged: (id) notification
{
	[self setImageForPlaybackState];
}

- (void) handleVolumeChanged: (id) notification
{

}

- (void) handleRight: (Gesture *) gesture
{
	[self.player skipToNextItem];
}

- (void) handleLeft: (Gesture *) gesture
{
	[self.player skipToPreviousItem];
}

- (void) handleTap: (Gesture *) gesture
{
	if ([self.player playbackState] == MPMusicPlaybackStatePlaying) {
		[self.player pause];
	} else {
		[self.player play];
	}
}

- (void) handleHold: (Gesture *) gesture
{
	if ([gesture state] == GESTURE_STATE_STARTED) {
		NSLog(@"1..");
		[self.audio prepareForRecording];
		NSLog(@"1.5");
		[self.voice.recorder prepareToRecord];
		NSLog(@"3..");
		[self vibrate];
		NSLog(@"4..");
		self.image.image = recordImage;
		NSLog(@"5..");
		[self.voice start];
		NSLog(@"6..");
	} else if ([gesture state] == GESTURE_STATE_RECOGNIZED) {
		[self.voice finish];
		//[self setVibration:TRUE intensity:1 duration:1];
	} else if ([gesture state] == GESTURE_STATE_CANCELLED) {
		[self.voice cancel];
		[self vibrate];
		//[self setVibration:TRUE intensity:1 duration:0.2];
		//[self setVibration:TRUE intensity:1 duration:0.2];
	}
}

- (void) handleUpDown: (SwipeGesture *) gesture
{
	if ([gesture state] == GESTURE_STATE_UPDATED) {
		CGPoint position = [gesture position];
		self.label.text = [NSString stringWithFormat:@"%@, %@", [NSNumber numberWithInt:position.x], [NSNumber numberWithInt:position.y]];
		//[self setVibration:TRUE intensity:1 duration:1];
	} else if ([gesture state] == GESTURE_STATE_STARTED){
	} else if ([gesture state] == GESTURE_STATE_RECOGNIZED) {
		
	} else if ([gesture state] == GESTURE_STATE_CANCELLED) {
		
	}
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	audio = [AudioController sharedInstance];

	voice = [VoiceRecognizer new];
	voice.delegate = self;

	feedback = [AudioFeedback new];

	GestureView *view = (GestureView *) self.view;

	playImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-play" ofType:@"png" inDirectory:@"Images"]];
	pauseImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-pause" ofType:@"png"inDirectory:@"Images"]];
	recordImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"audio-input-microphone" ofType:@"png"inDirectory:@"Images"]];

	Gesture *gesture = [[LongPressGesture alloc] initWithTarget:self selector:@selector(handleHold:)];
	((LongPressGesture *) gesture).onRelease = NO;
	[view addGesture:gesture];

	gesture = [[SwipeGesture alloc] initWithTarget:self selector:@selector(handleRight:)];
	[view addGesture:gesture];

	gesture = [[SwipeGesture alloc] initWithTarget:self selector:@selector(handleLeft:)];
	[((SwipeGesture *) gesture) setAngle:M_PI];
	[view addGesture:gesture];

	gesture = [[TapGesture alloc] initWithTarget:self selector:@selector(handleTap:)];
	[view addGesture:gesture];

	gesture = [[SwipeGesture alloc] initWithTarget:self selector:@selector(handleUpDown:)];
	[((SwipeGesture *) gesture) setAngle:M_PI/2];
	((LongPressGesture *) gesture).onRelease = NO;
	((LongPressGesture *) gesture).delay = 0.25;
	[view addGesture:gesture];

	gesture = [[SwipeGesture alloc] initWithTarget:self selector:@selector(handleUpDown:)];
	[((SwipeGesture *) gesture) setAngle:-M_PI/2];
	((LongPressGesture *) gesture).onRelease = NO;
	((LongPressGesture *) gesture).delay = 0.25;
	[view addGesture:gesture];

	/*
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	[tap setNumberOfTaps:1];
	[self.view addGestureRecognizer:tap];
	
	UILongPressGestureRecognizer *hold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
	[self.view addGestureRecognizer:hold];
	
	SwipeGestureRecognizer *left = [[SwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeft:)];
	[left setAngle: M_PI];
	[self.view addGestureRecognizer:left];
	SwipeGestureRecognizer *right = [[SwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRight:)];
	[left setAngle: M_PI];
	[self.view addGestureRecognizer:right];
	
	ElasticScaleGestureRecognizer *seek = [[ElasticScaleGestureRecognizer alloc] initWithTarget:self action:@selector(handleSeek:)];
	[seek setNumberOfTaps:2];
	[seek setDelay:0.4];
	[self.view addGestureRecognizer:seek];	
	
	
	ElasticScaleGestureRecognizer *volume = [[ElasticScaleGestureRecognizer alloc] initWithTarget:self action:@selector(handleVolume:)];
	[volume setAngle: M_PI_2];
	[volume setNumberOfTaps:1];
	[volume setDelay:0.1];
	[self.view addGestureRecognizer:volume];
	
	[tap requireOtherGestureToFail:seek];
	*/	

	player = [MPMusicPlayerController iPodMusicPlayer];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleNowPlayingItemChanged:)
		name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		object: player];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handlePlaybackStateChanged:)
		name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
		object: player];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleVolumeChanged:)
		name: MPMusicPlayerControllerVolumeDidChangeNotification
		object: player];

	[player	beginGeneratingPlaybackNotifications];
	

	
	[self setImageForPlaybackState];
}

@end

#import "MainViewController.h"

#import "HCIPlayerAppDelegate.h"
#import "VoiceRecognizer.h"
#import "Gesture.h"
#import <UIKit/UIView-UIViewGestures.h>
#import <Celestial/Celestial.h>
#import <AudioToolbox/AudioServices.h>
#import <time.h>


@implementation MainViewController



@synthesize label;
@synthesize image;
@synthesize player;

@synthesize audio;
@synthesize voice;
@synthesize feedback;
@synthesize currentItems;

/* Prototypes */
extern void * _CTServerConnectionCreate(CFAllocatorRef, int (*)(void *, CFStringRef, CFDictionaryRef, void *), int *);
extern int _CTServerConnectionSetVibratorState(int *, void *, int, float, float, float, float);
static NSString *_last_action;


- (void) loadView
{
	UIView *view = self.view = [[UIView	alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];

	self.image = [[UIImageView alloc] initWithFrame:CGRectInset([view bounds], 20, 20)];
	self.image.opaque = NO;
	self.image.clearsContextBeforeDrawing = NO;
	self.image.backgroundColor = [UIColor clearColor];
	self.image.contentMode = UIViewContentModeScaleAspectFit;
	self.image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	[view addSubview:self.image];

	CGRect rect = CGRectInset([view bounds], 20, 0);

	rect.origin.y += rect.size.height - 60.0;
	rect.size.height = 60.0;

	self.label = [[UILabel alloc] initWithFrame:rect];
	self.label.backgroundColor = [UIColor clearColor];
	self.label.opaque = NO;
	self.label.clearsContextBeforeDrawing = NO;
	self.label.textColor = [UIColor whiteColor];
	self.label.textAlignment = UITextAlignmentCenter;
	self.label.font = [UIFont systemFontOfSize:24.0];
	self.label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	self.label.numberOfLines = 4;
	self.label.lineBreakMode = UILineBreakModeWordWrap; 
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

- (Command) parseVoiceCommand: (NSString *) text
{
	Command command = { .type = COMMAND_NONE };

	NSArray *items = [text componentsSeparatedByString:@"\n"];

	if ([items length] == 0) {
		return command;
	}

	if ([[items objectAtIndex:0] isEqualToString:@"play"]) {
		command.type = COMMAND_TYPE_PLAY;
	} else if ([[items objectAtIndex:0] isEqualToString:@"pause"]) {
		command.type == COMMAND_TYPE_PAUSE;
	} else if ([[items objectAtIndex:0] isEqualToString:@"next"]) {
		command.type = COMMAND_TYPE_NEXT;
	} else if ([[items objectAtIndex:0] isEqualToString:@"previous"]) {
		command.type = COMMAND_TYPE_PREVIOUS;
	} else if ([[items objectAtIndex:0] isEqualToString:@"replay"]) {
		command.type = COMMAND_TYPE_REPLAY;
	} else if ([[items objectAtIndex:0] isEqualToString:@"info"]) {
		command.type = COMMAND_TYPE_INFO;
	} else if ([[items objectAtIndex:0] isEqualToString:@"help"]) {
		command.type = COMMAND_TYPE_HELP;
	} else if ([[items objectAtIndex:0] isEqualToString:@"exit"]) {
		command.type = COMMAND_TYPE_EXIT;
	} else if ([[items objectAtIndex:0] isEqualToString:@"tutorial"]) {
		command.type = COMMAND_TYPE_TUTORIAL;
	} else if ([[items objectAtIndex:0] isEqualToString:@"shuffle"]) {
		command.type = COMMAND_TYPE_SHUFFLE;
	} else if ([[items objectAtIndex:0] isEqualToString:@"repeat"]) {
		command.type = COMMAND_TYPE_REPEAT;
	} else if ([[items objectAtIndex:0] isEqualToString:@"playItems"]) {
		command.type = COMMAND_TYPE_PLAY_ITEMS;
	} else if ([[items objectAtIndex:0] isEqualToString:@"queueItems"]) {
		command.type = COMMAND_TYPE_QUEUE_ITEMS;
	}

	if (command.type == COMMAND_TYPE_SHUFFLE || command.type == COMMAND_TYPE_REPEAT) {
		command.arg = [[items objectAtIndex:1] isEqualToString:@"on"] ? COMMAND_ON :
			[[items objectAtIndex:1] isEqualToString:@"off"] ? COMMAND_OFF : COMMAND_TOGGLE;
	} else if (command.type == COMMAND_TYPE_PLAY_ITEMS || command.type == COMMAND_TYPE_QUEUE_ITEMS) {
		command.title = [items objectAtIndex:1];
		command.album = [items objectAtIndex:2];
		command.artist = [items objectAtIndex:3];
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

- (void) handleNowPlayingItemChanged: (NSNotification *) notification
{
	self.label.text = [[self.player nowPlayingItem] valueForProperty:@"title"];
	if ([[[self label] text] length] < 1){
		[[self player] setQueueWithItemCollection:[self currentItems]];
		[[self player] setNowPlayingItem:[[self currentItems] objectAtIndex:0]];
		if ([_last_action isEqualToString:@"next"]){
			[[self feedback] sayText: @"Reached end of queue. Say \"play\" again to restart current list."];
		}else if ([_last_action isEqualToString: @"previous"]){ 
			[self.player play];
		}
	}
}

- (void) handlePlaybackStateChanged: (id) notification
{
	[self setImageForPlaybackState];
	NSLog (@"enabled: %@", [notification description]);
	
}

- (void) handleVolumeChanged: (id) notification
{

}
- (void) handleRight: (UIGestureRecognizer *) gesture
{
	[self.player skipToNextItem];
	self.label.text = @"NEXT";
	_last_action = @"next";
}

- (void) handleLeft: (UIGestureRecognizer *) gesture
{
	[self.player skipToPreviousItem];
	self.label.text = @"PREV";
	_last_action = @"previous";
}

- (void) handleTap: (UIGestureRecognizer *) gesture
{
	
	if ([self.player playbackState] == MPMusicPlaybackStatePlaying) {
		[self.player pause];
		self.label.text = @"PAUSE";
	} else {
		[self.player play];
		self.label.text = @"PLAY";
	}
}

- (void) handleHold: (UILongPressGestureRecognizer *) gesture
{
	NSLog([gesture description]);
	if ([gesture state] == UIGestureRecognizerStateBegan) {
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
	} else if ([gesture state] == UIGestureRecognizerStateRecognized) {
		[self.voice finish];
		//[self setVibration:TRUE intensity:1 duration:1];
	} else if ([gesture state] == UIGestureRecognizerStateCancelled) {
		[self.voice cancel];
		//[self vibrate];
		//[self setVibration:TRUE intensity:1 duration:0.2];
		//[self setVibration:TRUE intensity:1 duration:0.2];
	}
}

- (void) handleUpDown: (ElasticScaleGestureRecognizer *) gesture
{
	if ([gesture state] == UIGestureRecognizerStateChanged) {
		float measure = [gesture measure];
		float newVolume = MIN(MAX( [self.player volume]+(measure/10000.0), 0), 1);
		[self.player setVolume:newVolume];
		if (newVolume <= 0 || newVolume >=1){
			[gesture setMeasure:0];
		}
		self.label.text = [NSString stringWithFormat:@"Y: %.3f\r\nVolume:%.2f", measure, [self.player volume]];
		//[self setVibration:TRUE intensity:1 duration:1];
	} else if ([gesture state] == UIGestureRecognizerStateBegan){
	} else if ([gesture state] == UIGestureRecognizerStateRecognized) {
		
	} else if ([gesture state] == UIGestureRecognizerStateCancelled) {
		
	}
}
- (void) handleLeftRight: (ElasticScaleGestureRecognizer *) gesture
{
	static is_forward = FALSE;
	if ([gesture state] == UIGestureRecognizerStateChanged) {
		float measure = [gesture measure];
		if (measure > 0){ 
			if (is_forward) {
				[self.player endSeeking];
				is_forward=FALSE;
				[self.player beginSeekingBackward];
				_last_action = @"previous";
			}
		} else {
			if (!is_forward) {
				[self.player endSeeking];
				is_forward=TRUE;
				[self.player beginSeekingForward];
				_last_action = @"next";
			}
		}
		self.label.text = [NSString stringWithFormat:@"X: %.2f\r\ntime:%.2f", measure, [self.player currentPlaybackTime]];
		//[self setVibration:TRUE intensity:1 duration:1];
	} else if ([gesture state] == UIGestureRecognizerStateBegan){
	} else if ([gesture state] == UIGestureRecognizerStateRecognized) {
		[self.player endSeeking];
	} else  {
		[self.player endSeeking];
		//restore previous time here!!!
	}
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	audio = [AudioController sharedInstance];

	voice = [VoiceRecognizer new];
	voice.delegate = self;

	feedback = [AudioFeedback new];

	playImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-play" ofType:@"png" inDirectory:@"Images"]];
	pauseImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-pause" ofType:@"png"inDirectory:@"Images"]];
	recordImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"audio-input-microphone" ofType:@"png"inDirectory:@"Images"]];
/*
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

	*/
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	[tap setNumberOfTaps:1];
	[self.view addGestureRecognizer:tap];
	
	UILongPressGestureRecognizer *hold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
	hold.allowableMovement = 10;
	hold.delay = 0.5;
	[self.view addGestureRecognizer:hold];
	
	SwipeGestureRecognizer *left = [[SwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeft:)];
	[left setAngle: M_PI];
	[self.view addGestureRecognizer:left];
	SwipeGestureRecognizer *right = [[SwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRight:)];
	[left setAngle: M_PI];
	[self.view addGestureRecognizer:right];
	
	ElasticScaleGestureRecognizer *seek = [[ElasticScaleGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftRight:)];
	[seek setAngle: M_PI];
	[seek setNumberOfTaps:2];
	[seek setDelay:0.4];
	[self.view addGestureRecognizer:seek];	
	
	
	ElasticScaleGestureRecognizer *volume = [[ElasticScaleGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpDown:)];
	[volume setAngle: M_PI_2];
	[volume setNumberOfTaps:1];
	[volume setDelay:0.1];
	[self.view addGestureRecognizer:volume];
	
	[tap requireOtherGestureToFail:seek];
	

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
	MPMediaQuery *query = [[MPMediaQuery alloc] init];
	self.currentItems = [query items];
	if ([[self player] nowPlayingItem] == NULL){
		[self.player setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:self.currentItems]];
	}
	
	[player	beginGeneratingPlaybackNotifications];


	
	[self setImageForPlaybackState];
}

@end

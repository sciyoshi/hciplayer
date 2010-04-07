#import "MainViewController.h"
#import "MainViewControllerCommands.h"

#import "JSON.h"

#import "HCIPlayerAppDelegate.h"
#import "VoiceRecognizer.h"
#import "Gesture.h"
#import <UIKit/UIView-UIViewGestures.h>
#import <Celestial/Celestial.h>
#import <AudioToolbox/AudioServices.h>
#import "Commands.h"
#import "MPMediaItemCollection-Utils.h"
#import <time.h>
#import "AnimatedGif.h"


@implementation MainViewController

@synthesize label;
@synthesize volumeFill;
@synthesize image;
@synthesize loader;
@synthesize player;

@synthesize audio;
@synthesize voice;
@synthesize feedback;
@synthesize currentItems;
@synthesize selectedItems;

- (void) loadView
{
	UIView *view = self.view = [[UIView	alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];

	self.volumeFill = [[UILabel alloc] initWithFrame:view.bounds];
	self.volumeFill.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
	self.volumeFill.opaque = NO;
	self.volumeFill.clearsContextBeforeDrawing = NO;
	self.volumeFill.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	self.volumeFill.contentMode = UIViewContentModeRedraw;
	self.volumeFill.lineBreakMode = UILineBreakModeWordWrap; 
	
	[view addSubview:self.volumeFill];
	
	self.image = [[UIImageView alloc] initWithFrame:CGRectInset([view bounds], 30, 30)];
	self.image.opaque = NO;
	self.image.clearsContextBeforeDrawing = NO;
	self.image.backgroundColor = [UIColor clearColor];
	self.image.contentMode = UIViewContentModeScaleAspectFit;
	self.image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	[view addSubview:self.image];
	
	NSURL* loaderURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ajaxloader" ofType:@"gif" inDirectory:@"Images"]];
	
    self.loader = [AnimatedGif getAnimationForGifAtUrl: loaderURL forUIImageView:[[UIImageView alloc] initWithFrame:view.bounds]];
	self.loader.hidden = YES;
	self.loader.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	self.loader.contentMode = UIViewContentModeScaleAspectFit;
	self.loader.bounds = CGRectMake(20, 100, 280, 280);
	self.loader.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
		UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

	[view addSubview:self.loader];

	CGRect rect = view.bounds;
	
	rect.origin.y += rect.size.height - 60.0;
	rect.size.height = 60.0;
	
	self.label = [[UILabel alloc] initWithFrame:rect];
	self.label.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.7];
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

- (void) restorePlaybackState
{
	if (lastPlaybackState == MPMusicPlaybackStatePaused || lastPlaybackState == MPMusicPlaybackStateStopped) {
		[self.player performSelectorOnMainThread:@selector(pause) withObject:nil waitUntilDone:NO];
	} else if (lastPlaybackState == MPMusicPlaybackStatePlaying) {
		[self.player performSelectorOnMainThread:@selector(play) withObject:nil waitUntilDone:YES];
	}
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

- (MPMediaItemCollection *) getCollectionForSingleFilter: (NSDictionary *) filter
{
	MPMediaQuery *query = [[MPMediaQuery alloc] init];

	for (NSString *key in [filter allKeys]) {
		if ([[filter valueForKey:key] length]) {
			[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[filter valueForKey:key] forProperty:key comparisonType:MPMediaPredicateComparisonEqualTo]];
		}
	}

	if (query.items.count > 0) {
		return [MPMediaItemCollection collectionWithItems:query.items];
	} else {
		return nil;
	}
}

- (MPMediaItemCollection *) getCollectionForFilters: (NSArray *) filters
{
	MPMediaItemCollection *items = nil;

    for (NSDictionary *filter in filters) {
		MPMediaItemCollection *temp = nil;

		if ([filter isEqual:@"selected"] || [filter isEqual:@""]) {
			filter = @"selected";
			temp = ([self.selectedItems count] > 0) ? [MPMediaItemCollection collectionWithItems:self.selectedItems] : nil;
		} else if ([filter isEqual:@"all"]) {
			temp = [MPMediaItemCollection collectionWithItems:[[[MPMediaQuery alloc] init] items]];
		} else {
			temp =  [self getCollectionForSingleFilter:filter];
		}

		if (temp) {
			items = items ? [items collectionByAppendingCollection:temp] : temp;
		}
	}

	if (items && items.items.count > 0){
		return [MPMediaItemCollection collectionWithItems:[[NSSet setWithArray:items.items] allObjects]];
	} else {
		return nil;
	}
}

- (void) voiceRecognitionFinished: (VoiceRecognizer *) recognizer withText: (NSString *) text
{
	Command command = [self parseVoiceCommand:text];

	[self handleCommand:command];

	self.loader.hidden = YES;
	self.label.text = text;
}

- (void) voiceRecognitionFailed: (VoiceRecognizer *) recognizer withError: (NSError *)error
{
	self.loader.hidden = YES;
	SAY(@"Error, couldn't connect to the voice recognition server!");
	self.label.text = @"Network Error";
}

int vibratecallback(void *connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
	return 1;
}

- (void) vibrate
{
	AudioServicesPlaySystemSound(0xFFF);
}

- (void) setVibration: (BOOL) onoff intensity: (float) intensity duration: (float) duration
{
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
	if ([notification object] != self.player)
		return;

	if (self.player.playbackState == MPMusicPlaybackStateStopped) {
		if (lastAction == COMMAND_NEXT) {
			SAY(@"Reached end of queue. Say \"play\" again to restart current list.");
		} else if (lastAction == COMMAND_PREVIOUS) { 
			[self.player play];
		}
		lastAction = COMMAND_NONE;
	}

	lastPlayingItem = [(NSNumber *) [self.player.nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID] unsignedLongLongValue];
}

- (void) handlePlaybackStateChanged: (id) notification
{
	if ([notification object] != self.player)
		return;

	[self setImageForPlaybackState];

	// playback breaks if you don't stop it here
	if ([self.player playbackState] == MPMusicPlaybackStateStopped) {
		[self.player stop];
	}	
}

- (void) handleVolumeChanged: (id) notification
{
	if ([notification object] != self.player)
		return;

	CGRect rect = self.view.bounds;
	rect.origin.y += rect.size.height * (1.0 - self.player.volume);
	rect.size.height *= self.player.volume;
	self.volumeFill.frame = rect;
	[self.view setNeedsDisplay];
}

/**** GESTURE HANDLERS ****/

- (void) handleTap: (UIGestureRecognizer *) gesture
{
	Command c = { .type = COMMAND_TAP, .gesture = gesture };
	[self handleCommand:c];
}

- (void) handleRight: (UIGestureRecognizer *) gesture
{
	Command c = { .type = COMMAND_SWIPE_RIGHT, .gesture = gesture };
	[self handleCommand:c];
}

- (void) handleLeft: (UIGestureRecognizer *) gesture
{
	Command c = { .type = COMMAND_SWIPE_LEFT, .gesture = gesture };
	[self handleCommand:c];
}

- (void) handleUpDown: (ElasticScaleGestureRecognizer *) gesture
{
	Command c = { .type = COMMAND_SWIPE_UPDOWN, .gesture = gesture };
	[self handleCommand:c];	
}

- (void) handleLeftRight: (ElasticScaleGestureRecognizer *) gesture
{
	Command c = { .type = COMMAND_SWIPE_LEFTRIGHT, .gesture = gesture };
	[self handleCommand:c];
}

- (void) handleHold: (UILongPressGestureRecognizer *) gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan) {
		lastPlaybackState = self.player.playbackState;

		[self.player pause];

		//[self.voice.recorder prepareToRecord];
		[self.audio prepareForRecording];
		//[self setVibration:TRUE intensity:1 duration:0.2];		
		[self vibrate];
		[self.voice start];

		self.image.image = recordImage;
	} else if (gesture.state == UIGestureRecognizerStateRecognized) {
		[self.voice finish];
		[self setVibration:TRUE intensity:1 duration:0.6];
		self.loader.hidden = NO;
	} else if ([gesture state] == UIGestureRecognizerStateCancelled) {
		[self.voice cancel];
		[self setVibration:TRUE intensity:1 duration:0.2];
		self.loader.hidden = YES;
		[self restorePlaybackState];
	}
}

- (void) voiceRecordingStopped: (VoiceRecognizer *) recognizer successfully: (BOOL) flag
{
	[self.audio finishRecording];
	[self setImageForPlaybackState];
}

- (void) handleDollarTouch: (DollarTouchGestureRecognizer *) gesture
{
	NSString *name = gesture.result.name;
	if ([name isEqualToString:@"circle"]){
		Command c = { .type = COMMAND_REPEAT, .arg=COMMAND_TOGGLE, .gesture = gesture };
		[self handleCommand:c];
	} else if ([name isEqualToString:@"alpha"]){
		Command c = { .type = COMMAND_SHUFFLE, .arg=COMMAND_TOGGLE, .gesture = gesture };
		[self handleCommand:c];
	} else if ([name isEqualToString:@"question"]){
		Command c = { .type = COMMAND_INFO, .gesture = gesture };
		[self handleCommand:c];
	} else if ([name isEqualToString:@"check"]){
		Command c = { .type = COMMAND_LIST_ITEMS, .filters = [NSArray arrayWithObject:@"selected"], .gesture = gesture };
		[self handleCommand:c];
	} 
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	audio = [AudioController sharedInstance];

	voice = [VoiceRecognizer new];
	voice.delegate = self;

	feedback = [AudioFeedback new];

	tutorial = [[Tutorial alloc] init:feedback];

	playImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-play" ofType:@"png" inDirectory:@"Images"]];
	pauseImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-pause" ofType:@"png"inDirectory:@"Images"]];
	recordImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"audio-input-microphone" ofType:@"png"inDirectory:@"Images"]];
	volumeImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"audio-volume-high" ofType:@"png"inDirectory:@"Images"]];

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

	DollarTouchGestureRecognizer *dt = [[DollarTouchGestureRecognizer alloc] initWithTarget:self action:@selector(handleDollarTouch:)];
	[self.view addGestureRecognizer:dt];

	player = [MPMusicPlayerController iPodMusicPlayer];
	[self.player pause];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleNowPlayingItemChanged:)
		name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		object: self.player];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handlePlaybackStateChanged:)
		name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
		object: self.player];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleVolumeChanged:)
		name: MPMusicPlayerControllerVolumeDidChangeNotification
		object: self.player];
	

	MPMediaQuery *query = [[MPMediaQuery alloc] init];
	self.currentItems = [query items];
	if ([[self currentItems] count] > 0){
		[self.player setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:self.currentItems]];
	}

	[self.player beginGeneratingPlaybackNotifications];

	self.selectedItems = self.currentItems;
	
	[self setImageForPlaybackState];
}

@end


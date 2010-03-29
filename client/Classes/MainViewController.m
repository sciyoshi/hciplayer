#import "MainViewController.h"

#import "HCIPlayerAppDelegate.h"

#import "Gesture.h"

#import "UIKit/UIView-UIViewGestures.h"
#import "UIKit/UIGestureRecognizer.h"
#import "UIKit/UILongPressGestureRecognizer.h"
#import "UIKit/UITapGestureRecognizer.h"

@implementation MainViewController

@synthesize label;
@synthesize image;
@synthesize application;

- (void) viewDidLoad
{
	[super viewDidLoad];

	playImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-play" ofType:@"png"]];
	pauseImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"media-playback-pause" ofType:@"png"]];

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	[tap setNumberOfTaps:1];
	[self.view addGestureRecognizer:tap];

	UILongPressGestureRecognizer *hold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold)];
	[self.view addGestureRecognizer:hold];

	SwipeGestureRecognizer *right = [[SwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRight)];
	[self.view addGestureRecognizer:right];
}

- (void) initialize
{
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleNowPlayingItemChanged:)
		name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		object: application.player];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handlePlaybackStateChanged:)
		name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
		object: application.player];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleVolumeChanged:)
		name: MPMusicPlayerControllerVolumeDidChangeNotification
		object: application.player];

	image.hidden = NO;
	image.image = playImage;
}

- (void) handleRight
{
	[application.player skipToNextItem];
}

- (void) handleTap: (UITapGestureRecognizer *)recognizer
{
	if ([application.player playbackState] == MPMusicPlaybackStatePlaying) {
		[application.player pause];
	} else {
		[application.player play];
	}
}

- (void) handleHold: (UILongPressGestureRecognizer *)recognizer
{
	if ([recognizer state] == 1) {
		
	} else if ([recognizer state] == 3) {
		
	}
}

- (void) handleNowPlayingItemChanged: (id) notification
{
	label.text = [[application.player nowPlayingItem] valueForProperty:@"title"];
}

- (void) handlePlaybackStateChanged: (id) notification
{
	if ([application.player playbackState] == MPMusicPlaybackStatePlaying) {
		image.image = playImage;
	} else {
		image.image = pauseImage;
	}
}

- (void) handleVolumeChanged: (id) notification
{

}

- (void) viewDidUnload
{
}

- (void) dealloc
{
    [super dealloc];
}

@end

#import "HCIPlayerAppDelegate.h"
#import "MainViewController.h"

#import "AudioToolbox/AudioToolbox.h"

@implementation HCIPlayerAppDelegate

@synthesize window;
@synthesize mainView;
@synthesize player;
@synthesize audioFeedback;

- (void) applicationDidFinishLaunching: (UIApplication *) application
{
	self.audioFeedback = [AudioFeedback new];

	self.player = [MPMusicPlayerController iPodMusicPlayer];

	[player beginGeneratingPlaybackNotifications];

	[player setQueueWithQuery:[MPMediaQuery new]];

	[mainView setApplication:self];

	[mainView initialize];

	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];

	[window addSubview:mainView.view];
	[window makeKeyAndVisible];
}

- (void) readNowPlaying
{
	
}

- (void) vibrate
{
	AudioServicesPlayAlertSound(0xFFF);
}

- (void) handleText: (NSString *) text
{
	text = [text lowercaseString];
	if ([text isEqualToString:@"play"]) {
	}
}

- (void) dealloc
{
	[player endGeneratingPlaybackNotifications];
	[player release];

    [window release];
	[mainView release];
	[audioFeedback release];

    [super dealloc];
}

@end

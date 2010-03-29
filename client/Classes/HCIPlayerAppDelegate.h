#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "MainViewController.h"
#import "AudioFeedback.h"

@interface HCIPlayerAppDelegate : NSObject <UIApplicationDelegate>
{
	IBOutlet UIWindow *window;
	IBOutlet MainViewController *mainView;

	MPMusicPlayerController *player;
	AudioFeedback *audioFeedback;
}

@property (retain) IBOutlet UIWindow *window;
@property (retain) IBOutlet MainViewController *mainView;

@property (retain) MPMusicPlayerController *player;
@property (retain) AudioFeedback *audioFeedback;

- (void) vibrate;
- (void) readNowPlaying;

@end

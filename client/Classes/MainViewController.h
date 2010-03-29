#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMusicPlayerController.h>

#import "AudioFeedback.h"

@class HCIPlayerAppDelegate;

@interface MainViewController : UIViewController
{
	IBOutlet UILabel *label;
	IBOutlet UIImageView *image;

	HCIPlayerAppDelegate *application;

@private
	UIImage *playImage;
	UIImage *pauseImage;
}

@property (retain) IBOutlet UILabel *label;
@property (retain) IBOutlet UIImageView *image;

@property (retain) HCIPlayerAppDelegate *application;

- (void) initialize;

@end

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIView-Gestures.h>
#import "AudioFeedback.h"
#import "AudioController.h"
#import "VoiceRecognizer.h"

@interface MainViewController : UIViewController <VoiceRecognizerDelegate>
{
	UILabel *label;
	UIImageView *image;
	MPMusicPlayerController *player;
	
	AudioController *audio;
	VoiceRecognizer *voice;
	AudioFeedback *feedback;

	UIImage *playImage;
	UIImage *pauseImage;
	UIImage *recordImage;
	NSArray *currentItems;
}

@property (retain) UILabel *label;
@property (retain) UIImageView *image;
@property (retain, readonly) MPMusicPlayerController *player;
@property (retain) NSArray *currentItems;
@property (retain) AudioController *audio;
@property (retain) VoiceRecognizer *voice;
@property (retain) AudioFeedback *feedback;


@end

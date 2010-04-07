#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "AudioFeedback.h"
#import "AudioController.h"
#import "VoiceRecognizer.h"
#import "Tutorial.h"

#define SAY(str) [self.feedback sayText:str]

@interface MainViewController : UIViewController <VoiceRecognizerDelegate>
{
	UILabel *label;
	UILabel *volumeFill;
	UIImageView *image;
	UIImageView *loader;

	MPMusicPlayerController *player;

	Tutorial *tutorial;
	AudioController *audio;
	VoiceRecognizer *voice;
	AudioFeedback *feedback;

	UIImage *playImage;
	UIImage *pauseImage;
	UIImage *recordImage;
	UIImage *volumeImage;

	NSArray *currentItems;
	NSArray *selectedItems;
	
	CommandType lastAction;
	int lastPlaybackState;
	int selectedItemIndex;
	unsigned long long lastPlayingItem;
}

@property (retain) UILabel *label;
@property (retain) UILabel *volumeFill;
@property (retain) UIImageView *image;
@property (retain) UIImageView *loader;
@property (retain, readonly) MPMusicPlayerController *player;
@property (retain) NSArray *selectedItems;
@property (retain) NSArray *currentItems;
@property (retain) AudioController *audio;
@property (retain) VoiceRecognizer *voice;
@property (retain) AudioFeedback *feedback;

- (void) restorePlaybackState;

- (void) setImageForPlaybackState;

- (MPMediaItemCollection *) getCollectionForSingleFilter: (NSDictionary *) filter;

- (MPMediaItemCollection *) getCollectionForFilters: (NSArray *) filters;

@end

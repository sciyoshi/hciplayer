#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define SPEECH_CACHE_DIRECTORY [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/Speech/"]

@interface AudioFeedback : NSObject <AVAudioPlayerDelegate>
{
	AVAudioPlayer *player;
}

@property (assign, readwrite) AVAudioPlayer *player;

- (id) init;

- (NSString *) hashForText: (NSString *) text;

- (void) sayText: (NSString *) text;

@end

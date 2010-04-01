#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioController : NSObject <AVAudioSessionDelegate>
{
	AVAudioSession *session;
}

@property (retain) AVAudioSession *session;

+ (AudioController *) sharedInstance;

- (id) init;

- (BOOL) setOtherMixableAudioShouldDuck: (BOOL) shouldDuck error: (NSError **) error;
- (BOOL) setOverrideCategoryMixWithOthers: (BOOL) allowMixing error: (NSError **) error;
- (BOOL) setOverrideCategoryDefaultToSpeaker: (BOOL) defaultToSpeaker error: (NSError **) error;

- (BOOL) prepareForRecording;
- (BOOL) finishRecording;
- (BOOL) prepareForPlayback;
- (BOOL) finishPlayback;

@end

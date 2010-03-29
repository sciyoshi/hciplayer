#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VoiceRecognition : NSObject <AVAudioRecorderDelegate>
{
	AVAudioRecorder *recorder;
	BOOL cancelled;
}

@property (retain) AVAudioRecorder *recorder;
@property BOOL cancelled;

- (id)init;
- (void)start;
- (void)cancel;
- (void)finish;

@end

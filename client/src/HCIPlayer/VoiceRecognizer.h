#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "ASIHTTPRequest.h"

@protocol VoiceRecognizerDelegate;

@interface VoiceRecognizer : NSObject <AVAudioRecorderDelegate>
{
	id<VoiceRecognizerDelegate> _delegate;
	AVAudioRecorder *_recorder;
	BOOL _recording;
	BOOL _cancelled;
	BOOL _ready;
}

@property (retain) id<VoiceRecognizerDelegate> delegate;
@property (retain) AVAudioRecorder *recorder;
@property (assign, readonly) BOOL recording;

- (id) init;

- (void) start;
- (void) cancel;
- (void) finish;

@end

@protocol VoiceRecognizerDelegate

@optional

- (void) voiceRecognitionFinished: (VoiceRecognizer *) recognizer withText: (NSString *) text;
- (void) voiceRecordingStopped: (VoiceRecognizer *) recognizer successfully: (BOOL) flag;

@end

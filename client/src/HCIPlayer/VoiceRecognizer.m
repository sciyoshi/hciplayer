#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "AudioController.h"
#import "VoiceRecognizer.h"
#import "ASIHTTPRequest.h"

@implementation VoiceRecognizer

@synthesize recorder = _recorder;
@synthesize delegate = _delegate;
@synthesize recording = _recording;

- (void) showErrorDialog: (NSError *) error withMessage: (NSString *) message
{
	UIAlertView *alert = [[UIAlertView alloc]
		initWithTitle:@"Error"
		message:[NSString stringWithFormat:@"%@\nDetails: %@ %d %@", message, [error domain], [error code], [[error userInfo] description]]
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];

	[alert show];
}

- (void) audioRecorderBeginInterruption: (AVAudioRecorder *) recorder
{
	NSLog(@"magic is happening");
}

- (void) audioRecorderEndInterruption: (AVAudioRecorder *) recorder
{
	NSLog(@"thanks Apple for coding so I don’t have to!");
}

- (void) reset
{
	_recording = NO;

	//[self.recorder prepareToRecord];
}

- (id) init
{
	if (!(self = [super init]))
		return nil;

	NSError *error = nil;

	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:kAudioFormatULaw], AVFormatIDKey,
		[NSNumber numberWithFloat:8000.0], AVSampleRateKey,
		[NSNumber numberWithInt:1], AVNumberOfChannelsKey, nil];

	NSURL *url = [NSURL fileURLWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"hciplayer.wav"]];

	self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];

	if (error) {
		[self showErrorDialog:error withMessage:@"Error initializing audio recorder; voice commands will not be enabled."];
        return nil;
	}

	self.recorder.delegate = self;

	_recording = NO;
	_cancelled = NO;

	return self;
}

- (void) start
{
	_cancelled = NO;
	_recording = YES;
	[self.recorder record];
}

- (void) finish
{
	[self.recorder stop];
}

- (void) cancel
{
	_cancelled = YES;
	[self.recorder stop];
}

- (void) startRecognition
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *url = [NSString stringWithFormat:@"http://%@:%@/",
				  [defaults stringForKey:@"ip_address"], 
				  [defaults stringForKey:@"port"]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString:url]];
	[request setShouldStreamPostDataFromDisk:YES];
	[request appendPostDataFromFile:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"hciplayer.wav"]];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void) requestFinished: (ASIHTTPRequest *) request
{
	NSString *text = [request responseString];

	[self.delegate voiceRecognitionFinished:self withText:text];

	[self reset];
}

- (void) requestFailed: (ASIHTTPRequest *) request
{
	NSError *error = [request error];

	[self.delegate voiceRecognitionFailed:self withError:error];
	
	[self reset];
}

- (void) audioRecorderEncodeErrorDidOccur: (AVAudioRecorder *) rec withError: (NSError *) error
{
	NSLog(@"Error recording audio.");

	[self reset];
}

- (void) audioRecorderDidFinishRecording: (AVAudioRecorder *) rec successfully: (BOOL) successfully
{
	_recording = NO;

	[self.delegate voiceRecordingStopped:self successfully:successfully && !_cancelled];

	if (successfully && !_cancelled) {
		[self startRecognition];
	} else {
		[self reset];
	}
}

@end

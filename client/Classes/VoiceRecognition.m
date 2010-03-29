#import <CoreAudio/CoreAudioTypes.h>

#import "VoiceRecognition.h"
#import "ASIHTTPRequest.h"

@implementation VoiceRecognition

@synthesize recorder;
@synthesize cancelled;

- (id)init
{
	self = [super init];

	NSError *error = nil;

	NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];

	[settings setValue:[NSNumber numberWithInt:kAudioFormatULaw] forKey:AVFormatIDKey];
	[settings setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
	[settings setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];

	NSURL *url = [[NSURL alloc] fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"hciplayer.aiff"]];

	recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];

	recorder.delegate = self;

	[recorder prepareToRecord];

	return self;
}

- (void)start
{
	cancelled = NO;
	[recorder record];
}

- (void)finish
{
	[recorder stop];
}

- (void)cancel
{
	cancelled = YES;
	[recorder stop];
}

- (void)startRecognition
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.66:9090/"]];
	[request setShouldStreamPostDataFromDisk:YES];
	[request appendPostDataFromFile:[NSHomeDirectory() stringByAppendingPathComponent:@"hciplayer.aiff"]];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSString *text = [request responseString];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder BOOL:successfully
{
	if (!cancelled) {
		[self startRecognition];
	}

	[recorder prepareToRecord];
}

@end

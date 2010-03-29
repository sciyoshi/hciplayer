#import "AudioFeedback.h"
#import "ASIFormDataRequest.h"

@implementation AudioFeedback

@synthesize streamer;

- (id)init
{
	self = [super init];

	streamer = [[AudioStreamer alloc] init];

	return self;
}

- (NSURL *)getTTSUrl:(NSString *)text
{
	NSURL *url = [[NSURL alloc] initWithString:@"http://192.20.225.36/tts/cgi-bin/nph-talk"];

	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

	[request addRequestHeader:@"Accept" value:@"text/plain"];
	[request setPostValue:@"SPEAK" forKey:@"speakButton"];
	[request setPostValue:@"crystal" forKey:@"voice"];
	[request setPostValue:text forKey:@"txt"];
	[request setShouldRedirect:NO];

	[request startSynchronous];

	return [[NSURL alloc] initWithScheme:@"http" host:@"192.20.225.36" path:[[request responseHeaders] objectForKey:@"Location"]];
}

- (void)sayText:(NSString *)text
{
	streamer.url = [self getTTSUrl:text];

	[streamer start];
}

@end

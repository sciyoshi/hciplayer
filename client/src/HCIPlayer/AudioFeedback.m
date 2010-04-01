#import "AudioFeedback.h"
#import "AudioController.h"
#import "ASIFormDataRequest.h"
#import <CommonCrypto/CommonDigest.h>

@implementation AudioFeedback

@synthesize player;

- (id) init
{
	if (!(self = [super init]))
		return nil;

	[[NSFileManager defaultManager]
		createDirectoryAtPath:SPEECH_CACHE_DIRECTORY
		withIntermediateDirectories:YES
		attributes:nil
		error:nil];

	return self;
}

- (NSString *) hashForText: (NSString *) text
{
	unsigned char hash[CC_MD5_DIGEST_LENGTH];

	CC_MD5([text UTF8String], [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding], hash);

	return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
		hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7],
		hash[8], hash[9], hash[10], hash[11], hash[12], hash[13], hash[14], hash[15]] lowercaseString];
}

- (NSString *) bundlePathForText: (NSString *) text
{
	return [[NSBundle mainBundle] pathForResource:[self hashForText:text] ofType:@"wav" inDirectory:@"Speech"];
}

- (NSString *) audioFilePathForText: (NSString *) text
{
	return [[SPEECH_CACHE_DIRECTORY stringByAppendingPathComponent:[self hashForText:text]] stringByAppendingPathExtension:@"wav"];
}

- (void) playTextFromFile: (NSString *) file
{
	NSError *error = nil;

	self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&error];

	if (error) {
		NSLog(@"Error activating audio session: %@", [[error userInfo] description]);
		return;
	}

	self.player.delegate = self;

	[[AudioController sharedInstance] prepareForPlayback];

	[self.player play];
}

- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) player successfully: (BOOL)flag
{
	[[AudioController sharedInstance] finishPlayback];
}

- (void) saveAudioFileForText: (NSString *) text
{
	NSURL *url = [[NSURL alloc] initWithString:@"http://192.20.225.36/tts/cgi-bin/nph-talk"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

	request.downloadDestinationPath = [self audioFilePathForText:text];
	request.delegate = self;

	[request addRequestHeader:@"Accept" value:@"text/plain"];
	[request setPostValue:@"SPEAK" forKey:@"speakButton"];
	[request setPostValue:@"crystal" forKey:@"voice"];
	[request setPostValue:text forKey:@"txt"];
	[request startAsynchronous];
}

- (void) requestFinished: (ASIHTTPRequest *) request
{
	[self playTextFromFile:[request downloadDestinationPath]];
}

- (NSURL *) audioURLForText: (NSString *) text
{
	NSURL *url = [[NSURL alloc] initWithString:@"http://192.20.225.36/tts/cgi-bin/nph-talk"];

	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

	[request addRequestHeader:@"Accept" value:@"text/plain"];
	[request setPostValue:@"SPEAK" forKey:@"speakButton"];
	[request setPostValue:@"crystal" forKey:@"voice"];
	[request setPostValue:text forKey:@"txt"];
	[request setShouldRedirect:NO];
	[request startSynchronous];

	return [NSURL URLWithString:[[request responseHeaders] objectForKey:@"Location"] relativeToURL:url];
}

- (void) sayText: (NSString *) text
{
	NSString *path = [self bundlePathForText:text];

	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[self playTextFromFile:path];
		return;
	}

	path = [self audioFilePathForText:text];

	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[self playTextFromFile:path];
		return;
	}

	[self saveAudioFileForText:text];
}

@end

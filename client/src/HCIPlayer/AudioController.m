#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "AudioController.h"

@implementation AudioController

@synthesize session;
void AudioSessionListener(void                      *inClientData,
						  AudioSessionPropertyID    inID,
						  UInt32                    inDataSize,
						  const void                *inData)
{
	if (inID == kAudioSessionProperty_OtherMixableAudioShouldDuck) {
		NSLog(@"Got mixable should duck = %@", * (UInt32 *) inData);
	} else if (inID == kAudioSessionProperty_OverrideCategoryDefaultToSpeaker) {
		NSLog(@"Got default to speaker = %@", * (UInt32 *) inData);
	} else if (inID == kAudioSessionProperty_AudioCategory) {
		NSLog(@"Catagorychange = %@", * (UInt32 *) inData);
	} else if (inID == kAudioSessionProperty_OverrideCategoryMixWithOthers) {
		NSLog(@"Got mix with others = %@", * (UInt32 *) inData);
	}
}


+ (AudioController *) sharedInstance
{
	static AudioController *shared;

	@synchronized(self) {
		if (!shared) {
			shared = [[AudioController alloc] init];
		}
		return shared;
	}
}

- (id) init
{
	if (!(self = [super init]))
		return nil;

	AudioSessionInitialize(NULL, NULL, NULL, NULL);

	session = [AVAudioSession sharedInstance];

	[self finishRecording];
	
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioCategory, AudioSessionListener, self);
	AudioSessionAddPropertyListener(kAudioSessionProperty_OtherMixableAudioShouldDuck, AudioSessionListener, self);
	AudioSessionAddPropertyListener(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, AudioSessionListener, self);
	AudioSessionAddPropertyListener(kAudioSessionProperty_OverrideCategoryMixWithOthers, AudioSessionListener, self);
	return self;
}

+ (BOOL) errorFromCode: (OSStatus) code error: (NSError **) error
{
	if (code == kAudioSessionNoError)
		return YES;

	if (error)
		*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:code userInfo:nil];

	return NO;
}

- (BOOL) setOtherMixableAudioShouldDuck: (BOOL) shouldDuck error: (NSError **) error
{
	UInt32 val = shouldDuck;
	
	OSStatus code = AudioSessionSetProperty(kAudioSessionProperty_OtherMixableAudioShouldDuck, sizeof (val), &val);

	return [AudioController errorFromCode:code error:error];
}

- (BOOL) setOverrideCategoryMixWithOthers: (BOOL) allowMixing error: (NSError **) error
{
	UInt32 val = allowMixing;
	
	OSStatus code = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (val), &val);
	
	return [AudioController errorFromCode:code error:error];
}		
		
- (BOOL) setOverrideCategoryDefaultToSpeaker: (BOOL) defaultToSpeaker error: (NSError **) error
{
	UInt32 val = defaultToSpeaker;

	OSStatus code = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (val), &val);

	return [AudioController errorFromCode:code error:error];
}

- (BOOL) prepareForPlayback
{
	return [self.session setActive:YES error:nil];
}

- (BOOL) finishPlayback
{
	return [self.session setActive:NO error:nil];
}

- (BOOL) prepareForRecording
{
	NSError *error = nil;

	if (![self setOtherMixableAudioShouldDuck:NO error:&error]) {
		return NO;
	}

	if (![self setOverrideCategoryMixWithOthers:NO error:&error]) {
		return NO;
	}

	if (![self.session setCategory:AVAudioSessionCategoryRecord error:&error]) {
		return NO;
	}
	
	if (![self.session setActive:YES error:&error]) {
		return NO;
	}
	
	return YES;
}

- (BOOL) finishRecording
{
	NSError *error = nil;

	if (![self.session setCategory:AVAudioSessionCategoryPlayback error:&error]) {
		return NO;
	}

	if (![self setOverrideCategoryMixWithOthers:YES error:&error]) {
		return NO;
	}

	if (![self setOtherMixableAudioShouldDuck:YES error:&error]) {
		return NO;
	}

	if (![self.session setActive:NO error:&error]) {
		return NO;
	}

	return YES;
}

- (void) beginInterruption
{
	
}

- (void) endInterruption
{
	
}

@end

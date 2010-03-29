#import <Foundation/Foundation.h>
#import "AudioStreamer.h"

@interface AudioFeedback : NSObject
{
	AudioStreamer *streamer;
}

@property (retain) AudioStreamer *streamer;

- (void)sayText:(NSString *)text;

@end

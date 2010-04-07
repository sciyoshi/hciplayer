#import <Foundation/Foundation.h>

#import "MainViewController.h"

#import "Commands.h"

@interface MainViewController (CommandHandlers)

- (void) handleCommand: (Command) command;

- (Command) parseVoiceCommand: (NSString *) text;

@end

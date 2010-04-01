#import "HCIPlayerAppDelegate.h"

#import "MainViewController.h"

@implementation HCIPlayerAppDelegate

- (void) applicationDidFinishLaunching: (UIApplication *) application
{
	UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	[window addSubview:[[MainViewController new] view]];

	[window makeKeyAndVisible];

	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
}

@end

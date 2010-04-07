#import <UIKit/UIKit.h>

#import "MainViewControllerCommands.h"
#import "JSON.h"

#import "HCIPlayerAppDelegate.h"
#import "VoiceRecognizer.h"
#import "Gesture.h"
#import <UIKit/UIView-UIViewGestures.h>
#import <Celestial/Celestial.h>
#import <AudioToolbox/AudioServices.h>
#import "Commands.h"
#import "MPMediaItemCollection-Utils.h"
#import <time.h>


@implementation MainViewController (CommandHandlers)

- (void) commandPlayItems: (Command) command
{
	MPMediaItemCollection *newCol = [self getCollectionForFilters:command.filters];
	MPMediaItemCollection *col = [MPMediaItemCollection collectionWithItems:self.currentItems];

	if (newCol.items.count > 0) {
		self.selectedItems = newCol.items;
		selectedItemIndex = 0;
		if (newCol.items.count == 1 && [col containsItem:(MPMediaItem *)[newCol.items objectAtIndex:0]]){
			self.player.nowPlayingItem = (MPMediaItem *)[newCol.items objectAtIndex:0];
			[self.player play];
			return;
		}

		self.currentItems = newCol.items;
		if (newCol.items.count > 0) {
			[self.player setQueueWithItemCollection:newCol];
		}
		[self.player play];	
	}
}

- (void) commandQueueItems: (Command) command
{
	MPMediaItemCollection *newCol = [self getCollectionForFilters:command.filters];
	
	if ([[newCol items] count] > 0){	
		self.selectedItems = [newCol items];
		selectedItemIndex = 0;
		MPMediaItem *currentItem = [[self player] nowPlayingItem];
		double currentTime = [[self player] currentPlaybackTime];
		
		if ([[newCol items] count] > 0){
			self.currentItems = [self.currentItems arrayByAddingObjectsFromArray:[newCol items]];
			
			MPMediaItemCollection *col = [MPMediaItemCollection collectionWithItems:self.currentItems];
			[[self player] setQueueWithItemCollection:col];
			[[self player] setNowPlayingItem:currentItem];
			[[self player] setCurrentPlaybackTime:currentTime];
		}
		SAY(([NSString stringWithFormat:@"Queued %i items", [[newCol items] count]]));
		[[self player] play];
	}
}

- (void) commandSelectItems: (Command) command {
	MPMediaItemCollection *newCol = [self getCollectionForFilters:command.filters];
	self.selectedItems = [newCol items];
	selectedItemIndex = 0;
	if ([self.selectedItems  count] > 0){
		NSDictionary * commonProps = [[MPMediaItemCollection collectionWithItems:self.selectedItems] commonProperties];
		NSString * f = [NSString stringWithFormat:@"Found %i matching %@: ", [self.selectedItems  count], [self.selectedItems count] > 1 ? @"items" : @"item"];
		for (NSString *key in [commonProps allKeys]){
			if ([[commonProps  valueForKey:key] length]){
				f = [NSString stringWithFormat:@"Found %i %@ %@ \"%@\": ", [self.selectedItems count], [self.selectedItems count] > 1 ? @"items" : @"item",
					 ([key isEqualToString:@"albumTitle"] ? @"in album":([key isEqualToString:@"title"] ? @"called":@"by artist")), [commonProps valueForKey:key]];
				break;
			}		
		} 
		if (([self.selectedItems  count] < 4  && [self.selectedItems  count] > 1) || [command.raw isEqual:@"list"]){
			Command c = { .type = COMMAND_LIST_ITEMS, .raw=@"list"};
			f = [NSString stringWithFormat:@"%@ %@", f, [self commandListItems:c]];
		}
		SAY(f);
	} else {
		SAY(@"Sorry, no items found.");
	}
}

- (NSString *) commandListItems:(Command)command {
	
	NSString * f = @"";
	if (![[command.filters objectAtIndex:0] isEqual:@"selected"] && ![[command.filters objectAtIndex:0] isEqual:@""]&& [command.filters count] > 0) {
		command.raw = @"list";
		[self commandSelectItems:command];
		return @"";
	}
	NSDictionary * commonProps = [[MPMediaItemCollection collectionWithItems:self.selectedItems] commonProperties];
	if (([self.selectedItems count] > 3 && [self.selectedItems count] - 1> selectedItemIndex) || [[command.filters objectAtIndex:0] isEqual:@"selected"] ){
		
		f = [NSString stringWithFormat:@"Items %i to %i of %i: ",  selectedItemIndex + 1, MIN(selectedItemIndex + 3, [self.selectedItems count]),[self.selectedItems count]];
		if (![command.raw isEqual:@"list"]){
			if ([[commonProps valueForKey:@"title"]length] > 0 ) {
				f = [NSString stringWithFormat:@"Items %i to %i of %i items matching title %@.", selectedItemIndex + 1, MIN(selectedItemIndex + 3, [self.selectedItems count]), [self.selectedItems count] ,
					 [commonProps  valueForKey:@"title"]];
			} else if ([[commonProps  valueForKey:@"artist"]length] > 0) {
				f = [NSString stringWithFormat:@"Items %i to %i of %i items matching artist %@.", selectedItemIndex + 1, MIN(selectedItemIndex + 3, [self.selectedItems count]), [self.selectedItems count],
					 [commonProps valueForKey:@"artist"]];
			} else if ([[commonProps valueForKey:@"albumTitle"]length] > 0) {
				f = [NSString stringWithFormat:@"Items %i to %i of %i items matching album %@.",  selectedItemIndex + 1, MIN(selectedItemIndex + 3, [self.selectedItems count]), [self.selectedItems count],
					 [commonProps  valueForKey:@"albumTitle"]];
			}
		}
		
	} 
	int i = 0;
	for (i = selectedItemIndex; i < MIN(selectedItemIndex + 3, [self.selectedItems count]); i++){
		f = [NSString stringWithFormat:@"%@, %@ %@ %@.", f,	[[self.selectedItems objectAtIndex:i] valueForProperty:@"title"],
			 ([[commonProps objectForKey:@"albumTitle"] length] <= 0) ?
			 [NSString stringWithFormat:@", in album:%@", [[self.selectedItems objectAtIndex:i] valueForProperty:@"albumTitle"]] : @"",
			 ([[commonProps objectForKey:@"artist"] length] <= 0) ?
			 [NSString stringWithFormat:@", by artist:%@", [[self.selectedItems objectAtIndex:i] valueForProperty:@"artist"]]: @""];
		
	}
	selectedItemIndex = (i == [self.selectedItems count]) ? 0 : i;
	if (![command.raw isEqual:@"list"] && ([[command.filters objectAtIndex:0] isEqual:@"selected"] || [[command.filters objectAtIndex:0] isEqual:@""]|| [command.filters count] == 0)) {
		SAY(f);
	}
	return f;
}

- (void) commandPlay: (Command) command
{
	[self.player performSelectorOnMainThread:@selector(play) withObject:nil waitUntilDone:NO];
}

- (void) commandPause: (Command) command
{
	[self.player pause];
}

- (void) commandTap: (Command) command
{
	if ([self.player playbackState] == MPMusicPlaybackStatePlaying) {
		[self commandPause:command];
	} else {
		[self commandPlay:command];
	}
}

- (void) commandReplay: (Command) command
{
	[[self player] skipToBeginning];
	[[self player] play];
}

- (void) commandNext: (Command) command
{
	[self.player skipToNextItem];
	lastAction = COMMAND_NEXT;
}

- (void) commandPrevious: (Command) command
{
	if (command.gesture && [self.player currentPlaybackTime] > 7){
		[[self player] skipToBeginning];
	} else {
		[self.player skipToPreviousItem];
	}
	lastAction = COMMAND_PREVIOUS;
}

- (void) commandUpDown: (ElasticScaleGestureRecognizer *) gesture
{
	if (gesture.state == UIGestureRecognizerStateChanged) {
		float newVolume = MIN(MAX(self.player.volume + (gesture.measure / 10000.0), 0), 1);

		self.player.volume = newVolume;

		if (newVolume <= 0 || newVolume >= 1) {
			gesture.measure = 0;
		}
	} else if (gesture.state == UIGestureRecognizerStateBegan) {
	} else if (gesture.state == UIGestureRecognizerStateRecognized) {
		[self setImageForPlaybackState];
	} else if (gesture.state == UIGestureRecognizerStateCancelled) {
		
	}
}

- (void) commandLeftRight: (ElasticScaleGestureRecognizer *) gesture
{
	if (gesture.state == UIGestureRecognizerStateChanged) {
		if (gesture.measure < 0){
			if (self.player.playbackState != MPMusicPlaybackStateSeekingBackward) { 
				[self.player endSeeking];	
				[self.player beginSeekingBackward];
				lastAction = COMMAND_PREVIOUS;
			} 
		} else if (gesture.measure > 0) {
			if (self.player.playbackState != MPMusicPlaybackStateSeekingForward) {
				[self.player endSeeking];	
				[self.player beginSeekingForward];
				lastAction = COMMAND_NEXT;
			} 
		}
	} else if (gesture.state == UIGestureRecognizerStateBegan){
		[self.player play];
	} else if (gesture.state == UIGestureRecognizerStateRecognized) {
		[self.player endSeeking];
	} else {
		[self.player endSeeking];
	}
}

- (void) commandHelp: (Command) command
{
	[self.feedback sayText:@"You can say things like, play, pause, repeat, \
	 next song, play previous, re-play track, and toggle mute. To play or \
	 queue a specific song, say 'play' or 'queue', followed by the artist \
	 name or song title. For example, try saying 'Play song Bulls on Parade'."];
}

- (void) commandInfo: (Command) command
{
	if ([self.player playbackState] == MPMusicPlaybackStatePlaying || lastPlaybackState == MPMusicPlaybackStatePlaying) {
		[self.feedback sayText:[NSString stringWithFormat:@"Now playing %@ by %@",
								[[self.player nowPlayingItem] valueForProperty:@"title"],
								[[self.player nowPlayingItem] valueForProperty:@"artist"]]];
	}
}

- (void) commandExit: (Command) command
{
	
}

- (void) commandShuffle: (Command) command
{
	MPMusicShuffleMode mode = self.player.shuffleMode;
	
	if (command.arg == COMMAND_ON || (command.arg == COMMAND_TOGGLE && mode == MPMusicShuffleModeOff)) {
		self.player.shuffleMode = MPMusicShuffleModeSongs;
		SAY(@"Turning shuffle: on.");
	} else {
		self.player.shuffleMode = MPMusicShuffleModeOff;
		SAY(@"Turning shuffle: off.");
	}

	[self restorePlaybackState];
}

- (void) commandRepeat: (Command) command
{
	MPMusicRepeatMode mode = self.player.repeatMode;
	
	if (command.arg == COMMAND_ON || (command.arg == COMMAND_TOGGLE && mode == MPMusicRepeatModeNone)) {
		self.player.repeatMode = MPMusicRepeatModeAll;
		SAY(@"Turning re-peat: on.");
	} else {
		self.player.repeatMode = MPMusicRepeatModeNone;
		SAY(@"Turning re-peat: off.");
	}

	[self restorePlaybackState];
}

- (void) handleCommand: (Command) command
{
	if (![tutorial handleCommand:command]) {
		return;
	}
	
	if (command.type == COMMAND_TAP) {
		[self commandTap:command];
	} else if (command.type == COMMAND_SWIPE_RIGHT) {
		[self commandNext:command];
	} else if (command.type == COMMAND_SWIPE_LEFT) {
		[self commandPrevious:command];
	} else if (command.type == COMMAND_SWIPE_UPDOWN) {
		[self commandUpDown:(ElasticScaleGestureRecognizer *) command.gesture];
	} else if (command.type == COMMAND_SWIPE_LEFTRIGHT) {
		[self commandLeftRight:(ElasticScaleGestureRecognizer *) command.gesture];
	} else if (command.type == COMMAND_PLAY) {
		[self commandPlay:command];
	} else if (command.type == COMMAND_PAUSE) {
		[self commandPause:command];
	} else if (command.type == COMMAND_NEXT) {
		[self commandNext:command];
	} else if (command.type == COMMAND_PREVIOUS) {
		[self commandPrevious:command];
	} else if (command.type == COMMAND_REPLAY) {
		[self commandReplay:command];
	} else if (command.type == COMMAND_INFO) {
		[self commandInfo:command];
	} else if (command.type == COMMAND_HELP) {
		[self commandHelp:command];
		[self restorePlaybackState];
	} else if (command.type == COMMAND_EXIT) {
		[self commandExit:command];
	} else if (command.type == COMMAND_SHUFFLE) {
		[self commandShuffle:command];
	} else if (command.type == COMMAND_REPEAT) {
		[self commandRepeat:command];
	} else if (command.type == COMMAND_PLAY_ITEMS) {
		[self commandPlayItems:command];
	} else if (command.type == COMMAND_QUEUE_ITEMS) {
		[self commandQueueItems:command];
	} else if (command.type == COMMAND_SELECT_ITEMS) {
		[self commandSelectItems:command];
	} else if (command.type == COMMAND_LIST_ITEMS) {
		[self commandListItems:command];
	}
}

- (Command) parseVoiceCommand: (NSString *) text
{
	Command command = { .type = COMMAND_NONE };
	
	if ([text length] == 0) {
		[self restorePlaybackState];
		return command;
	}

	NSDictionary *info = (NSDictionary *) [[SBJSON new] objectWithString:text error:NULL];
	
	NSString *type = [info valueForKey:@"type"];
	
	if ([type isEqualToString:@"play"]) {
		command.type = COMMAND_PLAY;
	} else if ([type isEqualToString:@"pause"]) {
		command.type == COMMAND_PAUSE;
	} else if ([type isEqualToString:@"next"]) {
		command.type = COMMAND_NEXT;
	} else if ([type isEqualToString:@"previous"]) {
		command.type = COMMAND_PREVIOUS;
	} else if ([type isEqualToString:@"replay"]) {
		command.type = COMMAND_REPLAY;
	} else if ([type isEqualToString:@"info"]) {
		command.type = COMMAND_INFO;
	} else if ([type isEqualToString:@"help"]) {
		command.type = COMMAND_HELP;
	} else if ([type isEqualToString:@"exit"]) {
		command.type = COMMAND_EXIT;
	} else if ([type isEqualToString:@"tutorial"]) {
		command.type = COMMAND_TUTORIAL;
	} else if ([type isEqualToString:@"shuffle"]) {
		command.type = COMMAND_SHUFFLE;
	} else if ([type isEqualToString:@"repeat"]) {
		command.type = COMMAND_REPEAT;
	} else if ([type isEqualToString:@"playItems"]) {
		command.type = COMMAND_PLAY_ITEMS;
	} else if ([type isEqualToString:@"queueItems"]) {
		command.type = COMMAND_QUEUE_ITEMS;
	} else if ([type isEqualToString:@"selectItems"]) {
		command.type = COMMAND_SELECT_ITEMS;
	} else if ([type isEqualToString:@"listItems"]) {
		command.type = COMMAND_LIST_ITEMS;
	}

	command.raw = [text copy];

	if (command.type == COMMAND_SHUFFLE || command.type == COMMAND_REPEAT) {
		NSString *args = [info valueForKey:@"args"];
		if ([args isEqualToString:@"on"]) {
			command.arg = COMMAND_ON;
		} else if ([args isEqualToString:@"off"]) {
			command.arg = COMMAND_OFF;
		} else {
			command.arg = COMMAND_TOGGLE;
		}
	} else if (command.type == COMMAND_PLAY_ITEMS || command.type == COMMAND_QUEUE_ITEMS || command.type == COMMAND_SELECT_ITEMS || command.type == COMMAND_LIST_ITEMS) {
		command.filters = [info valueForKey:@"args"];
	}
	
	return command;
}

@end
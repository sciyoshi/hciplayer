#import "MPMediaItemCollection-Utils.h"

@implementation MPMediaItemCollection(Utils)
- (MPMediaItem *)firstMediaItem {
    return [[self items] objectAtIndex:0];
}

- (MPMediaItem *)lastMediaItem {
    return [[self items] lastObject];
}

- (MPMediaItem *)mediaItemAtIndex:(NSUInteger)index {
    return [[self items] objectAtIndex:index];
}

- (MPMediaItem *)mediaItemAfterItem:(MPMediaItem *)compare {
    NSArray *items = [self items];
    
    for (MPMediaItem *oneItem in items) {
        if ([oneItem isEqual:compare]) {
            // If last item, there is no index + 1
            if (![[items lastObject] isEqual: oneItem])
                return [items objectAtIndex:[items indexOfObject:oneItem] + 1];
        }
    }
    return nil;
}

- (NSString *)titleForMediaItemAtIndex:(NSUInteger)index {
    MPMediaItem *item = [[self items] objectAtIndex:index];
    return [item valueForProperty:MPMediaItemPropertyTitle];
}

- (BOOL)containsItem:(MPMediaItem *)compare {
    NSArray *items = [self items];
    
    for (MPMediaItem *oneItem in items) {
        if ([oneItem isEqual:compare])
            return YES;
    }
    return NO;
}
- (NSDictionary *)commonProperties{
    NSArray *items = [self items];
    NSString* artist = @"";
    NSString* albumTitle = @"";
    NSString* title = @"";
	bool first = TRUE;
    for (MPMediaItem *oneItem in items) {
        if (first){
			first = FALSE;
			artist=[oneItem valueForProperty:@"artist"];
			albumTitle=[oneItem valueForProperty:@"albumTitle"];
			title=[oneItem valueForProperty:@"title"];
		} else {
			if (![[oneItem valueForProperty:@"artist"] isEqualToString:artist]) {
				artist = @"";
			} 
			if (![[oneItem valueForProperty:@"albumTitle"] isEqualToString:albumTitle]) {
				albumTitle = @"";
			} 
			if (![[oneItem valueForProperty:@"title"] isEqualToString:title]) {
				title = @"";
			}
		}
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:artist, @"artist", albumTitle, @"albumTitle", title, @"title", nil];
}

- (MPMediaItemCollection *)collectionByAppendingCollection:(MPMediaItemCollection *)otherCollection {
    return [self collectionByAppendingMediaItems:[otherCollection items]];
}

- (MPMediaItemCollection *)collectionByAppendingMediaItems:(NSArray *)items {
    if (items == nil || [items count] == 0)
        return nil;
    NSMutableArray *appendCollection = [[[self items] mutableCopy] autorelease];
    [appendCollection addObjectsFromArray:items];
    return [MPMediaItemCollection collectionWithItems:appendCollection];
}

- (MPMediaItemCollection *)collectionByAppendingMediaItem:(MPMediaItem *)item {
    if (item == nil)
        return nil;
	
    return [self collectionByAppendingMediaItems:[NSArray arrayWithObject:item]];
}

- (MPMediaItemCollection *)collectionByDeletingMediaItems:(NSArray *)itemsToRemove {
    if (itemsToRemove == nil || [itemsToRemove count] == 0)
        return [[self copy] autorelease];
    NSMutableArray *items = [[[self items] mutableCopy] autorelease];
    [items removeObjectsInArray:itemsToRemove];
    return [MPMediaItemCollection collectionWithItems:items];
}

- (MPMediaItemCollection *)collectionByDeletingMediaItem:(MPMediaItem *)itemToRemove {
    if (itemToRemove == nil)
        return [[self copy] autorelease];
    
    NSMutableArray *items = [[[self items] mutableCopy] autorelease];
    [items removeObject:itemToRemove];
    return [MPMediaItemCollection collectionWithItems:items];
}

- (MPMediaItemCollection *)collectionByDeletingMediaItemAtIndex:(NSUInteger)index {
    NSMutableArray *items = [[[self items] mutableCopy] autorelease];
    [items removeObjectAtIndex:index];
    return [items count] > 0 ? [MPMediaItemCollection collectionWithItems:items] : nil;
}

- (MPMediaItemCollection *)collectionByDeletingMediaItemsFromIndex:(NSUInteger)from toIndex:(NSUInteger)to {
    
    // Ensure from is before to
    if (to < from) {
        NSUInteger temp = from;
        to = from;
        from = temp;
    }
    
    NSMutableArray *items = [[[self items] mutableCopy] autorelease];
    [items removeObjectsInRange:NSMakeRange(from, to - from)];
    return [MPMediaItemCollection collectionWithItems:items];
}
@end
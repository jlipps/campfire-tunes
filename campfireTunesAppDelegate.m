//
//  campfireTunesAppDelegate.m
//  campfire-tunes
//
//  Created by Jonathan Lipps on 5/17/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "campfireTunesAppDelegate.h"

@implementation campfireTunesAppDelegate

@synthesize window;
@synthesize statusLabel;
@synthesize trackName;
@synthesize trackInfo;
@synthesize preferences;
@synthesize prefsCampName;
@synthesize prefsAuthToken;
@synthesize prefsSave;
@synthesize prefsListBtn;
@synthesize prefsRooms;
@synthesize player;
@synthesize timer;
@synthesize playerTimer;
@synthesize currentName;
@synthesize currentAlbum;
@synthesize currentArtist;
@synthesize campfire;
@synthesize campfireIsAuthed;
@synthesize prefs;

- (campfireTunesAppDelegate*)init {
	[super init];
	self.currentName = @"";
	self.currentAlbum = @"";
	self.currentArtist = @"";
	return self;
}

- (void)dealloc {
	[self.campfire dealloc];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	self.prefs = [NSUserDefaults standardUserDefaults];
	
	if ( [self preferencesSet] ) {
		[self doCampfireAuth];
		[self doCampfireRoomJoin];
		[self findPlayer];
	} else {
		[self updateStatus:@"Checking for preferences..."];
		NSLog(@"No prefs set, opening prefs pane");
		[self openPreferences];
	}
}

- (BOOL)preferencesSet {
	NSLog(@"Checking preferences: campfireName: %@, campfireAuthToken: %@, campfireRoomID: %@", 
		  [self.prefs stringForKey:@"campfireName"],
		  [self.prefs stringForKey:@"campfireAuthToken"],
		  [self.prefs stringForKey:@"campfireRoomID"]);
	return [self.prefs stringForKey:@"campfireName"] && 
			[self.prefs stringForKey:@"campfireAuthToken"] && 
			[self.prefs stringForKey:@"campfireRoomID"];
}

- (void)openPreferences {
	[NSApp beginSheet:self.preferences 
		modalForWindow:self.window
		modalDelegate:self 
		didEndSelector:NULL 
		contextInfo:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(prefPaneFieldDidChange:)
		name:NSControlTextDidChangeNotification 
		object:self.prefsCampName];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(prefPaneFieldDidChange:)
		name:NSControlTextDidChangeNotification 
		object:self.prefsAuthToken];
	
	[self.prefsRooms removeAllItems];
	
	NSString *camp = [self.prefs stringForKey:@"campfireName"];
	NSString *token = [self.prefs stringForKey:@"campfireAuthToken"];
	[self.prefsCampName setStringValue:camp];
	[self.prefsAuthToken setStringValue:token];
	
	if ([self.prefs objectForKey:@"campfireRooms"] != nil) {
		NSLog(@"Have campfire room list in preferences");
		[self.prefsRooms addItemsWithTitles:[self.prefs objectForKey:@"campfireRoomList"]];
		[self.prefsRooms setEnabled:YES];
		[self.prefsListBtn setEnabled:YES];
	} else if (camp && token) {
		NSLog(@"No rooms in prefs, but name and token are, refreshing rooms list");
		// if we already have name and token, refresh rooms list
		[self.prefsListBtn setEnabled:YES];
		[self doCampfireAuth];
		[self setRooms];
	}
	
	// if we already have preferences, pre-enable buttons
	if ([self preferencesSet]) {
		[self.prefsSave setEnabled:YES];
	}
}

-(IBAction) prefsMenuItem: (id) sender {
	[self openPreferences];
}

- (NSString *) getRoomIDForTitle:(NSString *)title {
	if ( [self.prefs objectForKey:@"campfireRooms"] != nil ) {
		NSMutableArray *rooms = [self.prefs objectForKey:@"campfireRooms"];
		for (id room in rooms) {
			if ( [title isEqualToString:[room objectForKey:@"name"]] ) {
				return [room objectForKey:@"roomID"];
			}
		}
	}
	return nil;
}

- (void) prefPaneFieldDidChange:(NSNotification *)aNotification {
	NSString *room = [self.prefsCampName stringValue];
	NSString *auth = [self.prefsAuthToken stringValue];
	NSLog(@"Checking prefs status, room is %@ and auth is %@", room, auth);
	if (![room isEqualToString:@""] && ![auth isEqualToString:@""]) {
		NSLog(@"Setting enabled button!");
		[self.prefsListBtn setEnabled:YES];
	} else {
		[self.prefsListBtn setEnabled:NO];
		[self.prefsSave setEnabled:NO];
	}
}

- (IBAction) listRoomsPressed:(id) sender {
	NSLog(@"Getting rooms...");
	[self saveCampAndTokenPrefs];
	[self doCampfireAuth];
	[self setRooms];
}

- (void)setRooms {
	[self.campfire getVisibleRoomsWithHandler:^(NSArray* rooms) {
		NSLog(@"%@", rooms);
		NSMutableArray *titles = [NSMutableArray array];
		NSMutableArray *defRooms = [NSMutableArray array];
		for (id room in rooms) {
			[titles addObject:[room name]];
			NSDictionary *defRoom = [NSDictionary dictionaryWithObjectsAndKeys:
				[room name], @"name", [room roomID], @"roomID", [room topic], @"topic", nil];
			[defRooms addObject:defRoom];
		}
		[self.prefs setObject:defRooms forKey:@"campfireRooms"];
		NSLog(@"%@", titles);
		[self.prefsRooms removeAllItems];
		[self.prefs setObject:titles forKey:@"campfireRoomList"];
		[self.prefsRooms addItemsWithTitles:titles];
		[self.prefsRooms setEnabled:YES];
		[self.prefsSave setEnabled:YES];
	}];
}

- (void)saveCampAndTokenPrefs {	
	NSString *camp = [self.prefsCampName stringValue];
	NSString *auth = [self.prefsAuthToken stringValue];
	NSString *roomID = [self getRoomIDForTitle:[self.prefsRooms titleOfSelectedItem]];
	[self.prefs setObject:camp forKey:@"campfireName"];
	[self.prefs setObject:auth forKey:@"campfireAuthToken"];
	[self.prefs setObject:roomID forKey:@"campfireRoomID"];
}

- (IBAction) savePreferencesPressed:(id) sender {
	NSLog(@"Saving preferences...");
	NSLog(@"%@", self.prefs);
	[self closePreferences];
}

- (void)closePreferences {
	[NSApp endSheet:self.preferences];
	[self.preferences orderOut:self];
	[self.preferences performClose:self];
	if (!self.campfireIsAuthed) {
		[self doCampfireAuth];
	}
	[self doCampfireRoomJoin];
	[self findPlayer];
}

- (void)doCampfireAuth {
	[self updateStatus:@"Joining campfire..."];
	NSString *campfireUrl = [NSString stringWithFormat:@"https://%@.campfirenow.com", 
							 [self.prefs stringForKey:@"campfireName"]];
	NSLog(@"Initializing HappyCampfire");
	self.campfire = [[HappyCampfire alloc] initWithCampfireURL:campfireUrl];
	self.campfire.authToken = [self.prefs stringForKey:@"campfireAuthToken"];
	[self updateStatus:@"Logged in to campfire"];
}

- (void)doCampfireRoomJoin {
	NSLog(@"Joining campfire room %@...", [self.prefs stringForKey:@"campfireRoomID"]);
	[self.campfire joinRoom:[self.prefs stringForKey:@"campfireRoomID"]
	  WithCompletionHandler:^(NSError *error) {
		  NSLog(@"Joined room with error: %@", error);
	  }];
}

- (void)findPlayer {
	[self updateStatus:@"Finding music player..."];
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	if ( [iTunes isRunning] ) {
		self.player = iTunes;
		[self updateStatus:@"Found iTunes"];
		[self.playerTimer invalidate];
		[self startUpdateLoop];
		
	} else {
		[self updateStatus:@"Start iTunes!"];
		if (![self.playerTimer isValid]) {
			self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:3
															target:self
														  selector:@selector(playerTimerUpdate:)
														  userInfo:nil
														   repeats:YES];
		}
	}

}

- (void)playerTimerUpdate:(NSTimer *)timerObj {
	[self findPlayer];
}

- (void)startUpdateLoop {
	[self update];
	self.timer = [NSTimer scheduledTimerWithTimeInterval:3
						target:self 
						selector:@selector(timerUpdate:) 
						userInfo:nil 
						repeats:YES];
}

- (void)timerUpdate:(NSTimer *)timerObj {
	[self update];
}

- (void)update {
	NSLog(@"Updating...");
	if ([player isRunning]) {
		iTunesTrack *newTrack = [player currentTrack];
		if ([newTrack name] == nil || [player playerState] != iTunesEPlSPlaying) {
			[self updateStatus:@"You need to play something!"];
			[self clearTrackInfo];
		} else {
			[self updateStatus:@"Connected to Campfire"];
			NSLog(@"Playing track: %@ from %@ by %@", [newTrack name], [newTrack album], [newTrack artist]);
			BOOL different = ![self.currentName isEqualToString:[newTrack name]];
			different = different || ![self.currentAlbum isEqualToString:[newTrack album]];
			different = different || ![self.currentArtist isEqualToString:[newTrack artist]];
			if (different) {
				NSLog(@"Track is new");
				self.currentName = [NSString stringWithString:[newTrack name]];
				self.currentAlbum = [NSString stringWithString:[newTrack album]];
				self.currentArtist = [NSString stringWithString:[newTrack artist]];
				NSString *roomID = [self.prefs stringForKey:@"campfireRoomID"];
				[self updateStatus:@"Sending track to Campfire..."];
				NSLog(@"Notifying campfire of new track");
				NSString *campfireText = [NSString stringWithFormat:@"*playing %@, by %@ (from '%@')*",
										  self.currentName, self.currentArtist, self.currentAlbum];
				[self.campfire sendText:campfireText toRoom:roomID 
				 completionHandler:^(HCMessage *message, NSError *error){
					 NSLog(@"Sent [%@] to campfire", message);
					 NSLog(@"Error: %@", error);
					 [self updateStatus:@"...sent!"];
				 }];
				NSLog(@"Current track now is: %@, %@, %@", self.currentName, self.currentAlbum, self.currentArtist);
			} else {
				NSLog(@"Song the same, doing nothing");
			}
			[self updateTrackWithName:self.currentName withArtist:self.currentArtist withAlbum:self.currentAlbum];
		}
	} else {
		[self clearTrackInfo];
		[self.timer invalidate];
		[self findPlayer];
	}
}


- (void)updateStatus:(NSString *)msg {
	[self.statusLabel setStringValue:msg];
}

- (void)updateTrackWithName: (NSString *)name withArtist:(NSString *)artist withAlbum:(NSString *)album {
	[self.trackName setStringValue:name];
	NSString *info = [NSString stringWithFormat:@"by %@, (from %@)", artist, album];
	[self.trackInfo setStringValue:info];
}

- (void)clearTrackInfo {
	[self.trackName setStringValue:@""];
	[self.trackInfo setStringValue:@""];
}

@end

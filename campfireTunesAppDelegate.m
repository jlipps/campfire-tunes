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
@synthesize trackAlbum;
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
@synthesize debug;

- (campfireTunesAppDelegate*)init {
	self = [super init];
	self.currentName = @"";
	self.currentAlbum = @"";
	self.currentArtist = @"";
	self.debug = NO;//YES;
	return self;
}

- (void)dealloc {
	[self.campfire dealloc];
	[self.player dealloc];
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
	NSLog(@"Checking preferences: campfireName: %@, campfireAuthToken: %@, campfireRoomID: %@, campfireRoomTitle: %@", 
		  [self.prefs stringForKey:@"campfireName"],
		  [self.prefs stringForKey:@"campfireAuthToken"],
		  [self.prefs stringForKey:@"campfireRoomID"],
		  [self.prefs stringForKey:@"campfireRoomTitle"]);
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
		[self.prefsRooms selectItemWithTitle:[self.prefs stringForKey:@"campfireRoomTitle"]];
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
				NSLog(@"ID for %@ is %@", title, [room objectForKey:@"roomID"]);
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
		if ( [self.prefs stringForKey:@"campfireRoomTitle"] != nil ) {
			[self.prefsRooms selectItemWithTitle:[self.prefs stringForKey:@"campfireRoomTitle"]];
		}
		[self.prefsRooms setEnabled:YES];
		[self.prefsSave setEnabled:YES];
	}];
}

- (void)saveCampAndTokenPrefs {	
	NSString *camp = [self.prefsCampName stringValue];
	NSString *auth = [self.prefsAuthToken stringValue];
	[self.prefs setObject:camp forKey:@"campfireName"];
	[self.prefs setObject:auth forKey:@"campfireAuthToken"];
}

- (void)saveRoomPrefs {
	NSString *roomID = [self getRoomIDForTitle:[self.prefsRooms titleOfSelectedItem]];
	[self.prefs setObject:roomID forKey:@"campfireRoomID"];
	[self.prefs setObject:[self.prefsRooms titleOfSelectedItem] forKey:@"campfireRoomTitle"];
}

- (IBAction) savePreferencesPressed:(id) sender {
	NSLog(@"Saving preferences...");
	NSLog(@"%@", self.prefs);
	[self saveCampAndTokenPrefs];
	[self saveRoomPrefs];
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
	NSLog(@"Finding music player");
	PlayerApplication *p = [PlayerApplication getActivePlayer];
	if ( p != nil ) {
		[self.player release];
		self.player = p;
		NSString *msg = [NSString stringWithFormat:@"Found %@", [self.player name]];
		NSLog(msg);
		[self updateStatus:msg];
		[self.playerTimer invalidate];
		[self startUpdateLoop];
		
	} else {
		[self updateStatus:@"Start iTunes or Spotify!"];
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
		PlayerTrack *newTrack = [player currentTrack];
		if ([newTrack name] == nil || ![player isPlaying]) {
			[self updateStatus:@"You need to play something!"];
			[self clearTrackInfo];
		} else {
			[self updateStatus:[NSString stringWithFormat:@"Connected to Campfire with %@", [self.player name]]];
			NSLog(@"Playing track: %@ from %@ by %@", [newTrack name], [newTrack album], [newTrack artist]);
			BOOL diff = ![self.currentName isEqualToString:[newTrack name]];
			diff = diff || ![self.currentAlbum isEqualToString:[newTrack album]];
			diff = diff || ![self.currentArtist isEqualToString:[newTrack artist]];
			if (diff) {
				NSLog(@"Track is not the same as last track this run");				
				self.currentName = [NSString stringWithString:[newTrack name]];
				self.currentAlbum = [NSString stringWithString:[newTrack album]];
				self.currentArtist = [NSString stringWithString:[newTrack artist]];
				BOOL prefsDiff = YES;
				if ([self.prefs stringForKey:@"lastSentName"] != nil) {
					NSString *pName = [self.prefs stringForKey:@"lastSentName"];
					NSString *pAlbum = [self.prefs stringForKey:@"lastSentAlbum"];
					NSString *pArtist = [self.prefs stringForKey:@"lastSentArtist"];
					prefsDiff = ![pName isEqualToString:self.currentName];
					prefsDiff = prefsDiff || ![pAlbum isEqualToString:self.currentAlbum];
					prefsDiff = prefsDiff || ![pArtist isEqualToString:self.currentArtist];
				}
				if(!prefsDiff) {
					NSLog(@"This is the same track we uploaded last time, doing nothing");
				} else {
					NSString *roomID = [self.prefs stringForKey:@"campfireRoomID"];
					[self updateStatus:@"Sending track..."];
					NSLog(@"Notifying campfire of new track");
					NSString *campfireText = [NSString stringWithFormat:@":notes: %@ :guitar: %@ :dvd: %@%@%@",
											  self.currentName, self.currentArtist, 
											  self.currentAlbum, [newTrack campfireStarEmoji],
											  [newTrack url]];
					if ([self.currentAlbum hasPrefix:@"spotify:user"]) {
						NSLog(@"Not sending, this is an ad!");
					} else {
						if (self.debug) {
							NSLog(@"Fake-sent [%@] to campfire", campfireText);
						} else {
							[self.campfire sendText:campfireText toRoom:roomID 
							 completionHandler:^(HCMessage *message, NSError *error){
								 NSLog(@"Sent [%@] to campfire", message);
								 NSLog(@"Error: %@", error);
								 [self updateStatus:@"Sending track...done!"];
								 [self.prefs setObject:self.currentName forKey:@"lastSentName"];
								 [self.prefs setObject:self.currentAlbum forKey:@"lastSentAlbum"];
								 [self.prefs setObject:self.currentArtist forKey:@"lastSentArtist"];
							 }];
						}
					}
				}				
				NSLog(@"Current track now is: %@, %@, %@", self.currentName, self.currentAlbum, self.currentArtist);
			} else {
				NSLog(@"Track is the same, doing nothing");
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
	[self.trackInfo setStringValue:artist];
	[self.trackAlbum setStringValue:album];
}

- (void)clearTrackInfo {
	[self.trackName setStringValue:@""];
	[self.trackInfo setStringValue:@""];
	[self.trackAlbum setStringValue:@""];
}

@end

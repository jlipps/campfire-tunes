//
//  campfireTunesAppDelegate.h
//  campfire-tunes
//
//  Created by Jonathan Lipps on 5/17/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlayerApplication.h"
#import "HappyCampfire/HappyCampfire.h"

@interface campfireTunesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSTextField *statusLabel;
	NSTextField *trackName;
	NSTextField *trackInfo;
	NSTextField *trackAlbum;
	NSPanel *preferences;
	NSTextField *prefsCampName;
	NSTextField *prefsAuthToken;
	NSButton *prefsSave;
	NSButton *prefsListBtn;
	NSPopUpButton *prefsRooms;
	PlayerApplication *player;
	NSTimer *timer;
	NSTimer *playerTimer;
	NSString *currentName;
	NSString *currentAlbum;
	NSString *currentArtist;
	HappyCampfire *campfire;
	BOOL campfireIsAuthed;
	NSUserDefaults *prefs;
	BOOL debug;
}

@property (assign) BOOL debug;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSTextField *trackName;
@property (assign) IBOutlet NSTextField *trackInfo;
@property (assign) IBOutlet NSTextField *trackAlbum;
@property (assign) IBOutlet NSPanel *preferences;
@property (assign) IBOutlet NSTextField *prefsCampName;
@property (assign) IBOutlet NSTextField *prefsAuthToken;
@property (assign) IBOutlet NSButton *prefsSave;
@property (assign) IBOutlet NSButton *prefsListBtn;
@property (assign) IBOutlet NSPopUpButton *prefsRooms;
@property (retain) PlayerApplication *player;
@property (assign) NSTimer *timer;
@property (assign) NSTimer *playerTimer;
@property (copy) NSString *currentName;
@property (copy) NSString *currentAlbum;
@property (copy) NSString *currentArtist;
@property (assign) HappyCampfire *campfire;
@property (assign) BOOL campfireIsAuthed;
@property (assign) NSUserDefaults *prefs;

- (IBAction) savePreferencesPressed:(id) sender;
- (IBAction) listRoomsPressed:(id) sender;
- (IBAction) prefsMenuItem:(id) sender;

- (BOOL) preferencesSet;
- (void) openPreferences;
- (void) closePreferences;
- (void) saveCampAndTokenPrefs;
- (void) saveRoomPrefs;
- (void) doCampfireAuth;
- (void) doCampfireRoomJoin;
- (void) setRooms;
- (NSString *) getRoomIDForTitle: (NSString *)title;
- (void) findPlayer;
- (void) startUpdateLoop;
- (void) timerUpdate:(NSTimer*) timer;
- (void) update;
- (void) updateStatus: (NSString *)msg;
- (void) updateTrackWithName: (NSString *)name withArtist:(NSString *)artist withAlbum:(NSString *)album;
- (void) clearTrackInfo;
- (void) prefPaneFieldDidChange:(NSNotification *)aNotification;

@end

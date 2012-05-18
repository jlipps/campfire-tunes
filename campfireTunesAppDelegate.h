//
//  campfireTunesAppDelegate.h
//  campfire-tunes
//
//  Created by Jonathan Lipps on 5/17/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import "HappyCampfire/HappyCampfire.h"

@interface campfireTunesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSTextField *statusLabel;
	NSTextField *trackName;
	NSTextField *trackInfo;
	NSPanel *preferences;
	NSTextField *prefsCampName;
	NSTextField *prefsAuthToken;
	NSButton *prefsSave;
	NSButton *prefsListBtn;
	NSPopUpButton *prefsRooms;
	SBApplication *player;
	NSTimer *timer;
	NSTimer *playerTimer;
	NSString *currentName;
	NSString *currentAlbum;
	NSString *currentArtist;
	HappyCampfire *campfire;
	BOOL campfireIsAuthed;
	NSUserDefaults *prefs;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSTextField *trackName;
@property (assign) IBOutlet NSTextField *trackInfo;
@property (assign) IBOutlet NSPanel *preferences;
@property (assign) IBOutlet NSTextField *prefsCampName;
@property (assign) IBOutlet NSTextField *prefsAuthToken;
@property (assign) IBOutlet NSButton *prefsSave;
@property (assign) IBOutlet NSButton *prefsListBtn;
@property (assign) IBOutlet NSPopUpButton *prefsRooms;
@property (assign) SBApplication *player;
@property (assign) NSTimer *timer;
@property (assign) NSTimer *playerTimer;
@property (copy autorelease) NSString *currentName;
@property (copy autorelease) NSString *currentAlbum;
@property (copy autorelease) NSString *currentArtist;
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
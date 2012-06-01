//
//  PlayerApplication.h
//  campfire-tunes
//
//  Created by Jonathan Lipps on 5/21/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import "Spotify.h"

@class PlayerTrack, PlayerApplication;

enum PlayerType {
	PlayerTypeITunes = 'iTunes',
	PlayerTypeSpotify = 'Spotify'
};
typedef enum PlayerType PlayerType;


@interface PlayerTrack : NSObject {
	PlayerType type;
	SBObject *nativeTrack;
}

@property (assign) PlayerType type;
@property (assign) SBObject *nativeTrack;

- (PlayerTrack *)init:(id)track withPlayerType:(PlayerType)playerType;
- (NSString *)artist;
- (NSString *)album;
- (NSImage *)artwork;
- (NSString *)name;
- (NSInteger)rating;
- (BOOL)starred;
- (NSString *)url;
- (NSString *)campfireStarEmoji;


@end


@interface PlayerApplication : NSObject {
	PlayerType type;
	SBApplication *nativeApp;
}

@property (assign) PlayerType type;
@property (assign) SBApplication *nativeApp;

- (PlayerApplication *)initWithPlayerType:(PlayerType)playerType;
- (BOOL) isRunning;
- (BOOL) isPlaying;
- (NSString *) name;
- (PlayerTrack *) currentTrack;

+ (PlayerApplication *)getActivePlayer;

@end

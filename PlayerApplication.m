//
//  PlayerApplication.m
//  campfire-tunes
//
//  Created by Jonathan Lipps on 5/21/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "PlayerApplication.h"
#import "NSImage+SaveExtensions.h"


@implementation PlayerTrack

@synthesize type;
@synthesize nativeTrack;

- (PlayerTrack *)init:(id)track withPlayerType:(PlayerType)playerType {
	self = [super init];
	self.type = playerType;
	self.nativeTrack = [track retain];
	return self;
}

- (void)dealloc {
    [self.nativeTrack release];
	[super dealloc];
}

- (NSString *)artist {
	return [self.nativeTrack artist];
}

- (NSString *)album {
	return [self.nativeTrack album];
}

- (NSImage *)artwork {
	if (self.type == PlayerTypeSpotify) {
		return [self.nativeTrack artwork];
	} else if (self.type == PlayerTypeITunes) {
		iTunesArtwork *artwork = [[self.nativeTrack artworks] objectAtIndex:0];
		if (artwork != nil) {
			return [artwork data];
		}
		return nil;
	}
}

- (NSString *)name {
	return [self.nativeTrack name];
}

- (NSString *)url {
	if (self.type == PlayerTypeSpotify) {
		NSArray *chunks = [[self.nativeTrack spotifyUrl] componentsSeparatedByString: @":"];
		NSString *track = [chunks objectAtIndex:([chunks count]-1)];
		return [NSString stringWithFormat:@" http://open.spotify.com/track/%@", track];
	} else {
		return @"";
	}
}

- (NSInteger)rating {
	if (self.type == PlayerTypeITunes) {
		// returns 0 - 5
		if ([self.nativeTrack ratingKind] == iTunesERtKUser) {
			NSInteger rating = [self.nativeTrack rating];
			return rating / 20;
		} else {
			return 0;
		}
	} else {
		return 0;
	}
}

- (BOOL)starred {
	if (self.type == PlayerTypeSpotify) {
		return [self.nativeTrack starred];
	} else {
		return NO;
	}
}

- (NSString *)campfireStarEmoji {
	NSMutableString *emoji = [NSMutableString stringWithString:@""];
	if (self.type == PlayerTypeITunes) {
		NSInteger rating = [self rating];
		for (int i=0; i < rating; i++) {
			[emoji appendString:@" :star:"];
		}
	} else if (self.type == PlayerTypeSpotify && [self starred]) {
		[emoji appendString:@" :star2:"];
	}
	return emoji;	
}

- (BOOL)isAdvertisement {
	if (self.type == PlayerTypeSpotify) {
		NSString *album = [self album];
		return [album hasPrefix:@"spotify:user"] ||
				[album hasPrefix:@"http:"] ||
				[album hasPrefix:@"spotify:ad"];
	}
	return NO;
}

@end


@implementation PlayerApplication

@synthesize type;
@synthesize nativeApp;

- (PlayerApplication *)initWithPlayerType:(PlayerType)playerType {
	[super init];
	self.type = playerType;
	if (self.type == PlayerTypeITunes) {
		self.nativeApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	} else if (self.type == PlayerTypeSpotify) {
		self.nativeApp = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
	}
    [self.nativeApp retain];
	return self;
}

- (void)dealloc {
    [self.nativeApp release];
	[super dealloc];
}

- (BOOL)isRunning {
	return [self.nativeApp isRunning];
}

- (BOOL)isPlaying {
	if (self.type == PlayerTypeITunes) {
		return [self.nativeApp playerState] == iTunesEPlSPlaying;
	} else if (self.type == PlayerTypeSpotify) {
		return [self.nativeApp playerState] == SpotifyEPlSPlaying;
	}
	return NO;
}

- (PlayerTrack *)currentTrack {
	return [[[PlayerTrack alloc] init:[self.nativeApp currentTrack] 
								 withPlayerType:self.type] autorelease];
}

- (NSString *)name {
	if (self.type == PlayerTypeITunes) {
		return @"iTunes";
	} else if (self.type == PlayerTypeSpotify) {
		return @"Spotify";
	}
	return @"";
}

+ (PlayerApplication *)getActivePlayer {
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
	if ( [iTunes isRunning] || [spotify isRunning] ) {
		if ( [spotify isRunning] && [spotify playerState] == SpotifyEPlSPlaying ) {
			return [[PlayerApplication alloc] initWithPlayerType:PlayerTypeSpotify];
		} else if ( [iTunes isRunning] ) {
			return [[PlayerApplication alloc] initWithPlayerType:PlayerTypeITunes];
		} else {
			return [[PlayerApplication alloc] initWithPlayerType:PlayerTypeSpotify];
		}
	}
	return nil;
}

@end



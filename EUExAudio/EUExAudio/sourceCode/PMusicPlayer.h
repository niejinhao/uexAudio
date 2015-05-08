//
//  PMusicPlayer.h
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-8.
//  Copyright 2011 正益无线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MusicListViewController.h"
@class EUExAudio;
@interface PMusicPlayer : NSObject <MusicListDelegate>{
	EUExAudio * euexObj;
	NSArray * musicSet;
 	UINavigationController * nav;
	MPMoviePlayerViewController * playerViewController;
}
 @property(nonatomic,retain)UINavigationController * nav;
-(void)openPlayerWithUrlSet:(NSArray *)urlSet activeIndex:(int)startIndex;
-(id)initWithEuex:(EUExAudio *)euexObj_;
@end

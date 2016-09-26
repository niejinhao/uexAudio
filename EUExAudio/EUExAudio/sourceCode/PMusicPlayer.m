//
//  PMusicPlayer.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-8.
//  Copyright 2011 正益无线. All rights reserved.
//

#import "PMusicPlayer.h"
#import "EUExAudio.h"
#import "EUtility.h"
@implementation PMusicPlayer
 @synthesize nav;
-(id)initWithEuex:(EUExAudio *)euexObj_{
	euexObj = euexObj_;
	return self;
}
-(void)showMusicPlayer{
  
}
-(void)openPlayerWithUrlSet:(NSArray *)urlSet activeIndex:(int)startIndex{
 	musicSet = [[NSArray alloc] initWithArray:urlSet];
	if ([musicSet count]==0) {
		return;
	}
	 playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:[musicSet objectAtIndex:startIndex]];  
 	[playerViewController.moviePlayer prepareToPlay];
	[playerViewController.moviePlayer play];
	[playerViewController.moviePlayer setFullscreen:NO]; 
    [playerViewController.moviePlayer setControlStyle:MPMovieControlStyleEmbedded];
	[playerViewController.moviePlayer setScalingMode:MPMovieScalingModeAspectFill];
 	playerViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(moreBtnClick)];

	playerViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"关闭"
																							 style:UIBarButtonItemStylePlain 
																							target:self 
																							action:@selector(closeBtnClick)];
 	UINavigationController * navigation = [[UINavigationController alloc] initWithRootViewController:playerViewController];
	self.nav = navigation;
	nav.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [EUtility brwView:euexObj.meBrwView presentModalViewController:nav animated:YES];
}
-(void)moreBtnClick {
	MusicListViewController *listController = [[MusicListViewController alloc] init];
	listController.musicList = [NSMutableArray arrayWithArray:musicSet];
	listController.delegate = self;
	[nav pushViewController:listController animated:YES];
}
-(void)musicNeedPlayWithUrl:(NSURL *)mUrl {
	if (playerViewController) {
		[playerViewController.moviePlayer setContentURL:mUrl];
		[playerViewController.moviePlayer prepareToPlay];
		[playerViewController.moviePlayer play];
	}
	
}
-(void)closeBtnClick {
  	[nav dismissViewControllerAnimated:YES completion:nil];
}
//-(void)dealloc{
//	if (playerViewController) {
//		playerViewController = nil;
//	}
// 	[musicSet release];
//	[nav release];
//	[super dealloc];
//}
@end

//
//  MusicPlayerViewController.h
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-17.
//  Copyright 2011 正益无线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
@protocol MusicListDelegate <NSObject>

-(void)musicNeedPlayWithUrl:(NSURL *)mUrl;

@end

@interface MusicListViewController : UITableViewController{
	id<MusicListDelegate> _delegate;
	NSMutableArray * musicList;
}
@property(nonatomic, assign) id<MusicListDelegate> delegate;
@property(nonatomic, retain) NSMutableArray * musicList;
@end

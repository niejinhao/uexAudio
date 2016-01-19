//

//  PlayerManager.h

//

//  Created by  正益无线 on 12-3-30.

//  Copyright 2012 正益无线. All rights reserved.

//


#import <Foundation/Foundation.h>
#import "AMRPlayer.h"
#import "EUtility.h"
#import "EUExAudio.h"
@class EUExAudio;

@protocol PlayManagerDelegate <NSObject>

-(void)changePlayProgressWithPro:(int)newProgress;
-(void)playFinishedNotify;

@end



@class AMRPlayer;
@interface PlayerManager : NSObject  <AMRPlayerDelegate>{
    EUExAudio * euexObj;
    
	AMRPlayer* _player;
	NSString* _currentFileName;
	
	BOOL _playStatus;
	
	BOOL _recordStatus;
	
	id<PlayManagerDelegate> _delegate;
}
@property(assign)id<PlayManagerDelegate> delegate;

@property (nonatomic,assign) BOOL playStatus;
@property (nonatomic,assign) NSInteger runloopTime;
@property (nonatomic,assign) NSInteger playedTime;
@property (nonatomic,strong) NSString *fileName;

@property (nonatomic,assign) BOOL recordStatus;

@property(nonatomic,copy) NSString* currentFileName;

@property(nonatomic,assign) NSInteger stopStaus;

-(void)initAudioSession:(int)type;

+ (id)getInstance;

+ (void)releaseInstance;

- (BOOL)startRecord:(NSString*)fileName;

- (BOOL)stopRecord;

- (BOOL)playStop:(NSString*)fileName runloopTime:(NSInteger)runloopTime euexObj:(EUExAudio *)inEuexObj;
-(void)pausePlay;

-(id)init;

@end

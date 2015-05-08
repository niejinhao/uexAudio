//
//  PFMusicPlayer.h
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-7.
//  Copyright 2011 正益无线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class EUExAudio;

@interface PFMusicPlayer : NSObject <AVAudioPlayerDelegate>{
	EUExAudio * euexObj;
    NSInteger playTimes;//循环播放次数
}
@property (assign)NSInteger runloopMode;
-(BOOL)openWithPath:(NSString *)inPath euexObj:(EUExAudio *)inEuexObj;
-(BOOL)playMusic;
-(BOOL)palyNext:(NSString *)inPath;
-(BOOL)pauseMusic;
-(BOOL)stopMusic;
-(BOOL)replayMusic;
-(void)volumeUp;
-(void)volumeDown;
@end

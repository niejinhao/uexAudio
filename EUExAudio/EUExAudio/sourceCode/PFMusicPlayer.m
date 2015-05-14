//
//  PFMusicPlayer.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-7.
//  Copyright 2011 正益无线. All rights reserved.
//

#import "PFMusicPlayer.h"
#import "EUtility.h"
#import "EUExAudio.h"
#define PER_VOLUME 0.1
#define PER_FORWARD_BACK 2

@implementation PFMusicPlayer
AVAudioPlayer * currentPlayer;
@synthesize runloopMode;
-(BOOL)openWithPath:(NSString *)inPath euexObj:(EUExAudio *)inEuexObj {
	 euexObj = inEuexObj;
	NSFileManager * fmanager = [NSFileManager defaultManager];
	if (![fmanager fileExistsAtPath:inPath]) {
		return NO;
	}
	NSURL * fileUrl = [NSURL fileURLWithPath:inPath];
	if (currentPlayer) {
		if ([currentPlayer isPlaying]) {
			[currentPlayer stop];
		}
		[currentPlayer release];
		currentPlayer = nil; 
	}
    
	currentPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:nil];
	if (currentPlayer) {
		[currentPlayer setDelegate:self];
		currentPlayer.volume = 1.0; 
		[currentPlayer prepareToPlay];
         playTimes = 0;
	}
	return YES;
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    playTimes++;
    if (self.runloopMode == -1) {
        //无限循环播放
        [currentPlayer play];
        NSString * jsStr = [NSString stringWithFormat:@"if(uexAudio.onPlayFinished!=null){uexAudio.onPlayFinished(%d)}",(int)playTimes];
        [euexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    } else {
        if (playTimes < self.runloopMode) {
            //循环一定次数
            [currentPlayer play];
            NSString * jsStr = [NSString stringWithFormat:@"if(uexAudio.onPlayFinished!=null){uexAudio.onPlayFinished(%d)}",(int)playTimes];
            [euexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
        }else {
            [self stopMusic];
            NSString * jsStr = [NSString stringWithFormat:@"if(uexAudio.onPlayFinished!=null){uexAudio.onPlayFinished(1)}"];
            [euexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
        }
    }
}
-(BOOL)playMusic {
	[currentPlayer play];
	if ([currentPlayer isPlaying]) {
		return YES;
	} else {
		return NO;
	}
}
-(BOOL)pauseMusic{
	if ([currentPlayer isPlaying]) {
		[currentPlayer pause];
	}
	return YES;
}
-(BOOL)replayMusic {
	if (currentPlayer) {
		[currentPlayer setCurrentTime:0];
		[currentPlayer play];
	}
	return YES;
}
-(BOOL)stopMusic {
    playTimes =0;
	[currentPlayer setCurrentTime:0];
	[currentPlayer stop];
	return YES;
}
-(BOOL)palyNext:(NSString *)inPath {
	BOOL result;
	if (currentPlayer) {
		[currentPlayer stop];
		[currentPlayer release];
		currentPlayer = nil;
	}
	NSFileManager * fmanager = [NSFileManager defaultManager];
	if ([fmanager fileExistsAtPath:inPath]) {
		result = YES;
	}else {
		result = NO;
	}	
	currentPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:inPath] error:nil];
	[currentPlayer prepareToPlay];
	[currentPlayer play];
	return result;
}
-(void)volumeUp {
	if ((currentPlayer.volume + PER_VOLUME) <= 1) {		
		currentPlayer.volume += PER_VOLUME;
	}
	[currentPlayer updateMeters];
}
-(void)volumeDown {
	if (currentPlayer.volume > 0) {
		currentPlayer.volume  = currentPlayer.volume -  PER_VOLUME;
        [currentPlayer updateMeters];
	}
}
-(void)dealloc {
	if (currentPlayer) {
		[currentPlayer release];
		currentPlayer = nil;
	}
    [super dealloc];
}




// 解码错误
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"解码错误！");
    
    
}

// 当音频播放过程中被中断时
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    // 当音频播放过程中被中断时，执行该方法。比如：播放音频时，电话来了！
    // 这时候，音频播放将会被暂停。
}

// 当中断结束时
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags{
    
    // AVAudioSessionInterruptionFlags_ShouldResume 表示被中断的音频可以恢复播放了。
    // 该标识在iOS 6.0 被废除。需要用flags参数，来表示视频的状态。
    
    NSLog(@"中断结束，恢复播放");
    if (flags == AVAudioSessionInterruptionFlags_ShouldResume && player != nil){
        [player play];
    }
    
}
@end

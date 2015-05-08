//
//  AudioPlayer.m
//  Share
//
//  Created by Lin Zhang on 11-4-26.
//  Copyright 2011年 www.eoemobile.com. All rights reserved.
//

#import "AudioPlayer.h"
#import "AudioButton.h"
#import "AudioStreamer.h"

@implementation AudioPlayer

@synthesize streamer, url, button;


- (id)initWithUexobj:(EUExAudio*)uexObj{
    self = [super init];
    if (self) {
        self.isContent=0;
        self.playTimes = 0;
        self.uexObj = uexObj;
    }
    
    return self;
}
- (id)init
{
    self = [super init];
    if (self) {
        self.isContent=0;
        self.playTimes = 0;
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
    [url release];
    [streamer release];
    [button release];
    [timer invalidate];
}


- (BOOL)isProcessing
{
    return [streamer isPlaying] || [streamer isWaiting] || [streamer isFinishing] ;
}

- (void)play
{        
    if (!streamer) {
        
        self.streamer = [[AudioStreamer alloc] initWithURL:self.url];
        
        // set up display updater
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                    [self methodSignatureForSelector:@selector(updateProgress)]];    
        [invocation setSelector:@selector(updateProgress)];
        [invocation setTarget:self];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                             invocation:invocation 
                                                repeats:YES];
        
        // register the streamer on notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:streamer];
    }
    
    if ([streamer isPlaying]) {
        [streamer pause];
    } else {
        [streamer start];
    }
//    [self.streamer seekToTime:20];
//    if (self.isContent>0)
//    {
//        [self.streamer seekToTime:self.isContent];
//        NSLog(@"继续始点%f",self.isContent);
//        self.isContent=0;
//    }
}


- (void)stop
{
    
    [button setProgress:0];
    [button stopSpin];

    button.image = [UIImage imageNamed:playImage];
    button = nil; // 避免播放器的闪烁问题        
    [button release];     
    
    // release streamer
	if (streamer)
	{        
		[streamer stop];
		[streamer release];
		streamer = nil;
        
        // remove notification observer for streamer
		[[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:ASStatusChangedNotification
                                                      object:streamer];		
	}
}

- (void)updateProgress
{
    if (streamer.progress <= streamer.duration ) {
        [button setProgress:streamer.progress/streamer.duration];        
    } else {
        [button setProgress:0.0f];        
    }
}

-(void)setPositions:(double)posite
{
    [self.streamer seekToTime:posite];
}
- (double)currentTime
{
    return self.streamer.progress;
}
- (double)totalTime
{
    return self.streamer.duration;
}
/*
 *  observe the notification listener when loading an audio
 */
- (void)playbackStateChanged:(NSNotification *)notification
{
	if ([streamer isWaiting])
	{
        button.image = [UIImage imageNamed:stopImage];
        [button startSpin];
    } else if ([streamer isIdle]) {
        button.image = [UIImage imageNamed:playImage];
        self.playTimes++;
        
            //循环一定次数
            [self stop];
            NSString * jsStr = [NSString stringWithFormat:@"if(uexAudio.onPlayFinished!=null){uexAudio.onPlayFinished(%d)}",(int)self.playTimes];
            [_uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
            if (self.playTimes != self.runloopMode) {
                [self play];
            }
        
				
	} else if ([streamer isPaused]) {
        button.image = [UIImage imageNamed:playImage];
        [button stopSpin];
        [button setColourR:0.0 G:0.0 B:0.0 A:0.0];
    } else if ([streamer isPlaying] || [streamer isFinishing]) {
        button.image = [UIImage imageNamed:stopImage];
        [button stopSpin];        
	} else {
        
    }
    
    [button setNeedsLayout];    
    [button setNeedsDisplay];
}


@end

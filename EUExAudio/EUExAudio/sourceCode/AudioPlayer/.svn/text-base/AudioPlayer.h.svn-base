//
//  AudioPlayer.h
//  Share
//
//  Created by Lin Zhang on 11-4-26.
//  Copyright 2011年 www.eoemobile.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUExAudio.h"

@class AudioButton;
@class AudioStreamer;

@interface AudioPlayer : NSObject {
    AudioStreamer *streamer;
    AudioButton *button;   
    NSURL *url;
    NSTimer *timer;
}

@property (nonatomic, retain) AudioStreamer *streamer;
@property (nonatomic, retain) AudioButton *button;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) EUExAudio * uexObj;
@property (nonatomic, assign) NSInteger playTimes;
@property (nonatomic, assign) NSInteger runloopMode;
@property double isContent;
- (id)initWithUexobj:(EUExAudio*)uexObj;
- (void)play;
- (void)stop;
- (BOOL)isProcessing;
- (double)currentTime;
- (double)totalTime;
-(void)setPositions:(double)posite;
@end

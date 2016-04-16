//
//  RecorderController.h
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-19.
//  Copyright 2011 正益无线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "lame.h"
@protocol RecorderMp3ControllerDelegate <NSObject>

-(void)closeRecorder;

@end

@class EUExAudio;
@class saveController;
#define RECORD_DOC_NAME @"audio"
@interface RecorderMp3Controller : UIViewController <AVAudioSessionDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate>{
	NSInteger minute;
	NSInteger second;
	NSInteger hours;
	 
	UIButton *startBtn;
	NSTimer *recordTimer;
	NSTimer *sliderTimer;
	UILabel *showTimeLabel;
	//AVAudioRecorder *current_audioRecorder;
	//AVAudioPlayer *audioPlayer;
	EUExAudio *euexAudio;
    NSString *saveNameStr;
	UIImageView *bgView;
	UIImageView *statusView;
	UIImageView *bottomBgView;
	UIImageView *bottomView;
	UIButton *playBtn;
	UIButton *useBtn;
	UIImageView *redCircleView;
	UIImageView *trendsImage;
	BOOL isRed;
    UISlider *playSlider;
	NSString *savePath;
	UILabel *leftTimeLabel;
	UILabel *rightTimeLabel;
	NSString *timeStr;
    //mp3
    AVAudioSession *session;
    NSURL *recordedFile;
    AVAudioPlayer *playerMp3;
    AVAudioRecorder *recordermp3;
    NSString *saveNameMp3;

//	id<RecorderMp3ControllerDelegate> _delegate;
}
@property (nonatomic, assign) id<RecorderMp3ControllerDelegate> delegate;
//@property (nonatomic, retain) AVAudioRecorder * current_audioRecorder;
@property (nonatomic, retain) NSString * timeStr;
@property (nonatomic, retain) UILabel * leftTimeLabel;
@property (nonatomic, retain) UILabel * rightTimeLabel;
@property (nonatomic, retain) UILabel * showTimeLabel;
@property (nonatomic, retain) NSString * savePath;
@property (nonatomic, retain) NSString * saveNameStr;
//@property (nonatomic, retain) AVAudioPlayer * audioPlayer;
@property (nonatomic, retain) UISlider * playSlider;
@property (nonatomic, retain) UIImageView * trendsImage;
@property (nonatomic, retain) UIImageView * redCircleView;
@property (nonatomic, retain) UIImageView * bottomView;
@property (nonatomic, retain) UIImageView * bottomBgView;
@property (nonatomic, retain) UIImageView * statusView;
@property (nonatomic, retain) UIImageView * bgView;
@property (nonatomic, retain) UIButton * playBtn;
@property (nonatomic, retain) UIButton * startBtn;
@property (nonatomic, retain) UIButton * useBtn;
@property (nonatomic, retain) EUExAudio * euexAudio;
@property BOOL startBtnIsSelected;
//mp3
@property (nonatomic , retain) NSURL *recordedFile;
@property (nonatomic , retain) AVAudioPlayer *playerMp3;

@end

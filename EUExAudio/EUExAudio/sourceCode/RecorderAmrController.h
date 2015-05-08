//
//  RecorderAmrController.h
//  WebKitCorePlam
//
//  Created by 正益无线 on 12-5-14.
//  Copyright 2012 正益无线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PlayerManager.h"

@protocol RecorderAmrControllerDelegate <NSObject>

-(void)closeRecorder;

@end

@class EUExAudio;

#define RECORD_DOC_NAME @"audio"

@interface RecorderAmrController : UIViewController <PlayManagerDelegate,AVAudioPlayerDelegate>{
	NSInteger minute;
	NSInteger second;
	NSInteger hours;
	UIButton *startBtn;
	NSTimer *recordTimer;
	UILabel *showTimeLabel;
	EUExAudio *euexAudio;
	UIImageView *bgView;
	UIImageView *statusView;
	UIImageView *bottomBgView;
	UIImageView *bottomView;
	UIButton *playBtn;
	UIButton *useBtn;
	UIImageView *redCircleView;
	UIImageView *trendsImage;
	UIProgressView *progressView;
	BOOL isRed;
	NSString *savePath;
	NSString *timeStr;
    //
    AVAudioPlayer *audioPlayer;
    UISlider *playSlider;
    UILabel *leftTimeLabel;
    UILabel *rightTimeLabel;
    NSTimer *sliderTimer;
	id<RecorderAmrControllerDelegate> _delegate;
	int recordFileLength;
}
@property (nonatomic,assign) id<RecorderAmrControllerDelegate> delegate;
@property (nonatomic, retain) NSString * timeStr;
@property (nonatomic, retain) UILabel * showTimeLabel;
@property (nonatomic, retain) NSString * savePath;
@property (nonatomic, retain) NSString * saveNameStr;
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
@property (nonatomic, retain) UIProgressView * progressView;
@property BOOL startBtnIsSelected;

@property (nonatomic, retain) AVAudioPlayer * audioPlayer;
@property (nonatomic, retain) UISlider * playSlider;
@property (nonatomic, retain) UILabel * leftTimeLabel;
@property (nonatomic, retain) UILabel * rightTimeLabel;
@end

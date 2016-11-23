//
//  RecorderAmrController.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 12-5-14.
//  Copyright 2012 正益无线. All rights reserved.
//

#import "RecorderAmrController.h"

#import "EUExAudio.h"
#import <QuartzCore/CALayer.h>
#import "EUExBaseDefine.h"

#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen] bounds].size.height-(double)568 ) < DBL_EPSILON )

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

@implementation RecorderAmrController
@synthesize startBtnIsSelected;
@synthesize useBtn,startBtn,playBtn;
@synthesize euexAudio;
@synthesize bgView,bottomBgView,statusView,bottomView,redCircleView,trendsImage,showTimeLabel,progressView,audioPlayer,rightTimeLabel,leftTimeLabel,playSlider;
@synthesize  savePath, saveNameStr, timeStr;
@synthesize delegate = _delegate;
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
-(void) audioRecordBegin {
    NSFileManager * fmanager = [NSFileManager defaultManager];
    if ([fmanager fileExistsAtPath:savePath]) {
        [fmanager removeItemAtPath:savePath error:nil];
    }
    PlayerManager * rManager = [PlayerManager getInstance];
    [rManager startRecord:savePath];
}

- (void)showTimer {
    second += 1;
    if (second == 60) {
        minute ++;
        second = 0;
    }
    if (minute == 60) {
        hours ++;
        minute = 0;
    }
    if (hours == 99) {
        hours = 0;
    }
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    
    NSString * formatStr = [NSString stringWithFormat:@"%d:%d:%d",(int)hours,(int)minute,(int)second];
    NSDate * date = [df dateFromString:formatStr];
    NSString * str = [df stringFromDate:date];
    [showTimeLabel setText:str];
    self.timeStr = str;
    if (isRed) {
        [redCircleView setImage:[self getUIImageByPath:@"plugin_audio_recorder_turn_off.png"]];
        isRed = NO;
    } else {
        [redCircleView setImage:[self getUIImageByPath:@"plugin_audio_recorder_turn_on.png"]];
        isRed = YES;
    }
}

//获取当前时间字符串 //得到毫秒
- (NSString*)getCurrentTimeStr {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *curTimeStr = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
    return curTimeStr;
}

- (NSString *)getRecordFileName {
    NSString * wgtid = [[euexAudio.webViewEngine widget] widgetId];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString * wgtPath = [paths objectAtIndex:0];
    NSString *recorderPath = [NSString stringWithFormat:@"%@/apps/%@/%@/",wgtPath,wgtid,RECORD_DOC_NAME];
    NSFileManager * fmanager = [NSFileManager defaultManager];
    if (![fmanager fileExistsAtPath:recorderPath]) {
        [fmanager createDirectoryAtPath:recorderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName;
    if (self.saveNameStr) {
        fileName = [recorderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.amr",self.saveNameStr]];
    } else {
        fileName = [recorderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.amr",[self getCurrentTimeStr]]];
    }
    return fileName;
}
-(void)stopRecorder {
    [recordTimer invalidate];
    if (redCircleView) {
        [redCircleView removeFromSuperview];
    }
    if (showTimeLabel) {
        [showTimeLabel removeFromSuperview];
    }
    //draw progress
    if (playSlider) {
        [playSlider removeFromSuperview];
        
    }
    if (leftTimeLabel) {
        [leftTimeLabel removeFromSuperview];
        
    }
    if (rightTimeLabel) {
        [rightTimeLabel removeFromSuperview];
        
    }
    UISlider *proV = [[UISlider alloc] initWithFrame:CGRectMake(32, 60, 244, 16)];
    proV.userInteractionEnabled = YES;
    proV.value = 0;
    self.playSlider = proV;
    [statusView addSubview:playSlider];
    //left label
    UILabel * leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(32, 30, 80, 14)];
    leftLabel.text = @"00:00:00";
    [leftLabel setBackgroundColor:[UIColor clearColor]];
    [leftLabel setTextColor:[UIColor whiteColor]];
    self.leftTimeLabel = leftLabel;
    [statusView addSubview:leftTimeLabel];
    //right label
    UILabel * rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(202, 30, 80, 14)];
    rightLabel.text = self.timeStr;
    [rightLabel setBackgroundColor:[UIColor clearColor]];
    [rightLabel setTextColor:[UIColor whiteColor]];
    self.rightTimeLabel = rightLabel;
    [statusView addSubview:rightTimeLabel];
    PlayerManager *pMgr = [PlayerManager getInstance];
    if (pMgr) {
        [pMgr stopRecord];
        hours = 0;
        minute = 0;
        second = 0;
    }
}
- (void)startRecord {
    [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_normal.png"] forState:UIControlStateNormal];
    
    if (playSlider) {
        [playSlider removeFromSuperview];
    }
    if (leftTimeLabel) {
        [leftTimeLabel removeFromSuperview];
    }
    if(rightTimeLabel) {
        [rightTimeLabel removeFromSuperview];
    }
    if (redCircleView) {
        [redCircleView removeFromSuperview];
        [statusView addSubview:redCircleView];
    }
    if (showTimeLabel) {
        [showTimeLabel setText:@"00:00:00"];
        [showTimeLabel removeFromSuperview];
        [statusView addSubview:showTimeLabel];
    }
    
    recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showTimer) userInfo:nil repeats:YES];
    [self audioRecordBegin];
    
}
-(long)getFileLength:(NSString *)fileName {
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSDictionary * dic = [fmanager attributesOfItemAtPath:fileName error:nil];
    NSNumber * fileSize = [dic objectForKey:NSFileSize];
    long sum = [fileSize longValue];
    return sum;
}
-(void)playRecord {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
        //
    }
    recordFileLength = [self getFileLength:savePath];
    PlayerManager * pMgr = [PlayerManager getInstance];
    pMgr.playStatus = NO;
    pMgr.delegate = self;
    [pMgr playStop:savePath euexObjc:euexAudio];
     
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{

    if (playBtn) {
        [playBtn setSelected:NO];
        [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_normal.png"] forState:UIControlStateNormal];
    }
    if ([sliderTimer isValid]) {
        [sliderTimer invalidate];
    }
    if (leftTimeLabel) {
        [leftTimeLabel setText:@"00:00:00"];
    }
    if(playSlider){
        playSlider.value = 0;
    }
    
}
-(void)stopPlay{
    if (playBtn) {
        [playBtn setSelected:NO];
        [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_normal.png"] forState:UIControlStateNormal];
    }
    PlayerManager *pMgr = [PlayerManager getInstance];
    if (pMgr) {
        [pMgr playStop:savePath euexObjc:euexAudio];
    }
    //
    if ([sliderTimer isValid]) {
        [sliderTimer invalidate];
    }
    if (playSlider) {
        playSlider.value = 0;
    }
    
}
-(void)playBtnClick:(id)sender{
    UIButton * senderBtn = (UIButton *)sender;
    if ([senderBtn isSelected]) {
        [senderBtn setImage:[self getUIImageByPath:@"plugin_video_play_normal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[self getUIImageByPath:@"plugin_video_play_selected.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[self getUIImageByPath:@"plugin_video_play_disabled.png"] forState:UIControlStateDisabled];
        [senderBtn setSelected:	NO];
        [self stopPlay];
    } else {
        [senderBtn setImage:[self getUIImageByPath:@"parse_narmal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[self getUIImageByPath:@"parse_focus.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[self getUIImageByPath:@"parse_disable.png"] forState:UIControlStateDisabled];
        [senderBtn setSelected:YES];
        [self playRecord];
    }
}
-(void)startBtnCick:(id)sender {
    
    minute = 0;
    second = 0;
    hours = 0;
    PlayerManager *pMgr = [PlayerManager getInstance];
    if ([pMgr playStatus] == YES) {
        [pMgr playStop:savePath euexObjc:euexAudio];
    }
    UIButton * senderBtn = (UIButton *)sender;
    if ([senderBtn isSelected]) {
        [senderBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_record_normal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_record_pressed.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_record_disabled.png"] forState:UIControlStateDisabled];
        [useBtn setEnabled:YES];
        [playBtn setEnabled:YES];
        [senderBtn setSelected:	NO];
        [self stopRecorder];
    } else {
        [senderBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_stop_normal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_stop_pressed.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_stop_disabled.png"] forState:UIControlStateDisabled];
        [useBtn setEnabled:NO];
        [playBtn setEnabled:NO];
        [senderBtn setSelected:YES];
        [self startRecord];
    }
}
-(void)useBtnClick:(id)sender {
    PlayerManager * pMgr = [PlayerManager getInstance];
    if ([pMgr playStatus] == YES) {
        [pMgr playStop:savePath euexObjc:euexAudio];
    }
    if ([pMgr recordStatus] == YES) {
        [pMgr stopRecord];
    }
    //设置返回路径
    if (euexAudio) {
        [euexAudio uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:savePath];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_delegate && [_delegate respondsToSelector:@selector(closeRecorder)]) {
            [_delegate closeRecorder];
        }
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(void)closeBtnClick {
    PlayerManager *pMgr = [PlayerManager getInstance];
    if ([pMgr playStatus] == YES) {
        [pMgr playStop:savePath euexObjc:euexAudio];
    }
    if ([pMgr recordStatus] == YES) {
        [pMgr stopRecord];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_delegate&&[_delegate respondsToSelector:@selector(closeRecorder)]) {
            [_delegate closeRecorder];
        }
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    //INIT TIME
    minute = 0;
    second = 0;
    hours = 0;
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.savePath  = [self getRecordFileName];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(closeBtnClick)];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    //bg view
    UIImage * bguexAudio = [self getUIImageByPath:@"plugin_audio_recorder_bg.png"];
    bgView = [[UIImageView alloc] initWithImage:bguexAudio];
    if ([[[UIDevice currentDevice] systemVersion] floatValue]<7.0) {
        [bgView setFrame:self.view.bounds];
    }else{
        if (IS_IPHONE_5) {
            [bgView setFrame:CGRectMake(0, 70, 320, 568-70)];
        }else{
            [bgView setFrame:CGRectMake(0, 70, 320, 480-70)];
        }
    }
    [bgView setUserInteractionEnabled:YES];
    [bgView setContentMode:UIViewContentModeScaleToFill];
    //status view;
    UIImage * statusViewuexAudio = [self getUIImageByPath:@"plugin_audio_recorder_center_bg.png"];
    statusView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)];
    [statusView setImage:statusViewuexAudio];
    [statusView setUserInteractionEnabled:YES];
    //red circle
    redCircleView = [[UIImageView alloc] initWithFrame:CGRectMake(48, 40, 38, 38)];
    [redCircleView setImage:[self getUIImageByPath:@"plugin_audio_recorder_turn_off.png"]];
    [statusView addSubview:redCircleView];
    //time view
    
    showTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 42, 190, 38)];
    [showTimeLabel setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:30]];
    [showTimeLabel setTextColor:[UIColor whiteColor]];
    [showTimeLabel setText:@" 00:00:00"];
    [showTimeLabel setBackgroundColor:[UIColor clearColor]];
    [statusView addSubview:showTimeLabel];
    
    //status image
    trendsImage = [[UIImageView alloc] initWithFrame:CGRectMake(30, 100, 250, 100)];
    [trendsImage setImage:[self getUIImageByPath:@"plugin_audio_recorder_status.png"]];
    [statusView addSubview:trendsImage];
    [bgView addSubview:statusView];
    
    //bottom background
    UIImage  * dotImage = [[self getUIImageByPath:@"plugin_audio_recorder_bg_dot.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:20];
    float dotH = 198;
    if (IS_IPHONE_5) {
        dotH = 568 - 218 - 70;
    }
    bottomBgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 218, 320,dotH)];
    [bottomBgView setImage:dotImage];
    [bottomBgView setUserInteractionEnabled:YES];
    //bottomview
    bottomView = [[UIImageView alloc] initWithImage:[self getUIImageByPath:@"footerbg.png"]];
    [bottomView setFrame:CGRectMake(0,bottomBgView.bounds.size.height - 50, 320, 50)];
    [bottomView setUserInteractionEnabled:YES];
    
    
    //play btn
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_normal.png"] forState:UIControlStateNormal];
    [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_selected.png"] forState:UIControlStateHighlighted];
    [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_disabled.png"] forState:UIControlStateDisabled];
    [playBtn setFrame:CGRectMake(15, 0, 50, 50)];
    [playBtn setEnabled:NO];
    [playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:playBtn];
    
    useBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [useBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_use_normal.png"] forState:UIControlStateNormal];
    [useBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_use_pressed.png"] forState:UIControlStateHighlighted];
    [useBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_use_disabled.png"] forState:UIControlStateDisabled];
    [useBtn setFrame:CGRectMake(255, 0, 50, 50)];
    [useBtn setEnabled:NO];
    [useBtn addTarget:self action:@selector(useBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:useBtn];
    
    //two lines
    UIImageView * imageLeft = [[UIImageView alloc] initWithImage:[self getUIImageByPath:@"plugin_arrow_left.png"]];
    UIImageView * imageRight = [[UIImageView alloc] initWithImage:[self getUIImageByPath:@"plugin_arrow_right.png"]];
    [imageLeft setFrame:CGRectMake(85, 0, 26, 50)];
    [imageRight setFrame:CGRectMake(209, 0, 26, 50)];
    [bottomView addSubview:imageLeft];
    [bottomView addSubview:imageRight];
    
    //start btn
    startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [startBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_record_normal.png"] forState:UIControlStateNormal];
    [startBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_record_pressed.png"] forState:UIControlStateHighlighted];
    [startBtn setImage:[self getUIImageByPath:@"plugin_audio_recorder_record_disabled.png"] forState:UIControlStateDisabled];
    [startBtn setFrame:CGRectMake(135, 0, 50, 50)];
    [startBtn setEnabled:YES];
    [startBtn addTarget:self action:@selector(startBtnCick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:startBtn];
    [bottomBgView addSubview:bottomView];
    [bgView addSubview:bottomBgView];
    [self.view addSubview:bgView];
}


/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    trendsImage = nil;
    redCircleView = nil;
    bgView = nil;
    bottomView = nil;
    playBtn = nil;
    useBtn = nil;
    bottomBgView = nil;
    statusView = nil;
    startBtn = nil;
    showTimeLabel = nil;
    leftTimeLabel = nil;
    rightTimeLabel = nil;
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


-(void)changePlayProgressWithPro:(int)newProgress {
    if (recordFileLength == 0) {
        return;
    }
    
    double progress =  (newProgress*1.0)/recordFileLength;
    double timeInter = playSlider.value;
    NSString *zoneTime = [NSString stringWithFormat:@"00:00:00"];
    playSlider.value = progress;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    NSDate *zoneDate = [df dateFromString:zoneTime];
    NSDate *localeDate = [zoneDate dateByAddingTimeInterval:timeInter];
    NSString *textStr = [df stringFromDate:localeDate];
    [leftTimeLabel setText:textStr];
}

-(void)playFinishedNotify{
    self.playSlider.value = 0;
    if (playBtn) {
        [playBtn setSelected:NO];
        [playBtn setImage:[self getUIImageByPath:@"plugin_video_play_normal.png"] forState:UIControlStateNormal];
    }
   
}
-(UIImage*)getUIImageByPath:(NSString *)path{
    UIImage *img=[UIImage imageWithContentsOfFile:[self getMyBundlePath1:path]];
    return img;
}
- (NSString*)getMyBundlePath1:(NSString *)filename
{
    NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"uexAudio.bundle"];
    NSBundle * libBundle = [NSBundle bundleWithPath: path] ;
    if ( libBundle && filename ){
        NSString * s=[[libBundle resourcePath ] stringByAppendingPathComponent : filename];
        return s;
    }
    return nil ;
}

//- (void)dealloc {
//    [savePath release];
//    if (self.saveNameStr) {
//        self.saveNameStr = nil;
//    }
//    [trendsImage release];
//    [redCircleView release];
//    [bgView release];
//    [bottomView release];
//    [playBtn release];
//    [useBtn release];
//    [bottomBgView release];
//    [statusView release];
//    [euexAudio release];
//    [startBtn release];
//    [showTimeLabel release];
//    [timeStr release];
//    //
//    [leftTimeLabel release];
//    [rightTimeLabel release];
//    [audioPlayer release];
//    [playSlider release];
//    [super dealloc];
//}
@end

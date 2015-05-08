//
//  RecorderController.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-19.
//  Copyright 2011 正益无线. All rights reserved.
//

#import "RecorderMp3Controller.h"
#import "EUtility.h"
#import "EUExAudio.h"
#import <QuartzCore/CALayer.h>
#import "EUExBaseDefine.h"

#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen] bounds].size.height-(double)568 ) < DBL_EPSILON )

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

@implementation RecorderMp3Controller
@synthesize startBtnIsSelected;
@synthesize useBtn,startBtn,playBtn;
@synthesize euexAudio;
@synthesize bgView,bottomBgView,statusView,bottomView,redCircleView,trendsImage,playSlider,showTimeLabel,rightTimeLabel,leftTimeLabel;
@synthesize playerMp3,savePath,saveNameStr,timeStr;
@synthesize delegate = _delegate;
@synthesize recordedFile;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.


-(void) audioRecordBegin {
    
    //liguofu
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString * path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.caf"];
    self.recordedFile = [[[NSURL alloc] initFileURLWithPath:path] autorelease];
    
    if (!savePath) {
        self.savePath = [self getRecordFileName];
    }
    if ([fmanager fileExistsAtPath:savePath]) {
        [fmanager removeItemAtPath:savePath error:nil];
    }
    session = [AVAudioSession sharedInstance];
    session.delegate = self;
    NSError * sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil) {
        //
    } else {
        [session setActive:YES error:nil];
    }
    //录音设置
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [settings setValue :[NSNumber numberWithFloat:11025.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    recordermp3 = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:settings error:nil];
    [recordermp3 prepareToRecord];
    [recordermp3 record];
    [settings release];
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    PluginLog(@"recoder:successful");
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    PluginLog(@"recoder:fail error = %@,info = %@",[error domain],[[error userInfo] description]);
}
- (void)showTimer{
    
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
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    
    NSString * formatStr = [NSString stringWithFormat:@"%d:%d:%d",(int)hours,(int)minute,(int)second];
    NSDate * date = [df dateFromString:formatStr];
    NSString * str = [df stringFromDate:date];
    [df release];
    [showTimeLabel setText:str];
    self.timeStr = str;
    if (isRed) {
        [redCircleView setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_turn_off.png"]];
        isRed = NO;
    }else {
        [redCircleView setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_turn_on.png"]];
        isRed = YES;
    }
}

//获取当前时间字符串 //得到毫秒
-(NSString*)getCurrentTimeStr {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString * curTimeStr=[NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
    [dateFormatter release];
    return curTimeStr;
}

- (NSString *)getRecordFileName {
    NSString * wgtName = [EUtility brwViewWidgetId:euexAudio.meBrwView];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString * wgtPath = [paths objectAtIndex:0];
    wgtPath = [NSString stringWithFormat:@"%@/apps/%@/%@/",wgtPath,wgtName,RECORD_DOC_NAME];
    NSFileManager * fmanager =  [NSFileManager defaultManager];
    if (![fmanager fileExistsAtPath:wgtPath]) {
        [fmanager createDirectoryAtPath:wgtPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * fileName;
    if (saveNameStr) {
        fileName = [NSString stringWithFormat:@"%@%@.mp3",wgtPath,saveNameStr];
    }else{
        fileName = [NSString stringWithFormat:@"%@%@.mp3 ",wgtPath,[self getCurrentTimeStr]];
    }
    return fileName;
}

-(void)sliderDisplay{
    if (playerMp3) {
        double timeInter = [self.playerMp3 currentTime];
        NSString *zoneTime = [NSString stringWithFormat:@"00:00:00"];
        playSlider.value = timeInter;
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"HH:mm:ss"];
        NSDate *zoneDate = [df dateFromString:zoneTime];
        NSDate *localeDate = [zoneDate dateByAddingTimeInterval:timeInter];
        NSString *textStr = [df stringFromDate:localeDate];
        [df release];
        if (leftTimeLabel) {
            [leftTimeLabel setText:textStr];
        }
    }else {
        playSlider.value = 0;
    }
}

-(void)sliderChange:(UISlider *)sender{
    if (sender.value == sender.maximumValue) {
        [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
        [playerMp3 stop];
        [playBtn setSelected:NO];
    }
    if (leftTimeLabel) {
        double timeInter = sender.value;
        NSString *zoneTime = [NSString stringWithFormat:@"00:00:00"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"HH:mm:ss"];
        NSDate *zoneDate =  [df dateFromString:zoneTime];
        NSDate *localeDate = [zoneDate dateByAddingTimeInterval:timeInter];
        NSString *textStr = [df stringFromDate:localeDate];
        [df release];
        [leftTimeLabel setText:textStr];
    }
    if (playerMp3) {
        if ([playerMp3 isPlaying]) {
            [playerMp3 stop];
            [playerMp3 setCurrentTime:sender.value];
            [playerMp3 prepareToPlay];
            [playerMp3 play];
        }
    }
}

-(void)stopRecorder{
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
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(32, 60, 244, 16)];
    slider.userInteractionEnabled = YES;
    
    [slider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged];
    slider.value = 0;
    self.playSlider = slider;
    [slider release];
    [statusView addSubview:playSlider];
    //left label
    UILabel * leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(32, 30, 80, 14)];
    leftLabel.text = @"00:00:00";
    [leftLabel setBackgroundColor:[UIColor clearColor]];
    [leftLabel setTextColor:[UIColor whiteColor]];
    self.leftTimeLabel = leftLabel;
    [leftLabel release];
    [statusView addSubview:leftTimeLabel];
    //right label
    UILabel * rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(202, 30, 80, 14)];
    rightLabel.text = self.timeStr;
    [rightLabel setBackgroundColor:[UIColor clearColor]];
    [rightLabel setTextColor:[UIColor whiteColor]];
    self.rightTimeLabel = rightLabel;
    [rightLabel release];
    [statusView addSubview:rightTimeLabel];
    if (recordermp3) {
        [recordermp3 stop];
        [self audio_PCMtoMP3];
        hours = 0;
        minute = 0;
        second = 0;
    }
    
}

- (void)audio_PCMtoMP3 {
    
    @try {
        int read, write;
        NSString *cafFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.caf"];
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([self.savePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        
        NSError * playerError;
        AVAudioPlayer * playerMp3Mp3 = [[AVAudioPlayer alloc] initWithContentsOfURL:[[[NSURL alloc] initFileURLWithPath:self.savePath] autorelease] error:&playerError];
        self.playerMp3 = playerMp3Mp3;
        playerMp3.volume = 1.0f;
        if (playerMp3 == nil) {
            //
        }
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
        playerMp3.delegate = self;
        [playerMp3Mp3 release];
    }
}
//liguofu
-(void)startRecord {
    if (playerMp3) {
        [playerMp3 stop];
        [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
    }
    if (playSlider) {
        [playSlider removeFromSuperview];
    }
    if (leftTimeLabel) {
        [leftTimeLabel removeFromSuperview];
    }
    if (rightTimeLabel) {
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
    recordTimer =[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showTimer) userInfo:nil repeats:YES];
    
    [self audioRecordBegin];
    if (recordermp3) {
        [recordermp3 record];
    }
}
-(void)playRecord {
    NSFileManager *fmanager = [NSFileManager defaultManager];
    if ([fmanager fileExistsAtPath:savePath]) {
        PluginLog(@"file exist and savapath = %@",savePath);
    }
    NSURL *url = [NSURL fileURLWithPath:savePath];
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    player.numberOfLoops = 0;
    [player setDelegate:self];
    [player prepareToPlay];
    self.playerMp3 = player;
    [player release];
    [playerMp3 play];
    sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(sliderDisplay) userInfo:nil repeats:YES];
    playSlider.minimumValue = 0;
    playSlider.maximumValue = [playerMp3 duration];
}

-(void)playerMp3DidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if (playBtn) {
        [playBtn setSelected:NO];
        [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
        
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
        [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
        
    }
    if (playerMp3) {
        if ([playerMp3 isPlaying]) {
            [playerMp3 stop];
        }
    }
    if ([sliderTimer isValid]) {
        [sliderTimer invalidate];
    }
    if (playSlider) {
        playSlider.value = 0;
    }
    
}
-(void)playBtnClick:(id)sender{
    UIButton *senderBtn = (UIButton *)sender;
    if ([senderBtn isSelected]) {
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_selected.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_disabled.png"] forState:UIControlStateDisabled];
        [senderBtn setSelected:	NO];
        [self stopPlay];
    }else {
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/parse_narmal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/parse_focus.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/parse_disable.png"] forState:UIControlStateDisabled];
        [senderBtn setSelected:YES];
        [self playRecord];
    }
}
//liguofu
-(void)startBtnCick:(id)sender{
    minute = 0;
    second = 0;
    hours = 0;
    if (playerMp3) {
        if ([playerMp3 isPlaying]) {
            [playerMp3 stop];
        }
    }
    UIButton *senderBtn = (UIButton *)sender;
    if ([senderBtn isSelected]) {
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_normal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_pressed.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_disabled.png"] forState:UIControlStateDisabled];
        [useBtn setEnabled:YES];
        [playBtn setEnabled:YES];
        [senderBtn setSelected:	NO];
        [self stopRecorder];
    }else {
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_stop_normal.png"] forState:UIControlStateNormal];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_stop_pressed.png"] forState:UIControlStateHighlighted];
        [senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_stop_disabled.png"] forState:UIControlStateDisabled];
        [useBtn setEnabled:NO];
        [playBtn setEnabled:NO];
        [senderBtn setSelected:YES];
        [self startRecord];
    }
}
//liguofu
-(void)useBtnClick:(id)sender{
    if (playerMp3) {
        if ([playerMp3 isPlaying]) {
            [playerMp3 stop];
        }
    }
    if (recordermp3) {
        if ([recordermp3 isRecording]) {
            [recordermp3 stop];
        }
    }
    if (euexAudio) {
        [euexAudio  uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:savePath];
    }
    if (320 != SCREEN_WIDTH && [EUtility isIpad]) {
        if (_delegate&&[_delegate respondsToSelector:@selector(closeRecorder)]) {
            [_delegate closeRecorder];
        }
    }else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(void)closeBtnClick{
    if (playerMp3) {
        if ([playerMp3 isPlaying]) {
            [playerMp3 stop];
        }
    }
    if (recordermp3) {
        if ([recordermp3 isRecording]) {
            [recordermp3 stop];
        }
    }
    if (320 != SCREEN_WIDTH && [EUtility isIpad]) {
        if (_delegate&&[_delegate respondsToSelector:@selector(closeRecorder)]) {
            [_delegate closeRecorder];
        }
    }else {
        [self dismissModalViewControllerAnimated:YES];
        
    }
    
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

-(void)viewDidAppear:(BOOL)animated{
    self.savePath = [self getRecordFileName];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //INIT TIME
    minute = 0;
    second = 0;
    hours = 0;
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(closeBtnClick)] autorelease];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    //bg view
    UIImage * bguexAudio = [UIImage imageNamed:@"uexAudio/plugin_audio_recorder_bg.png"];
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
    UIImage * statusViewuexAudio = [UIImage imageNamed:@"uexAudio/plugin_audio_recorder_center_bg.png"];
    statusView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)];
    [statusView setImage:statusViewuexAudio];
    [statusView setUserInteractionEnabled:YES];
    //red circle
    redCircleView = [[UIImageView alloc] initWithFrame:CGRectMake(48, 40, 38, 38)];
    [redCircleView setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_turn_off.png"]];
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
    [trendsImage setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_status.png"]];
    [statusView addSubview:trendsImage];
    [bgView addSubview:statusView];
    
    //bottom background
    UIImage  * dotImage = [[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_bg_dot.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:20];
    float dotH = 198;
    if (IS_IPHONE_5) {
        dotH = 568 - 218 - 70;
    }
    bottomBgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 218, 320,dotH)];
    [bottomBgView setImage:dotImage];
    [bottomBgView setUserInteractionEnabled:YES];
    //bottomview
    bottomView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uexAudio/footerbg.png"]];
    [bottomView setFrame:CGRectMake(0,bottomBgView.bounds.size.height - 50, 320, 50)];
    [bottomView setUserInteractionEnabled:YES];
    
    
    //play btn
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
    [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_selected.png"] forState:UIControlStateHighlighted];
    [playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_disabled.png"] forState:UIControlStateDisabled];
    [playBtn setFrame:CGRectMake(15, 0, 50, 50)];
    [playBtn setEnabled:NO];
    [playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:playBtn];
    
    useBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [useBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_use_normal.png"] forState:UIControlStateNormal];
    [useBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_use_pressed.png"] forState:UIControlStateHighlighted];
    [useBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_use_disabled.png"] forState:UIControlStateDisabled];
    [useBtn setFrame:CGRectMake(255, 0, 50, 50)];
    [useBtn setEnabled:NO];
    [useBtn addTarget:self action:@selector(useBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:useBtn];
    
    //two lines
    UIImageView * imageLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uexAudio/plugin_arrow_left.png"]];
    UIImageView * imageRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uexAudio/plugin_arrow_right.png"]];
    [imageLeft setFrame:CGRectMake(85, 0, 26, 50)];
    [imageRight setFrame:CGRectMake(209, 0, 26, 50)];
    [bottomView addSubview:imageLeft];
    [bottomView addSubview:imageRight];
    [imageRight release];
    [imageLeft release];
    
    //start btn
    startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [startBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_normal.png"] forState:UIControlStateNormal];
    [startBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_pressed.png"] forState:UIControlStateHighlighted];
    [startBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_disabled.png"] forState:UIControlStateDisabled];
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
}


- (void)dealloc {
    [recordermp3 release];
    [savePath release];
    if (self.saveNameStr) {
        self.saveNameStr=nil;
    }
    [playerMp3 release];
    [playSlider release];
    [trendsImage release];
    [redCircleView release];
    [bgView release];
    [bottomView release];
    [playBtn release];
    [useBtn release];
    [bottomBgView release];
    [statusView release];
    [euexAudio release];
    [startBtn release];
    [showTimeLabel release];
    [leftTimeLabel release];
    [rightTimeLabel release];
    [timeStr release];
    [super dealloc];
}
@end

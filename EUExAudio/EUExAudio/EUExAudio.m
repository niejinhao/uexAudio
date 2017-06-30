//
//  EUExAudioMgr.m
//  testjs1
//
//  Created by zywx on 11-8-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUExAudio.h"

#import "PMusicPlayer.h"
#import "Recorder.h"

#import "EUExBaseDefine.h"
#import "PlayerManager.h"
#import "AudioButton.h"
#import "AudioPlayer.h"
#import "lame.h"

@interface EUExAudio()
@property (nonatomic,strong)ACJSFunctionRef *cbBackgroundRecord;

@end


@implementation EUExAudio{
    int backgroundSoundType;
    
}
//@synthesize  soundFileObject;
@synthesize amrPath;
@synthesize currentRecorder;
@synthesize recordFilePath;
@synthesize soundPoolDict;
@synthesize alert_Arguments;
@synthesize player;
@synthesize recordedFile;

//onLine
@synthesize sliderse,musicUrl;


- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    if (self = [super initWithWebViewEngine:engine]) {
        
    }
    return self;
}

-(void)dealloc{
    pfPlayer = nil;
    currentRecorder = nil;
    musicPlayer  = nil;
    amrPath = nil;
    backBoard = nil;
    btnAudio = nil;
    progresse = nil;
    _audioPlayer = nil;
    self.sliderse = nil;
    self.musicUrl = nil;
}


-(void)open:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSString *inPath) = inArguments;

    
    session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
    [session setActive:YES error:nil];
    if ([inPath hasPrefix:@"http://"]) {
        isNetResource = YES;
        self.musicUrl = inPath;
        backBoard = [[UIView alloc]initWithFrame:CGRectMake(0, 100, 320, 200)];
        backBoard.backgroundColor = [UIColor greenColor];
        [self musicOnline];
    } else {
        isNetResource=NO;
        if (inPath!=nil) {
            NSString *absPath = [self absPath:inPath];
            NSString *exestr = nil;
            NSString *lastStr = nil;
            exestr = [self file:absPath];
            // 提取路径的最后一部分
            lastStr = [absPath lastPathComponent];
            if ([exestr isEqualToString:@"#!AMR\n"] || [lastStr isEqualToString:@"amr"]) {
                isAmr = YES;
                self.amrPath = absPath;
            }else{
                pfPlayer = [[PFMusicPlayer alloc] init];
                if (![pfPlayer openWithPath:absPath euexObj:self]) {
                    //[self jsFailedWithOpId:0 errorCode:1010104 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
                }
            }
        } else {
            //[self jsFailedWithOpId:0 errorCode:1010101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
        }
    }
}
// 获取文件播放格式，amr #!AMR\n    mp3 ID3\n    car caff\n
- (NSString *)file:(NSString *)path{
    // 打开文件~
    FILE *pF  = fopen([path UTF8String], "r");
    
    int WhichLine=0;             //指定要读取哪一行
    int CurrentIndex=0;             //当前读取的行
    char StrLine[1024];             //每行最大读取的字符数,可根据实际情况扩大
    if(pF == NULL) //判断文件是否存在及可读
    {
        printf("error!");
        return nil;
        
    }
    
    while (!feof(pF))
    {
        if (CurrentIndex==WhichLine)
        {
            fgets(StrLine,1024,pF);  //读取一行
            NSString *string = [[NSString alloc]initWithCString:StrLine encoding:NSUTF8StringEncoding];
            return string;
        }
        fgets(StrLine,1024,pF);  //读取一行,并定位到下一行
        CurrentIndex++;
    }
    fclose(pF);                     //关闭文件
    return nil;
}


//光感事件，使用近距离传感器，当接近耳朵时，调用听筒模式，远离时采用功放模式（也可以自定义）

-(void)proximityStateChanged:(NSNotificationCenter *)notification;
{
    if ([[UIDevice currentDevice] proximityState] == YES) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else{
        
        if (self.needCall)
        {
            //切换为听筒播放
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        }else{
            //切换为扬声器播放
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
    }
}

- (void)setProximityState:(NSMutableArray *)inArray
{
    ACArgsUnpack(NSNumber *flagNum) = inArray;
    if (flagNum.integerValue == 1) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateChanged:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
    else
    {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
        
    }
    
}

-(void)play:(NSMutableArray *)inArguments {
    
    if (self.needCall)
    {
        //切换为听筒播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else{
        //切换为扬声器播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    if ([inArguments count] > 0) {
        self.runloopTime = [[inArguments objectAtIndex:0] integerValue];
    }
    if (isNetResource) {
        isPlayed = YES;
        isNeedCloseTimerAutomatic = YES;
        [self playAudio:btnAudio];
        musicTimer =[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(upProgress) userInfo:nil repeats:YES];
    } else {
        //
        NSInteger inRunloopMode = [[inArguments objectAtIndex:0] intValue];
        
        if (isAmr==YES) {
            PlayerManager *amrMgr = [PlayerManager getInstance];
            //
            amrMgr.runloopMode = inRunloopMode;
            
            [amrMgr playStop:amrPath  euexObjc:self];
            return;
        }
        if (pfPlayer) {
            if ([inArguments count] > 0) {
                
                pfPlayer.runloopMode = inRunloopMode;
                if ([pfPlayer playMusic] == NO) {
                    //[super jsFailedWithOpId:0 errorCode:1010203 errorDes:UEX_ERROR_DESCRIBE_FILE_FORMAT];
                }
            } else {
                pfPlayer.runloopMode = 0;
                if ([pfPlayer playMusic] == NO) {
                    //[super jsFailedWithOpId:0 errorCode:1010203 errorDes:UEX_ERROR_DESCRIBE_FILE_FORMAT];
                }
            }
        }
    }
}

-(void)pause:(NSMutableArray *)inArguments
{
    if(self.needCall)
    {
        //切换为听筒播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else{
        //切换为扬声器播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    if (isNetResource) {
        if (isPlayed) {
            [self playAudio:btnAudio];
            if (musicTimer) {
                [musicTimer invalidate];
                musicTimer = nil;
            }
            isPlayed = NO;
        }
    } else {
        if (isAmr == YES) {
            PlayerManager *amrMgr = [PlayerManager getInstance];
            [amrMgr pausePlay];
            return;
        }
        if ([pfPlayer pauseMusic] == NO) {
            //[super jsFailedWithOpId:0 errorCode:1010304 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
        }
    }
}

-(void)replay:(NSMutableArray *)inArguments {
    if (isAmr == YES) {
        PlayerManager *amrMgr = [PlayerManager getInstance];
        if ([amrMgr playStatus]==YES) {
            [amrMgr playStop:amrPath euexObjc:self];
            [amrMgr playStop:amrPath euexObjc:self];
        }
    } else {
        [pfPlayer replayMusic];
    }
}

-(void)stop:(NSMutableArray *)inArguments {
    if(self.needCall)
    {
        //切换为听筒播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else{
        //切换为扬声器播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    if (isNetResource) {
        if (isPlayed) {
            if (musicTimer) {
                [musicTimer invalidate];
                musicTimer=nil;
            }
            [_audioPlayer stop];
            progresse.progress=0;
        }
    } else {
        if (isAmr==YES) {
            PlayerManager *amrMgr = [PlayerManager getInstance];
            if ([amrMgr playStatus]==YES) {
                [amrMgr playStop:amrPath euexObjc:self];
            }
            return;
        }
        if (pfPlayer) {
            [pfPlayer stopMusic];
        } else {
            //[super jsFailedWithOpId:0 errorCode:1010404 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
        }
    }
}

-(void)volumeUp:(NSMutableArray *)inArguments {
    if (!isNetResource) {
        if (isAmr) {
            return;
        }
        if (pfPlayer) {
            [pfPlayer volumeUp];
        } else {
            //[super jsFailedWithOpId:0 errorCode:1010504 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
        }
    }
}

-(void)volumeDown:(NSMutableArray *)inArguments {
    if (!isNetResource) {
        if (isAmr) {
            return;
        }
        if (pfPlayer) {
            [pfPlayer volumeDown];
        } else {
            //[super jsFailedWithOpId:0 errorCode:1010604 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
        }
    }
}

-(void)openPlayer:(NSMutableArray *)inArguments {
//    ACArgsUnpack(NSArray *paths,NSNumber *idxNum) = inArguments;
//    int startIndex = idxNum.intValue;
//    
//    NSMutableArray *urlSet = [NSMutableArray array];
//
//    for (NSString *path in paths) {
//        NSString *absPath = [[self absPath:path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        NSURL * url = nil;
//        if ([absPath hasPrefix:@"http://"] || [absPath hasPrefix:@"https://"]) {
//            url = [NSURL URLWithString:absPath];
//        }else {
//            url = [NSURL fileURLWithPath:absPath];
//        }
//        [urlSet addObject:url];
//    }
//    if(startIndex >= [urlSet count]){
//        startIndex = 0;
//    }
//    if ([urlSet count] > 0) {
//        musicPlayer = [[PMusicPlayer alloc] initWithEuex:self];
//        [musicPlayer openPlayerWithUrlSet:urlSet activeIndex:startIndex];
//    } else {
//        //[super jsFailedWithOpId:0 errorCode:1010701 errorDes:UEX_ERROR_DESCRIBE_ARGS];
//    }
}

#pragma mark Recorder
//打开录音界面

-(void)openRecord_ViewController:(NSMutableArray*)inArguments{
    
    if (!recorder) {
        session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [session setActive:YES error:nil];
        recorder = [[Recorder alloc] initWithEuex:self];
    }
    if ([inArguments count] > 0) {
        recorder.soundType = [[inArguments objectAtIndex:0] intValue];
    } else {
        recorder.soundType = 0;
    }
    //指定文件名
    if ([inArguments count] >= 2) {
        if ([[inArguments objectAtIndex:1] length] > 0) {
            recorder.saveNameStr = [inArguments objectAtIndex:1];
        }
    }
    [recorder showRecorder];
}

//对话框代理
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.message isEqualToString:@"文件已存在，是否覆盖已存在文件？"]) {
        if (buttonIndex == 1) {
            //打开录音界面
            if (self.alert_Arguments && [self.alert_Arguments objectForKey:@"inArguments"]) {
                if ([[self.alert_Arguments objectForKey:@"inArguments"] isKindOfClass:[NSArray class]]) {
                    if ([self.alert_Arguments objectForKey:@"Type"]) {
                        if ([[self.alert_Arguments objectForKey:@"Type"] isEqualToString:@"record"]) {
                            [self openRecord_ViewController:[self.alert_Arguments objectForKey:@"inArguments"]];
                        } else if ([[self.alert_Arguments objectForKey:@"Type"] isEqualToString:@"startBackgroundRecord"]) {
                            [self open_startBackgroundRecord:[self.alert_Arguments objectForKey:@"inArguments"]];
                        }
                    }
                }
            }
        }
    }
}

//判断文件时候已经存在
- (BOOL)isfileExisted:(NSString *)fileNameStr {
    NSString * wgtName = [self.webViewEngine.widget appId];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString * wgtPath = [paths objectAtIndex:0];
    NSString * recorderPath = [NSString stringWithFormat:@"%@/apps/%@/%@/",wgtPath,wgtName,RECORD_DOC_NAME];
    NSFileManager * fmanager = [NSFileManager defaultManager];
    if (![fmanager fileExistsAtPath:recorderPath]) {
        [fmanager createDirectoryAtPath:recorderPath withIntermediateDirectories:YES attributes:nil error:nil];
        return NO;
    }
    NSString * fileName = [recorderPath stringByAppendingPathComponent:fileNameStr];
    if ([fmanager fileExistsAtPath:fileName]) {
        return YES;
    }
    return NO;
}

-(void)record:(NSMutableArray *)inArguments {
//    //指定文件名 判断该文件是否存在 如果存在则提示用户
//    if ([inArguments count] >= 2) {
//        int soundType = [[inArguments objectAtIndex:0] intValue];
//        NSString * inSaveNameStr = [inArguments objectAtIndex:1];
//        NSString * saveNameStr = nil;
//        if ([inSaveNameStr length] > 0) {
//            if (soundType == 0) {
//                saveNameStr = [NSString stringWithFormat:@"%@.amr",inSaveNameStr];
//            }
//            if (soundType == 1){
//                saveNameStr = [NSString stringWithFormat:@"%@.caf",inSaveNameStr];
//            }
//            if (soundType == 2) {
//                saveNameStr = [NSString stringWithFormat:@"%@.mp3",inSaveNameStr];
//                saveNameMp3 = [NSString stringWithFormat:@"%@",inSaveNameStr] ;
//            }
//            
//            if (saveNameStr != nil) {
//                if ([self isfileExisted:saveNameStr]) { //已经存在 则提示是否进行替换
//                    if (self.alert_Arguments == nil) {
//                        self.alert_Arguments = [NSMutableDictionary dictionaryWithCapacity:3];
//                    }
//                    [self.alert_Arguments setObject:inArguments forKey:@"inArguments"];
//                    [self.alert_Arguments setObject:@"record" forKey:@"Type"];
//                    
//                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示"
//                                                                     message:@"文件已存在，是否覆盖已存在文件？"
//                                                                    delegate:self
//                                                           cancelButtonTitle:@"取消"
//                                                           otherButtonTitles:@"确定",nil];
//                    [alert show];
//                    return;
//                }
//            }
//        }
//    }
//    //打开录音界面
//    [self openRecord_ViewController:inArguments];
}

-(void) audioRecordInstance:(NSString *)savePath {
    NSFileManager * fmanager = [NSFileManager defaultManager];
    if ([fmanager fileExistsAtPath:savePath]) {
        [fmanager removeItemAtPath:savePath error:nil];
    }
    NSURL * destinationURL = [NSURL fileURLWithPath:savePath];
    NSMutableDictionary * recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    [recordSettings setObject:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];
    [recordSettings setObject:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    NSError * recorderSetupError = nil;
    AVAudioRecorder  * audioRecorder = [[AVAudioRecorder alloc] initWithURL:destinationURL
                                                                   settings:recordSettings
                                                                      error:&recorderSetupError];
    if (!audioRecorder) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @" "
                                                        message: [recorderSetupError localizedDescription]
                                                       delegate: nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];

        return;
    }
    [audioRecorder setDelegate:self];
    [audioRecorder prepareToRecord];
    [audioRecorder setMeteringEnabled:YES];
    self.currentRecorder = audioRecorder;
}


//获取当前时间字符串 //得到毫秒
-(NSString*)getCurrentTimeStr {
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString * curTimeStr=[NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];

    return curTimeStr;
}

- (NSString *)getRecordFileName:(NSString*)saveNameStr  with_format:(NSString *)format {
    NSString * wgtName = [self.webViewEngine.widget appId];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString * wgtPath = [paths objectAtIndex:0];
    NSString * recorderPath = [NSString stringWithFormat:@"%@/apps/%@/%@/",wgtPath,wgtName,RECORD_DOC_NAME];
    NSFileManager * fmanager =  [NSFileManager defaultManager];
    if (![fmanager fileExistsAtPath:recorderPath]) {
        [fmanager createDirectoryAtPath:recorderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * fileName;
    if (saveNameStr && [saveNameStr length] > 0) {
        fileName = [recorderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",saveNameStr, format]];
    } else {
        fileName = [recorderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",[self getCurrentTimeStr], format]];
    }
    self.recordFilePath = fileName;
    ACLogDebug(@"hui-->uexAudio-->EUExAudio-->getRecordFileName-->fileName %@",fileName);
    return fileName;
}

-(void)open_startBackgroundRecord:(NSMutableArray *)inArguments{
    session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    NSString * inSaveNameStr = (inArguments.count >= 2) ? stringArg(inArguments[1]) : nil;


    
    
    
    if (backgroundSoundType == 0) {
        //amr
        NSString * filePath = [self getRecordFileName:inSaveNameStr with_format:@"amr"];
        PlayerManager * manager = [PlayerManager getInstance];
        if (manager.recordStatus == NO) {
            [manager startRecord:filePath];
        }
    } else if (backgroundSoundType == 1) {
        //caf
        NSString * filePath = [self getRecordFileName:inSaveNameStr with_format:@"caf"];
        [self audioRecordInstance:filePath];
        if (currentRecorder) {
            [currentRecorder record];
        }
    }
}
- (void)audio_PCMtoMP3
{
    NSString *cafFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.caf"];
    
    NSString *mp3FilePath = [self getRecordFileName:saveNameMp3 with_format:@"mp3"];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100.0);
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
        AVAudioPlayer * audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSURL alloc] initFileURLWithPath:mp3FilePath] error:&playerError];
        self.player = audioPlayer;
        player.volume = 1.0f;
        if (player == nil) {
            //
        }
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
        player.delegate = self;

    }
}
-(void)startBackgroundRecordMP3 {
    NSString * path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.caf"];
    self.recordedFile = [[NSURL alloc] initFileURLWithPath:path];
    session = [AVAudioSession sharedInstance];
    //session.delegate = self;
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
    [settings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    recordermp3 = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:settings error:nil];
    [recordermp3 prepareToRecord];
    [recordermp3 record];

}

-(void)startBackgroundRecord:(NSMutableArray *)inArguments {
    //指定文件名 判断该文件是否存在 如果存在则提示用户
    ACArgsUnpack(NSNumber *modeNum,NSString *fileName) = inArguments;
    backgroundSoundType = [modeNum intValue];
    if (fileName) {
        session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [session setActive:YES error:nil];
        NSString * inSaveNameStr = fileName;
        NSString * saveNameStr = nil;
        if ([inSaveNameStr length] > 0) {
            if (backgroundSoundType == 0) {
                saveNameStr = [NSString stringWithFormat:@"%@.amr",inSaveNameStr];
            } if (backgroundSoundType == 1){
                saveNameStr = [NSString stringWithFormat:@"%@.caf",inSaveNameStr];
            }if (backgroundSoundType == 2) {
                saveNameStr = [NSString stringWithFormat:@"%@.mp3",inSaveNameStr];
                saveNameMp3 = [NSString stringWithFormat:@"%@",inSaveNameStr];
            }
            if (saveNameStr != nil) {
                if ([self isfileExisted:saveNameStr]) { //已经存在 则提示是否进行替换
                    if (self.alert_Arguments == nil) {
                        self.alert_Arguments = [NSMutableDictionary dictionaryWithCapacity:3];
                    }
                    [self.alert_Arguments setObject:inArguments forKey:@"inArguments"];
                    [self.alert_Arguments setObject:@"startBackgroundRecord" forKey:@"Type"];
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                     message:@"文件已存在，是否覆盖已存在文件？"
                                                                    delegate:self
                                                           cancelButtonTitle:@"取消"
                                                           otherButtonTitles:@"确定",nil];
                    [alert show];
                    return;
                }
            }
        }

    }
    if (backgroundSoundType == 0 || backgroundSoundType == 1) {
        //开始后台录音
        [self open_startBackgroundRecord:inArguments];
    } else {
        [self startBackgroundRecordMP3];
    }
    
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    //successful
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexAudio.cbBackgroundRecord" arguments:ACArgsPack(@0,@0,recordFilePath)];
    [self.cbBackgroundRecord executeWithArguments:ACArgsPack(recordFilePath)];
    self.cbBackgroundRecord = nil;
}


-(void)stopBackgroundRecord:(NSMutableArray *)inArguments {
    ACArgsUnpack(ACJSFunctionRef *cb) = inArguments;

    switch (backgroundSoundType) {
        case 0:{
            PlayerManager *manager = [PlayerManager getInstance];
            if (manager.recordStatus == YES) {
                [manager stopRecord];
                [self.webViewEngine callbackWithFunctionKeyPath:@"uexAudio.cbBackgroundRecord" arguments:ACArgsPack(@0,@0,recordFilePath)];
                [cb executeWithArguments:ACArgsPack(recordFilePath)];
            }
            break;
            
        }
        case 1:{
            if (currentRecorder) {
                if ([currentRecorder isRecording]) {
                    self.cbBackgroundRecord = cb;
                    [currentRecorder stop];
                }
            }
            break;
            
        }
        case 2:{
            [recordermp3 stop];
            if(recordermp3) {
                recordermp3 = nil;
            }
            [self audio_PCMtoMP3];
            NSString *mp3FilePath=[self getRecordFileName:saveNameMp3 with_format:@"mp3"];
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexAudio.cbBackgroundRecord" arguments:ACArgsPack(@0,@0,mp3FilePath)];
            [cb executeWithArguments:ACArgsPack(recordFilePath)];
            break;
        }
        default:
            break;
    }

}

#pragma mark systemsound
static void completionCallback(SystemSoundID  mySSID, void* myself) {
    AudioServicesPlaySystemSound(mySSID);
}

-(void)openSoundPool:(NSMutableArray *)inArguments {
    if (!self.soundPoolDict) {
        self.soundPoolDict = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
}



-(void)addSound:(NSMutableArray *)inArguments {
    if ([inArguments count] > 1) {
        NSString * soundId = [inArguments objectAtIndex:0];
        NSString * soundPath = [inArguments objectAtIndex:1];
        if (soundPath == nil || soundId == nil) {
            //[super jsFailedWithOpId:0 errorCode:1011001 errorDes:UEX_ERROR_DESCRIBE_ARGS];
            return;
        }
        SystemSoundID soundFileObject;
        NSString * absPath = [super absPath:soundPath];
        OSStatus err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:absPath], &soundFileObject);
        if (err || !soundPoolDict) {
            //[super jsFailedWithOpId:0 errorCode:1011002 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
        } else {
            [self.soundPoolDict setObject:[NSNumber numberWithInt:soundFileObject] forKey:soundId];
        }
    }
}
-(void)playFromSoundPool:(NSMutableArray *)inArguments {
    NSString *inOpId = [inArguments objectAtIndex:0];
    if (soundPoolDict) {
        SystemSoundID sID = (SystemSoundID)[[soundPoolDict objectForKey:inOpId] intValue];
        AudioServicesPlaySystemSound(sID);
    }
}

-(void)stopFromSoundPool:(NSMutableArray *)inArguments {
    NSString *inOpId = [inArguments objectAtIndex:0];
    if (soundPoolDict) {
        SystemSoundID sID = (SystemSoundID)[[soundPoolDict objectForKey:inOpId] intValue];
        AudioServicesDisposeSystemSoundID(sID);
    }
}
-(void)closeSoundPool:(NSMutableArray *)inArguments{
    if (soundPoolDict) {
        [soundPoolDict removeAllObjects];

        soundPoolDict = nil;
    }
}
-(void)uexSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData{
    if (inData) {
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexAudio.cbRecord" arguments:ACArgsPack(@(inOpId),@(inDataType),inData)];

    }
}

-(void)clean{
    currentRecorder = nil;
    recordFilePath  = nil;
    pfPlayer = nil;
    soundPoolDict = nil;
    self.alert_Arguments = nil;
    //    退出后，光感取消
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
}
#pragma  mark
#pragma  mark - 加载播放网络音乐
#pragma  mark
//努力加载播放网络音乐
-(void)musicOnline {
    //播放网络音乐
    btnAudio = [[AudioButton alloc] initWithFrame:CGRectMake(130, 10, 50, 50)];
    UILabel * valume = [[UILabel alloc]initWithFrame:CGRectMake(10, 65, 45, 30)];
    valume.text = @"音量";
    valume.backgroundColor = [UIColor clearColor];
    [backBoard addSubview:valume];

    MPVolumeView * volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(90, 70, 200, 40)];
    [backBoard addSubview:volumeView];

    UILabel * valumee = [[UILabel alloc]initWithFrame:CGRectMake(10, 135, 45, 30)];
    valumee.text = @"进度";
    valumee.backgroundColor = [UIColor clearColor];
    [backBoard addSubview:valumee];

    
    progresse = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    progresse.frame = CGRectMake(90, 140, 200, 0);
    [backBoard addSubview:progresse];
    [self dragPlayPositionLines];
    isPlayed = NO;
}
//添加一个slider在progress上
-(void)dragPlayPositionLines {
    //slider
    UISlider * slider = [[UISlider alloc] initWithFrame:CGRectMake(90, 140, 200, 0)];
    [slider setBackgroundColor:[UIColor redColor]];
    slider.maximumValue = 100.0;
    slider.minimumValue = 0.0;
    slider.value = progresse.progress * 100;
    [slider setContinuous:YES];
    NSString * pathback = [[NSBundle mainBundle] pathForResource:@"uexAudioOnline/drage_null" ofType:@"png"];
    NSString * pathbackee = [[NSBundle mainBundle] pathForResource:@"uexAudioOnline/drage_null" ofType:@"png"];
    [slider setThumbImage:[UIImage imageWithContentsOfFile:pathback] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageWithContentsOfFile:pathbackee] forState:UIControlStateHighlighted];
    [slider addTarget:self action:@selector(valueChangede:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(displayTheNote:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(disappearTheNote:) forControlEvents:UIControlEventTouchCancel];
    [slider addTarget:self action:@selector(disappearTheNote:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(disappearTheNote:) forControlEvents:UIControlEventTouchUpOutside];
    
    UITapGestureRecognizer * tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTape:)];
    [slider addGestureRecognizer:tapGest];

    
    slider.backgroundColor = [UIColor clearColor];
    NSString * slidepath = [[NSBundle mainBundle]pathForResource:@"uexAudioOnline/drage_null" ofType:@"png"];
    UIImage * sImage = [UIImage imageWithContentsOfFile:slidepath];
    [slider setMinimumTrackImage:sImage forState:UIControlStateNormal];
    [slider setMaximumTrackImage:sImage forState:UIControlStateNormal];
    [backBoard addSubview:slider];
    self.sliderse = slider;

}
-(void)sliderTape:(UITapGestureRecognizer *)gesture {
    UISlider * slider = (UISlider *)gesture.view;
    CGPoint touchPoint = [gesture locationInView:slider];
    if (slider) {
        float newValue = touchPoint.x*100/200.0;
        [slider setValue:newValue animated:YES];
        progresse.progress = slider.value/100;
        [_audioPlayer setPositions:slider.value*totlesTime/100];
    }
}

-(void)valueChangede:(id)sender {
    UISlider * slider = (UISlider *)sender;
    [_audioPlayer setPositions:slider.value*currentTime/100];
    progresse.progress=slider.value/100;
}
-(void)displayTheNote:(id)sender{
    UISlider * slider = (UISlider *)sender;
    float value = slider.value;
    [slider setValue:value animated:YES];
    [_audioPlayer setPositions:value * totlesTime / 100];
    progresse.progress = value/100;
}
-(void)disappearTheNote:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [_audioPlayer setPositions:slider.value * totlesTime / 100];
    progresse.progress = slider.value/100;
}
//demo播放网络音频
- (void)playAudio:(AudioButton *)button {
    if (_audioPlayer == nil) {
        _audioPlayer = [[AudioPlayer alloc] initWithUexobj:self];
        _audioPlayer.runloopMode = self.runloopTime;
        _audioPlayer.playTimes=0;
    }
    if ([_audioPlayer.button isEqual:button]) {
        [_audioPlayer play];
    } else {
        [_audioPlayer stop];
        _audioPlayer.button = button;
        _audioPlayer.url = [NSURL URLWithString:self.musicUrl];
        _audioPlayer.runloopMode = self.runloopTime;
        _audioPlayer.playTimes = 0;
        [_audioPlayer play];
    }
}
//更新进度
-(void)upProgress {
    currentTime = [_audioPlayer currentTime];
    double totltime = [_audioPlayer totalTime];
    if (totltime>0) {
        totlesTime = totltime;
    }
    if (totltime == 0) {
        totltime = 1.0e308;
    }
    progresse.progress=currentTime/totltime;
    if (currentTime > 1 && currentTime > totltime - 0.5) {
        if (musicTimer) {
            [musicTimer invalidate];
            musicTimer=nil;
        }
    }
}

//播放网络资源后，需调用此方法关闭播放器
-(void)closePlayer:(NSMutableArray *)datas {
//    if (isNetResource) {
//        [_audioPlayer stop];
//        btnAudio=nil;
//        _audioPlayer=nil;
//        if (musicTimer) {
//            [musicTimer invalidate];
//            musicTimer=nil;
//        }
//    }
}

#pragma mark - UIApplicationAction

+ (void)applicationWillResignActive:(UIApplication *)application {
    
    NSArray * backgroundModes = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"UIBackgroundModes"];
    if ([backgroundModes containsObject:@"audio"]) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
    }
    
}

+ (void)applicationDidEnterBackground:(UIApplication *)application {
    
    NSArray * backgroundModes = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"UIBackgroundModes"];
    
    if ([backgroundModes containsObject:@"audio"]) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
    }
    
}

-(void)setPlayMode:(NSMutableArray*)inArguments
{
    ACArgsUnpack(NSDictionary *dict) = inArguments;
    NSNumber *flagNum = numberArg(dict[@"playMode"]);

    if (flagNum.integerValue == 1){
        self.needCall = YES;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else{
        self.needCall = NO;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

@end

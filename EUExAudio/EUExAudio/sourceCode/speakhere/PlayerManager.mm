//

//  PlayerManager.h

//

//  Created by  正益无线 on 12-3-30.

//  Copyright 2012 正益无线. All rights reserved.

//


#import <Foundation/Foundation.h>

#import "PlayerManager.h"
#import "AQRecorder.h"


AQRecorder* _recorder;

@implementation PlayerManager


@synthesize playStatus=_playStatus;

@synthesize recordStatus=_recordStatus;

@synthesize currentFileName=_currentFileName;

@synthesize delegate = _delegate;
//singleton

static PlayerManager* g_instance = nil;


+ (id)getInstance {
	
	if (g_instance == nil) {
		
		g_instance=[[PlayerManager alloc]init];
		
	}
	
	return g_instance;
	
}


+ (void)releaseInstance {
	
    if (g_instance) {
		
        [g_instance release];
		
    }
	
}


-(id)init

{
	
	_playStatus= NO;
	[self initAudioSession:0];

	_player = [[AMRPlayer alloc]init];
	
 	_player.playNotify=self;
	_recorder = new AQRecorder();
	return self;
}


-(void)initAudioSession:(int)type

{
	UInt32 category = kAudioSessionCategory_PlayAndRecord;
	
	int error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
	
	if (error) printf("couldn't set audio category!");
	
	
	
	UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
	
	AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (audioRouteOverride),&audioRouteOverride);
	
	NSString* text=[NSString stringWithFormat:@"initAudioSession:%d",type];
	
	NSLog(@"text = %@",text);
	
}


- (void)dealloc {
	
	
	if (_player) {
		
		[_player StopQueue];
		
		[_player release];
		
	}

	if (_recorder) {
		
		_recorder->StopRecord();
		
		delete _recorder;
		
	}
	
    [super dealloc];
	
}


- (BOOL)startRecord:(NSString*)fileName

{
	
	NSLog(@"playmanager startRecord");
	if (_recorder) {
		
		[self initAudioSession:0];
		
		self.recordStatus=YES;
		
		_recorder->StartRecord((CFStringRef)fileName);
		
	}
	return 0;
	
}
- (BOOL)stopRecord

{

    NSLog(@"player manager stopRecord");
	
	if (_recorder && self.recordStatus==YES) {
		
		_recorder->StopRecord();
		self.recordStatus=NO;
	}
	return 0;
}
- (BOOL)playStop:(NSString*)fileName

{
	
	NSLog(@"playStop ptt");
	
	if (_player) {
		
		// NSString* amrPath=[NSString stringWithFormat:@"%@/%@",[testView DocPath],@"record.amr"];
		
		if (self.playStatus == NO) {
			if (fileName) {
				[_player startPlay:[fileName UTF8String]];
			}
			self.playStatus=YES;
		}
		else {
			[_player StopQueue];
			self.playStatus=NO;
		}

	}
	
	return 0;

}

-(void)pausePlay
{
	[_player PauseQueue];
	self.playStatus = NO;
}

-(void)stopRecordFinish

{
	self.recordStatus=NO;
	
}
-(void)playedFileFileProgress:(int)_progress{
	if (_delegate&&[_delegate respondsToSelector:@selector(changePlayProgressWithPro:)]) {
		[_delegate changePlayProgressWithPro:_progress];
	}
}
-(void)playedFinishNotify{
	[_player StopQueue];
	self.playStatus=NO;
	if (_delegate&&[_delegate respondsToSelector:@selector(playFinishedNotify)]) {
		[_delegate playFinishedNotify];
	}
}

@end


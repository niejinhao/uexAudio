//
//  Recorder.h
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-19.
//  Copyright 2011 正益无线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecorderController.h"
#import "EUExAudio.h"
#import "RecorderAmrController.h"
#import "RecorderMp3Controller.h"

@interface Recorder : NSObject <RecorderControllerDelegate,RecorderAmrControllerDelegate,RecorderMp3ControllerDelegate>{
	EUExAudio *euexObj;
//	UIPopoverController *popController;
	UINavigationController *nav;
	NSInteger soundType;
    NSString* saveNameStr;
}
@property(nonatomic,retain)UINavigationController * nav;
@property(nonatomic,assign)UIPopoverController * popController;
@property NSInteger soundType;
@property(nonatomic,retain)NSString * saveNameStr;

-(void)showRecorder;
-(id)initWithEuex:(EUExAudio *)euexObj;
@end

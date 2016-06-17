//
//  Recorder.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-19.
//  Copyright 2011 正益无线. All rights reserved.
//

#import "Recorder.h"
#import "EUtility.h"

@implementation Recorder
@synthesize popController,nav;
@synthesize soundType;
@synthesize saveNameStr;

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

-(id)initWithEuex:(EUExAudio *)euexObj_ {
	 euexObj = euexObj_;
	return self;
}

-(void)showRecorder {
	if (soundType == 1) {
		RecorderController * recController = [[RecorderController alloc] init];
		recController.euexAudio = euexObj;
		recController.delegate = self;
        if (saveNameStr && saveNameStr.length > 0) {
            recController.saveNameStr = self.saveNameStr;
        }
		nav = [[UINavigationController alloc] initWithRootViewController:recController];
        
		if(320 != SCREEN_WIDTH && [EUtility isIpad]){
			popController = [[UIPopoverController alloc] initWithContentViewController:nav];
			[popController setPopoverContentSize:CGSizeMake(320, 480)];
            [EUtility brwView:euexObj.meBrwView presentPopover:popController FromRect:CGRectMake(200, 30, 10, 10) permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
 		} else {
            [EUtility brwView:euexObj.meBrwView presentModalViewController:nav animated:YES];
		}
    }else if(soundType == 2){
        RecorderMp3Controller * recController = [[RecorderMp3Controller alloc] init];
        recController.euexAudio = euexObj;
        recController.delegate = self;
        if (saveNameStr && saveNameStr.length > 0) {
            recController.saveNameStr = self.saveNameStr;
            //NSLog(@"recController.saveNameStr------>>>>%@",recController.saveNameStr);
        }
        nav = [[UINavigationController alloc] initWithRootViewController:recController];
        
        if(320 != SCREEN_WIDTH && [EUtility isIpad]){
            popController = [[UIPopoverController alloc] initWithContentViewController:nav];
            [popController setPopoverContentSize:CGSizeMake(320, 480)];
            [EUtility brwView:euexObj.meBrwView presentPopover:popController FromRect:CGRectMake(200, 30, 10, 10) permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            [EUtility brwView:euexObj.meBrwView presentModalViewController:nav animated:YES];
        }
    }
    else {
        RecorderAmrController *amrController = [[RecorderAmrController alloc] init];
        amrController.euexAudio = euexObj;
        amrController.delegate = self;
        if (self.saveNameStr != nil && [self.saveNameStr length] > 0) {
            amrController.saveNameStr = self.saveNameStr;
        }
        nav = [[UINavigationController alloc] initWithRootViewController:amrController];
        
        if(320 != SCREEN_WIDTH && [EUtility isIpad]) {
            popController = [[UIPopoverController alloc] initWithContentViewController:nav];
            [popController setPopoverContentSize:CGSizeMake(320, 480)];
            [EUtility brwView:euexObj.meBrwView presentPopover:popController FromRect:CGRectMake(200, 30, 10, 10) permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            [EUtility brwView:euexObj.meBrwView presentModalViewController:nav animated:YES];
        }
    }
}

-(void)closeRecorder {
	if (popController) {
		[popController dismissPopoverAnimated:YES];
	}
}

//-(void)dealloc {
//	if (nav) {
//		[nav release];
//		nav = nil;
//	}
//    if (popController) {
//        [popController release];
//        popController=nil;
//    }
//    if (self.saveNameStr) {
//        self.saveNameStr = nil;
//    }
//	[super dealloc];
//}
@end

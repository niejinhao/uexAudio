//

//  AQRecorder.h

//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-19.
//  Copyright 2011 正益无线. All rights reserved.
//



#include <AudioToolbox/AudioToolbox.h>

#include <Foundation/Foundation.h>

#include <libkern/OSAtomic.h>


#include "CAStreamBasicDescription.h"

#include "CAXException.h"


#define kNumberRecordBuffers    3


class AQRecorder 

{
	
public:
	
	AQRecorder();
	
	~AQRecorder();
	
	
	
	UInt32                      GetNumberChannels() const   { return mRecordFormat.NumberChannels(); }
	
	CFStringRef                 GetFileName() const         { return mFileName; }
	
	AudioQueueRef               Queue() const               { return mQueue; }
	
	CAStreamBasicDescription    DataFormat() const          { return mRecordFormat; }
	
	
	
	void            StartRecord(CFStringRef inRecordFile);
	
	void            StopRecord();       
	
	Boolean         IsRunning() const           { return mIsRunning; }
	
	
	
	void EncodeBuffer(short* buf,int len);
	
	
	
	UInt64          startTime;
	
	CGFloat mFileDuration;
	
	
	
	FILE *_AmrFile;
	
	int* _destate;
	
	
	
private:
	
	CFStringRef                 mFileName;
	
	AudioQueueRef               mQueue;
	
	AudioQueueBufferRef         mBuffers[kNumberRecordBuffers];
	
	AudioFileID                 mRecordFile;
	
	SInt64                      mRecordPacket; // current packet number in record file
	
	CAStreamBasicDescription    mRecordFormat;
	
	Boolean                     mIsRunning;
	
	
	
	void            CopyEncoderCookieToFile();
	
	void            SetupAudioFormat(UInt32 inFormatID);
	
	int             ComputeRecordBufferSize(const AudioStreamBasicDescription *format, float seconds);
	
	
	
	static void MyInputBufferHandler(   void *                              inUserData,
									 
									 AudioQueueRef                       inAQ,
									 
									 AudioQueueBufferRef                 inBuffer,
									 
									 const AudioTimeStamp *              inStartTime,
									 
									 UInt32                              inNumPackets,
									 
									 const AudioStreamPacketDescription* inPacketDesc);
	
};
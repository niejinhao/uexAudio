//

//  AQRecorder.m

//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-19.
//  Copyright 2011 正益无线. All rights reserved.
//



#include "AQRecorder.h"


extern "C"

{
	
#include "interf_enc.h"
	
}


#define SAMPLES_PER_SECOND 8000.0f

const float kBufferDurationSeconds = 0.5;


// Determine the size, in bytes, of a buffer necessary to represent the supplied number

// of seconds of audio data.

int AQRecorder::ComputeRecordBufferSize(const AudioStreamBasicDescription *format, float seconds)

{
	
    int packets, frames, bytes = 0;
	
    try {
		
        frames = (int)ceil(seconds * format->mSampleRate);
		
        
		
        if (format->mBytesPerFrame > 0)
			
            bytes = frames * format->mBytesPerFrame;
		
        else {
			
            UInt32 maxPacketSize;
			
            if (format->mBytesPerPacket > 0)
				
                maxPacketSize = format->mBytesPerPacket;    // constant packet size
			
            else {
				
                UInt32 propertySize = sizeof(maxPacketSize);
				
                XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize,&propertySize), "couldn't get queue's maximum output packet size");
				
				
            }
			
            if (format->mFramesPerPacket > 0)
				
                packets = frames / format->mFramesPerPacket;
			
            else
				
                packets = frames;   // worst-case scenario: 1 frame in a packet
			
            if (packets == 0)       // sanity check
				
                packets = 1;
			
            bytes = packets * maxPacketSize;
			
        }
		
    } 
	
	catch (CAXException e) {
		
        char buf[256];
		
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		
        return 0;
		
    }   
	
    return bytes;
	
}


// ____________________________________________________________________________________

// AudioQueue callback function, called when an input buffers has been filled.

void AQRecorder::MyInputBufferHandler(  void *                              inUserData,
									  
									  AudioQueueRef                       inAQ,
									  
									  AudioQueueBufferRef                 inBuffer,
									  
									  const AudioTimeStamp *              inStartTime,
									  
									  UInt32                              inNumPackets,
									  
									  const AudioStreamPacketDescription* inPacketDesc)

{
	
    AQRecorder *aqr = (AQRecorder *)inUserData;
	
    try {
		
        if (inNumPackets > 0) {
			
			// // write packets to file
			
			//            XThrowIfError(AudioFileWritePackets(aqr->mRecordFile, FALSE, inBuffer->mAudioDataByteSize,
			
			// inPacketDesc, aqr->mRecordPacket, &inNumPackets, inBuffer->mAudioData),
			
			//   "AudioFileWritePackets failed");
			
			//            aqr->mRecordPacket += inNumPackets;
			
			
			
			for (int i =0; i < inBuffer->mAudioDataByteSize ;i+=160*2) {
				
				short * pPacket = (short *)(((unsigned char*)(inBuffer->mAudioData))+i);
				
				
				
				const short par = 2;
				
				for (int j=0; j<160; j++) {
					
					if (pPacket[j]<(0x7FFF/par)&&pPacket[j]>(-0x7FFF/par)) {
						
						if (pPacket[j] > 0x7FFF/2) {
							
							pPacket[j] = 0x7FFF-1;
							
						}else if (pPacket[j] < -0x7FFF/2) {
							
							pPacket[j] = -0x7FFF+1;
							
						}else{
							
							pPacket[j] = pPacket[j]*par;
							
						}
						
					}
					
				}
				
				
				
				aqr->EncodeBuffer(pPacket,320);
				
			}
			
			
			aqr->mRecordPacket += inNumPackets;
			
			//int duration   = (int)(aqr->mRecordPacket * (aqr->mRecordFormat).mFramesPerPacket) %  (int)((aqr->mRecordFormat).mSampleRate) >= 0.5 ? 1 : 0;
			
			aqr->mFileDuration = (aqr->mRecordPacket * (aqr->mRecordFormat).mFramesPerPacket) / (aqr->mRecordFormat).mSampleRate;// + duration;
			
			
			
        }
		
        
		
        // if we're not stopping, re-enqueue the buffe so that it gets filled again
		
        if (aqr->IsRunning())
			
            XThrowIfError(AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer failed");
		
    } catch (CAXException e) {
		
        char buf[256];
		
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		
    }
	
}


AQRecorder::AQRecorder()

{
	
    mIsRunning = false;
	
    mRecordPacket = 0;
	
	_destate = (int*) Encoder_Interface_init(0);
	
	mFileName=NULL;
	
}


AQRecorder::~AQRecorder()

{
	
    AudioQueueDispose(mQueue, TRUE);
	
    AudioFileClose(mRecordFile);
	
    if (mFileName) CFRelease(mFileName);
	
	
	
	Encoder_Interface_exit((void*)_destate);
	
	_destate = 0;
	
	
	
	if (_AmrFile)
		
	{
		
		fclose(_AmrFile);
		
	}
	
}


// ____________________________________________________________________________________

// Copy a queue's encoder's magic cookie to an audio file.

void AQRecorder::CopyEncoderCookieToFile()

{
	
    UInt32 propertySize;
	
    // get the magic cookie, if any, from the converter     
	
    OSStatus err = AudioQueueGetPropertySize(mQueue, kAudioQueueProperty_MagicCookie, &propertySize);
	
    
	
    // we can get a noErr result and also a propertySize == 0
	
    // -- if the file format does support magic cookies, but this file doesn't have one.
	
    if (err == noErr && propertySize > 0) {
		
        Byte *magicCookie = new Byte[propertySize];
		
        UInt32 magicCookieSize;
		
        XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_MagicCookie, magicCookie, &propertySize), "get audio converter's magic cookie");
		
        magicCookieSize = propertySize; // the converter lies and tell us the wrong size
		
        
		
        // now set the magic cookie on the output file
		
        UInt32 willEatTheCookie = false;
		
        // the converter wants to give us one; will the file take it?
		
        err = AudioFileGetPropertyInfo(mRecordFile, kAudioFilePropertyMagicCookieData, NULL, &willEatTheCookie);
		
        if (err == noErr && willEatTheCookie) {
			
            err = AudioFileSetProperty(mRecordFile, kAudioFilePropertyMagicCookieData, magicCookieSize, magicCookie);
			
            XThrowIfError(err, "set audio file's magic cookie");
			
        }
		
        delete[] magicCookie;
		
    }
	
}


void AQRecorder::SetupAudioFormat(UInt32 inFormatID)

{
	
	memset(&mRecordFormat, 0, sizeof(mRecordFormat));
	
	mRecordFormat.mFormatID = inFormatID;
	
	if (inFormatID == kAudioFormatLinearPCM)
		
	{
		
		// if we want pcm, default to signed 16-bit little-endian
		
		mRecordFormat.mSampleRate = SAMPLES_PER_SECOND; // amr 8khz
		
		mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		
		mRecordFormat.mBitsPerChannel = 16;
		
		mRecordFormat.mChannelsPerFrame = 1;
		
		mRecordFormat.mFramesPerPacket = 1;
		
		
		
		mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel/8) * mRecordFormat.mChannelsPerFrame;
		
		mRecordFormat.mBytesPerPacket =  mRecordFormat.mBytesPerFrame ;
		
	}
	
}


//void AQRecorder::SetupAudioFormat(UInt32 inFormatID)

//{

//    memset(&mRecordFormat, 0, sizeof(mRecordFormat));

//

//    UInt32 size = sizeof(mRecordFormat.mSampleRate);

//    XThrowIfError(AudioSessionGetProperty(  kAudioSessionProperty_CurrentHardwareSampleRate,

//   &size, 

//   &mRecordFormat.mSampleRate), "couldn't get hardware sample rate");

//

//    size = sizeof(mRecordFormat.mChannelsPerFrame);

//    XThrowIfError(AudioSessionGetProperty(  kAudioSessionProperty_CurrentHardwareInputNumberChannels, 

//   &size, 

//   &mRecordFormat.mChannelsPerFrame), "couldn't get input channel count");

//

//    mRecordFormat.mFormatID = inFormatID;

//    if (inFormatID == kAudioFormatLinearPCM)

//    {

//        // if we want pcm, default to signed 16-bit little-endian

//        mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;

//        mRecordFormat.mBitsPerChannel = 16;

//        mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel / 8) * mRecordFormat.mChannelsPerFrame;

//        mRecordFormat.mFramesPerPacket = 1;

//    }

//

//

//}


void AQRecorder::StartRecord(CFStringRef inRecordFile)

{
	
    int i, bufferByteSize;
	
	// UInt32 size;
	
	// CFURLRef url;
	
    
	
    try {       
		
        //mFileName = CFStringCreateCopy(kCFAllocatorDefault, inRecordFile);
		
		
		
        // specify the recording format
		
        SetupAudioFormat(kAudioFormatLinearPCM);
		
        
		
        // create the queue
		
        XThrowIfError(AudioQueueNewInput(
										 
										 &mRecordFormat,
										 
										 MyInputBufferHandler,
										 
										 this ,
										 
										 NULL , NULL ,
										 
										 0 , &mQueue), "AudioQueueNewInput failed");
		
		//--独立线程模式
		
		//XThrowIfError(AudioQueueNewInput(
		
		// &mRecordFormat,
		
		// MyInputBufferHandler,
		
		// self ,
		
		// CFRunLoopGetCurrent(), kCFRunLoopCommonModes ,
		
		// 0 , &mQueue), "AudioQueueNewInput failed");
		
		//---
		
        
		
        // get the record format back from the queue's audio converter --
		
        // the file may require a more specific stream description than was necessary to create the encoder.
		
        mRecordPacket = 0;
		
		
		
		// size = sizeof(mRecordFormat);
		
        //XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_StreamDescription,  
		
		// &mRecordFormat, &size), "couldn't get queue's format");
		
		//
		
		//        NSString *recordFile = [NSTemporaryDirectory() stringByAppendingPathComponent: (NSString*)inRecordFile];    
		
		//
		
		//        url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)recordFile, NULL);
		
		//        
		
		//        // create the audio file
		
		//        XThrowIfError(AudioFileCreateWithURL(url, kAudioFileCAFType, &mRecordFormat, kAudioFileFlags_EraseFile,
		
		// &mRecordFile), "AudioFileCreateWithURL failed");
		
		//        CFRelease(url);
		
		//        
		
		//        // copy the cookie first to give the file object as much info as we can about the data going in
		
		//        // not necessary for pcm, but required for some compressed audio
		
		//        CopyEncoderCookieToFile();
		
        
		
        // allocate and enqueue buffers
		
        bufferByteSize = ComputeRecordBufferSize(&mRecordFormat, kBufferDurationSeconds);   // enough bytes for half a second
		
        for (i = 0; i < kNumberRecordBuffers; ++i) {
			
            XThrowIfError(AudioQueueAllocateBuffer(mQueue, bufferByteSize, &mBuffers[i]),
						  
						  "AudioQueueAllocateBuffer failed");
			
            XThrowIfError(AudioQueueEnqueueBuffer(mQueue, mBuffers[i], 0, NULL),
						  
						  "AudioQueueEnqueueBuffer failed");
			
        }
		
        // start the queue
		
        mIsRunning = true;
		
		AudioQueueFlush(mQueue);
		
        XThrowIfError(AudioQueueStart(mQueue, NULL), "AudioQueueStart failed");
		
		
		
		if(mFileName){
			
			CFRelease(mFileName);
			
			mFileName = nil;
			
		}
		
		
		
		mFileName = CFStringCreateCopy(kCFAllocatorDefault, inRecordFile);
		
		mRecordPacket = 0;
		
		if (0!=mFileName) {
			
			_AmrFile = fopen((const char *)[(NSString *)mFileName UTF8String], "wb+");
			
			XThrowIfError(0 == _AmrFile, "Amr file create failed");
			
			fwrite("#!AMR\n", 1, strlen("#!AMR\n"), _AmrFile);
			
		}
		
		
		
    }
	
    catch (CAXException &e) {
		
        char buf[256];
		
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		
    }
	
    catch (...) {
		
        fprintf(stderr, "An unknown error occurred\n");
		
    }   
	
	
	
}


void AQRecorder::StopRecord()

{
	
    // end recording
	
    mIsRunning = false;
	
    XThrowIfError(AudioQueueStop(mQueue, true), "AudioQueueStop failed");   
	
    // a codec may update its cookie at the end of an encoding session, so reapply it to the file now
	
    CopyEncoderCookieToFile();
	
    if (mFileName)
		
    {
		
        CFRelease(mFileName);
		
        mFileName = NULL;
		
    }
	
	if (mQueue) {
		
		AudioQueueDispose(mQueue, true);
		
	}
	
    if (mRecordFile) {
		
		AudioFileClose(mRecordFile);
		
	}
	
	
	
	if (_AmrFile)
		
	{
		
		fclose(_AmrFile);
		
		_AmrFile=nil;
		
	}
	
}


void AQRecorder::EncodeBuffer(short *buf,int len)

{
	
	
	unsigned char serialbuf[320]= {0};
	
	memset(serialbuf, 0, sizeof(serialbuf));
	
	int FrameLen =0;
	
	FrameLen= Encoder_Interface_Encode(_destate,MR475,buf,serialbuf,0);
	
	// printf("amr Frame len = %d\n",FrameLen); 
	
	
	
	int ilen = 0;
	
	if (0!= _AmrFile) {
		
		ilen = fwrite((unsigned char *)serialbuf,1,FrameLen,_AmrFile);
		
	}
	
	
	
}


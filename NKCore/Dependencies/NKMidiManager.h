//
//  NKMidiManager.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/20/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//



#if NK_USE_MIDI

#import <Foundation/Foundation.h>
#import "MIKMIDI.h"

@class NKSceneNode;

@interface NKMidiManager : NSObject

@property (nonatomic, strong) MIKMIDIDeviceManager *midiDeviceManager;
@property (nonatomic, strong) NSMapTable *connectionTokensForSources;

@property (nonatomic, weak) NKSceneNode *delegate;
@property (nonatomic, strong, readonly) NSArray *availableDevices;
@property (nonatomic, readonly) NSArray *availableCommands;

@property (nonatomic, strong) NSArray *devices;
@property (nonatomic, strong) NSArray *sources;

+ (NKMidiManager *)sharedInstance;

@end

#endif
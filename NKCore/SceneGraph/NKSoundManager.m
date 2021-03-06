//
//  NKSoundManager.m
//  NKNikeField
//
//  Created by Leif Shackelford on 4/29/14.
//  Copyright (c) 2014 Chroma Developer. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "NodeKitten.h"

@implementation NKSoundManager

static NKSoundManager *sharedObject = nil;

-(instancetype)init {
    self = [super init];
    if (self) {
        _cachedSounds = [NSMutableDictionary dictionary];
    }
    
    return self;
}

+ (NKSoundManager *)sharedInstance
{
    static dispatch_once_t _singletonPredicate;
    
    dispatch_once(&_singletonPredicate, ^{
        sharedObject = [[super alloc] init];
    });
    
    return sharedObject;
}

+(void)loadMultipleSoundFiles:(NSArray*)names {
    for (NSString * name in names) {
        [NKSoundManager loadSoundFileNamed:name];
    }
}

+(void)loadSoundFileNamed:(NSString *)name {
    NKSoundManager *manager = [NKSoundManager sharedInstance];
    NKSoundNode* newSound = [NKSoundNode soundWithName:name];
    
    if (newSound) {
        [manager.cachedSounds setObject:newSound forKey:name];
    }
    else {
         NSLog(@"NKSoundManager failed to load sound %@", name);
    }
    //NSLog(@"added sound: %@", )
}

+(void)loadAndPlayMusicNamed:(NSString*)name {
    [NKSoundManager loadSoundFileNamed:name];
    [NKSoundManager playMusicNamed:name];
}

+(void)playSoundFileNamed:(NSString *)name isMusic:(bool)isMusic {
    
    NKSoundManager *manager = [NKSoundManager sharedInstance];
    NKSoundNode *soundPlayer = [manager.cachedSounds objectForKey:name];
    
    if (soundPlayer) {
        
        if (isMusic) {

            soundPlayer.autoRepeat = true;
            
            if (manager.currentPlayingMusic) {
                [manager.currentPlayingMusic runAction:[NKAction fadeOutSoundWithDuration:8.]];
                
                [soundPlayer runAction:[NKAction fadeInSoundWithDuration:2.] completion:^{
                    manager.currentPlayingMusic = soundPlayer;
                }];
            }
        
            else {
                manager.currentPlayingMusic = soundPlayer;
                [soundPlayer runAction:[NKAction fadeInSoundWithDuration:6.]];
            }
            
        }
        
        else {
            if (![soundPlayer play]) {
                   NSLog(@"NKSoundManager failed to play sound");
            }
        }
    
    }
    else {
        NSLog(@"NKSoundManager failed to play sound: %@ not loaded !", name);
    }

}

+(void)playSoundNamed:(NSString *)name {
    [NKSoundManager playSoundFileNamed:name isMusic:false];
}

+(void)playMusicNamed:(NSString *)name {
    [NKSoundManager playSoundFileNamed:name isMusic:true];
}

+(void)updateWithTimeSinceLast:(F1t)dt {
    NKSoundManager *manager = [NKSoundManager sharedInstance];
    
    for (NKSoundNode *s in manager.cachedSounds.allValues) {
        [s updateWithTimeSinceLast:dt];
    }
}

+(void)setVolume:(F1t)volume forSoundNamed:(NSString*)name {
    NKSoundManager *manager = [NKSoundManager sharedInstance];
    [[manager.cachedSounds objectForKey:name] setMaxVolume:volume];
}

@end

@implementation NKSoundNode

+(instancetype)soundWithName:(NSString *)name {
    NKSoundNode* sound = [[NKSoundNode alloc]initWithName:name];
    return sound;
}


-(instancetype)initWithName:(NSString*)name {
    
    self = [super init];
    
    if (self) {
        self.name = name;
        _maxVolume = 1.;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        if (path) {
            NSURL *pathURL = [NSURL fileURLWithPath : path];
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:nil];
            if (player) {
                [player prepareToPlay];
                player.delegate = (id <AVAudioPlayerDelegate>)self;
                NSLog(@"++NKSoundNode %@", name);
            }
            else {
                NSLog(@"NKSoundNode failed to load sound");
            }
        }
        else {
            NSLog(@"NKSoundNode bad file name, %@", name);
        }

    }
    
    return self;
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {

}

-(bool)play {
    if (player.isPlaying) {
        [player setCurrentTime:0];
        return 1;
    }
    else {
    if ([player play]) {
        //NSLog(@"--NKSoundNode playing: %@",self.name);
        return 1;
    }
    }
    return 0;
}

-(void)stop {
    [player stop];
}

-(F1t)duration {
    return player.duration;
}

-(bool)isPlaying {
    return player.isPlaying;
}

-(void)setMaxVolume:(F1t)volume {
    _maxVolume = volume;
    if (player.volume > _maxVolume) {
        [player setVolume:player.volume * _maxVolume];
    }
}

-(void)setVolume:(F1t)volume {
    [player setVolume:player.volume];
}

-(void)setAutoRepeat:(bool)autoRepeat {
    if (autoRepeat) {
        [player setNumberOfLoops:-1];
    }
    else {
        [player setNumberOfLoops:0];
    }
}
//-(void)updateWithTimeSinceLast:(F1t)dt {
//    if (player.isPlaying) {
//        [super updateWithTimeSinceLast:dt];
//    }
//}

@end

@implementation NKAction (NKSoundActions)

+(NKAction*)playSound {
    
    NKAction *newAction = [[NKAction alloc]initWithDuration:10.];
    
    newAction.actionBlock = (ActionBlock)^(NKAction *action, NKNode* node, F1t completion){
        
        if (action.frameCount == 0) {
            action.duration = [(NKSoundNode*)node duration];
            [(NKSoundNode*)node play];
            
        }
        
    };
    
    return newAction;
}

+(NKAction*)fadeInSoundWithDuration:(F1t)sec {
    NKAction *newAction = [[NKAction alloc]initWithDuration:sec];
    
    newAction.actionBlock = (ActionBlock)^(NKAction *action, NKNode* node, F1t completion){
        
        if (action.frameCount == 0) {
            if (![(NKSoundNode*)node isPlaying]) {
                [(NKSoundNode*)node play];
            }
            
        }
        
       // NSLog(@"fade sound to %1.2f", completion);
        
        [(NKSoundNode*)node setVolume:completion * [(NKSoundNode*)node maxVolume]];
        
    };
    
    return newAction;
}

+(NKAction*)fadeOutSoundWithDuration:(F1t)sec {
    NKAction *newAction = [[NKAction alloc]initWithDuration:sec];
    
    newAction.actionBlock = (ActionBlock)^(NKAction *action, NKNode* node, F1t completion){
        
        if (action.frameCount == 0) {
            
        }
        
        [(NKSoundNode*)node setVolume:(1. - completion) * [(NKSoundNode*)node maxVolume]];
        
        if (completion) {
               [(NKSoundNode*)node stop];
        }
        
    };
    
    return newAction;
}

@end
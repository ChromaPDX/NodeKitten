//
//  NKBulletWorld.h
//  EMA Stage
//
//  Created by Leif Shackelford on 6/2/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKpch.h"

@class NKNode;
@class NKBulletShape;

typedef NS_OPTIONS(uint32_t, NKCollisionFilter){

        NKCollisionFilterNone = 0,
        NKCollisionFilterDefault = 1 << 0,
        NKCollisionFilterStatic = 1 << 1,
        NKCollisionFilterKinematic = 1 << 2,
        NKCollisionFilterDebris = 1 << 3,
        NKCollisionFilterSensorTrigger = 1 << 4,
        NKCollisionFilterCharacter = 1 << 5,
        NKCollisionFilterWalls = 1 << 6,
        NKCollisionFilterAllFilter = UINT32_MAX //all bits sets: DefaultFilter | StaticFilter | KinematicFilter | DebrisFilter | SensorTrigger
};

typedef NS_ENUM(GLint, NKBulletShapes)
{
    NKBulletShapeNone,
    NKBulletShapeBox,
    NKBulletShapeSphere,
    NKBulletShapeCylinder,
    NKBulletShapeCone,
    NKBulletNumShapes
} NS_ENUM_AVAILABLE(10_8, 5_0);

@interface NKBulletWorld : NSObject

@property (nonatomic, strong) NSMutableSet *btShapeCache;
@property (nonatomic, strong) NSMutableSet *nodes;

+ (NKBulletWorld *)sharedInstance;
+ (NKBulletShape *)cachedShapeWithShape:(NKBulletShapes)shape size:(V3t)size;
+ (void)setGravity:(V3t)gravity;

-(void)updateWithTimeSinceLast:(F1t)dt;

-(void)addNode:(NKNode*)node;
-(void)removeNode:(NKNode*)node;

@end

@interface NKBulletShape : NSObject

@property (nonatomic) NKBulletShapes shape;
@property (nonatomic) V3t size;

-(BOOL)isEqual:(id)object;
-(void*)btShape;
-(NSString*)shapeString;

@end

@interface NKBulletBody : NSObject
{
    NKCollisionFilter _collisionGroup;
    NKCollisionFilter _collisionMask;
}
@property (nonatomic, strong) NKBulletShape *shape;

-(void*)btBody;

-(instancetype)initWithType:(NKBulletShapes)shape Size:(V3t)size transform:(M16t)m16 mass:(F1t)mass;

// PROPERTIES
-(void)setMass:(F1t)mass;
-(void)setDamping:(F1t)linear angular:(F1t)angular;
-(void)setFriction:(F1t)friction;
-(void)setRestitution:(F1t)restitution;
-(void)setSleepingThresholds:(F1t)linear angular:(F1t)angular;
// MOTION STATE
-(void)setTransform:(M16t)transform;
-(void)getTransform:(M16t *)m;
-(V3t)getLinearVelocity;
-(V3t)getAngularVelocity;
-(void)setLinearVelocity:(V3t)velocity;
-(void)setAngularVelocity:(V3t)velocity;
// FORCES
-(void)applyTorque:(V3t)torque;
-(void)applyTorqueImpulse:(V3t)torque;
-(void)applyCentralForce:(V3t)force;
-(void)applyCentralImpulse:(V3t)force;
-(void)applyDamping:(F1t)timeStep;
// COLLISION SYSTEM
-(void)setCollisionGroup:(NKCollisionFilter)category;
-(void)setCollisionMask:(NKCollisionFilter)category;
-(NKCollisionFilter)collisionGroup;
-(NKCollisionFilter)collisionMask;

-(void)forceAwake;
-(void)forceSleep;

@end

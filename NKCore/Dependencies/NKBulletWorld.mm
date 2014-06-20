//
//  NKBulletWorld.m
//  EMA Stage
//
//  Created by Leif Shackelford on 6/2/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#import "NKBulletWorld.h"
#import "btBulletDynamicsCommon.h"
#import "NKNode.h"

static NKBulletWorld *sharedObject = nil;

static inline btVector3 btv(V3t v){
    return btVector3(v.x,v.y,v.z);
}

@interface NKBulletWorld()
{
    btDefaultCollisionConfiguration* collisionConfiguration;
    btCollisionDispatcher* dispatcher;
    btBroadphaseInterface* overlappingPairCache;
    btSequentialImpulseConstraintSolver* solver;
    btDiscreteDynamicsWorld* dynamicsWorld;
}
@end

@implementation NKBulletWorld

+ (NKBulletWorld *)sharedInstance
{
    static dispatch_once_t _singletonPredicate;
    
    dispatch_once(&_singletonPredicate, ^{
        sharedObject = [[super alloc] init];
    });
    
    return sharedObject;
}


-(instancetype)init {
    self = [super init];
    if (self) {
        ///-----initialization_start-----
        
        ///collision configuration contains default setup for memory, collision setup. Advanced users can create their own configuration.
        collisionConfiguration = new btDefaultCollisionConfiguration();
        
        ///use the default collision dispatcher. For parallel processing you can use a diffent dispatcher (see Extras/BulletMultiThreaded)
        dispatcher = new	btCollisionDispatcher(collisionConfiguration);
        
        ///btDbvtBroadphase is a good general purpose broadphase. You can also try out btAxis3Sweep.
        overlappingPairCache = new btDbvtBroadphase();
        
        ///the default constraint solver. For parallel processing you can use a different solver (see Extras/BulletMultiThreaded)
        solver = new btSequentialImpulseConstraintSolver;
        
        
        dynamicsWorld = new btDiscreteDynamicsWorld(dispatcher,overlappingPairCache,solver,collisionConfiguration);
        
        dynamicsWorld->setGravity(btVector3(0,-10,0));
        
        btContactSolverInfo& info = dynamicsWorld->getSolverInfo();
        info.m_numIterations = 20; //more iterations will allow the solver to converge to the actual solution better
    
        
        _btShapeCache = [[NSMutableSet alloc]init];
        
        NSLog(@"bullet dynamics loaded");
    }
    
    return self;
}

-(void)setGravity:(V3t)gravity {
    dynamicsWorld->setGravity(btVector3(gravity.x, gravity.y,gravity.z));
}

+(void)setGravity:(V3t)gravity {
    [[NKBulletWorld sharedInstance]setGravity:gravity];
}

+(void)reset {
    [[NKBulletWorld sharedInstance] reset];
}

-(void)reset {
    NSArray *temp = [_nodes copy];
    for (NKNode* n in temp) {
        [self removeNode:n];
    }
}

+(NKBulletShape *)cachedShapeWithShape:(NKBulletShapes)shape size:(V3t)size {
    for (NKBulletShape* s in [[NKBulletWorld sharedInstance] btShapeCache]) {
        if (s.shape == shape) {
            if (V3Equal(s.size, size)) {
                NKLogV3([NSString stringWithFormat:@"found cached: %@ : size :", s.shapeString], size);
                return s;
            }
        }
    }
    return nil;
}

+(void*)dynamicsWorld {
    return [[NKBulletWorld sharedInstance]dynamicsWorld];
}

-(void*)dynamicsWorld {
    return dynamicsWorld;
}

-(void)addSpringConstraintToBodyA:(btRigidBody*)bodyA atPosition:(V3t)bodyAPos bodyB:(btRigidBody*)bodyB atPosition:(V3t)bodyBPos length:(F1t)length{
    
    btTransform frameInA, frameInB;
    
    frameInA = btTransform::getIdentity();
    frameInA.setOrigin(btv(bodyAPos));
    frameInB = btTransform::getIdentity();
    frameInB.setOrigin(btv(bodyBPos));
    
    btGeneric6DofSpringConstraint* pGen6DOFSpring = new btGeneric6DofSpringConstraint(*bodyA, *bodyB, frameInA, frameInB, true);
    
    
    pGen6DOFSpring->setLinearUpperLimit(btVector3(0., length, 0.));
    pGen6DOFSpring->setLinearLowerLimit(btVector3(0., -length, 0.));
    
    pGen6DOFSpring->setAngularLowerLimit(btVector3(0.f, 0.f, 0));
    pGen6DOFSpring->setAngularUpperLimit(btVector3(0.f, 0.f, 0));
    
    NSLog(@"add spring : ");
    NKLogV3(@"apos", bodyAPos);
    NKLogV3(@"bpos", bodyBPos);
    
    dynamicsWorld->addConstraint(pGen6DOFSpring, true);
    //pGen6DOFSpring->setDbgDrawSize(btScalar(5.f));
    
    pGen6DOFSpring->enableSpring(0, true);
    pGen6DOFSpring->setStiffness(0, 39.478f);
    pGen6DOFSpring->setDamping(0, 0.1f);
    
    pGen6DOFSpring->enableSpring(5, true);
    pGen6DOFSpring->setStiffness(5, 39.478f);
    pGen6DOFSpring->setDamping(0, 0.1f);
    
    pGen6DOFSpring->setEquilibriumPoint();
    
}

//var constraint = new Physijs.HingeConstraint(
//                                             physijs_mesh_a, // First object to be constrained
//                                             physijs_mesh_b, // OPTIONAL second object - if omitted then physijs_mesh_1 will be constrained to the scene
//                                             new THREE.Vector3( 0, 10, 0 ), // point in the scene to apply the constraint
//                                             new THREE.Vector3( 1, 0, 0 ) // Axis along which the hinge lies - in this case it is the X axis
//                                             );
//scene.addConstraint( constraint );
//constraint.setLimits(
//                     low, // minimum angle of motion, in radians
//                     high, // maximum angle of motion, in radians
//                     bias_factor, // applied as a factor to constraint error
//                     relaxation_factor, // controls bounce at limit (0.0 == no bounce)
//);

-(void)addWheelConstraintToBodyA:(btRigidBody*)bodyA atPosition:(V3t)bodyAPos bodyB:(btRigidBody*)bodyB atPosition:(V3t)bodyBPos limits:(V6t)limits{
    
    btTransform frameInA, frameInB;
    
    frameInA = btTransform::getIdentity();
    frameInA.setOrigin(btv(bodyAPos));
    frameInB = btTransform::getIdentity();
    frameInB.setOrigin(btv(bodyBPos));
    
//    btHin
//    btHingeConstraint(*bodyA, *bodyB, frameInA, btv(limits.min));
//    //btHinge2Constraint(*bodyA, *bodyB, btv(bodyAPos), <#btVector3 &axis1#>, <#btVector3 &axis2#>)
    btGeneric6DofConstraint* wheelJoint = new btGeneric6DofConstraint(*bodyA, *bodyB, frameInA, frameInB, true);

    wheelJoint->setAngularLowerLimit(btv(limits.min));
    wheelJoint->setAngularUpperLimit(btv(limits.max));
    

   // wheelJoint->setOverrideNumSolverIterations(20);
    
//    wheelJoint->getTranslationalLimitMotor()->m_enableMotor[0] = true;
//    wheelJoint->getTranslationalLimitMotor()->m_targetVelocity[0] = 5.0f;
//    wheelJoint->getTranslationalLimitMotor()->m_maxMotorForce[0] = 0.1f;
//    
    //wheelJoint->enableAngularMotor(true, 0, 1);
    
    NSLog(@"add spring : ");
    NKLogV3(@"apos", bodyAPos);
    NKLogV3(@"bpos", bodyBPos);
    
    dynamicsWorld->addConstraint(wheelJoint, true);
    
}

-(void)updateWithTimeSinceLast:(F1t)dt {
    int numSimSteps = dynamicsWorld->stepSimulation(1/30.f, 10);
//    //during idle mode, just run 1 simulation step maximum
//    int maxSimSubSteps = 2;
//    //int numSimSteps = dynamicsWorld->stepSimulation(dt,10);
//    
//    //optional but useful: debug drawing
//    //m_dynamicsWorld->debugDrawWorld();
////
////            if (numSimSteps > maxSimSubSteps)
////            {
////                //detect dropping frames
////                NSLog(@"Dropped (%i) simulation steps out of %i\n",numSimSteps - maxSimSubSteps,numSimSteps);
////            } else
////            {
////               NSLog(@"FT: %f vs: %f Simulated (%i) steps\n",dt ,1 / 60.,numSimSteps);
////            }
//    
   // NSLog(@"FT: %f vs: %f Simulated (%i) steps\n",dt ,1 / 60.,numSimSteps);
}

-(void)addNode:(NKNode*)node {
    
    if (!_nodes) {
        _nodes = [[NSMutableSet alloc]init];
    }
    
    if (![_nodes containsObject:node]) {
        [_nodes addObject:node];
        dynamicsWorld->addRigidBody((btRigidBody*)node.body.btBody,node.body.collisionGroup,node.body.collisionMask);
    }
    
}

-(void)removeNode:(NKNode*)node {

    if ([_nodes containsObject:node]) {
        int numConstraints = ((btRigidBody*)node.body.btBody)->getNumConstraintRefs();

        for (int i = 0; i < numConstraints; i++){
            btTypedConstraint *ref = ((btRigidBody*)node.body.btBody)->getConstraintRef(i);
            dynamicsWorld->removeConstraint(ref);
        }
        
        dynamicsWorld->removeRigidBody((btRigidBody*)node.body.btBody);
        [_nodes removeObject:node];
    }
    
}


-(void)dealloc {
    //delete dynamics world
	delete dynamicsWorld;
    
	//delete solver
	delete solver;
    
	//delete broadphase
	delete overlappingPairCache;
    
	//delete dispatcher
	delete dispatcher;
    
	delete collisionConfiguration;
}

@end

@interface NKBulletShape(){
    btCollisionShape* collisionShape;
}

@end

@implementation NKBulletShape

-(instancetype)initWithType:(NKBulletShapes)shape size:(V3t)size {

    NKBulletShape *cached = [NKBulletWorld cachedShapeWithShape:shape size:size];
    
    if (cached) {
        return cached;
    }
                                     
    if (self = [super init]){
        
        _shape = shape;
        _size = size;
        
        switch (shape) {
            case NKBulletShapeBox:
                collisionShape = new btBoxShape(btv(size));
                break;
                
            case NKBulletShapeSphere:
                collisionShape = new btSphereShape(size.x);
                break;
                
            case NKBulletShapeXCylinder:
                collisionShape = new btCylinderShapeX(btv(size));
                break;
                
            case NKBulletShapeYCylinder:
                collisionShape = new btCylinderShape(btv(size));
                break;
                
            case NKBulletShapeZCylinder:
                collisionShape = new btCylinderShapeZ(btv(size));
                break;
                

                
            case NKBulletShapeCone:
                collisionShape = new btConeShape(size.x,size.y);
                break;
                
            default:
                break;
        }
        
        [[[NKBulletWorld sharedInstance] btShapeCache] addObject:self];
    }
    return self;
}

-(NSString*)shapeString {
    switch (_shape) {
        case NKBulletShapeBox:
            return @"box";
        case NKBulletShapeSphere:
            return @"sphere";
        case NKBulletShapeXCylinder:
        case NKBulletShapeYCylinder:
        case NKBulletShapeZCylinder:
            return @"cylinder";
        case NKBulletShapeCone:
            return @"cone";
        default:
            return @"shapeError";
    }
}

-(NSUInteger)hash {
    return self.shape;
}

-(BOOL)isEqual:(id)object {
    if (self.shape != ((NKBulletShape*)object).shape) {
        return false;
    }
    if (V3Equal(self.size, ((NKBulletShape*)object).size)) {
        return false;
    }
    return true;
}

-(void)calculateLocalInertia:(F1t)mass inertia:(V3t)localInertia {
    btVector3 li(localInertia.x,localInertia.y,localInertia.z);
    collisionShape->calculateLocalInertia(mass,li);
}



-(void*)btShape {
    return collisionShape;
}

-(void)dealloc {
    delete collisionShape;
}

@end

@interface NKBulletBody(){
    btRigidBody* body;
}

@end

@implementation NKBulletBody

-(instancetype)initWithType:(NKBulletShapes)shape Size:(V3t)size transform:(M16t)m16 mass:(F1t)mass {
    if (self = [super init]){
        
        _shape = [[NKBulletShape alloc]initWithType:shape size:size];
        
        btTransform transform;
        transform.setIdentity();
        //transform.setOrigin(btVector3(position.x,position.y,position.z));
        transform.setFromOpenGLMatrix(m16.m);
        //rigidbody is dynamic if and only if mass is non zero, otherwise static
        bool isDynamic = (mass != 0.f);
        
        btVector3 localInertia(0,0,0);
        
        if (isDynamic)
            ((btCollisionShape*)_shape.btShape)->calculateLocalInertia(mass,localInertia);
        
        //using motionstate is recommended, it provides interpolation capabilities, and only synchronizes 'active' objects
        btDefaultMotionState* myMotionState = new btDefaultMotionState(transform);
        btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,myMotionState,(btCollisionShape*)_shape.btShape,localInertia);
        
        body = new btRigidBody(rbInfo);
        
        //add the body to the dynamics world
        
        //[[NKBulletWorld sharedInstance] addBody:self];
        
    }

    return self;
}

-(void*)btBody {
    return body;
}

// PROPERTIES

-(void)getTransform:(M16t *)m {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(m->m);
}

-(void)setTransform:(M16t)transform {
    btTransform tr;
    tr.setFromOpenGLMatrix(transform.m);
//    body->getWorldTransform().setIdentity();
//    body->getWorldTransform().setOrigin(btv(V3GetM16Translation(transform)));
    
   // btTransform tr;
   // body->getMotionState()->getWorldTransform(tr);
   // tr.setOrigin(btv(V3GetM16Translation(transform)));
    
    body->getMotionState()->setWorldTransform(tr);
    body->setWorldTransform(tr);
    
}

-(V3t)rayTest:(P2t)screenLocation {
    
//    V3t start = 
//    btCollisionWorld::ClosestRayResultCallback RayCallback(Start, End);
//    
//    // Perform raycast
//    world->rayTest(Start, End, RayCallback);
//    
//    if(RayCallback.hasHit()) {
//        End = RayCallback.m_hitPointWorld;
//        Normal = RayCallback.m_hitNormalWorld;
//        
//        // Do some clever stuff here
//    }
    return V3MakeF(0);
}

#pragma mark - Properties

-(void)setMass:(F1t)mass inertia:(V3t)inertia {
    body->setMassProps(mass, btv(inertia));
}

-(void)setSleepingThresholds:(F1t)linear angular:(F1t)angular {
    body->setSleepingThresholds(linear, angular);
}

-(void)setDamping:(F1t)linear angular:(F1t)angular {
    body->setDamping(linear, angular);
}

-(void)setFriction:(F1t)friction {
    body->setFriction(friction);
}

-(void)setRestitution:(F1t)restitution {
    body->setRestitution(restitution);
}

// FORCE
#pragma mark - Force

-(void)applyTorque:(V3t)torque {
     [self forceAwake];
    body->applyTorque(btv(torque));
}

-(void)applyTorqueImpulse:(V3t)torque {
    [self forceAwake];
    body->applyTorqueImpulse(btv(torque));
}

-(void)applyCentralForce:(V3t)force {
    body->applyCentralForce(btv(force));
}

-(void)applyCentralImpulse:(V3t)force {
    [self forceAwake];
    body->applyCentralForce(btv(force));
}

-(void)setLinearVelocity:(V3t)velocity {
    body->setLinearVelocity(btv(velocity));
}

-(void)setAngularVelocity:(V3t)velocity {
    body->setAngularVelocity(btv(velocity));
}

-(V3t)getLinearVelocity {
    btVector3 v = body->getLinearVelocity();
    return V3Make(v.x(), v.y(), v.z());
}

-(V3t)getAngularVelocity {
    btVector3 v = body->getAngularVelocity();
    return V3Make(v.x(), v.y(), v.z());
}

-(void)forceAwake {
    body->setActivationState(true);
}

#pragma mark - Constaints

-(void)addSpringConstraintAtPosition:(V3t)position toNode:(NKNode*)nodeB atPosition:(V3t)positionB length:(F1t)length{
    
    [[NKBulletWorld sharedInstance] addSpringConstraintToBodyA:(btRigidBody*)self.btBody atPosition:position bodyB:(btRigidBody*)nodeB.body.btBody atPosition:positionB length:length];
    
}

-(void)addWheelConstraintAtPosition:(V3t)position toNode:(NKNode*)nodeB atPosition:(V3t)positionB limits:(V6t)limits{
    [[NKBulletWorld sharedInstance] addWheelConstraintToBodyA:(btRigidBody*)self.btBody atPosition:position bodyB:(btRigidBody*)nodeB.body.btBody atPosition:positionB limits:limits];
}
// COLLISION
#pragma mark - Collision

-(bool)isDynamic {
    if (body->isKinematicObject() || body->isStaticObject()){
        return 0;
    }
    return 1;
}

-(NKCollisionFilter)collisionGroup {
    return _collisionGroup;
}

-(void)setCollisionGroup:(NKCollisionFilter)category {
    _collisionGroup = category;
}

-(NKCollisionFilter)collisionMask {
    return _collisionMask;
}

-(void)setCollisionMask:(NKCollisionFilter)category {
    _collisionMask = category;
}

-(void)forceSleep {
    body->setActivationState(false);
}

-(void)applyDamping:(F1t)timeStep {
    body->applyDamping(timeStep);
}

-(void)dealloc {
    delete body->getMotionState();
    delete body;
}

@end



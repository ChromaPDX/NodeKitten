//
//  NKPickerNode.m
//  NKNikeField
//
//  Created by Leif Shackelford on 4/16/14.
//  Copyright (c) 2014 Chroma Developer. All rights reserved.
//

#import "NodeKitten.h"

@implementation NKPickerNode

-(void)tableInit {
    [super tableInit];
    contentOffset = P2Make(.5,.5);
    
}
-(void) setChildFrame:(NKScrollNode *)child{
    
    if (self.fdirty) {
        
        if (self.scrollDirectionVertical){
            
            
            int tempSize = 0;
            for(int i = 0; i < [_children indexOfObject:child]; i++)
            {
                int temp = [(NKNode*)_children[i] size].height;
                tempSize += temp + self.padding.y;
            }
            
            V3t childSize;
            
            if ([child isKindOfClass:[NKScrollNode class]]) {
                childSize.height = self.size.height * child.autoSizePct.y;
                childSize.width = self.size.width-(self.padding.x);
                child.fdirty = true;
                
            }
            else {
                childSize = child.size;
            }
            
            float cOffset = tempSize + self.scrollPosition.y;
            float zPos = -(fabs(cOffset) * .75);
            float rotation = MAX(-45,MIN(cOffset / 8., 45));
            [child setPosition:V3Make(0,cOffset*.95,zPos)];
            [child setOrientationEuler:V3Make(rotation,0, 0)];
            
            [child setSize:childSize];
            
            
        }
        
        else {
            
            int tempSize = 0;
            for(int i = 0; i < [_children indexOfObject:child]; i++)
            {
                int temp = [(NKNode*)_children[i] size].width;
                tempSize += temp + self.padding.x;
            }
            
            V3t childSize;
            
            if ([child isKindOfClass:[NKScrollNode class]]) {
                childSize.width = self.size.width * child.autoSizePct.x;
                childSize.height = self.size.height-(self.padding.y);
                child.fdirty = true;
                
            }
            else {
                childSize = child.size;
            }
            
            float cOffset = tempSize + self.scrollPosition.x - self.size.width/2.;
            float zPos = -(fabs(cOffset) * .75);
            float rotation = MAX(-45,MIN(cOffset / 8., 45));
            [child setPosition:V3Make(cOffset*.95,0,zPos)];
            [child setOrientationEuler:V3Make(0, rotation, 0)];
            
            [child setSize:childSize];
            
        }
        
        child.hidden = [child shouldCull];
        
        
        
    }
    
}

-(void)endScroll {
    
    drag = 1.15;
    
    if (scrollVel > restitution) {
        
        if (self.scrollDirectionVertical) {
            [self setScrollPosition:P2Make(self.scrollPosition.x, self.scrollPosition.y + scrollVel)];
        }
        else {
            [self setScrollPosition:P2Make(self.scrollPosition.x + scrollVel, self.scrollPosition.y)];
        }
        
    }
    
    else {
        
        for (NKNode* n in _children) {
            
            if ([n containsPoint:P2Make(0,0)]) {
                
                self.selectedChild = n;
                
                int pos = [_children indexOfObject:n];
                
                if (self.scrollDirectionVertical) {
                    
                }
                
                else {
                    if (pos > 0 && n.position.x > n.size.width * .1 && scrollVel > 0) {
                        NSLog(@"going left, %f",scrollVel);
                        self.selectedChild = _children[pos-1];
                    }
                    else if (pos < (_children.count - 1 ) && n.position.x < -n.size.width * .1 && scrollVel < 0) {
                        self.selectedChild = _children[pos+1];
                        NSLog(@"going right, %f",scrollVel);
                    }
                }
                
            }
//            else {
//                if (self.scrollPosition.x < self.contentSize.width){
//                    self.selectedChild = _children[0];
//                }
//                else if (self.scrollPosition.x > 0){
//                    self.selectedChild = [_children lastObject];
//                }
//            }
        }
        
     
        [self shouldBeginRestitution];
        self.scrollPhase = ScrollPhaseRestitution;
        easeIn = 12.;
        easeOut = false;
        //NSLog(@"start restitution");
    }
    
}

-(P2t)outOfBounds {
    
    P2t realEdges = [super outOfBounds];
    
    if (P2Bool(realEdges)){
        if (self.scrollDirectionVertical) {

        }
        else {
            if (realEdges.x > 0) {
                self.selectedChild = _children[0];
            }
            else {
                self.selectedChild = [_children lastObject];
            }
        }

    }
    
    if (self.selectedChild) {
        
        if (self.scrollDirectionVertical) {
            return self.selectedChild.position.point;
        }
        else {
            return self.selectedChild.position.point;
        }
        
    }
    
    return P2Make(0,0);
    
}

-(void)handleEventWithType:(NKEvent*)event {
    if (NKEventPhaseEnd == event.phase) {
        if (self.scrollPhase == ScrollPhaseNil) {
            if (self.selectedChild) {
                [self.delegate cellWasSelected:self.selectedChild];
            }
        }
    }
    else {
        [super handleEvent:event];
    }
}

@end

//
//  MapPin.h
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapPin : NSObject<MKAnnotation>{
    NSString *title;
    NSString *subtitle;
    CLLocationCoordinate2D coordinate;
    
}

@property(nonatomic,copy)NSString *title;
@property(nonatomic,copy)NSString *subtitle;
@property(nonatomic,assign)CLLocationCoordinate2D coordinate;

@end

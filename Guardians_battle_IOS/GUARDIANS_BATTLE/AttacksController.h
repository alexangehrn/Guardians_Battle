//
//  AttacksController.h
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AttacksController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) NSString* hp; // donnée envoyée par la vue 1
@property (nonatomic, assign) NSInteger id;

@end

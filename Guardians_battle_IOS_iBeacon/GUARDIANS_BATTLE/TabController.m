//
//  TabController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "TabController.h"

@interface TabController ()

@end

@implementation TabController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if(_responseGame != 0)
    {
        UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil message:_responseGame delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        toast.backgroundColor=[UIColor redColor];
        [toast show];
        int duration = 2;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{                [toast dismissWithClickedButtonIndex:0 animated:YES];            });
        
        if([_responseGame isEqualToString:@"Defaite"])
        {}
        else
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *token = [defaults objectForKey:@"userToken"];
            
            //Insert monument owned
            NSString *url_string;
            url_string = [NSString stringWithFormat:@"%@%@", @"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/addMonument/" , _guardienId];
            
            NSURL *url = [NSURL URLWithString:url_string];
            
            NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"POST"];
            
            [request setValue:token forHTTPHeaderField:@"S-Token"];
            
            
            NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                              dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                              {
                                                  NSLog(@" %@", response);

                                              }];
            
            [dataTask resume];
            
            //Select specific monument attack
            NSString *url_string2;
            url_string2 = [NSString stringWithFormat:@"%@%@", @"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/monumentAttacks/" , _guardienId];
            
            NSURL *url2 = [NSURL URLWithString:url_string2];
            
            NSMutableURLRequest *request2 =[NSMutableURLRequest requestWithURL:url2];
            [request2 setHTTPMethod:@"GET"];
            
            [request2 setValue:token forHTTPHeaderField:@"S-Token"];
            
            
            NSURLSessionDataTask *dataTask2 = [[NSURLSession sharedSession]
                                              dataTaskWithRequest:request2 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                              {
                                                  NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                                  
                                                  if (!jsonFromData ){
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          NSLog(@"echecqsdlgjkbhsdgb");
                                                      });
                                                  }
                                                  else{
                                                    
                                                      
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          
                                                          NSMutableArray *attaqueArray = [NSMutableArray new];
                                                          for(id attaque in jsonFromData) {
                                                              
                                                              [attaqueArray addObject:[attaque objectForKey:@"attackid"]];
                                                          
                                                          }
                                                          
                                                          //Compter un array id
                                                          
                                                          NSInteger *count = [attaqueArray count];
                                                          
                                                          NSLog(@" %lu", count);
                                                      });
                                                      
                                                  }
                                                  
                                              }];
            
            [dataTask2 resume];
            
            
            

        }
    }
    
    
};

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

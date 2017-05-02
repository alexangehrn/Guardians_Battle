//
//  ViewController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "ViewController.h"
#import "RegisterController.h"
#import "TabController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passField;
@property (strong, nonatomic) NSArray *allData;

@end

@implementation ViewController
- (IBAction)connexionButton:(id)sender {
    
    NSString *login = [self.loginField text];
    NSString *password = [self.passField text];
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/login?"];

        
        NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        
        NSString *post =[[NSString alloc] initWithFormat:@"username=%@&password=%@",login,password];
        [request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];

    // NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (data == nil){
            NSLog(@"probleme");
        }
        
   NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSLog(@"%@",jsonFromData);

        if (!jsonFromData ){
            dispatch_async(dispatch_get_main_queue(), ^{

            NSString *title = @"Erreur";
            NSString *message = @"Votre identifiant ou mot de passe est incorrect!";
            NSString *actionRetry = @"Réessayer";
            
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *firstAction = [UIAlertAction actionWithTitle:actionRetry
                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                  }];
            
            [alert addAction:firstAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            });
        }
        else{

            dispatch_async(dispatch_get_main_queue(), ^{

            NSString *token=[jsonFromData valueForKey:@"token"];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            [defaults setObject:token forKey:@"userToken"];
            [defaults synchronize];
            
            TabController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"tab"];
            [self.navigationController pushViewController:rc animated:YES];
            });

        }
    }];
    
    [dataTask resume];

    
}

- (IBAction)registerButton:(id)sender {
    RegisterController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"register"];
    [self.navigationController pushViewController:rc animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@",@"zaza");

    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/renew?"];
    
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    [request setValue:token forHTTPHeaderField:@"S-Token"];
    

    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          if (data == nil){
                                              NSLog(@"probleme");
                                          }
                                          NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                          NSLog(@"%@",jsonFromData);


                                          if (!jsonFromData ){
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                              });
                                          }
                                          else{
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  NSString *token=[jsonFromData valueForKey:@"token"];
                                                  
                                                  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                  
                                                  [defaults setObject:token forKey:@"userToken"];
                                                  [defaults synchronize];
                                                  TabController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"tab"];
                                                  [self.navigationController pushViewController:rc animated:YES];
                                              });
                                              
                                          }
                                      }];
    
    [dataTask resume];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

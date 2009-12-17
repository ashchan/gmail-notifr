//
//  GNComposeHandler.m
//  gmail-notifr
//
//  Created by Eli Dourado on 12/16/09.
//  Copyright 2009 Eli Dourado. All rights reserved.
//

#import "GNComposeHandler.h"

@implementation GNComposeHandler


- (void)compose:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSClassFromString(@"GNAccount");
	id gnprefs = [[NSClassFromString(@"GNPreferences") alloc] init];
	NSScanner * scanner = [NSScanner scannerWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
	NSString * urlPrefix;
	
	[scanner scanUpToString:@":" intoString:&urlPrefix];
	[scanner scanString:@":" intoString:nil];
	if ([urlPrefix isEqualToString:@"mailto"])
	{
		NSString * base;
		NSString * address;
		NSString * temp;
		NSMutableString * params;
		NSString * url;
		NSString * username;
		NSString * domain;
		id accounts = [gnprefs accounts];
		if ([accounts count]>0){
			username = [[accounts objectAtIndex:0] username];
		}
		NSArray * terms = [username componentsSeparatedByString:@"@"];
		if ([terms count] > 1){
			domain = [terms objectAtIndex:1];
		} else {
			domain = @"gmail.com";
		}
				
		if (![domain isEqualToString:@"gmail.com"] && ![domain isEqualToString:@"googlemail.com"]) {
			base = [NSString stringWithFormat:@"https://mail.google.com/a/%@/?view=cm&fs=1&tf=1&to=", domain];
		}
		else {
			base = @"https://mail.google.com/mail/?view=cm&fs=1&tf=1&to=";
		}
		
		[scanner scanUpToString:@"?" intoString:&address];
				
		if ([scanner scanString:@"?" intoString:nil]) {
			temp = [[scanner string]substringFromIndex:[scanner scanLocation]];
			params = [NSMutableString stringWithString:temp];
			[params replaceOccurrencesOfString:@"subject=" withString:@"su=" options:1 range:NSMakeRange(0, [params length])];
			[params replaceOccurrencesOfString:@"CC=" withString:@"cc=" options:1 range:NSMakeRange(0, [params length])];
			[params replaceOccurrencesOfString:@"BCC=" withString:@"bcc=" options:1 range:NSMakeRange(0, [params length])];
			[params replaceOccurrencesOfString:@"Body=" withString:@"body=" options:1 range:NSMakeRange(0, [params length])];
			url = [[[base stringByAppendingString:address] stringByAppendingString:@"&"] stringByAppendingString:params];
		} else {
			url = [base stringByAppendingString:address];
		}
				
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
	}
	[gnprefs autorelease];
	[self autorelease];
}


@end

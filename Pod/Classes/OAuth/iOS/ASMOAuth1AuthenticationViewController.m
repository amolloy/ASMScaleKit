//
//  ASMOAuth1AuthenticationViewController.m
//  Pods
//
//  Created by Andrew Molloy on 7/15/14.
//
//

#import "ASMOAuth1AuthenticationViewController.h"

@interface ASMOAuth1AuthenticationViewController () <UIWebViewDelegate>
@property (nonatomic, strong) NSURL* authenticationURL;
@property (nonatomic, strong) NSURL* sentinelURL;
@property (nonatomic, copy) ASMOAuth1AuthenticationCompletionHandler completion;
@end

@implementation ASMOAuth1AuthenticationViewController

- (instancetype)initWithAuthorizationURL:(NSURL*)url
							 sentinelURL:(NSURL*)sentinelURL
							  completion:(ASMOAuth1AuthenticationCompletionHandler)completion
{
	self = [super init];
	if (self)
	{
		self.authenticationURL = url;
		self.sentinelURL = sentinelURL;
		self.completion = completion;
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	UIWebView* webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:webView];
	webView.delegate = self;

	[webView loadRequest:[NSURLRequest requestWithURL:self.authenticationURL]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAuthentication:)];
}


- (void)cancelAuthentication:(id)sender
{
	if (self.completion)
	{
		// TODO Error for user cancelled
		self.completion(nil, nil);
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	BOOL allow = YES;

	NSString* urlString = [request.URL absoluteString];
	if ([urlString hasPrefix:[self.sentinelURL absoluteString]])
	{
		if (self.completion)
		{
			self.completion(request.URL, nil);
		}
		allow = NO;
	}

	return allow;
}

@end

# Hello World

This example contains the full code of the “Hello World” app developed in the [“Getting Started”](https://github.com/thecatalinstan/Criollo/wiki/Getting-Started) guide.

While the server itself doesn’t do much, it does illustrate a few important steps in creating a standalone Criollo app.

## Creating a daemon-style app 
Daemon apps do not require a user session to be initiated in order to run. In other words, they can run in the background, independently of the window server. Criollo allows you to create such an app, by setting your bundle's principle class to `CRApplication` in `Info.plist` and simply calling the `CRApplicationMain` function in your `main.m` file, like so:

```plist
...
<key>NSPrincipalClass</key>
<string>CRApplication</string>
...
```

```objc
#import <Criollo/Criollo.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    return CRApplicationMain(argc, argv, [AppDelegate new]);
}
```

## Registering with `launchd`

`Launchd` is the system wide and per-user daemon/agent manager (`man 8 launchd`). You can use it to set your daemon style app at launch by creating a `launchd.plist` file (`man 5 launchd.plist`) and registering it.

```plist
...
<key>ProgramArguments</key>
<array>
	<string>/WebApplications/HelloWorld.app/Contents/MacOS/HelloWorld</string>
</array>
<key>RunAtLoad</key>
<true/>
...
```

## Adding middleware

Middleware are basically routing blocks that are associated with no particular paths. The example here adds a middleware that sets the 'Server' header and two cookies:

```objc
// Add a middleware that sets the 'Server' header and two cookies
[self.server add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

    // The the Server header to the main bundle identifier
    [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];

    // Set a session cookie if there isn't already one
    if ( !request.cookies[@"session"] ) {
        [response setCookie:@"session" value:[NSUUID UUID].UUIDString path:@"/" expires:nil domain:nil secure:NO];
    }

    // Set a long-lived cookie
    [response setCookie:@"token" value:[NSUUID UUID].UUIDString path:@"/" expires:[NSDate distantFuture] domain:nil secure:NO];

    // Call the next block
    completionHandler();
}];
```
 
## Exposing the contents of a directory at a path, with auto-generated fancy indexing

This is useful for scenarios where you want to expose resources located in a directory over HTTP, at a specified path. In this example we expose the contents of the home dir `"~"` at `"/pub"`.

```objc
[self.server mount:@"/pub" directoryAtPath:@"~" options:CRStaticDirectoryServingOptionsCacheFiles|CRStaticDirectoryServingOptionsAutoIndex];
```

The `CRStaticDirectoryServingOptionsAutoIndex` option generates an HTML index of the contents of the directory.

## Explicitly setting MIME content types for particular file extensions

Criollo will use the OS to determine the MIME types of the files it tries to serve, but this is not always reliable. You therefore can explicitly tell it which type a particular extension will have, thus helping it set the `Content-type` header correctly.

```objc
[[CRMimeTypeHelper sharedHelper] setMimeType:@"text/plain; charset=utf-8" forExtension:@"nfo"];
```


   


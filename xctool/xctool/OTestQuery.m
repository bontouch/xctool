//
// Copyright 2013 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "OTestQuery.h"

#import "iPhoneSimulatorRemoteClient.h"

#import "TaskUtil.h"
#import "XCToolUtil.h"

static NSArray *RunTaskAndReturnResult(NSTask *task, NSString **error)
{
  NSDictionary *output = LaunchTaskAndCaptureOutput(task);

  if ([task terminationStatus] != 0) {
    *error = output[@"stderr"];
    return nil;
  } else {
    NSString *jsonOutput = output[@"stdout"];

    NSError *parseError = nil;
    NSArray *list = [NSJSONSerialization JSONObjectWithData:[jsonOutput dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:0
                                                      error:&parseError];
    if (list) {
      return list;
    } else {
      *error = [NSString stringWithFormat:@"Error while parsing JSON: %@: %@",
                [parseError localizedFailureReason],
                jsonOutput];
      return nil;
    }
  }
}

NSArray *OTestQueryTestCasesInIOSBundle(NSString *bundlePath, NSString *sdk, NSString **error)
{
  NSCAssert([sdk hasPrefix:@"iphonesimulator"], @"Only iphonesimulator SDKs are supported.");

  NSString *version = [sdk stringByReplacingOccurrencesOfString:@"iphonesimulator" withString:@""];
  DTiPhoneSimulatorSystemRoot *systemRoot = [DTiPhoneSimulatorSystemRoot rootWithSDKVersion:version];
  NSCAssert(systemRoot != nil, @"Cannot get systemRoot");
  NSString *simulatorHome = [NSString stringWithFormat:@"%@/Library/Application Support/iPhone Simulator/%@", NSHomeDirectory(), version];

  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:[XCToolLibExecPath() stringByAppendingPathComponent:@"otest-query-ios"]];
  [task setEnvironment:@{@"CFFIXED_USER_HOME" : simulatorHome,
                         @"HOME" : simulatorHome,
                         @"IPHONE_SHARED_RESOURCES_DIRECTORY" : simulatorHome,
                         @"DYLD_ROOT_PATH" : [systemRoot sdkRootPath],
                         @"IPHONE_SIMULATOR_ROOT" : [systemRoot sdkRootPath],
                         @"IPHONE_SIMULATOR_VERSIONS" : @"iPhone Simulator (external launch) , iPhone OS 6.0 (unknown/10A403)",
                         @"NSUnbufferedIO" : @"YES"}];
  [task setArguments:@[bundlePath]];

  NSArray *result = RunTaskAndReturnResult(task, error);
  [task release];
  return result;
}

NSArray *OTestQueryTestCasesInOSXBundle(NSString *bundlePath, NSString *builtProductsDir, BOOL disableGC, NSString **error)
{
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:[XCToolLibExecPath() stringByAppendingPathComponent:@"otest-query-osx"]];
  [task setArguments:@[bundlePath]];
  [task setEnvironment:@{
   @"DYLD_FRAMEWORK_PATH" : builtProductsDir,
   @"DYLD_LIBRARY_PATH" : builtProductsDir,
   @"DYLD_FALLBACK_FRAMEWORK_PATH" : [XcodeDeveloperDirPath() stringByAppendingPathComponent:@"Library/Frameworks"],
   @"NSUnbufferedIO" : @"YES",
   @"OBJC_DISABLE_GC" : disableGC ? @"YES" : @"NO"
   }];

  NSArray *result = RunTaskAndReturnResult(task, error);
  [task release];
  return result;
}
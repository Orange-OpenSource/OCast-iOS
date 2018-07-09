//
// WifiSecurity.h
//
// Copyright 2018 Orange
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
//

#ifndef WifiSecurity_h
#define WifiSecurity_h

/**
 Wifi security

 - WifiSecurityWPS: WPS supported
 - WifiSecurityWPAPSK: WPA PSK
 - WifiSecurityWPAPEAP: WPA EAP
 - WifiSecurityWPA2PSK: WPA2 PSK
 - WifiSecurityWPA2EAP: WPA2 EAP
 - WifiSecurityWEP: WEP
 - WifiSecurityOpen: Open
 */
typedef NS_OPTIONS(NSInteger, WifiSecurity) {
    WifiSecurityWPS = 1 << 0,
    WifiSecurityWPAPSK = 1 << 1,
    WifiSecurityWPAPEAP = 1 << 2,
    WifiSecurityWPA2PSK = 1 << 3,
    WifiSecurityWPA2EAP = 1 << 4,
    WifiSecurityWEP = 1 << 5,
    WifiSecurityOpen = 1 << 6
};

#endif /* WifiSecurity_h */

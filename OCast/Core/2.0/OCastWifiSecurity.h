//
// OCastWifiSecurity.h
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

#ifndef OCastWifiSecurity_h
#define OCastWifiSecurity_h

/**
 Wifi security

 - OCastWifiSecurityWPS: WPS supported
 - OCastWifiSecurityWPAPSK: WPA PSK
 - OCastWifiSecurityWPAEAP: WPA EAP
 - OCastWifiSecurityWPA2PSK: WPA2 PSK
 - OCastWifiSecurityWPA2EAP: WPA2 EAP
 - OCastWifiSecurityWEP: WEP
 - OCastWifiSecurityOpen: Open
 */
typedef NS_OPTIONS(NSInteger, OCastWifiSecurity) {
    OCastWifiSecurityWPS = 1 << 0,
    OCastWifiSecurityWPAPSK = 1 << 1,
    OCastWifiSecurityWPAEAP = 1 << 2,
    OCastWifiSecurityWPA2PSK = 1 << 3,
    OCastWifiSecurityWPA2EAP = 1 << 4,
    OCastWifiSecurityWEP = 1 << 5,
    OCastWifiSecurityOpen = 1 << 6
};

#endif /* OCastWifiSecurity_h */

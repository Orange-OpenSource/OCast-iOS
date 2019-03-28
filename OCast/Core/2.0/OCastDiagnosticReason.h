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
//  OCastDiagnosticReason.h
//  OCast
//
//  Created by Christophe Azemar on 28/03/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

#ifndef OCastDiagnosticReason_h
#define OCastDiagnosticReason_h


typedef NS_OPTIONS(NSInteger, OCastDiagnosticReason) {
    OCastDiagnosticReasonPlayReady = 1 << 0,
    OCastDiagnosticReasonWideVine = 1 << 1,
    OCastDiagnosticReasonSerialNumber = 1 << 2,
    OCastDiagnosticReasonWifi = 1 << 3,
    OCastDiagnosticReasonBluetooth = 1 << 4
};

#endif /* OCastDiagnosticReason_h */

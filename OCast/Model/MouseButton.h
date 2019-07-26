//
// MouseButton.h
//
// Copyright 2019 Orange
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
// limitations under the License.
//

#ifndef MouseButton_h
#define MouseButton_h

/**
 The mouse button (https://www.w3.org/TR/uievents/#dom-mouseevent-buttons).

 - MouseButtonPrimary: The primary button of the device (the left button or the only button).
 - MouseButtonRight: The secondary button (the right button, if present).
 - MouseButtonMiddle: The auxiliary button (the middle button, often combined with a mouse wheel).
 */
typedef NS_OPTIONS(NSInteger, MouseButton) {
    MouseButtonPrimary = 1 << 0,
    MouseButtonRight = 1 << 1,
    MouseButtonMiddle = 1 << 2
};

#endif /* MouseButton_h */


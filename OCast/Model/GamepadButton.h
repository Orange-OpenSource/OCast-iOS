//
// GamepadButton.h
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

#ifndef GamepadButton_h
#define GamepadButton_h

/**
 The gamepad button (https://www.w3.org/TR/gamepad/#remapping).

 - GamepadButtonRightClusterBottom: The bottom button in right cluster.
 - GamepadButtonRightClusterRight: The right button in right cluster.
 - GamepadButtonRightClusterLeft: The left button in right cluster.
 - GamepadButtonRightClusterTop: The top button in right cluster.
 - GamepadButtonTopLeftFront: The top left front button.
 - GamepadButtonTopRightFront: The top right front button.
 - GamepadButtonBottomLeftFront: The bottom left front button.
 - GamepadButtonBottomRightFront: The bottom right front button.
 - GamepadButtonCenterClusterLeft: The left button in center cluster.
 - GamepadButtonCenterClusterRight: The right button in center cluster.
 - GamepadButtonLeftStickPressed: The left stick pressed button.
 - GamepadButtonRightStickPressed: The right stick pressed button.
 - GamepadButtonLeftClusterTop: The top button in left cluster.
 - GamepadButtonLeftClusterBottom: The bottom button in left cluster.
 - GamepadButtonLeftClusterLeft: The left button in left cluster.
 - GamepadButtonLeftClusterRight: The right button in left cluster.
 - GamepadButtonCenterClusterMiddle: The middle button in center cluster.
 */
typedef NS_OPTIONS(NSInteger, GamepadButton) {
    GamepadButtonRightClusterBottom = 1 << 0,
    GamepadButtonRightClusterRight = 1 << 1,
    GamepadButtonRightClusterLeft = 1 << 2,
    GamepadButtonRightClusterTop = 1 << 3,
    GamepadButtonTopLeftFront = 1 << 4,
    GamepadButtonTopRightFront = 1 << 5,
    GamepadButtonBottomLeftFront = 1 << 6,
    GamepadButtonBottomRightFront = 1 << 7,
    GamepadButtonCenterClusterLeft = 1 << 8,
    GamepadButtonCenterClusterRight = 1 << 9,
    GamepadButtonLeftStickPressed = 1 << 10,
    GamepadButtonRightStickPressed = 1 << 11,
    GamepadButtonLeftClusterTop = 1 << 12,
    GamepadButtonLeftClusterBottom = 1 << 13,
    GamepadButtonLeftClusterLeft = 1 << 14,
    GamepadButtonLeftClusterRight = 1 << 15,
    GamepadButtonCenterClusterMiddle = 1 << 16
};

#endif /* GamepadButton_h */


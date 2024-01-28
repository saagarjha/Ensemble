//
//  Keys.swift
//  Shared
//
//  Created by Saagar Jha on 12/12/23.
//

#if os(macOS)
	import Carbon
#endif
#if os(visionOS)
	import UIKit
#endif

enum Key: Int, Codable {
	case key_A
	case key_S
	case key_D
	case key_F
	case key_H
	case key_G
	case key_Z
	case key_X
	case key_C
	case key_V
	case key_B
	case key_Q
	case key_W
	case key_E
	case key_R
	case key_Y
	case key_T
	case key_1
	case key_2
	case key_3
	case key_4
	case key_6
	case key_5
	case key_Equal
	case key_9
	case key_7
	case key_Minus
	case key_8
	case key_0
	case key_RightBracket
	case key_O
	case key_U
	case key_LeftBracket
	case key_I
	case key_P
	case key_L
	case key_J
	case key_Quote
	case key_K
	case key_Semicolon
	case key_Backslash
	case key_Comma
	case key_Slash
	case key_N
	case key_M
	case key_Period
	case key_Grave
	case key_KeypadDecimal
	case key_KeypadMultiply
	case key_KeypadPlus
	case key_KeypadClear
	case key_KeypadDivide
	case key_KeypadEnter
	case key_KeypadMinus
	case key_KeypadEquals
	case key_Keypad0
	case key_Keypad1
	case key_Keypad2
	case key_Keypad3
	case key_Keypad4
	case key_Keypad5
	case key_Keypad6
	case key_Keypad7
	case key_Keypad8
	case key_Keypad9
	case key_Return
	case key_Tab
	case key_Space
	case key_Delete
	case key_Escape
	case key_Command
	case key_Shift
	case key_CapsLock
	case key_Option
	case key_Control
	case key_RightCommand
	case key_RightShift
	case key_RightOption
	case key_RightControl
	case key_Function
	case key_F17
	case key_VolumeUp
	case key_VolumeDown
	case key_Mute
	case key_F18
	case key_F19
	case key_F20
	case key_F5
	case key_F6
	case key_F7
	case key_F3
	case key_F8
	case key_F9
	case key_F11
	case key_F13
	case key_F16
	case key_F14
	case key_F10
	case key_F12
	case key_F15
	case key_Help
	case key_Home
	case key_PageUp
	case key_ForwardDelete
	case key_F4
	case key_End
	case key_F2
	case key_PageDown
	case key_F1
	case key_LeftArrow
	case key_RightArrow
	case key_DownArrow
	case key_UpArrow

	#if os(visionOS)
		init?(visionOSCode code: UIKeyboardHIDUsage) {
			switch code {
				case .keyboardA:
					self = .key_A
				case .keyboardB:
					self = .key_B
				case .keyboardC:
					self = .key_C
				case .keyboardD:
					self = .key_D
				case .keyboardE:
					self = .key_E
				case .keyboardF:
					self = .key_F
				case .keyboardG:
					self = .key_G
				case .keyboardH:
					self = .key_H
				case .keyboardI:
					self = .key_I
				case .keyboardJ:
					self = .key_J
				case .keyboardK:
					self = .key_K
				case .keyboardL:
					self = .key_L
				case .keyboardM:
					self = .key_M
				case .keyboardN:
					self = .key_N
				case .keyboardO:
					self = .key_O
				case .keyboardP:
					self = .key_P
				case .keyboardQ:
					self = .key_Q
				case .keyboardR:
					self = .key_R
				case .keyboardS:
					self = .key_S
				case .keyboardT:
					self = .key_T
				case .keyboardU:
					self = .key_U
				case .keyboardV:
					self = .key_V
				case .keyboardW:
					self = .key_W
				case .keyboardX:
					self = .key_X
				case .keyboardY:
					self = .key_Y
				case .keyboardZ:
					self = .key_Z
				case .keyboard1:
					self = .key_1
				case .keyboard2:
					self = .key_2
				case .keyboard3:
					self = .key_3
				case .keyboard4:
					self = .key_4
				case .keyboard5:
					self = .key_5
				case .keyboard6:
					self = .key_6
				case .keyboard7:
					self = .key_7
				case .keyboard8:
					self = .key_8
				case .keyboard9:
					self = .key_9
				case .keyboard0:
					self = .key_0
				case .keyboardReturnOrEnter:
					self = .key_Return
				case .keyboardEscape:
					self = .key_Escape
				case .keyboardDeleteOrBackspace:
					self = .key_Delete
				case .keyboardTab:
					self = .key_Tab
				case .keyboardSpacebar:
					self = .key_Space
				case .keyboardHyphen:
					self = .key_Minus
				case .keyboardEqualSign:
					self = .key_Equal
				case .keyboardOpenBracket:
					self = .key_LeftBracket
				case .keyboardCloseBracket:
					self = .key_RightBracket
				case .keyboardBackslash:
					self = .key_Backslash
				case .keyboardNonUSPound:
					return nil
				case .keyboardSemicolon:
					self = .key_Semicolon
				case .keyboardQuote:
					self = .key_Quote
				case .keyboardGraveAccentAndTilde:
					self = .key_Grave
				case .keyboardComma:
					self = .key_Comma
				case .keyboardPeriod:
					self = .key_Period
				case .keyboardSlash:
					self = .key_Slash
				case .keyboardCapsLock:
					self = .key_CapsLock
				case .keyboardF1:
					self = .key_F1
				case .keyboardF2:
					self = .key_F2
				case .keyboardF3:
					self = .key_F3
				case .keyboardF4:
					self = .key_F4
				case .keyboardF5:
					self = .key_F5
				case .keyboardF6:
					self = .key_F6
				case .keyboardF7:
					self = .key_F7
				case .keyboardF8:
					self = .key_F8
				case .keyboardF9:
					self = .key_F9
				case .keyboardF10:
					self = .key_F10
				case .keyboardF11:
					self = .key_F11
				case .keyboardF12:
					self = .key_F12
				case .keyboardPrintScreen:
					return nil
				case .keyboardScrollLock:
					return nil
				case .keyboardPause:
					return nil
				case .keyboardInsert:
					return nil
				case .keyboardHome:
					self = .key_Home
				case .keyboardPageUp:
					self = .key_PageUp
				case .keyboardDeleteForward:
					self = .key_ForwardDelete
				case .keyboardEnd:
					self = .key_End
				case .keyboardPageDown:
					self = .key_PageDown
				case .keyboardRightArrow:
					self = .key_RightArrow
				case .keyboardLeftArrow:
					self = .key_LeftArrow
				case .keyboardDownArrow:
					self = .key_DownArrow
				case .keyboardUpArrow:
					self = .key_UpArrow
				case .keypadNumLock:
					return nil
				case .keypadSlash:
					// FIXME
					self = .key_Slash
				case .keypadAsterisk:
					return nil
				case .keypadHyphen:
					self = .key_KeypadMinus
				case .keypadPlus:
					self = .key_KeypadPlus
				case .keypadEnter:
					self = .key_KeypadEnter
				case .keypad1:
					self = .key_Keypad1
				case .keypad2:
					self = .key_Keypad2
				case .keypad3:
					self = .key_Keypad3
				case .keypad4:
					self = .key_Keypad4
				case .keypad5:
					self = .key_Keypad5
				case .keypad6:
					self = .key_Keypad6
				case .keypad7:
					self = .key_Keypad7
				case .keypad8:
					self = .key_Keypad8
				case .keypad9:
					self = .key_Keypad9
				case .keypad0:
					self = .key_Keypad0
				case .keypadPeriod:
					// FIXME
					self = .key_Period
				case .keyboardLeftControl:
					self = .key_Control
				case .keyboardLeftShift:
					self = .key_Shift
				case .keyboardLeftAlt:
					self = .key_Option
				case .keyboardLeftGUI:
					self = .key_Command
				case .keyboardRightControl:
					self = .key_RightControl
				case .keyboardRightShift:
					self = .key_RightShift
				case .keyboardRightAlt:
					self = .key_RightOption
				case .keyboardRightGUI:
					self = .key_RightCommand
				default:
					return nil
			}
		}
	#endif

	#if os(macOS)
		var macOSCode: Int {
			switch self {
				case .key_A:
					return kVK_ANSI_A
				case .key_S:
					return kVK_ANSI_S
				case .key_D:
					return kVK_ANSI_D
				case .key_F:
					return kVK_ANSI_F
				case .key_H:
					return kVK_ANSI_H
				case .key_G:
					return kVK_ANSI_G
				case .key_Z:
					return kVK_ANSI_Z
				case .key_X:
					return kVK_ANSI_X
				case .key_C:
					return kVK_ANSI_C
				case .key_V:
					return kVK_ANSI_V
				case .key_B:
					return kVK_ANSI_B
				case .key_Q:
					return kVK_ANSI_Q
				case .key_W:
					return kVK_ANSI_W
				case .key_E:
					return kVK_ANSI_E
				case .key_R:
					return kVK_ANSI_R
				case .key_Y:
					return kVK_ANSI_Y
				case .key_T:
					return kVK_ANSI_T
				case .key_1:
					return kVK_ANSI_1
				case .key_2:
					return kVK_ANSI_2
				case .key_3:
					return kVK_ANSI_3
				case .key_4:
					return kVK_ANSI_4
				case .key_6:
					return kVK_ANSI_6
				case .key_5:
					return kVK_ANSI_5
				case .key_Equal:
					return kVK_ANSI_Equal
				case .key_9:
					return kVK_ANSI_9
				case .key_7:
					return kVK_ANSI_7
				case .key_Minus:
					return kVK_ANSI_Minus
				case .key_8:
					return kVK_ANSI_8
				case .key_0:
					return kVK_ANSI_0
				case .key_RightBracket:
					return kVK_ANSI_RightBracket
				case .key_O:
					return kVK_ANSI_O
				case .key_U:
					return kVK_ANSI_U
				case .key_LeftBracket:
					return kVK_ANSI_LeftBracket
				case .key_I:
					return kVK_ANSI_I
				case .key_P:
					return kVK_ANSI_P
				case .key_L:
					return kVK_ANSI_L
				case .key_J:
					return kVK_ANSI_J
				case .key_Quote:
					return kVK_ANSI_Quote
				case .key_K:
					return kVK_ANSI_K
				case .key_Semicolon:
					return kVK_ANSI_Semicolon
				case .key_Backslash:
					return kVK_ANSI_Backslash
				case .key_Comma:
					return kVK_ANSI_Comma
				case .key_Slash:
					return kVK_ANSI_Slash
				case .key_N:
					return kVK_ANSI_N
				case .key_M:
					return kVK_ANSI_M
				case .key_Period:
					return kVK_ANSI_Period
				case .key_Grave:
					return kVK_ANSI_Grave
				case .key_KeypadDecimal:
					return kVK_ANSI_KeypadDecimal
				case .key_KeypadMultiply:
					return kVK_ANSI_KeypadMultiply
				case .key_KeypadPlus:
					return kVK_ANSI_KeypadPlus
				case .key_KeypadClear:
					return kVK_ANSI_KeypadClear
				case .key_KeypadDivide:
					return kVK_ANSI_KeypadDivide
				case .key_KeypadEnter:
					return kVK_ANSI_KeypadEnter
				case .key_KeypadMinus:
					return kVK_ANSI_KeypadMinus
				case .key_KeypadEquals:
					return kVK_ANSI_KeypadEquals
				case .key_Keypad0:
					return kVK_ANSI_Keypad0
				case .key_Keypad1:
					return kVK_ANSI_Keypad1
				case .key_Keypad2:
					return kVK_ANSI_Keypad2
				case .key_Keypad3:
					return kVK_ANSI_Keypad3
				case .key_Keypad4:
					return kVK_ANSI_Keypad4
				case .key_Keypad5:
					return kVK_ANSI_Keypad5
				case .key_Keypad6:
					return kVK_ANSI_Keypad6
				case .key_Keypad7:
					return kVK_ANSI_Keypad7
				case .key_Keypad8:
					return kVK_ANSI_Keypad8
				case .key_Keypad9:
					return kVK_ANSI_Keypad9
				case .key_Return:
					return kVK_Return
				case .key_Tab:
					return kVK_Tab
				case .key_Space:
					return kVK_Space
				case .key_Delete:
					return kVK_Delete
				case .key_Escape:
					return kVK_Escape
				case .key_Command:
					return kVK_Command
				case .key_Shift:
					return kVK_Shift
				case .key_CapsLock:
					return kVK_CapsLock
				case .key_Option:
					return kVK_Option
				case .key_Control:
					return kVK_Control
				case .key_RightCommand:
					return kVK_RightCommand
				case .key_RightShift:
					return kVK_RightShift
				case .key_RightOption:
					return kVK_RightOption
				case .key_RightControl:
					return kVK_RightControl
				case .key_Function:
					return kVK_Function
				case .key_F17:
					return kVK_F17
				case .key_VolumeUp:
					return kVK_VolumeUp
				case .key_VolumeDown:
					return kVK_VolumeDown
				case .key_Mute:
					return kVK_Mute
				case .key_F18:
					return kVK_F18
				case .key_F19:
					return kVK_F19
				case .key_F20:
					return kVK_F20
				case .key_F5:
					return kVK_F5
				case .key_F6:
					return kVK_F6
				case .key_F7:
					return kVK_F7
				case .key_F3:
					return kVK_F3
				case .key_F8:
					return kVK_F8
				case .key_F9:
					return kVK_F9
				case .key_F11:
					return kVK_F11
				case .key_F13:
					return kVK_F13
				case .key_F16:
					return kVK_F16
				case .key_F14:
					return kVK_F14
				case .key_F10:
					return kVK_F10
				case .key_F12:
					return kVK_F12
				case .key_F15:
					return kVK_F15
				case .key_Help:
					return kVK_Help
				case .key_Home:
					return kVK_Home
				case .key_PageUp:
					return kVK_PageUp
				case .key_ForwardDelete:
					return kVK_ForwardDelete
				case .key_F4:
					return kVK_F4
				case .key_End:
					return kVK_End
				case .key_F2:
					return kVK_F2
				case .key_PageDown:
					return kVK_PageDown
				case .key_F1:
					return kVK_F1
				case .key_LeftArrow:
					return kVK_LeftArrow
				case .key_RightArrow:
					return kVK_RightArrow
				case .key_DownArrow:
					return kVK_DownArrow
				case .key_UpArrow:
					return kVK_UpArrow
			}
		}
	#endif
}

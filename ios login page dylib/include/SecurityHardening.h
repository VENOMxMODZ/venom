//
//  SecurityHardening.h
//  DefineAura - Military-Grade Anti-Tamper & Anti-Crack Protection Suite
//

#ifndef SecurityHardening_h
#define SecurityHardening_h

#import <Foundation/Foundation.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Initialize all anti-debugging, anti-Frida, and anti-tamper mechanisms.
/// Starts the background sentinel watchdog thread.
void SecurityHardeningInit(void);

/// Immediate synchronous security scan. Returns true if environment is clean, false if tampered.
bool SecurityCheckEnvironment(void);

/// Enforce security: if debugger, frida, or tampering is detected, immediately terminates execution.
void SecurityEnforceOrTerminate(void);

/// Compute cryptographic session canary upon valid server response.
void SecurityRegisterServerSession(NSString * _Nullable key, NSString * _Nullable token, NSString * _Nullable expiry, NSString * _Nullable deviceID);

/// Validate cryptographic session canary. Returns true ONLY if valid server auth occurred.
bool SecurityValidateServerSession(void);

/// Invalidate and wipe the session canary.
void SecurityInvalidateSession(void);

/// Silent hard crash for tamper response (anti-reversing trap)
void SecurityTriggerTrap(void);

#ifdef __cplusplus
}
#endif

#endif /* SecurityHardening_h */

//
//  Obfuscation.h
//  DefineAura - Anti-Tamper String Encryption Engine
//  Auto-generated: zero plaintext strings in binary
//

#ifndef Obfuscation_h
#define Obfuscation_h

#import <Foundation/Foundation.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

__attribute__((optnone)) static inline NSString * _Nonnull OBF_DECRYPT(const uint8_t * _Nonnull cipher, size_t len, uint8_t key) {
    volatile uint8_t vkey = key;
    char *buf = (char *)malloc(len + 1);
    if (!buf) return @"";
    for (size_t i = 0; i < len; i++) {
        volatile uint8_t b = cipher[i];
        uint8_t k = (uint8_t)((vkey + (i * 7)) & 0xFF);
        buf[i] = (char)(b ^ k);
    }
    buf[len] = '\0';
    NSString *res = [NSString stringWithUTF8String:buf];
    memset(buf, 0, len + 1);
    free(buf);
    return res ?: @"";
}

__attribute__((optnone)) static inline void OBF_DECRYPT_CSTR(const uint8_t * _Nonnull cipher, size_t len, uint8_t key, char * _Nonnull outBuf) {
    volatile uint8_t vkey = key;
    for (size_t i = 0; i < len; i++) {
        volatile uint8_t b = cipher[i];
        uint8_t k = (uint8_t)((vkey + (i * 7)) & 0xFF);
        outBuf[i] = (char)(b ^ k);
    }
    outBuf[len] = '\0';
}

// Encrypted: 'https://venompanel.shop/rootapi'
static const uint8_t STR_API_ENDPOINT_DATA[] = { 0x02, 0x05, 0x0C, 0x0F, 0xF5, 0xB7, 0xBB, 0xB4, 0xD4, 0xCC, 0xDE, 0xD8, 0xD3, 0xB5, 0xAD, 0xBD, 0xBF, 0x8D, 0xC6, 0x9C, 0x9E, 0x92, 0x74, 0x24, 0x60, 0x76, 0x4F, 0x53, 0x4F, 0x45, 0x55 };
static const size_t STR_API_ENDPOINT_LEN = 31;
static const uint8_t STR_API_ENDPOINT_KEY = 0x6A;
#define GET_STR_API_ENDPOINT() OBF_DECRYPT(STR_API_ENDPOINT_DATA, STR_API_ENDPOINT_LEN, STR_API_ENDPOINT_KEY)

// Encrypted: 'venompanel.shop'
static const uint8_t STR_API_HOST_DATA[] = { 0x10, 0x08, 0x1A, 0x14, 0xEF, 0xF9, 0xF1, 0xF9, 0xFB, 0xC9, 0x82, 0xC0, 0xD2, 0xAE, 0xB8 };
static const size_t STR_API_HOST_LEN = 15;
static const uint8_t STR_API_HOST_KEY = 0x66;
#define GET_STR_API_HOST() OBF_DECRYPT(STR_API_HOST_DATA, STR_API_HOST_LEN, STR_API_HOST_KEY)

// Encrypted: 'DefineAura'
static const uint8_t STR_GAME_NAME_DATA[] = { 0x23, 0x0B, 0x13, 0x15, 0xED, 0xEF, 0xD0, 0xED, 0xED, 0xC7 };
static const size_t STR_GAME_NAME_LEN = 10;
static const uint8_t STR_GAME_NAME_KEY = 0x67;
#define GET_STR_GAME_NAME() OBF_DECRYPT(STR_GAME_NAME_DATA, STR_GAME_NAME_LEN, STR_GAME_NAME_KEY)

// Encrypted: 'DefineAura/1.0 (iOS)'
static const uint8_t STR_USER_AGENT_DATA[] = { 0x2C, 0x0A, 0x10, 0x14, 0xEA, 0xEE, 0xD3, 0xEC, 0xD2, 0xC6, 0x81, 0x84, 0x92, 0xF3, 0xEA, 0xF9, 0xB1, 0x90, 0xB5, 0xC4 };
static const size_t STR_USER_AGENT_LEN = 20;
static const uint8_t STR_USER_AGENT_KEY = 0x68;
#define GET_STR_USER_AGENT() OBF_DECRYPT(STR_USER_AGENT_DATA, STR_USER_AGENT_LEN, STR_USER_AGENT_KEY)

// Encrypted: 'Content-Type'
static const uint8_t STR_CONTENT_TYPE_DATA[] = { 0x29, 0x1E, 0x16, 0x0B, 0xE3, 0xE3, 0xE0, 0xB6, 0xF6, 0xD0, 0xC0, 0xD2 };
static const size_t STR_CONTENT_TYPE_LEN = 12;
static const uint8_t STR_CONTENT_TYPE_KEY = 0x6A;
#define GET_STR_CONTENT_TYPE() OBF_DECRYPT(STR_CONTENT_TYPE_DATA, STR_CONTENT_TYPE_LEN, STR_CONTENT_TYPE_KEY)

// Encrypted: 'application/x-www-form-urlencoded'
static const uint8_t STR_URL_ENCODED_DATA[] = { 0x08, 0x00, 0x07, 0x12, 0xEC, 0xEF, 0xF2, 0xEE, 0xC8, 0xC7, 0xC1, 0x99, 0xC5, 0xE9, 0xBC, 0xA5, 0xAE, 0xCD, 0x81, 0x81, 0x87, 0x91, 0x2E, 0x7F, 0x63, 0x74, 0x7A, 0x48, 0x4E, 0x5B, 0x5F, 0x27, 0x2D };
static const size_t STR_URL_ENCODED_LEN = 33;
static const uint8_t STR_URL_ENCODED_KEY = 0x69;
#define GET_STR_URL_ENCODED() OBF_DECRYPT(STR_URL_ENCODED_DATA, STR_URL_ENCODED_LEN, STR_URL_ENCODED_KEY)

// Encrypted: 'Accept'
static const uint8_t STR_ACCEPT_DATA[] = { 0x25, 0x08, 0x11, 0x1C, 0xF0, 0xF3 };
static const size_t STR_ACCEPT_LEN = 6;
static const uint8_t STR_ACCEPT_KEY = 0x64;
#define GET_STR_ACCEPT() OBF_DECRYPT(STR_ACCEPT_DATA, STR_ACCEPT_LEN, STR_ACCEPT_KEY)

// Encrypted: 'application/json'
static const uint8_t STR_APP_JSON_DATA[] = { 0x07, 0x1D, 0x04, 0x17, 0xEB, 0xEA, 0xF1, 0xE3, 0xF7, 0xCA, 0xC2, 0x9C, 0xD0, 0xB2, 0xA7, 0xA1 };
static const size_t STR_APP_JSON_LEN = 16;
static const uint8_t STR_APP_JSON_KEY = 0x66;
#define GET_STR_APP_JSON() OBF_DECRYPT(STR_APP_JSON_DATA, STR_APP_JSON_LEN, STR_APP_JSON_KEY)

// Encrypted: 'game'
static const uint8_t STR_PARAM_GAME_DATA[] = { 0x0F, 0x0E, 0x1B, 0x18 };
static const size_t STR_PARAM_GAME_LEN = 4;
static const uint8_t STR_PARAM_GAME_KEY = 0x68;
#define GET_STR_PARAM_GAME() OBF_DECRYPT(STR_PARAM_GAME_DATA, STR_PARAM_GAME_LEN, STR_PARAM_GAME_KEY)

// Encrypted: 'user_key'
static const uint8_t STR_PARAM_USER_KEY_DATA[] = { 0x19, 0x00, 0x1F, 0xF3, 0xD7, 0xE4, 0xF3, 0xE4 };
static const size_t STR_PARAM_USER_KEY_LEN = 8;
static const uint8_t STR_PARAM_USER_KEY_KEY = 0x6C;
#define GET_STR_PARAM_USER_KEY() OBF_DECRYPT(STR_PARAM_USER_KEY_DATA, STR_PARAM_USER_KEY_LEN, STR_PARAM_USER_KEY_KEY)

// Encrypted: 'serial'
static const uint8_t STR_PARAM_SERIAL_DATA[] = { 0x19, 0x14, 0x0A, 0x16, 0xE7, 0xE1 };
static const size_t STR_PARAM_SERIAL_LEN = 6;
static const uint8_t STR_PARAM_SERIAL_KEY = 0x6A;
#define GET_STR_PARAM_SERIAL() OBF_DECRYPT(STR_PARAM_SERIAL_DATA, STR_PARAM_SERIAL_LEN, STR_PARAM_SERIAL_KEY)

// Encrypted: 'key'
static const uint8_t STR_PARAM_KEY_DATA[] = { 0x0C, 0x0B, 0x0C };
static const size_t STR_PARAM_KEY_LEN = 3;
static const uint8_t STR_PARAM_KEY_KEY = 0x67;
#define GET_STR_PARAM_KEY() OBF_DECRYPT(STR_PARAM_KEY_DATA, STR_PARAM_KEY_LEN, STR_PARAM_KEY_KEY)

// Encrypted: 'device_id'
static const uint8_t STR_PARAM_DEVICE_ID_DATA[] = { 0x09, 0x11, 0x0D, 0xEB, 0xEA, 0xF5, 0xC8, 0xF7, 0xC1 };
static const size_t STR_PARAM_DEVICE_ID_LEN = 9;
static const uint8_t STR_PARAM_DEVICE_ID_KEY = 0x6D;
#define GET_STR_PARAM_DEVICE_ID() OBF_DECRYPT(STR_PARAM_DEVICE_ID_DATA, STR_PARAM_DEVICE_ID_LEN, STR_PARAM_DEVICE_ID_KEY)

// Encrypted: 'status'
static const uint8_t STR_JSON_STATUS_DATA[] = { 0x1A, 0x04, 0x16, 0x0A, 0xF0, 0xFF };
static const size_t STR_JSON_STATUS_LEN = 6;
static const uint8_t STR_JSON_STATUS_KEY = 0x69;
#define GET_STR_JSON_STATUS() OBF_DECRYPT(STR_JSON_STATUS_DATA, STR_JSON_STATUS_LEN, STR_JSON_STATUS_KEY)

// Encrypted: 'result'
static const uint8_t STR_JSON_RESULT_DATA[] = { 0x1B, 0x15, 0x04, 0x0B, 0xE9, 0xF8 };
static const size_t STR_JSON_RESULT_LEN = 6;
static const uint8_t STR_JSON_RESULT_KEY = 0x69;
#define GET_STR_JSON_RESULT() OBF_DECRYPT(STR_JSON_RESULT_DATA, STR_JSON_RESULT_LEN, STR_JSON_RESULT_KEY)

// Encrypted: 'success'
static const uint8_t STR_JSON_SUCCESS_DATA[] = { 0x19, 0x04, 0x1B, 0x1C, 0xE3, 0xFE, 0xE7 };
static const size_t STR_JSON_SUCCESS_LEN = 7;
static const uint8_t STR_JSON_SUCCESS_KEY = 0x6A;
#define GET_STR_JSON_SUCCESS() OBF_DECRYPT(STR_JSON_SUCCESS_DATA, STR_JSON_SUCCESS_LEN, STR_JSON_SUCCESS_KEY)

// Encrypted: 'message'
static const uint8_t STR_JSON_MESSAGE_DATA[] = { 0x07, 0x14, 0x0B, 0x0C, 0xE7, 0xEA, 0xF1 };
static const size_t STR_JSON_MESSAGE_LEN = 7;
static const uint8_t STR_JSON_MESSAGE_KEY = 0x6A;
#define GET_STR_JSON_MESSAGE() OBF_DECRYPT(STR_JSON_MESSAGE_DATA, STR_JSON_MESSAGE_LEN, STR_JSON_MESSAGE_KEY)

// Encrypted: 'msg'
static const uint8_t STR_JSON_MSG_DATA[] = { 0x0B, 0x1E, 0x13 };
static const size_t STR_JSON_MSG_LEN = 3;
static const uint8_t STR_JSON_MSG_KEY = 0x66;
#define GET_STR_JSON_MSG() OBF_DECRYPT(STR_JSON_MSG_DATA, STR_JSON_MSG_LEN, STR_JSON_MSG_KEY)

// Encrypted: 'error'
static const uint8_t STR_JSON_ERROR_DATA[] = { 0x0D, 0x1D, 0x04, 0x12, 0xF6 };
static const size_t STR_JSON_ERROR_LEN = 5;
static const uint8_t STR_JSON_ERROR_KEY = 0x68;
#define GET_STR_JSON_ERROR() OBF_DECRYPT(STR_JSON_ERROR_DATA, STR_JSON_ERROR_LEN, STR_JSON_ERROR_KEY)

// Encrypted: 'reason'
static const uint8_t STR_JSON_REASON_DATA[] = { 0x1B, 0x15, 0x16, 0x0D, 0xEA, 0xE2 };
static const size_t STR_JSON_REASON_LEN = 6;
static const uint8_t STR_JSON_REASON_KEY = 0x69;
#define GET_STR_JSON_REASON() OBF_DECRYPT(STR_JSON_REASON_DATA, STR_JSON_REASON_LEN, STR_JSON_REASON_KEY)

// Encrypted: 'data'
static const uint8_t STR_JSON_DATA_DATA[] = { 0x03, 0x0F, 0x01, 0x1D };
static const size_t STR_JSON_DATA_LEN = 4;
static const uint8_t STR_JSON_DATA_KEY = 0x67;
#define GET_STR_JSON_DATA() OBF_DECRYPT(STR_JSON_DATA_DATA, STR_JSON_DATA_LEN, STR_JSON_DATA_KEY)

// Encrypted: 'expired_date'
static const uint8_t STR_JSON_EXPIRED_DATE_DATA[] = { 0x0A, 0x0E, 0x0D, 0xED, 0xF9, 0xF7, 0xFD, 0xFF, 0xC3, 0xCF, 0xC1, 0xD9 };
static const size_t STR_JSON_EXPIRED_DATE_LEN = 12;
static const uint8_t STR_JSON_EXPIRED_DATE_KEY = 0x6F;
#define GET_STR_JSON_EXPIRED_DATE() OBF_DECRYPT(STR_JSON_EXPIRED_DATE_DATA, STR_JSON_EXPIRED_DATE_LEN, STR_JSON_EXPIRED_DATE_KEY)

// Encrypted: 'expiry'
static const uint8_t STR_JSON_EXPIRY_DATA[] = { 0x0C, 0x08, 0x07, 0x17, 0xF7, 0xF5 };
static const size_t STR_JSON_EXPIRY_LEN = 6;
static const uint8_t STR_JSON_EXPIRY_KEY = 0x69;
#define GET_STR_JSON_EXPIRY() OBF_DECRYPT(STR_JSON_EXPIRY_DATA, STR_JSON_EXPIRY_LEN, STR_JSON_EXPIRY_KEY)

// Encrypted: 'token'
static const uint8_t STR_JSON_TOKEN_DATA[] = { 0x1C, 0x00, 0x1D, 0x18, 0xEA };
static const size_t STR_JSON_TOKEN_LEN = 5;
static const uint8_t STR_JSON_TOKEN_KEY = 0x68;
#define GET_STR_JSON_TOKEN() OBF_DECRYPT(STR_JSON_TOKEN_DATA, STR_JSON_TOKEN_LEN, STR_JSON_TOKEN_KEY)

// Encrypted: 'session_token'
static const uint8_t STR_JSON_SESSION_TOKEN_DATA[] = { 0x03, 0x12, 0x0D, 0xF6, 0xE5, 0xFC, 0xF4, 0xFE, 0xDC, 0xC0, 0xDD, 0xD8, 0xAA };
static const size_t STR_JSON_SESSION_TOKEN_LEN = 13;
static const uint8_t STR_JSON_SESSION_TOKEN_KEY = 0x70;
#define GET_STR_JSON_SESSION_TOKEN() OBF_DECRYPT(STR_JSON_SESSION_TOKEN_DATA, STR_JSON_SESSION_TOKEN_LEN, STR_JSON_SESSION_TOKEN_KEY)

// Encrypted: 'ptrace'
static const uint8_t STR_PTRACE_DATA[] = { 0x14, 0x1F, 0x00, 0x18, 0xE3, 0xE2 };
static const size_t STR_PTRACE_LEN = 6;
static const uint8_t STR_PTRACE_KEY = 0x64;
#define GET_STR_PTRACE() OBF_DECRYPT(STR_PTRACE_DATA, STR_PTRACE_LEN, STR_PTRACE_KEY)

// Encrypted: 'DYLD_INSERT_LIBRARIES'
static const uint8_t STR_DYLD_INSERT_DATA[] = { 0x2D, 0x29, 0x3B, 0x3A, 0xDA, 0xC5, 0xDD, 0xC9, 0xE4, 0xFA, 0xFB, 0xE9, 0xF1, 0x8D, 0x89, 0x80, 0x98, 0xB2, 0xAE, 0xAB, 0xA6 };
static const size_t STR_DYLD_INSERT_LEN = 21;
static const uint8_t STR_DYLD_INSERT_KEY = 0x69;
#define GET_STR_DYLD_INSERT() OBF_DECRYPT(STR_DYLD_INSERT_DATA, STR_DYLD_INSERT_LEN, STR_DYLD_INSERT_KEY)

// Encrypted: 'FridaGadget'
static const uint8_t STR_FRIDA_GADGET_DATA[] = { 0x2C, 0x03, 0x11, 0x1B, 0xE7, 0xCA, 0xF5, 0xFF, 0xC5, 0xCC, 0xC4 };
static const size_t STR_FRIDA_GADGET_LEN = 11;
static const uint8_t STR_FRIDA_GADGET_KEY = 0x6A;
#define GET_STR_FRIDA_GADGET() OBF_DECRYPT(STR_FRIDA_GADGET_DATA, STR_FRIDA_GADGET_LEN, STR_FRIDA_GADGET_KEY)

// Encrypted: 'frida-server'
static const uint8_t STR_FRIDA_SERVER_DATA[] = { 0x0C, 0x03, 0x11, 0x1B, 0xE7, 0xA0, 0xE7, 0xFE, 0xD0, 0xDF, 0xD5, 0xC5 };
static const size_t STR_FRIDA_SERVER_LEN = 12;
static const uint8_t STR_FRIDA_SERVER_KEY = 0x6A;
#define GET_STR_FRIDA_SERVER() OBF_DECRYPT(STR_FRIDA_SERVER_DATA, STR_FRIDA_SERVER_LEN, STR_FRIDA_SERVER_KEY)

// Encrypted: 'frida-agent'
static const uint8_t STR_FRIDA_AGENT_DATA[] = { 0x0F, 0x02, 0x1E, 0x1A, 0xE4, 0xA1, 0xF2, 0xFD, 0xC4, 0xC6, 0xDB };
static const size_t STR_FRIDA_AGENT_LEN = 11;
static const uint8_t STR_FRIDA_AGENT_KEY = 0x69;
#define GET_STR_FRIDA_AGENT() OBF_DECRYPT(STR_FRIDA_AGENT_DATA, STR_FRIDA_AGENT_LEN, STR_FRIDA_AGENT_KEY)

// Encrypted: 'cynject'
static const uint8_t STR_CYNJECT_DATA[] = { 0x06, 0x15, 0x1D, 0x10, 0xE4, 0xEB, 0xFB };
static const size_t STR_CYNJECT_LEN = 7;
static const uint8_t STR_CYNJECT_KEY = 0x65;
#define GET_STR_CYNJECT() OBF_DECRYPT(STR_CYNJECT_DATA, STR_CYNJECT_LEN, STR_CYNJECT_KEY)

// Encrypted: 'libhooker'
static const uint8_t STR_LIBHOOKER_DATA[] = { 0x0B, 0x07, 0x17, 0x14, 0xEC, 0xE5, 0xFA, 0xFD, 0xED };
static const size_t STR_LIBHOOKER_LEN = 9;
static const uint8_t STR_LIBHOOKER_KEY = 0x67;
#define GET_STR_LIBHOOKER() OBF_DECRYPT(STR_LIBHOOKER_DATA, STR_LIBHOOKER_LEN, STR_LIBHOOKER_KEY)

// Encrypted: 'substitute'
static const uint8_t STR_SUBSTITUTE_DATA[] = { 0x1B, 0x1A, 0x14, 0x0E, 0xF0, 0xE2, 0xE6, 0xEC, 0xD4, 0xC2 };
static const size_t STR_SUBSTITUTE_LEN = 10;
static const uint8_t STR_SUBSTITUTE_KEY = 0x68;
#define GET_STR_SUBSTITUTE() OBF_DECRYPT(STR_SUBSTITUTE_DATA, STR_SUBSTITUTE_LEN, STR_SUBSTITUTE_KEY)

// Encrypted: 'substrate'
static const uint8_t STR_SUBSTRATE_DATA[] = { 0x14, 0x1B, 0x17, 0x0F, 0xF7, 0xF8, 0xF0, 0xEC, 0xFA };
static const size_t STR_SUBSTRATE_LEN = 9;
static const uint8_t STR_SUBSTRATE_KEY = 0x67;
#define GET_STR_SUBSTRATE() OBF_DECRYPT(STR_SUBSTRATE_DATA, STR_SUBSTRATE_LEN, STR_SUBSTRATE_KEY)

// Encrypted: '/Applications/Cydia.app'
static const uint8_t STR_PATH_CYDIA_DATA[] = { 0x47, 0x2E, 0x06, 0x0D, 0xE8, 0xE2, 0xF1, 0xF8, 0xD4, 0xCE, 0xC1, 0xDB, 0xCF, 0xEC, 0x89, 0xA8, 0xBC, 0xB6, 0x87, 0xC3, 0x95, 0x8B, 0x72 };
static const size_t STR_PATH_CYDIA_LEN = 23;
static const uint8_t STR_PATH_CYDIA_KEY = 0x68;
#define GET_STR_PATH_CYDIA() OBF_DECRYPT(STR_PATH_CYDIA_DATA, STR_PATH_CYDIA_LEN, STR_PATH_CYDIA_KEY)

// Encrypted: '/Applications/Sileo.app'
static const uint8_t STR_PATH_SILEO_DATA[] = { 0x47, 0x2E, 0x06, 0x0D, 0xE8, 0xE2, 0xF1, 0xF8, 0xD4, 0xCE, 0xC1, 0xDB, 0xCF, 0xEC, 0x99, 0xB8, 0xB4, 0xBA, 0x89, 0xC3, 0x95, 0x8B, 0x72 };
static const size_t STR_PATH_SILEO_LEN = 23;
static const uint8_t STR_PATH_SILEO_KEY = 0x68;
#define GET_STR_PATH_SILEO() OBF_DECRYPT(STR_PATH_SILEO_DATA, STR_PATH_SILEO_LEN, STR_PATH_SILEO_KEY)

// Encrypted: '/Applications/Zebra.app'
static const uint8_t STR_PATH_ZEBRA_DATA[] = { 0x47, 0x2E, 0x06, 0x0D, 0xE8, 0xE2, 0xF1, 0xF8, 0xD4, 0xCE, 0xC1, 0xDB, 0xCF, 0xEC, 0x90, 0xB4, 0xBA, 0xAD, 0x87, 0xC3, 0x95, 0x8B, 0x72 };
static const size_t STR_PATH_ZEBRA_LEN = 23;
static const uint8_t STR_PATH_ZEBRA_KEY = 0x68;
#define GET_STR_PATH_ZEBRA() OBF_DECRYPT(STR_PATH_ZEBRA_DATA, STR_PATH_ZEBRA_LEN, STR_PATH_ZEBRA_KEY)

// Encrypted: '/Library/MobileSubstrate/MobileSubstrate.dylib'
static const uint8_t STR_PATH_SUBSTRATE_DATA[] = { 0x43, 0x3F, 0x13, 0xE3, 0xFA, 0xEE, 0xE4, 0xE4, 0x8B, 0xE6, 0xDD, 0xDB, 0xA9, 0xAB, 0xAB, 0x86, 0xA9, 0x81, 0x99, 0x85, 0x8A, 0x9E, 0x72, 0x68, 0x3B, 0x56, 0x4D, 0x4B, 0x59, 0x5B, 0x5B, 0x16, 0x39, 0x31, 0x29, 0x15, 0x1A, 0x0E, 0x02, 0x18, 0xAA, 0xEF, 0xEB, 0xF5, 0xC9, 0xC5 };
static const size_t STR_PATH_SUBSTRATE_LEN = 46;
static const uint8_t STR_PATH_SUBSTRATE_KEY = 0x6C;
#define GET_STR_PATH_SUBSTRATE() OBF_DECRYPT(STR_PATH_SUBSTRATE_DATA, STR_PATH_SUBSTRATE_LEN, STR_PATH_SUBSTRATE_KEY)

// Encrypted: '/usr/sbin/sshd'
static const uint8_t STR_PATH_SSHD_DATA[] = { 0x48, 0x1B, 0x06, 0x0E, 0xAC, 0xF9, 0xF3, 0xF1, 0xF1, 0x89, 0xDE, 0xC7, 0xD3, 0xA6 };
static const size_t STR_PATH_SSHD_LEN = 14;
static const uint8_t STR_PATH_SSHD_KEY = 0x67;
#define GET_STR_PATH_SSHD() OBF_DECRYPT(STR_PATH_SSHD_DATA, STR_PATH_SSHD_LEN, STR_PATH_SSHD_KEY)

// Encrypted: '/etc/apt'
static const uint8_t STR_PATH_APT_DATA[] = { 0x49, 0x08, 0x00, 0x18, 0xAD, 0xE8, 0xE0, 0xE3 };
static const size_t STR_PATH_APT_LEN = 8;
static const uint8_t STR_PATH_APT_KEY = 0x66;
#define GET_STR_PATH_APT() OBF_DECRYPT(STR_PATH_APT_DATA, STR_PATH_APT_LEN, STR_PATH_APT_KEY)

// Encrypted: '/bin/bash'
static const uint8_t STR_PATH_BASH_DATA[] = { 0x48, 0x0C, 0x1C, 0x12, 0xAC, 0xE8, 0xF0, 0xEB, 0xF7 };
static const size_t STR_PATH_BASH_LEN = 9;
static const uint8_t STR_PATH_BASH_KEY = 0x67;
#define GET_STR_PATH_BASH() OBF_DECRYPT(STR_PATH_BASH_DATA, STR_PATH_BASH_LEN, STR_PATH_BASH_KEY)

// Encrypted: '/private/jailbreak_test.txt'
static const uint8_t STR_PATH_TEST_SANDBOX_DATA[] = { 0x40, 0x06, 0x0F, 0xED, 0xFD, 0xF3, 0xED, 0xC5, 0x88, 0xC4, 0xD4, 0xD5, 0xAF, 0xA8, 0xA3, 0xBD, 0xBE, 0x8D, 0xB2, 0x80, 0x9E, 0x71, 0x7D, 0x3E, 0x63, 0x66, 0x51 };
static const size_t STR_PATH_TEST_SANDBOX_LEN = 27;
static const uint8_t STR_PATH_TEST_SANDBOX_KEY = 0x6F;
#define GET_STR_PATH_TEST_SANDBOX() OBF_DECRYPT(STR_PATH_TEST_SANDBOX_DATA, STR_PATH_TEST_SANDBOX_LEN, STR_PATH_TEST_SANDBOX_KEY)

#endif /* Obfuscation_h */

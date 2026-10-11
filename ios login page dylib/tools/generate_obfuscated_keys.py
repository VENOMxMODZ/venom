import os

STRINGS = {
    "STR_API_ENDPOINT": "https://venompanel.shop/rootapi",
    "STR_API_HOST": "venompanel.shop",
    "STR_GAME_NAME": "DefineAura",
    "STR_USER_AGENT": "DefineAura/1.0 (iOS)",
    "STR_CONTENT_TYPE": "Content-Type",
    "STR_URL_ENCODED": "application/x-www-form-urlencoded",
    "STR_ACCEPT": "Accept",
    "STR_APP_JSON": "application/json",
    "STR_PARAM_GAME": "game",
    "STR_PARAM_USER_KEY": "user_key",
    "STR_PARAM_SERIAL": "serial",
    "STR_PARAM_KEY": "key",
    "STR_PARAM_DEVICE_ID": "device_id",
    "STR_JSON_STATUS": "status",
    "STR_JSON_RESULT": "result",
    "STR_JSON_SUCCESS": "success",
    "STR_JSON_MESSAGE": "message",
    "STR_JSON_MSG": "msg",
    "STR_JSON_ERROR": "error",
    "STR_JSON_REASON": "reason",
    "STR_JSON_DATA": "data",
    "STR_JSON_EXPIRED_DATE": "expired_date",
    "STR_JSON_EXPIRY": "expiry",
    "STR_JSON_TOKEN": "token",
    "STR_JSON_SESSION_TOKEN": "session_token",
    # Security / Anti-Tamper check strings
    "STR_PTRACE": "ptrace",
    "STR_DYLD_INSERT": "DYLD_INSERT_LIBRARIES",
    "STR_FRIDA_GADGET": "FridaGadget",
    "STR_FRIDA_SERVER": "frida-server",
    "STR_FRIDA_AGENT": "frida-agent",
    "STR_CYNJECT": "cynject",
    "STR_LIBHOOKER": "libhooker",
    "STR_SUBSTITUTE": "substitute",
    "STR_SUBSTRATE": "substrate",
    "STR_PATH_CYDIA": "/Applications/Cydia.app",
    "STR_PATH_SILEO": "/Applications/Sileo.app",
    "STR_PATH_ZEBRA": "/Applications/Zebra.app",
    "STR_PATH_SUBSTRATE": "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "STR_PATH_SSHD": "/usr/sbin/sshd",
    "STR_PATH_APT": "/etc/apt",
    "STR_PATH_BASH": "/bin/bash",
    "STR_PATH_TEST_SANDBOX": "/private/jailbreak_test.txt"
}

def encrypt(s, key):
    raw = s.encode('utf-8')
    res = []
    for i, b in enumerate(raw):
        k = (key + (i * 7)) & 0xFF
        res.append(b ^ k)
    return res

lines = []
lines.append("//")
lines.append("//  Obfuscation.h")
lines.append("//  DefineAura - Anti-Tamper String Encryption Engine")
lines.append("//  Auto-generated: zero plaintext strings in binary")
lines.append("//\n")
lines.append("#ifndef Obfuscation_h")
lines.append("#define Obfuscation_h\n")
lines.append("#import <Foundation/Foundation.h>")
lines.append("#include <stdint.h>")
lines.append("#include <stdlib.h>")
lines.append("#include <string.h>\n")

lines.append("""static inline NSString * _Nonnull OBF_DECRYPT(const uint8_t * _Nonnull cipher, size_t len, uint8_t key) {
    char *buf = (char *)malloc(len + 1);
    if (!buf) return @"";
    for (size_t i = 0; i < len; i++) {
        uint8_t k = (uint8_t)((key + (i * 7)) & 0xFF);
        buf[i] = (char)(cipher[i] ^ k);
    }
    buf[len] = '\\0';
    NSString *res = [NSString stringWithUTF8String:buf];
    memset(buf, 0, len + 1);
    free(buf);
    return res ?: @"";
}

static inline void OBF_DECRYPT_CSTR(const uint8_t * _Nonnull cipher, size_t len, uint8_t key, char * _Nonnull outBuf) {
    for (size_t i = 0; i < len; i++) {
        uint8_t k = (uint8_t)((key + (i * 7)) & 0xFF);
        outBuf[i] = (char)(cipher[i] ^ k);
    }
    outBuf[len] = '\\0';
}
""")

key_base = 0x5A
for name, val in STRINGS.items():
    key = (key_base + len(name)) & 0xFF
    enc = encrypt(val, key)
    c_arr = ", ".join(f"0x{b:02X}" for b in enc)
    lines.append(f"// Encrypted: '{val}'")
    lines.append(f"static const uint8_t {name}_DATA[] = {{ {c_arr} }};")
    lines.append(f"static const size_t {name}_LEN = {len(enc)};")
    lines.append(f"static const uint8_t {name}_KEY = 0x{key:02X};")
    lines.append(f"#define GET_{name}() OBF_DECRYPT({name}_DATA, {name}_LEN, {name}_KEY)")
    lines.append("")

lines.append("#endif /* Obfuscation_h */\n")

output_path = os.path.join(os.getcwd(), "include", "Obfuscation.h")
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Generated {output_path} successfully with {len(STRINGS)} encrypted definitions.")

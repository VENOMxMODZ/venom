//
//  SecurityHardening.m
//  DefineAura - Military-Grade Anti-Tamper & Anti-Crack Protection Suite
//

#import "SecurityHardening.h"
#import "Obfuscation.h"

#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <fcntl.h>
#include <pthread.h>

#define PT_DENY_ATTACH 31
typedef int (*ptrace_fn_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

static volatile uint64_t g_SessionCanary = 0ULL;
static volatile uint64_t g_ExpectedCanary = 0ULL;
static pthread_t g_WatchdogThread;
static volatile bool g_WatchdogRunning = false;

// Anti-reversing silent trap
void SecurityTriggerTrap(void) {
#if defined(__arm64__) || defined(__arm64e__)
    __asm__ volatile (
        "mov x0, #0\n"
        "br x0\n"
    );
#endif
    __builtin_trap();
    *(volatile int *)0 = 0xDEADBEEF;
    exit(0);
}

// Check for attached debugger via sysctl P_TRACED
static bool CheckSysctlDebugger(void) {
    int name[4];
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    
    memset(&info, 0, sizeof(info));
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    if (sysctl(name, 4, &info, &info_size, NULL, 0) == 0) {
        return (info.kp_proc.p_flag & P_TRACED) != 0;
    }
    return false;
}

// Dynamic ptrace invocation to deny debug attachment
static void InvokeAntiDebugPtrace(void) {
    char ptraceSym[16];
    OBF_DECRYPT_CSTR(STR_PTRACE_DATA, STR_PTRACE_LEN, STR_PTRACE_KEY, ptraceSym);
    
    void *handle = dlopen(NULL, RTLD_GLOBAL | RTLD_NOW);
    if (handle) {
        ptrace_fn_t ptrace_ptr = (ptrace_fn_t)dlsym(handle, ptraceSym);
        if (ptrace_ptr) {
            ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
        }
        dlclose(handle);
    }
    memset(ptraceSym, 0, sizeof(ptraceSym));
}

// Scan loaded dyld dynamic libraries for Frida, Cycript, Substrate, and inject libraries
static bool DetectInjectedLibraries(void) {
    char frida1[32], frida2[32], frida3[32], cynj[32], hooker[32], sub1[32], sub2[32];
    OBF_DECRYPT_CSTR(STR_FRIDA_GADGET_DATA, STR_FRIDA_GADGET_LEN, STR_FRIDA_GADGET_KEY, frida1);
    OBF_DECRYPT_CSTR(STR_FRIDA_SERVER_DATA, STR_FRIDA_SERVER_LEN, STR_FRIDA_SERVER_KEY, frida2);
    OBF_DECRYPT_CSTR(STR_FRIDA_AGENT_DATA, STR_FRIDA_AGENT_LEN, STR_FRIDA_AGENT_KEY, frida3);
    OBF_DECRYPT_CSTR(STR_CYNJECT_DATA, STR_CYNJECT_LEN, STR_CYNJECT_KEY, cynj);
    OBF_DECRYPT_CSTR(STR_LIBHOOKER_DATA, STR_LIBHOOKER_LEN, STR_LIBHOOKER_KEY, hooker);
    OBF_DECRYPT_CSTR(STR_SUBSTITUTE_DATA, STR_SUBSTITUTE_LEN, STR_SUBSTITUTE_KEY, sub1);
    OBF_DECRYPT_CSTR(STR_SUBSTRATE_DATA, STR_SUBSTRATE_LEN, STR_SUBSTRATE_KEY, sub2);
    
    uint32_t count = _dyld_image_count();
    bool suspicious = false;
    for (uint32_t i = 0; i < count; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (!imageName) continue;
        
        if (strcasestr(imageName, frida1) != NULL ||
            strcasestr(imageName, frida2) != NULL ||
            strcasestr(imageName, frida3) != NULL ||
            strcasestr(imageName, cynj) != NULL ||
            strcasestr(imageName, hooker) != NULL ||
            strcasestr(imageName, sub1) != NULL ||
            strcasestr(imageName, sub2) != NULL ||
            strcasestr(imageName, "frida") != NULL ||
            strcasestr(imageName, "shadow") != NULL ||
            strcasestr(imageName, "dobby") != NULL) {
            suspicious = true;
            break;
        }
    }
    
    memset(frida1, 0, sizeof(frida1));
    memset(frida2, 0, sizeof(frida2));
    memset(frida3, 0, sizeof(frida3));
    memset(cynj, 0, sizeof(cynj));
    memset(hooker, 0, sizeof(hooker));
    memset(sub1, 0, sizeof(sub1));
    memset(sub2, 0, sizeof(sub2));
    
    return suspicious;
}

// Check if default Frida listening port 27042 is open on localhost
static bool DetectFridaPort(void) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return false;
    
    // Set non-blocking
    int flags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(27042);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    
    int ret = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
    close(sock);
    return (ret == 0);
}

// Check for jailbreak artifacts and sandbox breaches
static bool DetectJailbreakArtifacts(void) {
    char p1[64], p2[64], p3[64], p4[64], p5[64], p6[64], p7[64];
    OBF_DECRYPT_CSTR(STR_PATH_CYDIA_DATA, STR_PATH_CYDIA_LEN, STR_PATH_CYDIA_KEY, p1);
    OBF_DECRYPT_CSTR(STR_PATH_SILEO_DATA, STR_PATH_SILEO_LEN, STR_PATH_SILEO_KEY, p2);
    OBF_DECRYPT_CSTR(STR_PATH_ZEBRA_DATA, STR_PATH_ZEBRA_LEN, STR_PATH_ZEBRA_KEY, p3);
    OBF_DECRYPT_CSTR(STR_PATH_SUBSTRATE_DATA, STR_PATH_SUBSTRATE_LEN, STR_PATH_SUBSTRATE_KEY, p4);
    OBF_DECRYPT_CSTR(STR_PATH_SSHD_DATA, STR_PATH_SSHD_LEN, STR_PATH_SSHD_KEY, p5);
    OBF_DECRYPT_CSTR(STR_PATH_APT_DATA, STR_PATH_APT_LEN, STR_PATH_APT_KEY, p6);
    OBF_DECRYPT_CSTR(STR_PATH_BASH_DATA, STR_PATH_BASH_LEN, STR_PATH_BASH_KEY, p7);
    
    const char *paths[] = { p1, p2, p3, p4, p5, p6, p7 };
    bool found = false;
    for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); i++) {
        if (access(paths[i], F_OK) == 0) {
            found = true;
            break;
        }
    }
    
    // Check environment DYLD_INSERT_LIBRARIES
    char dyldVar[32];
    OBF_DECRYPT_CSTR(STR_DYLD_INSERT_DATA, STR_DYLD_INSERT_LEN, STR_DYLD_INSERT_KEY, dyldVar);
    if (getenv(dyldVar) != NULL || getenv("_DYLD_INSERT_LIBRARIES") != NULL) {
        found = true;
    }
    
    memset(p1, 0, sizeof(p1));
    memset(p2, 0, sizeof(p2));
    memset(p3, 0, sizeof(p3));
    memset(p4, 0, sizeof(p4));
    memset(p5, 0, sizeof(p5));
    memset(p6, 0, sizeof(p6));
    memset(p7, 0, sizeof(p7));
    memset(dyldVar, 0, sizeof(dyldVar));
    
    return found;
}

bool SecurityCheckEnvironment(void) {
    if (CheckSysctlDebugger()) return false;
    if (DetectInjectedLibraries()) return false;
    if (DetectFridaPort()) return false;
    if (DetectJailbreakArtifacts()) return false;
    return true;
}

void SecurityEnforceOrTerminate(void) {
    if (!SecurityCheckEnvironment()) {
        SecurityTriggerTrap();
    }
}

// Background sentinel thread that runs periodic randomized integrity checks
static void *WatchdogWorker(void *arg) {
    while (g_WatchdogRunning) {
        // Sleep between 2.5 and 4.5 seconds
        usleep(3000000 + (arc4random_uniform(1500000)));
        
        // 1. Re-invoke ptrace anti-debug
        InvokeAntiDebugPtrace();
        
        // 2. Perform deep environment check
        if (!SecurityCheckEnvironment()) {
            SecurityTriggerTrap();
        }
        
        // 3. Verify session canary if authenticated
        if (g_SessionCanary != 0ULL && g_SessionCanary != g_ExpectedCanary) {
            SecurityTriggerTrap();
        }
    }
    return NULL;
}

void SecurityHardeningInit(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Immediate anti-debug deny attach
        InvokeAntiDebugPtrace();
        
        // Immediate check
        SecurityEnforceOrTerminate();
        
        // Start background watchdog thread
        g_WatchdogRunning = true;
        pthread_create(&g_WatchdogThread, NULL, WatchdogWorker, NULL);
    });
}

// FNV-1a 64-bit rolling hash for session validation
static uint64_t HashField(uint64_t hash, const char *data) {
    if (!data) return hash;
    const uint64_t prime = 1099511628211ULL;
    while (*data) {
        hash ^= (uint64_t)(unsigned char)(*data++);
        hash *= prime;
    }
    return hash;
}

void SecurityRegisterServerSession(NSString * _Nullable key, NSString * _Nullable token, NSString * _Nullable expiry, NSString * _Nullable deviceID) {
    uint64_t baseSeed = 0x84222325CBF29CE4ULL;
    baseSeed = HashField(baseSeed, [key UTF8String]);
    baseSeed = HashField(baseSeed, [token UTF8String]);
    baseSeed = HashField(baseSeed, [expiry UTF8String]);
    baseSeed = HashField(baseSeed, [deviceID UTF8String]);
    baseSeed ^= 0xA5C3E1F79D4B6028ULL;
    
    g_ExpectedCanary = baseSeed;
    g_SessionCanary = baseSeed;
}

bool SecurityValidateServerSession(void) {
    if (g_ExpectedCanary == 0ULL || g_SessionCanary == 0ULL) {
        return false;
    }
    return (g_SessionCanary == g_ExpectedCanary);
}

void SecurityInvalidateSession(void) {
    g_SessionCanary = 0ULL;
    g_ExpectedCanary = 0ULL;
}

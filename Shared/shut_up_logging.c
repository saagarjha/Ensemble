//
//  shut_up_logging.c
//  MacCast
//
//  Created by Saagar Jha on 11/20/23.
//

#if DEBUG

#include <TargetConditionals.h>
#include <assert.h>
#include <mach-o/dyld_images.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <os/log.h>

struct {
	char *name;
	void *load_address;
} bad_libraries[] = {
    {"/System/Library/Frameworks/CoreVideo.framework"},
    {"/System/Library/PrivateFrameworks/AppleJPEG.framework"},
};

struct stub {
	uint32_t adrp;
#if !TARGET_OS_SIMULATOR
	uint32_t add;
#endif
	uint32_t ldr;
#if TARGET_OS_SIMULATOR
	uint32_t br;
#else
	uint32_t braa;
#endif
};

void *functions[] = {
    _os_log_impl,
    _os_log_debug_impl,
    _os_log_error_impl,
    _os_log_fault_impl,
};

static void __os_log_impl(void *dso, os_log_t log, os_log_type_t type, const char *format, uint8_t *buf, uint32_t size) {
	for (int i = 0; i < sizeof(bad_libraries) / sizeof(*bad_libraries); ++i) {
		if (dso == bad_libraries[i].load_address) {
			return;
		}
	}
	_os_log_impl(dso, log, type, format, buf, size);
}

static void patch(void **address) {
	vm_protect(mach_task_self(), (mach_vm_address_t)address / PAGE_SIZE * PAGE_SIZE, PAGE_SIZE, false, VM_PROT_READ | VM_PROT_WRITE);
	*address = __os_log_impl;
}

static void find(struct mach_header_64 *header) {
	size_t size;
	struct stub *stubs = (struct stub *)getsectiondata(header, "__TEXT",
#if TARGET_OS_SIMULATOR
	    "__stubs"
#else
	    "__auth_stubs"
#endif
	    ,
	    &size);
	for (int i = 0; i < size / sizeof(*stubs); ++i) {
#if TARGET_OS_SIMULATOR
		// adrp x16, *
		// ldr x16, [x16, *]
		// br x16
		assert((stubs[i].adrp & 0x9f00001f) == 0x90000010);
		assert((stubs[i].ldr & 0xffc003fc) == 0xf9400210);
		assert(stubs[i].br == 0xd61f0200);
#else
		// adrp x17, *
		// add x17, x17, *
		// ldr x16, [x17]
		// braa x16, x17
		assert((stubs[i].adrp & 0x9f00001f) == 0x90000011);
		assert((stubs[i].add & 0xff8003ff) == 0x91000231);
		assert(stubs[i].ldr == 0xf9400230);
		assert(stubs[i].braa == 0xd71f0a11);
#endif
		uintptr_t lo = stubs[i].adrp >> 29 & 0x3;
		uintptr_t hi = stubs[i].adrp >> 5 & 0x7ffff;
		uintptr_t base = (uintptr_t)(stubs + i) & ((uintptr_t)-1 >> 12 << 12);
#if TARGET_OS_SIMULATOR
		uintptr_t offset = (stubs[i].ldr >> 10 & 0xfff) << 3;
#else
		uintptr_t offset = stubs[i].add >> 10 & 0xfff;
#endif
		void **address = (void **)(base + ((hi << 2 | lo) << 12) + offset);
		for (int j = 0; j < sizeof(functions) / sizeof(*functions); ++j) {
			if (*address == functions[j]) {
				patch(address);
			}
		}
	}
}

__attribute__((constructor)) static void init(void) {
	struct task_dyld_info info;
	mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
	task_info(mach_task_self(), TASK_DYLD_INFO, (task_info_t)&info, &count);
	struct dyld_all_image_infos *all_image_infos = (struct dyld_all_image_infos *)info.all_image_info_addr;
	for (int i = 0; i < all_image_infos->infoArrayCount; ++i) {
		for (int j = 0; j < sizeof(bad_libraries) / sizeof(*bad_libraries); ++j) {
			if (strstr(all_image_infos->infoArray[i].imageFilePath, bad_libraries[j].name)) {
				bad_libraries[j].load_address = (void *)all_image_infos->infoArray[i].imageLoadAddress;
				find(bad_libraries[j].load_address);
			}
		}
	}
}

#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <process.h>

// Loosely according to https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way/
size_t argvQuote(wchar_t *in, wchar_t *out) {
    int ipos;
    int opos;
    int bs_count;
    int c;

    ipos = 0;
    opos = 0;

    if (!wcschr(in, L' ') && !wcschr(in, L'\\"') && !wcschr(in, L'\\t') && !wcschr(in, L'\\n') && !wcschr(in, L'\\v')) {
        if (out) wcscpy(out, in);
        return (wcslen(in) + 1) * sizeof(wchar_t);
    }

    if (out) out[opos] = L'\\"';
    opos++;

    while (in[ipos] != 0) {
        bs_count = 0;
        while (in[ipos] != 0 && in[ipos] == L'\\\\') {
            ipos++;
            bs_count++;
        }

        if (in[ipos] == 0) {
            for (c = 0; c < (bs_count * 2); c++) {
                if (out) out[opos] = L'\\\\';
                opos++;
            }
            break;
        }
        else if (in[ipos] == L'\\"') {
            for (c = 0; c < (bs_count * 2 + 1); c++) {
                if (out) out[opos] = L'\\\\';
                opos++;
            }
            if (out) out[opos] = in[ipos];
            opos++;
        }
        else {
            for (c = 0; c < bs_count; c++) {
                if (out) out[opos] = L'\\\\';
                opos++;
            }
            if (out) out[opos] = in[ipos];
            opos++;
        }

        ipos++;
    }

    if (out) out[opos] = L'\\"';
    opos++;
    if (out) out[opos] = 0;
    opos++;

    return opos * sizeof(wchar_t);
}

int wmain(int argc, wchar_t *argv[])
{
    int moar_argc;
    int exec_argc;
    int c;
    wchar_t **exec_argv;
    wchar_t *moar = L"@c_escape(@nfp(@MOAR@)@)@";
    wchar_t *buf;
    size_t buf_size;

    moar_argc = 3;

    // program name + moar args + passed args (without program name) + NULL pointer
    exec_argc = 1 + moar_argc + (argc - 1) + 1;
    exec_argv = malloc(exec_argc * sizeof(void*));

    exec_argv[0] = L"@c_escape(@nfp(@MOAR@)@)@";

    // Set up moar args.
    exec_argv[1] = L"--execname=@c_escape(@nfp(@exec_name@)@)@";
    exec_argv[2] = L"--libpath=@c_escape(@nfp(@base_dir@)@)@";
    exec_argv[3] = L"@c_escape(@nfp(@mbc@)@)@";

    // Copy passed args.
    for (c = 0; c < argc - 1; c++) {
        exec_argv[1 + moar_argc + c] = argv[c + 1];
    }

    exec_argv[exec_argc - 1] = NULL;

    for (c = 0; c < exec_argc - 1; c++) {
        buf_size = argvQuote(exec_argv[c], NULL);
        buf = malloc(buf_size);
        argvQuote(exec_argv[c], buf);
        exec_argv[c] = buf;
    }

    _wexecv(moar, exec_argv);
    // execv doesn't return on successful exec.
    fprintf(stderr, "ERROR: Failed to execute moar. Error code: %i\n", errno);
    return EXIT_FAILURE;
}
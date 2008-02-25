#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <regex.h>

#include "POSIX.h"

REGEXP *
POSIX_comp(pTHX_ const SV * const pattern, const U32 flags)
{
    REGEXP  *rx;
    regex_t *re;

    STRLEN plen;
    char  *exp = SvPV((SV*)pattern, plen);
    char *xend = exp + plen;
    U32 extflags = flags;

    /* pregcomp vars */
    int cflags = 0;
    int err;
#define ERR_STR_LENGTH 512
    char err_str[ERR_STR_LENGTH];
    size_t err_str_length;

    /* C<split " ">, bypass the engine alltogether and act as perl does */
    if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ')
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);

    /* RXf_NULL - Have C<split //> split by characters */
    if (plen == 0)
        extflags |= RXf_NULL;

    /* RXf_START_ONLY - Have C<split /^/> split on newlines */
    else if (plen == 1 && exp[0] == '^')
        extflags |= RXf_START_ONLY;

    /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
    else if (plen == 3 && strnEQ("\\s+", exp, 3))
        extflags |= RXf_WHITE;

    /* REGEX structure for perl */
    Newxz(rx, 1, REGEXP);

    rx->refcnt = 1;
    rx->extflags = extflags;
    rx->engine = &engine_posix;

    /* Precompiled regexp for pp_regcomp to use */
    rx->prelen = (I32)plen;
    rx->precomp = SAVEPVN(exp, rx->prelen);

    /* qr// stringification, reuse the space */
    rx->wraplen = rx->prelen;
    rx->wrapped = (char *)rx->precomp; /* from const char* */

    /* Catch invalid modifiers, the rest of the flags are ignored */
    if (flags & (RXf_PMf_SINGLELINE|RXf_PMf_KEEPCOPY))
        if (flags & RXf_PMf_SINGLELINE) /* /s */
            croak("The `s' modifier is not supported by re::engine::POSIX");
        else if (flags & RXf_PMf_KEEPCOPY) /* /p */
            croak("The `p' modifier is not supported by re::engine::POSIX");

    /* Modifiers valid, munge to POSIX cflags */
    if (flags & PMf_EXTENDED) /* /x */
        cflags |= REG_EXTENDED;
    if (flags & PMf_MULTILINE) /* /m */
        cflags |= REG_NEWLINE;
    if (flags & PMf_FOLD) /* /i */
        cflags |= REG_ICASE;

    Newxz(re, 1, regex_t);

    err = regcomp(re, exp, cflags);

    if (err != 0) {
        /* note: we do not call regfree() when regncomp returns an error */
        err_str_length = regerror(err, re, err_str, ERR_STR_LENGTH);
        if (err_str_length > ERR_STR_LENGTH) {
            croak("error compiling `%s': %s (error message truncated)", exp, err_str);
        } else {
            croak("error compiling `%s': %s", exp, err_str);
        }
    }

    /* Save for later */
    rx->pprivate = re;

    /*
      Tell perl how many match vars we have and allocate space for
      them, at least one is always allocated for $&
     */
    rx->nparens = (U32)re->re_nsub; /* cast from size_t */
    Newxz(rx->offs, rx->nparens + 1, regexp_paren_pair);

    /* return the regexp structure to perl */
    return rx;
}

I32
POSIX_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
           char *strbeg, I32 minend, SV * sv,
           void *data, U32 flags)
{
    regex_t *re;
    regmatch_t *matches;
    regoff_t offs;
    size_t parens;
    int err;
    char *err_msg;
    int i;

    re = rx->pprivate;
    parens = (size_t)rx->nparens + 1;

    Newxz(matches, parens, regmatch_t);

    err = regexec(re, stringarg, parens, matches, 0);

    if (err != 0) {
        assert(err == REG_NOMATCH);
        Safefree(matches);
        return 0;
    }

    rx->subbeg = strbeg;
    rx->sublen = strend - strbeg;

    /*
      regexec returns offsets from the start of `stringarg' but perl expects
      them to count from `strbeg'.
    */
    offs = stringarg - strbeg;

    for (i = 0; i < parens; i++) {
        rx->offs[i].start = matches[i].rm_so + offs;
        rx->offs[i].end   = matches[i].rm_eo + offs;
    }

    Safefree(matches);

    /* known to have matched by this point (see error handling above */
    return 1;
}

char *
POSIX_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos,
             char *strend, U32 flags, re_scream_pos_data *data)
{
    PERL_UNUSED_ARG(rx);
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(strpos);
    PERL_UNUSED_ARG(strend);
    PERL_UNUSED_ARG(flags);
    PERL_UNUSED_ARG(data);
    return NULL;
}

SV *
POSIX_checkstr(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return NULL;
}

void
POSIX_free(pTHX_ REGEXP * const rx)
{
    regfree(rx->pprivate);
}

void *
POSIX_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    regex_t *re;
    Copy(rx->pprivate, re, 1, regex_t);
    return re;
}

SV *
POSIX_package(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return newSVpvs("re::engine::POSIX");
}

MODULE = re::engine::POSIX PACKAGE = re::engine::POSIX
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(PTR2IV(&engine_posix))));

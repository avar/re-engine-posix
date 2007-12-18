#define SAVEPVN(p,n) ((p) ? savepvn(p,n) : NULL)

START_EXTERN_C
EXTERN_C const regexp_engine engine_posix;
EXTERN_C REGEXP * POSIX_comp(pTHX_ const SV const *, const U32);
EXTERN_C I32      POSIX_exec(pTHX_ REGEXP * const, char *, char *,
                             char *, I32, SV *, void *, U32);
EXTERN_C char *   POSIX_intuit(pTHX_ REGEXP * const, SV *, char *,
                               char *, U32, re_scream_pos_data *);
EXTERN_C SV *     POSIX_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     POSIX_free(pTHX_ REGEXP * const);
EXTERN_C SV *     POSIX_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   POSIX_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
END_EXTERN_C

char *get_regerror(int, regex_t *);

const regexp_engine engine_posix = {
    POSIX_comp,
    POSIX_exec,
    POSIX_intuit,
    POSIX_checkstr,
    POSIX_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    POSIX_package,
#ifdef USE_ITHREADS
    POSIX_dupe,
#endif
};

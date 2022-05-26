//
// Created by simsilver on 2021/11/26.
//

#ifndef PDFREADER_LIBPDFEDITOR_JNI_PDF_MERGE_H
#define PDFREADER_LIBPDFEDITOR_JNI_PDF_MERGE_H

#ifdef __cplusplus
extern "C"
{
#endif

    extern int pdf_merge(char *output, int count, char **files, char **params, fz_progress_data *dcb);
    extern int pdf_create(const char *input, const char *output, const char *flags, fz_progress_data *dcb);

#ifdef __cplusplus
}
#endif

#endif // PDFREADER_LIBPDFEDITOR_JNI_PDF_MERGE_H

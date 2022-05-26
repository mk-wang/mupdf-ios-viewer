/*
 * PDF merge tool: Tool for merging pdf content.
 *
 * Simple test bed to work with merging pages from multiple PDFs into a single PDF.
 */

#include "mupdf/fitz.h"
#include "mupdf/pdf.h"

#include <stdio.h>
#include <stdlib.h>

#include "pdf-tool.h"

typedef struct MERGE_INFO_S
{
    fz_context *ctx;
    pdf_document *doc_des;
    pdf_document *doc_src;
    fz_progress_data *dataCb;
} MergeInfo;

typedef struct DATA_PROCESS_S
{
    void *saved;
    int idx, count;
} DataProcess;

static void page_merge(const MergeInfo *mergeInfo, int page_from, int page_to, pdf_graft_map *graft_map)
{
    pdf_obj *page_ref;
    pdf_obj *page_dict;
    pdf_obj *obj;
    pdf_obj *ref = NULL;
    int i;
    fz_context *ctx = mergeInfo->ctx;
    pdf_document *doc_des = mergeInfo->doc_des;
    pdf_document *doc_src = mergeInfo->doc_src;
    char pageIdx[16];

    /* Copy as few key/value pairs as we can. Do not include items that reference other pages. */
    static pdf_obj *const copy_list[] = {PDF_NAME_Contents, PDF_NAME_Resources,
                                         PDF_NAME_MediaBox, PDF_NAME_CropBox, PDF_NAME_BleedBox, PDF_NAME_TrimBox, PDF_NAME_ArtBox,
                                         PDF_NAME_Rotate, PDF_NAME_UserUnit, PDF_NAME_Annots};

    fz_var(ref);

    fz_try(ctx)
    {
        snprintf(pageIdx, sizeof(pageIdx), "%d", page_from);
        page_ref = pdf_lookup_page_obj(ctx, doc_src, page_from - 1);
        pdf_flatten_inheritable_page_items(ctx, page_ref);

        /* Make a new page object dictionary to hold the items we copy from the source page. */
        page_dict = pdf_new_dict(ctx, doc_des, 4);

        pdf_dict_put_drop(ctx, page_dict, PDF_NAME_Type, PDF_NAME_Page);

        for (i = 0; i < nelem(copy_list); i++) {
            obj = pdf_dict_get(ctx, page_ref, copy_list[i]);
            if (obj != NULL)
                pdf_dict_put_drop(ctx, page_dict, copy_list[i], pdf_graft_object(ctx, doc_des, doc_src, obj, graft_map));
        }

        /* Add the page object to the destination document. */
        ref = pdf_add_object_drop(ctx, doc_des, page_dict);

        /* Insert it into the page tree. */
        pdf_insert_page(ctx, doc_des, page_to - 1, ref);
        fz_progress_data *dcb = mergeInfo->dataCb;
        DataProcess *process = dcb->extra;
        dcb->cb(dcb->data, process->idx, process->count, pageIdx);
    }
    fz_always(ctx)
    {
        pdf_drop_obj(ctx, ref);
    }
    fz_catch(ctx)
    {
        fz_rethrow(ctx);
    }
}

static void merge_range(const MergeInfo *mergeInfo, const char *range)
{
    int start, end, i, count;
    pdf_graft_map *graft_map;

    fz_context *ctx = mergeInfo->ctx;
    pdf_document *doc_src = mergeInfo->doc_src;

    count = pdf_count_pages(ctx, doc_src);
    graft_map = pdf_new_graft_map(ctx, doc_src);

    fz_try(ctx)
    {
        while ((range = fz_parse_page_range(ctx, range, &start, &end, count))) {
            if (start < end)
                for (i = start; i <= end; ++i)
                    page_merge(mergeInfo, i, -1, graft_map);
            else
                for (i = start; i >= end; --i)
                    page_merge(mergeInfo, i, -1, graft_map);
        }
    }
    fz_always(ctx)
    {
        pdf_drop_graft_map(ctx, graft_map);
    }
    fz_catch(ctx)
    {
        fz_rethrow(ctx);
    }
}

int pdf_merge(char *output, int count, char **files, char **params, fz_progress_data *dcb)
{
    pdf_write_options opts = {0};
    char *input;
    int idx = 0;

    fz_context *ctx = NULL;
    pdf_document *doc_des = NULL;
    pdf_document *doc_src = NULL;
    MergeInfo mergeInfo;
    DataProcess processInfo;
    mergeInfo.dataCb = dcb;
    processInfo.saved = dcb->extra;
    dcb->extra = &processInfo;
    processInfo.count = count;

    ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!ctx) {
        dcb->cb(dcb->data, -1, count, "error: Cannot initialize MuPDF context.");
        return 0;
    }
    mergeInfo.ctx = ctx;

    fz_try(ctx)
    {
        doc_des = pdf_create_document(ctx);
    }
    fz_catch(ctx)
    {
        fz_drop_context(ctx);
        dcb->cb(dcb->data, -1, count, "error: Cannot create destination document.");
        return 0;
    }
    mergeInfo.doc_des = doc_des;

    dcb->cb(dcb->data, idx, count, "start");

    /* Step through the source files */
    while (idx < count) {
        processInfo.idx = idx;
        input = files[idx];
        fz_try(ctx)
        {
            pdf_drop_document(ctx, doc_src);
            doc_src = pdf_open_document(ctx, input);
            mergeInfo.doc_src = doc_src;
            if (params == NULL || !fz_is_page_range(ctx, params[idx]))
                merge_range(&mergeInfo, "1-N");
            else
                merge_range(&mergeInfo, params[idx]);
        }
        fz_catch(ctx)
        {
            dcb->cb(dcb->data, idx, -1, "error: Cannot merge document.");
            break;
        }
        idx++;
    }

    fz_try(ctx)
    {
        pdf_save_document(ctx, doc_des, output, &opts);
    }
    fz_always(ctx)
    {
        pdf_drop_document(ctx, doc_des);
        pdf_drop_document(ctx, doc_src);
    }
    fz_catch(ctx)
    {
        dcb->cb(dcb->data, idx, count, "error: Cannot save output file.");
        count = -idx;
    }

    fz_flush_warnings(ctx);
    fz_drop_context(ctx);
    if (idx == count) {
        dcb->cb(dcb->data, idx, count, output);
    }
    return idx == count;
}
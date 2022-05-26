// Copyright (C) 2004-2021 Artifex Software, Inc.
//
// This file is part of MuPDF.
//
// MuPDF is free software: you can redistribute it and/or modify it under the
// terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// MuPDF is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with MuPDF. If not, see <https://www.gnu.org/licenses/agpl-3.0.en.html>
//
// Alternative licensing terms are available from the licensor.
// For commercial licensing, see <https://www.artifex.com/> or contact
// Artifex Software, Inc., 1305 Grant Avenue - Suite 200, Novato,
// CA 94945, U.S.A., +1(415)492-9861, for further information.

/*
 * PDF creation tool: Tool for creating pdf content.
 *
 * Simple test bed to work with adding content and creating PDFs
 */

#include "mupdf/fitz.h"
#include "mupdf/pdf.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pdf-tool.h"

int pdf_create(const char *input, const char *output, const char *flags, fz_progress_data *dcb)
{
    fz_context *ctx = NULL;
    pdf_document *doc = NULL;
    pdf_write_options opts = pdf_default_write_options;
    int result = 1;

    ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!ctx) {
        dcb->cb(dcb->data, -1, 0, "result: Cannot initialize MuPDF context.");
        return 0;
    }

    pdf_parse_write_options(ctx, &opts, flags);

    int total = 0;
    dcb->extra = &total;

    fz_var(doc);

    fz_try(ctx)
    {
        doc = pdf_open_document(ctx, input);
        int status = 1;
        if (fz_needs_password(ctx, &doc->super)) {
            status = fz_authenticate_password(ctx, &doc->super, opts.upwd_utf8);
        }
        if (status > 0) {
            pdf_save_document_cb(ctx, doc, output, &opts, dcb);
        } else {
            result = -2;
        };
    }
    fz_always(ctx)
    {
        pdf_drop_document(ctx, doc);
    }
    fz_catch(ctx)
        result = -1;

    fz_flush_warnings(ctx);
    fz_drop_context(ctx);
    if (result != 1) {
        dcb->cb(dcb->data, 0, result, "result: Cannot create document.");
    } else {
        dcb->cb(dcb->data, total, total, output);
    }
    return result;
}

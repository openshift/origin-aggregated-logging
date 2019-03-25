/**
 * @file enc.h
 * @brief Encoder functions
 */
/*
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010 by Rainer Gerhards and Adiscon GmbH.
 *
 * Modified by Pavel Levshin (pavel@levshin.spb.ru) in 2013
 *
 * This file is part of liblognorm.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * A copy of the LGPL v2.1 can be found in the file "COPYING" in this distribution.
 */

#ifndef LIBLOGNORM_ENC_H_INCLUDED
#define	LIBLOGNORM_ENC_H_INCLUDED

int ln_fmtEventToRFC5424(struct json_object *json, es_str_t **str);

int ln_fmtEventToCSV(struct json_object *json, es_str_t **str, es_str_t *extraData);

int ln_fmtEventToXML(struct json_object *json, es_str_t **str);

#endif /* LIBLOGNORM_ENC_H_INCLUDED */

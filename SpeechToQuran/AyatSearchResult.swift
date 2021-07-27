//
//  AyatSearchResult.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import Foundation

struct AyatSearchResult {
    let index: Int
    let text: String //obj->aya->text_no_highlight
    let suratName: String //obj->identifier->sura_name
    let suratId: Int //obj->identifier->sura_id
    let ayatId: Int //obj->identifier->aya_id
    let ayatIdGlobal: Int //obj->identifier->gid
}

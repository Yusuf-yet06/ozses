#ifndef OZSES_SIBER_STREAM_FILTER_HPP
#define OZSES_SIBER_STREAM_FILTER_HPP

#include <cstring>
#include <cctype>
#include <cstdint>

extern "C" {

/**
 * OZSES V7 IMPERIUM - Native C++ Piggyback Stream & Shorts Filter
 * Ekstra arka plan uyanıklığı (wake-lock) olmadan, YT ve Spotify akışlarını
 * anlık filtreler (75sn altı Shorts, Teaser, Kesit elemesi).
 */
inline bool siber_is_valid_full_song(const char* title, int duration_seconds) {
    if (!title || title[0] == '\0') return false;
    if (duration_seconds > 0 && duration_seconds < 75) return false;

    char lower[512];
    size_t len = std::strlen(title);
    if (len >= sizeof(lower)) len = sizeof(lower) - 1;
    for (size_t i = 0; i < len; ++i) {
        lower[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(title[i])));
    }
    lower[len] = '\0';

    const char* blocked[] = {
        "#shorts", "#short", "teaser", "snippet",
        "onizleme", "tanitim", "fragman", "kesit", "reels", "#tiktok"
    };
    for (const char* kw : blocked) {
        if (std::strstr(lower, kw) != nullptr) {
            return false;
        }
    }
    return true;
}

} // extern "C"

#endif // OZSES_SIBER_STREAM_FILTER_HPP

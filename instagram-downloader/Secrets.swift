func getCookiesAndHeaders(videoCode: String) -> ([String: String], [String: String]) {
    let cookies: [String: String] = [
        "fbm_124024574287414": "base_domain=.instagram.com",
        "datr": "...",
        "mid": "...",
        "ps_n": "1",
        "ps_l": "1",
        "igd_ls": "...",
        "ds_user_id": "...",
        "csrftoken": "...",
        "ig_did": "...",
        "wd": "...",
        "sessionid": "...",
        "rur": "..."
    ]

    let headers: [String: String] = [
        "accept": "*/*",
        "accept-language": "en-US,en;q=0.9,ru;q=0.8,uk;q=0.7",
        "cache-control": "no-cache",
        "content-type": "application/x-www-form-urlencoded",
        "origin": "https://www.instagram.com",
        "pragma": "no-cache",
        "priority": "u=1, i",
        "referer": "https://www.instagram.com/reel/\(videoCode)/",
        "sec-ch-prefers-color-scheme": "dark",
        "sec-ch-ua": "\"Google Chrome\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\"",
        "sec-ch-ua-full-version-list": "\"Google Chrome\";v=\"131.0.6778.266\", \"Chromium\";v=\"131.0.6778.266\", \"Not_A Brand\";v=\"24.0.0.0\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-model": "\"\"",
        "sec-ch-ua-platform": "\"macOS\"",
        "sec-ch-ua-platform-version": "\"13.7.2\"",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "same-origin",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "x-asbd-id": "129477",
        "x-bloks-version-id": "...",
        "x-csrftoken": "...",
        "x-fb-friendly-name": "PolarisFeedTimelineRootV2Query",
        "x-fb-lsd": "...",
        "x-ig-app-id": "..."
    ]
    
    return (cookies, headers)
}

from flask import Flask, request, jsonify
from yt_dlp import YoutubeDL


app = Flask(__name__)
    

@app.route('/info', methods=['GET'])
def info():
    url = request.args.get('url')
    if not url:
        return "Error: No URL provided", 400

    """
    cookies from Instagram downloaded with
    https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc
    """
    options = {
        'format': 'bestvideo[vcodec=avc1]+bestaudio[acodec=aac]/mp4',
        'cookiefile': 'cookies.txt'
    }

    try:
        with YoutubeDL(options) as ydl:
            info_dict = ydl.extract_info(url)
            print("Info downloaded")
    except Exception as e:
        print(f"Download failed: {str(e)}")
        return f"Error while downloading video: {str(e)}", 500

    return jsonify(info_dict.get("url"))

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=6000)

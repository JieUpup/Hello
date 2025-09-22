from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse
import os
import shutil
import uuid

from moviepy.editor import TextClip, CompositeVideoClip

app = FastAPI()

# 确保视频输出目录存在
os.makedirs("uploads", exist_ok=True)
os.makedirs("videos", exist_ok=True)

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    # 保存上传的文本文件
    file_id = str(uuid.uuid4())
    input_path = f"uploads/{file_id}_{file.filename}"
    with open(input_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 读取文本内容
    with open(input_path, "r") as f:
        text = f.read()

    # 创建一个 720p 的文字视频（限制文字长度）
    clip = TextClip(text[:500], fontsize=40, color='white', size=(1280, 720), method='caption')
    clip = clip.set_duration(10)  # 视频长度 10 秒
    video = CompositeVideoClip([clip])

    # 输出视频文件
    video_path = f"videos/{file_id}.mp4"
    video.write_videofile(video_path, fps=24, codec='libx264')

    # 返回视频链接
    return {"video_url": f"http://localhost:8001/video/{file_id}.mp4"}

@app.get("/video/{filename}")
async def get_video(filename: str):
    path = f"videos/{filename}"
    if not os.path.exists(path):
        return {"error": "Video not found"}
    return FileResponse(path, media_type="video/mp4")


import sys
import os
import subprocess
import re
import time
import signal

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
CLOUDFLARED_PATH = os.path.join(BACKEND_DIR, "cloudflared.exe")
URL_FILE = os.path.join(BACKEND_DIR, "server_url.txt")

def main():
    print("\n" + "=" * 70)
    print("      🎵 RHYTHM / VIBEFLOW — REMOTE CLOUD TUNNEL LAUNCHER")
    print("=" * 70 + "\n")
    
    if not os.path.exists(CLOUDFLARED_PATH):
        print(f"❌ Ошибка: {CLOUDFLARED_PATH} не найден.")
        return

    # 1. Запуск uvicorn
    print("⏳ [1/2] Запуск локального бэкенда FastAPI (порт 8000)...")
    uvicorn_cmd = [sys.executable, "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
    uvicorn_proc = subprocess.Popen(
        uvicorn_cmd,
        cwd=BACKEND_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    # Даем серверу 1-2 секунды на инициализацию
    time.sleep(1.5)

    # 2. Запуск Cloudflare Tunnel
    print("⏳ [2/2] Подключение защищенного туннеля Cloudflare...")
    cf_cmd = [CLOUDFLARED_PATH, "tunnel", "--url", "http://127.0.0.1:8000"]
    cf_proc = subprocess.Popen(
        cf_cmd,
        cwd=BACKEND_DIR,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="ignore"
    )

    tunnel_url = None
    start_time = time.time()
    
    while time.time() - start_time < 20:
        line = cf_proc.stderr.readline()
        if not line:
            time.sleep(0.1)
            continue
        if "trycloudflare.com" in line:
            match = re.search(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com", line)
            if match:
                tunnel_url = match.group(0)
                break

    if not tunnel_url:
        print("❌ Не удалось получить адрес туннеля за 20 секунд.")
        uvicorn_proc.terminate()
        cf_proc.terminate()
        return

    api_url = f"{tunnel_url}/api"

    # Сохраняем адрес в текстовый файл для быстрого копирования
    try:
        with open(URL_FILE, "w", encoding="utf-8") as f:
            f.write(api_url)
    except Exception:
        pass

    print("\n" + "=" * 70)
    print("       🎉 СЕРВЕР УСПЕШНО ЗАПУЩЕН И ДОСТУПЕН В ИНТЕРНЕТЕ!")
    print("=" * 70)
    print("\n📲 ВАША ПЕРСОНАЛЬНАЯ ССЫЛКА ДЛЯ IPHONE (СКОПИРУЙТЕ ЕЁ):")
    print(f"\n   👉   {api_url}   👈\n")
    print("-" * 70)
    print("📌 ИНСТРУКЦИЯ ДЛЯ IPHONE (РАБОТАЕТ ЧЕРЕЗ 5G / LTE / ЛЮБОЙ WI-FI):")
    print("1. Откройте приложение Rhythm на вашем iPhone.")
    print("2. На вкладке 'Главная' нажмите на шестеренку ⚙️ в правом верхнем углу.")
    print("3. Вставьте ссылку выше и нажмите 'Сохранить'.")
    print("4. Готово! Вся музыка с вашего ПК через yt-dlp теперь играет на айфоне.")
    print("-" * 70)
    print(f"(Ссылка также сохранена в файл: {URL_FILE})")
    print("Для завершения работы сервера нажмите Ctrl + C")
    print("=" * 70 + "\n")

    def shutdown(signum, frame):
        print("\n🛑 Завершение работы бэкенда и туннеля...")
        try:
            cf_proc.terminate()
            uvicorn_proc.terminate()
        except Exception:
            pass
        print("✅ Сервер остановлен.")
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        while True:
            time.sleep(1)
            if uvicorn_proc.poll() is not None:
                print("⚠️ FastAPI процесс неожиданно завершился.")
                break
            if cf_proc.poll() is not None:
                print("⚠️ Cloudflare процесс неожиданно завершился.")
                break
    except KeyboardInterrupt:
        shutdown(None, None)

if __name__ == "__main__":
    main()

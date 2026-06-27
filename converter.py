import cv2
import mediapipe as mp
import numpy as np
import sys
import os

def process_video_original_features(input_path, output_path=None, threshold=0.6):
    mp_selfie_segmentation = mp.solutions.selfie_segmentation
    mp_face_mesh = mp.solutions.face_mesh

    selfie_segmentation = mp_selfie_segmentation.SelfieSegmentation(model_selection=1)
    face_mesh = mp_face_mesh.FaceMesh(
        static_image_mode=False,
        max_num_faces=1,
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7
    )

    LEFT_EYE_INDICES = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
    RIGHT_EYE_INDICES = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]
    MOUTH_INDICES = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]

    LEFT_EYEBROW = [46, 53, 52, 65, 55]
    RIGHT_EYEBROW = [276, 283, 282, 295, 285]
    ALL_FEATURES = LEFT_EYE_INDICES + RIGHT_EYE_INDICES + MOUTH_INDICES + LEFT_EYEBROW + RIGHT_EYEBROW

    if not os.path.exists(input_path):
        print(f"Ошибка: Файл '{input_path}' не найден!")
        return False

    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        print(f"Ошибка: Не удалось открыть видео '{input_path}'")
        return False

    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_original_features{ext}"

    fps = int(cap.get(cv2.CAP_PROP_FPS))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    print(f"Обработка видео: {input_path}")
    print(f"Размер: {width}x{height}, FPS: {fps}")

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height), isColor=True)

    smoothed_body = None
    smoothed_features = None
    alpha = 0.3

    frame_count = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        seg_results = selfie_segmentation.process(rgb)
        body_mask = (seg_results.segmentation_mask > threshold).astype(np.uint8) * 255

        if smoothed_body is None:
            smoothed_body = body_mask.astype(np.float32)
        else:
            smoothed_body = alpha * body_mask.astype(np.float32) + (1 - alpha) * smoothed_body
        body_mask_smooth = smoothed_body.astype(np.uint8)

        features_mask = np.zeros((height, width), dtype=np.uint8)

        try:
            face_results = face_mesh.process(rgb)

            if face_results.multi_face_landmarks:
                for face_landmarks in face_results.multi_face_landmarks:
                    h, w = frame.shape[:2]
                    landmarks = face_landmarks.landmark

                    def get_point(idx):
                        return (int(landmarks[idx].x * w), int(landmarks[idx].y * h))

                    left_eye_points = [get_point(idx) for idx in LEFT_EYE_INDICES]
                    right_eye_points = [get_point(idx) for idx in RIGHT_EYE_INDICES]
                    mouth_points = [get_point(idx) for idx in MOUTH_INDICES]
                    left_eyebrow_points = [get_point(idx) for idx in LEFT_EYEBROW]
                    right_eyebrow_points = [get_point(idx) for idx in RIGHT_EYEBROW]

                    cv2.fillPoly(features_mask, [np.array(left_eye_points)], 255)
                    cv2.fillPoly(features_mask, [np.array(right_eye_points)], 255)
                    cv2.fillPoly(features_mask, [np.array(mouth_points)], 255)
                    cv2.fillPoly(features_mask, [np.array(left_eyebrow_points)], 255)
                    cv2.fillPoly(features_mask, [np.array(right_eyebrow_points)], 255)

                    kernel = np.ones((5, 5), np.uint8)
                    features_mask = cv2.dilate(features_mask, kernel, iterations=2)

                    features_mask = cv2.GaussianBlur(features_mask, (15, 15), 0)
        except Exception as e:
            print(f"Ошибка при обработке лица на кадре {frame_count}: {e}")

        if smoothed_features is None:
            smoothed_features = features_mask.astype(np.float32)
        else:
            smoothed_features = alpha * features_mask.astype(np.float32) + (1 - alpha) * smoothed_features
        features_mask_smooth = smoothed_features.astype(np.uint8)

        output_frame = np.ones((height, width, 3), dtype=np.uint8) * 255

        body_mask_3ch = cv2.cvtColor(body_mask_smooth, cv2.COLOR_GRAY2BGR)
        output_frame = cv2.bitwise_and(output_frame, body_mask_3ch)

        features_mask_3ch = cv2.cvtColor(features_mask_smooth, cv2.COLOR_GRAY2BGR)

        features_mask_normalized = features_mask_smooth.astype(np.float32) / 255.0
        features_mask_normalized = np.stack([features_mask_normalized] * 3, axis=2)

        original_features = frame.copy()

        output_frame = (output_frame * (1 - features_mask_normalized) +
                       original_features * features_mask_normalized).astype(np.uint8)

        kernel = np.ones((3, 3), np.uint8)
        output_frame = cv2.morphologyEx(output_frame, cv2.MORPH_CLOSE, kernel)

        out.write(output_frame)
        frame_count += 1

        if frame_count % 30 == 0:
            print(f"Обработано кадров: {frame_count}")

    cap.release()
    out.release()
    print(f"Готово! Обработано {frame_count} кадров")
    print(f"Результат сохранён в: {output_path}")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Использование: python script.py <путь_к_видео> [путь_к_выходному_файлу] [порог]")
        print("Пример: python script.py ./Room.mp4")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    threshold = float(sys.argv[3]) if len(sys.argv) > 3 else 0.6

    process_video_original_features(input_file, output_file, threshold)

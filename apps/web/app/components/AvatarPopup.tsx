"use client";

import { useCallback, useEffect, useRef, useState, type PointerEvent as ReactPointerEvent, type WheelEvent as ReactWheelEvent } from "react";
import { apiFetch } from "../api-fetch";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "/api";

type AvatarPopupProps = {
    characterId: string;
    lang: "en" | "ru";
    onClose: () => void;
};

const VIEWPORT_W = 360;
const VIEWPORT_H = 303;

type UploadState =
    | { phase: "idle" }
    | { phase: "uploading"; percent: number }
    | { phase: "done" }
    | { phase: "error"; message: string };

/** Clamp offset so the image always covers the viewport (no empty space). */
function clampOffset(
    ox: number, oy: number,
    imgW: number, imgH: number,
): { ox: number; oy: number } {
    // Image right edge must be >= viewport right edge  →  ox + imgW >= VIEWPORT_W  →  ox >= VIEWPORT_W - imgW
    // Image left edge must be <= 0                      →  ox <= 0
    const minOX = Math.min(0, VIEWPORT_W - imgW);
    const maxOX = Math.max(0, VIEWPORT_W - imgW);
    const minOY = Math.min(0, VIEWPORT_H - imgH);
    const maxOY = Math.max(0, VIEWPORT_H - imgH);
    return {
        ox: Math.max(minOX, Math.min(maxOX, ox)),
        oy: Math.max(minOY, Math.min(maxOY, oy)),
    };
}

/** Minimum scale so image covers viewport entirely. */
function minCoverScale(nw: number, nh: number): number {
    if (nw === 0 || nh === 0) return 1;
    return Math.max(VIEWPORT_W / nw, VIEWPORT_H / nh);
}

export function AvatarPopup({ characterId, lang, onClose }: AvatarPopupProps) {
    const t = lang === "ru"
        ? { title: "Аватар", chooseFile: "Выбрать файл", upload: "Загрузить", ok: "Ок", loading: "Загрузка…", noImage: "Нет изображения" }
        : { title: "Avatar", chooseFile: "Choose file", upload: "Upload", ok: "Ok", loading: "Loading…", noImage: "No image" };

    const fileInputRef = useRef<HTMLInputElement>(null);
    const viewportRef = useRef<HTMLDivElement>(null);
    const imgRef = useRef<HTMLImageElement>(null);

    // Image state
    const [imageSrc, setImageSrc] = useState<string | null>(null);
    const [naturalW, setNaturalW] = useState(0);
    const [naturalH, setNaturalH] = useState(0);
    const [scale, setScale] = useState(1);
    const [offsetX, setOffsetX] = useState(0);
    const [offsetY, setOffsetY] = useState(0);

    // Drag state
    const dragRef = useRef<{ startX: number; startY: number; startOX: number; startOY: number } | null>(null);

    // Upload state
    const [uploadState, setUploadState] = useState<UploadState>({ phase: "idle" });

    // Load existing avatar on mount
    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                const resp = await apiFetch(`${API_URL}/characters/${characterId}/avatar`);
                if (!resp.ok) return;
                const blob = await resp.blob();
                if (cancelled) return;
                const url = URL.createObjectURL(blob);
                setImageSrc(url);
            } catch {
                // no avatar yet — fine
            }
        })();
        return () => { cancelled = true; };
    }, [characterId]);

    // When imageSrc changes, wait for natural dimensions
    const onImageLoad = useCallback(() => {
        const img = imgRef.current;
        if (!img) return;
        const nw = img.naturalWidth;
        const nh = img.naturalHeight;
        setNaturalW(nw);
        setNaturalH(nh);

        // Fit image to cover the viewport (no empty space)
        const coverScale = minCoverScale(nw, nh);
        setScale(coverScale);
        // center
        const { ox, oy } = clampOffset(
            (VIEWPORT_W - nw * coverScale) / 2,
            (VIEWPORT_H - nh * coverScale) / 2,
            nw * coverScale,
            nh * coverScale,
        );
        setOffsetX(ox);
        setOffsetY(oy);
    }, []);

    // Drag handlers
    const onPointerDown = useCallback((e: ReactPointerEvent<HTMLDivElement>) => {
        e.preventDefault();
        (e.target as HTMLElement).setPointerCapture(e.pointerId);
        dragRef.current = { startX: e.clientX, startY: e.clientY, startOX: offsetX, startOY: offsetY };
    }, [offsetX, offsetY]);

    const onPointerMove = useCallback((e: ReactPointerEvent<HTMLDivElement>) => {
        if (!dragRef.current) return;
        const dx = e.clientX - dragRef.current.startX;
        const dy = e.clientY - dragRef.current.startY;
        const imgW = naturalW * scale;
        const imgH = naturalH * scale;
        const { ox, oy } = clampOffset(dragRef.current.startOX + dx, dragRef.current.startOY + dy, imgW, imgH);
        setOffsetX(ox);
        setOffsetY(oy);
    }, [naturalW, naturalH, scale]);

    const onPointerUp = useCallback(() => {
        dragRef.current = null;
    }, []);

    // Zoom via scroll
    const onWheel = useCallback((e: ReactWheelEvent<HTMLDivElement>) => {
        e.preventDefault();
        const rect = viewportRef.current?.getBoundingClientRect();
        if (!rect) return;
        // Cursor position relative to viewport
        const cx = e.clientX - rect.left;
        const cy = e.clientY - rect.top;

        const factor = e.deltaY < 0 ? 1.08 : 1 / 1.08;
        // Don't allow zoom out below cover scale
        const minScale = minCoverScale(naturalW, naturalH);
        const newScale = Math.max(minScale, Math.min(20, scale * factor));

        // Adjust offset so the point under the cursor stays fixed
        const rawOX = cx - (cx - offsetX) * (newScale / scale);
        const rawOY = cy - (cy - offsetY) * (newScale / scale);
        const { ox, oy } = clampOffset(rawOX, rawOY, naturalW * newScale, naturalH * newScale);

        setScale(newScale);
        setOffsetX(ox);
        setOffsetY(oy);
    }, [scale, offsetX, offsetY, naturalW, naturalH]);

    // Choose file
    const onFileChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        e.target.value = "";
        if (!file) return;
        const url = URL.createObjectURL(file);
        setImageSrc(url);
        setUploadState({ phase: "idle" });
    }, []);

    // Crop & upload
    const handleUpload = useCallback(async () => {
        if (!imageSrc || naturalW === 0 || naturalH === 0) return;

        setUploadState({ phase: "uploading", percent: 0 });

        // Draw visible region onto canvas
        const canvas = document.createElement("canvas");
        canvas.width = VIEWPORT_W;
        canvas.height = VIEWPORT_H;
        const ctx = canvas.getContext("2d")!;
        const img = imgRef.current;
        if (!img) return;

        ctx.drawImage(
            img,
            0, 0, naturalW, naturalH,
            offsetX, offsetY, naturalW * scale, naturalH * scale,
        );

        // Export as JPEG blob (pdfkit doesn't support WebP)
        const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.88));
        if (!blob) {
            setUploadState({ phase: "error", message: "Failed to encode image" });
            return;
        }

        // Upload with progress via XMLHttpRequest
        const xhr = new XMLHttpRequest();
        xhr.open("PUT", `${API_URL}/characters/${characterId}/avatar`);

        // Copy auth header from apiFetch
        try {
            const tempResp = await apiFetch(`${API_URL}/characters/avatar-viewport`);
            // We'll just re-do with the current token
            void tempResp;
        } catch { /* ignore */ }

        // Get fresh auth token
        const { ensureFreshAuthIdToken, getCurrentAuthIdToken } = await import("../auth-context");
        const token = (await ensureFreshAuthIdToken(false)) ?? getCurrentAuthIdToken();
        if (token) {
            xhr.setRequestHeader("Authorization", `Bearer ${token}`);
        }
        xhr.setRequestHeader("Content-Type", "image/jpeg");

        xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
                const pct = Math.round((e.loaded / e.total) * 100);
                setUploadState({ phase: "uploading", percent: pct });
            }
        };

        xhr.onload = () => {
            if (xhr.status >= 200 && xhr.status < 300) {
                setUploadState({ phase: "done" });
            } else {
                setUploadState({ phase: "error", message: `HTTP ${xhr.status}` });
            }
        };

        xhr.onerror = () => {
            setUploadState({ phase: "error", message: "Network error" });
        };

        xhr.send(blob);
    }, [imageSrc, naturalW, naturalH, offsetX, offsetY, scale, characterId]);

    // Prevent background scroll when over popup
    useEffect(() => {
        const vp = viewportRef.current;
        if (!vp) return;
        const preventScroll = (e: globalThis.WheelEvent) => e.preventDefault();
        vp.addEventListener("wheel", preventScroll, { passive: false });
        return () => vp.removeEventListener("wheel", preventScroll);
    }, []);

    // Close on overlay click
    const onOverlayClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
        if (e.target === e.currentTarget) onClose();
    }, [onClose]);

    // Upload button label
    let uploadLabel: string;
    if (uploadState.phase === "uploading") {
        uploadLabel = `${t.upload} (${uploadState.percent}%)`;
    } else if (uploadState.phase === "done") {
        uploadLabel = t.ok;
    } else if (uploadState.phase === "error") {
        uploadLabel = `${t.upload} ⚠`;
    } else {
        uploadLabel = t.upload;
    }

    return (
        <div className="modal-overlay" onClick={onOverlayClick}>
            <div className="modal avatar-popup-modal" style={{ maxWidth: 420, width: "auto" }}>
                <div className="modal-header">
                    <span className="modal-title">{t.title}</span>
                    <button type="button" className="modal-close" onClick={onClose}>✕</button>
                </div>
                <div className="modal-body" style={{ padding: "16px 18px", display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
                    {/* Viewport */}
                    <div
                        ref={viewportRef}
                        className="avatar-viewport"
                        style={{
                            width: VIEWPORT_W,
                            height: VIEWPORT_H,
                            overflow: "hidden",
                            position: "relative",
                            borderRadius: 10,
                            border: "1px solid rgba(255,255,255,0.1)",
                            background: "rgba(4,6,11,0.9)",
                            cursor: imageSrc ? (dragRef.current ? "grabbing" : "grab") : "default",
                            touchAction: "none",
                            userSelect: "none",
                        }}
                        onPointerDown={imageSrc ? onPointerDown : undefined}
                        onPointerMove={imageSrc ? onPointerMove : undefined}
                        onPointerUp={imageSrc ? onPointerUp : undefined}
                        onPointerCancel={imageSrc ? onPointerUp : undefined}
                        onWheel={imageSrc ? onWheel : undefined}
                    >
                        {imageSrc ? (
                            <img
                                ref={imgRef}
                                src={imageSrc}
                                alt="avatar"
                                onLoad={onImageLoad}
                                draggable={false}
                                style={{
                                    position: "absolute",
                                    left: offsetX,
                                    top: offsetY,
                                    width: naturalW * scale || "auto",
                                    height: naturalH * scale || "auto",
                                    pointerEvents: "none",
                                    imageRendering: "auto",
                                }}
                            />
                        ) : (
                            <div style={{
                                width: "100%",
                                height: "100%",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                color: "rgba(255,255,255,0.25)",
                                fontSize: 13,
                            }}>
                                {t.noImage}
                            </div>
                        )}
                    </div>

                    {/* Buttons */}
                    <div style={{ display: "flex", gap: 8, width: "100%", justifyContent: "center" }}>
                        <input
                            ref={fileInputRef}
                            type="file"
                            accept="image/png, image/jpeg, image/jpg, image/bmp, image/webp"
                            style={{ display: "none" }}
                            onChange={onFileChange}
                        />
                        <button
                            type="button"
                            className="btn"
                            onClick={() => fileInputRef.current?.click()}
                        >
                            {t.chooseFile}
                        </button>
                        <button
                            type="button"
                            className="btn btn-primary"
                            disabled={!imageSrc || uploadState.phase === "uploading" || uploadState.phase === "done"}
                            onClick={() => void handleUpload()}
                        >
                            {uploadLabel}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
